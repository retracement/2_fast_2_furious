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

/**********************************/
/* Consistency and bad behaviours */
/**********************************/
-- In this section we will demonstrate how SQL Server
-- can return inconsistent or problematic result


--------------------------------------------------------
-- In this example we will look at inconsistent reads --
--------------------------------------------------------

-- Run a while loop to insert all visible records to a temp table and BREAK
-- if record count is not equal to 10.
-- Excecute this several times until you are happy
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE 1=1
BEGIN
	DELETE FROM @Cars
	INSERT INTO @Cars SELECT * FROM Cars --with (holdlock) --with (serializable)
	IF @@ROWCOUNT <> 10
		BREAK

	SET @ConsistentResults = @ConsistentResults + 1
	WAITFOR DELAY '00:00:00.013'
END
SELECT @ConsistentResults AS SuccessfulPriorRuns
SELECT * FROM @Cars

-- Note the biggest trigger for this problem is the table Cluster GUID
-- and the way SQL accesses mixed extents
-- See https://www.sqlskills.com/blogs/paul/read-committed-doesnt-guarantee-much/



-- Let's repeat under SERIALIZABLE
-- Excecute this several times until you are happy
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE 1=1
BEGIN
	BEGIN TRY
		DELETE FROM @Cars
		INSERT INTO @Cars SELECT * FROM Cars WITH (SERIALIZABLE)
		IF @@ROWCOUNT <> 10
			BREAK

		SET @ConsistentResults = @ConsistentResults + 1
		WAITFOR DELAY '00:00:00.013'
	END TRY
	BEGIN CATCH -- we need catch in this scenario to output runs on DL
		SELECT @ConsistentResults AS SuccessfulPriorRuns
		SELECT * FROM @Cars
		SELECT ERROR_MESSAGE() 
		BREAK
	END CATCH
END


-- Let's transition to a new OPTIMISTIC default
-- of READ_COMMITTED_SNAPSHOT
USE MASTER
GO
ALTER DATABASE [2Fast2Furious] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO
USE [2Fast2Furious];
GO


/***************************************WARNING**********************************/
/* You'll need to SWITCH BACK to SESSION 1 and RERUN the loop before continuing */
/********************************************************************************/


-- Run again using the new default of READ_COMMITTED_SNAPSHOT
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE 1=1
BEGIN
	DELETE FROM @Cars
	INSERT INTO @Cars SELECT * FROM Cars --with (holdlock) --with (serializable)
	IF @@ROWCOUNT <> 10
		BREAK

	SET @ConsistentResults = @ConsistentResults + 1
	WAITFOR DELAY '00:00:00.013'
END
SELECT @ConsistentResults AS SuccessfulPriorRuns
SELECT * FROM @Cars



-- Finally let's repeat under SNAPSHOT
-- and cancel once you are happy
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
SET NOCOUNT ON
DECLARE @Cars TABLE (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), 
	lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000));
DECLARE @ConsistentResults INT = 0
WHILE 1=1
BEGIN
	DELETE FROM @Cars
	INSERT INTO @Cars SELECT * FROM Cars --SNAPSHOT HINT ONLY RELEVANT TO IMTABLES
	IF @@ROWCOUNT <> 10
		BREAK

	SET @ConsistentResults = @ConsistentResults + 1
	WAITFOR DELAY '00:00:00.013'
END


-- Let's transition back to READ COMMITTED default
USE MASTER
GO
ALTER DATABASE [2Fast2Furious] SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE;
GO
USE [2Fast2Furious];
GO


-- set isolation level back to read committed
SET TRANSACTION ISOLATION LEVEL READ COMMITTED



-- Switch back to session 1 (stop the while loop *if* still running)



--------------------------------------------------------
-- In this example we will look at atomicity concerns --
--------------------------------------------------------
-- and attempt to solve them
SET NOCOUNT OFF
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK


-- Set a lock timeout to avoid any waiting on lock
SET LOCK_TIMEOUT 10


-- Run a transaction to insert a new record
-- and DELETE any records with an ID of 1
BEGIN TRAN
    INSERT INTO t1 VALUES ('2');
    DELETE FROM t1 WHERE c1 = 1; --wait (block) on X lock
COMMIT


-- Check transaction has rolled back (or committed...)
SELECT @@TRANCOUNT AS Trancount


-- Switch back to session 1
--fin.