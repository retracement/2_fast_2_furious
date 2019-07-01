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
-- can return inconsistent or problematic results
-- aka "isolation matters" 


--------------------------------------------------------
-- In this example we will look at inconsistent reads --
--------------------------------------------------------
-- Execute a transaction to delete all records and insert with 10 records
-- we expect that (with exception) we will either be blocked or always return 10 records
SET NOCOUNT ON
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK
TRUNCATE TABLE Cars

WHILE 1=1
BEGIN 
	BEGIN TRAN
		DELETE FROM Cars

		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Ferrari', 170, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Porsche', 150, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Lamborghini', 175, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Mini', 110, '')	
		WAITFOR DELAY '00:00:00.02'
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Datsun', 90, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Ford', 125, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Audi', 138, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('BMW', 120, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Honda', 87, '')
		INSERT INTO Cars(Carname, SpeedMPH, Details) VALUES('Mercedes', 155, '')   
	COMMIT TRAN
END


-- Switch to session 2


-- Stop the running while loop



--------------------------------------------------------
-- In this example we will look at atomicity concerns --
--------------------------------------------------------
-- Rollback any open transactions
SET NOCOUNT OFF
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK


-- Create our table and insert a record
CREATE TABLE t1 (c1 INT)
GO
INSERT INTO t1 VALUES ('1');
 

-- Start open ended transaction
-- and update our record
BEGIN TRAN
    UPDATE t1 SET c1 = 3 WHERE c1=1
	

-- Switch to session 2


-- Commit transaction and query 
-- table records
COMMIT
SELECT * FROM t1

-- Review the number of rows
-- and their values :)