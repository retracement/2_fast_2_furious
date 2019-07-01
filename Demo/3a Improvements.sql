/************************************************************
*   All scripts contained within are Copyright © 2015 of    *
*   SQLCloud Limited, whether they are derived or actual    *
*   works of SQLCloud Limited or its representatives        *
*************************************************************
*   All rights reserved. No part of this work may be        *
*   reproduced or transmitted in any form or by any means,  *
*   electronic or mechanical, including photocopying,       *
*   recording, or by any information storage or retrieval   *
*   system, without the prior written permission of the     *
*   copyright owner and the publisher.                      *
************************************************************/

/**************************/
/* Implement Improvements */
/**************************/
-- In this section we will look at implementing 
-- improvements to our database

--------------------------------------------------------
-- In this example we will look at implementing temp  --
-- tables using efficient techniques                  --
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
SELECT * from #MyTable1 WHERE id = 25000



---------------------------------------------------------
-- In this example we will look at implementing IMOLTP --
---------------------------------------------------------
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


-- SQLQueryStress execute transaction under
-- 1000 iterations, 4 threads
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
GO 2000


-- SQLQueryStress execute NCP transaction under
-- 1000 iterations, 4 threads
EXEC dbo.InsertArrestsIM
GO 2000

-- Was it any quicker?
-- We might have cheated slightly -do you know where?



---------------------------------------------------------------
-- In this example we will look at implementing IMOLTP types --
---------------------------------------------------------------
-- We will execute transactional updates in batches

-- Create an In-Memory table type
USE [2Fast2Furious]
GO
CREATE TYPE [dbo].[PersonTyp] AS TABLE( 
  [PersonID] [INT] NOT NULL,    
  [Height] [SMALLINT] NOT NULL, 
  [Hair] [VARCHAR] NOT NULL,  
  INDEX [IX_PersonID] HASH ([PersonID]) WITH ( BUCKET_COUNT = 8),  
  INDEX [IX_Height]  NONCLUSTERED ([Height])
)  WITH ( MEMORY_OPTIMIZED = ON) --note durability not supported in table types  


-- Declare In-Memory temp table variables!
-- And lets use them (obviously they are 
-- only available within batch scope
DECLARE @PersonsTable1 [PersonTyp]
DECLARE @PersonsTable2 [PersonTyp]

BEGIN TRAN
	INSERT INTO @PersonsTable1 VALUES (1,200,'None')
	INSERT INTO @PersonsTable1 VALUES (2,172,'Black')
	INSERT INTO @PersonsTable1 VALUES (3,180,'Blonde')
	INSERT INTO @PersonsTable1 VALUES (4,175,'Brown')
	INSERT INTO @PersonsTable1 VALUES (5,165,'Black')
COMMIT

INSERT INTO @PersonsTable2 SELECT * FROM @PersonsTable1 
	WHERE PersonID > 3
	
SELECT * FROM @PersonsTable1 WHERE PersonID = 2 

SELECT * FROM @PersonsTable1 WHERE Height > 180 


-- Now select the whole batch and look at query plans
-- notice when and why there are scans and seeks
-- in the context of IMOLTP indexing
