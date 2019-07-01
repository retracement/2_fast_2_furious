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


-- set isolation level back to read committed
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


-- Switch back to session 1
-- and stop the while loop



--------------------------------------------------------
-- In this example we will look at atomicity concerns --
--------------------------------------------------------
-- and attempt to solve them
SET NOCOUNT OFF
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK


-- Set a lock timeout to avoid waiting on lock
SET LOCK_TIMEOUT 10


-- Run a transaction to insert a new record
-- and DELETE any records with an ID of 1
BEGIN TRAN
    INSERT INTO t1 VALUES ('2');
    DELETE FROM t1 WHERE c1 = 1;
COMMIT


-- Has transaction rolled back
-- or committed?
SELECT @@TRANCOUNT AS Trancount


-- Query table jumping over other
-- session locked records (if any)
SELECT * FROM t1 WITH (READPAST);


-- Switch back to session 1