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
-- can return inconsistent or problematic results
-- aka "isolation matters" 


--------------------------------------------------------
-- In this example we will look at inconsistent reads --
--------------------------------------------------------
-- Execute a transaction to delete all records and insert with 10 records.
-- Since this modification is transactional we would expect other sessions
-- to always return 10 records or be blocked.
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
-- We want to try and avoid transactions getting
-- blocked - because our API developer apparently says
-- he can replay them. Should we be concerned?

-- Rollback any open transactions
SET NOCOUNT OFF
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK


-- Create our table and insert a record
IF OBJECT_ID('dbo.t1','U') IS NOT NULL DROP TABLE t1
CREATE TABLE t1 (c1 INT)
GO
INSERT INTO t1 (c1) VALUES ('1');


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

-- Errm!

-- Presenters Note:
-- REMEMBER AS A DEVELOPER YOU ARE BALANCING
-- CONCURRENCY AGAINST CORRECTNESS CONCERNS!