/*************************************************************/
/* All scripts contained within are Copyright © 2015 of      */
/* Mark Broadbent, whether they are derived or actual        */
/* works by him or his representatives                       */
/*************************************************************/
/* They are distributed under the Apache 2.0 licence and any */
/* reproducion, transmittion, storage, or derivation must    */
/* comply with the terms under the licence linked below.     */
/* If in any doubt, contact the license owner for written    */
/* permission by emailing contactme@sturmovik.net            */
/*************************************************************
Copyright [2019] [Mark Broadbent]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.*/

/**************************/
/* Implement Improvements */
/**************************/
-- In this section we will look at implementing 
-- improvements to our database

--------------------------------------------------------
-- In this example we will look at techniques for     --
-- efficiently implementing temp tables               --
--------------------------------------------------------
SET NOCOUNT ON
USE [2Fast2Furious]
GO

-- Create compressed empty temp table
-- You can also alter a temp table and add compression
-- but do before it is loaded
CREATE TABLE #MyTable1 (id INT, name VARCHAR(100)) 
WITH (DATA_COMPRESSION = PAGE)


-- Load temp table
DECLARE @x INT = 0
WHILE @x < 30000
BEGIN
	INSERT INTO #MyTable1 VALUES (@x,'{your column value for id}')
	SET @x = @x + 1
END


-- Add index for efficient joins
CREATE CLUSTERED INDEX ix_t_mytable1 ON #MyTable1 (id)


-- Look at table execution plan
-- How efficient is our data access to our temp table?
SELECT * from #MyTable1 WHERE id = 25000



---------------------------------------------------------
-- In this example we will look at implementing IMOLTP --
---------------------------------------------------------
-- This can be useful to reduce transacation log overhead/ bottleneck
-- We will execute transactional updates in batches
-- Enable Database for IMOLTP
USE [master]
GO
ALTER DATABASE [2Fast2Furious] ADD FILEGROUP IMOLTP_FG
CONTAINS MEMORY_OPTIMIZED_DATA
USE [master]
GO


USE master
GO
-- Change these paths for your environment
-- DECLARE @defaultdatapath NVARCHAR(512)= 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA' --SQL2016
DECLARE @defaultdatapath NVARCHAR(512)= 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA' --SQL2017

-- Add container1 to filegroups.
DECLARE @createdb VARCHAR(MAX)=
'
ALTER DATABASE [2Fast2Furious] 
	ADD FILE ( NAME = N''2Fast2Furious_imoltp_1'', 
	FILENAME = N''' + @defaultdatapath +'\2Fast2Furious_IMOLTP_1'' )
	TO FILEGROUP [IMOLTP_FG]'
	print @createdb
EXEC(@createdb)
GO


-- Create In-Memory table
USE [2Fast2Furious]
GO
CREATE TABLE ArrestsIM 
	(id INT IDENTITY PRIMARY KEY NONCLUSTERED HASH
		WITH (BUCKET_COUNT=8000) NOT NULL, --bucket size compromises performance
		-- Bucket count (power of two), so 2^13 = 8192
	Arrest_Date datetime DEFAULT getdate(), 
	Charges INT INDEX idxCharges NONCLUSTERED, 
	Details CHAR (50))
	WITH (MEMORY_OPTIMIZED=ON, --defines in-memory table
	DURABILITY = SCHEMA_AND_DATA) --default (also SCHEMA_ONLY)
-- Presenters note: In-Memory table durability is not
-- related to delayed durability! (in means durability of IM table)
GO



-- SQLQueryStress execute transaction under
-- 1000 iterations, 4 threads
-- 50 iterations, 4 threads (if using my cloud db)
BEGIN TRAN
	INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
		VALUES (GETDATE(), 10);
	INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
		VALUES (GETDATE(), 15);
	INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
		VALUES (GETDATE(), 5);
	INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
		VALUES (GETDATE(), 7);
COMMIT



-- Create Native Compilation Stored Procedure
USE [2Fast2Furious]
GO

CREATE PROCEDURE dbo.InsertArrestsIM
	WITH NATIVE_COMPILATION, -- native proc
	SCHEMABINDING, -- prevent drop
	EXECUTE AS OWNER -- execution context required either OWNER/SELF/USER
AS
	BEGIN ATOMIC WITH -- Create tran if no open or create savepoint
		(TRANSACTION ISOLATION LEVEL = SNAPSHOT, -- SERIALIZABLE or REPEATABLE READ
		LANGUAGE = N'british', -- language required
		DELAYED_DURABILITY = ON -- not required
		)
-- Presenters note: Delayed durability can be forced or allowed on DB
-- Allowed means native compilation procedure can use it through
-- DELAYED_DURABILITY = ON
		BEGIN
			INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
				VALUES (GETDATE(), 10);
			INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
				VALUES (GETDATE(), 15);
			INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
				VALUES (GETDATE(), 5);
			INSERT INTO dbo.ArrestsIM (Arrest_date, Charges) 
				VALUES (GETDATE(), 7);
		END
	END
GO



-- SQLQueryStress execute NCP transaction under
-- 1000 iterations, 4 threads
-- 50 iterations, 4 threads (if using my cloud db)
EXEC dbo.InsertArrestsIM

-- Was it any quicker?
-- We might have cheated slightly -do you know where?



---------------------------------------------------------------
-- In this example we will look at implementing IMOLTP types --
---------------------------------------------------------------
-- We will look at them as very easy and efficient replacement
-- to on-disk temp tables

-- First define our In-Memory table type
USE [2Fast2Furious]
GO
CREATE TYPE [dbo].[PersonTyp] AS TABLE( 
  [PersonID] [INT] NOT NULL,    
  [Height] [SMALLINT] NOT NULL, 
  [Hair] [VARCHAR](10) NOT NULL,  
  INDEX [IX_PersonID] HASH ([PersonID]) WITH ( BUCKET_COUNT = 8),  
  INDEX [IX_Height]  NONCLUSTERED ([Height])
)  WITH ( MEMORY_OPTIMIZED = ON) --note durability not supported in table types  



-- Declare In-Memory temp table variables!
-- And lets use them (obviously they are 
-- only available within batch scope



-- Select Include Actual Execution Plan



DECLARE @PersonsTable1 [PersonTyp]
DECLARE @PersonsTable2 [PersonTyp]

BEGIN TRAN
	INSERT INTO @PersonsTable1 VALUES (1,200,'None')
	INSERT INTO @PersonsTable1 VALUES (2,172,'Black')
	INSERT INTO @PersonsTable1 VALUES (3,180,'Blonde')
	INSERT INTO @PersonsTable1 VALUES (4,175,'Brown')
	INSERT INTO @PersonsTable1 VALUES (5,165,'Black')
COMMIT

INSERT INTO @PersonsTable2 SELECT * FROM @PersonsTable1 --Query 6
	WHERE PersonID > 3
	
SELECT * FROM @PersonsTable1 WHERE PersonID = 2  --Query 7

SELECT * FROM @PersonsTable1 WHERE Height > 180 --Query 8

SELECT * FROM @PersonsTable1 WHERE PersonID > 4 AND PersonID <6 --Query 9


-- Now select the whole batch and 
-- review the Execution Plan for the 1 INSERT statement
-- and 3 SELECT statements (queries 6, 7, 8, 9)
-- When and why are there SCANS and SEEKS?
-- Understand the context of IMOLTP indexing

-- fin.