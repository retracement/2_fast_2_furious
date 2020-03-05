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

/*******************************************/
/* Concurrency with In-Memory transactions */
/*******************************************/
-- In this section we will demonstrate how SQL Server
-- handles isolation with in-memory transactions


--------------------------------------------------------
-- In this example we will look at IMOLTP concurrency --
--------------------------------------------------------
-- We will see how IMOLTP enables concurrency


-- One record has been updated in the table
-- so on-disk read committed would block......
-- query all table records under read committed for IM table
SET NOCOUNT ON
USE [2Fast2Furious]
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SELECT * FROM [dbo].[ArrestsIM] ORDER BY id
-- Review id 6 that is being updated in an open ended transaction
-- i.e. we still have charges

-- lets repeat under serializable
SET NOCOUNT ON
USE [2Fast2Furious]
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
SELECT * FROM [dbo].[ArrestsIM] ORDER BY id
/*
Msg 41333, Level 16, State 1, Line 37
The following transactions must access memory optimized tables and natively compiled modules under 
snapshot isolation: RepeatableRead transactions, Serializable transactions, and transactions that 
access tables that are not memory optimized in RepeatableRead or Serializable isolation.
*/


-- So lets attempt to create Native Compilation Stored Procedure
-- to do the same thing
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
USE [2Fast2Furious]
GO

CREATE PROCEDURE dbo.QueryArrestsIM
	WITH NATIVE_COMPILATION,
	SCHEMABINDING,
	EXECUTE AS OWNER
AS
	BEGIN ATOMIC WITH -- Create tran if no open or create savepoint
		(TRANSACTION ISOLATION LEVEL = SERIALIZABLE, -- SNAPSHOT or REPEATABLE READ
		LANGUAGE = N'british' -- language required
		)
		BEGIN
			SELECT id, Arrest_Date, Charges, Details FROM [dbo].[ArrestsIM]
				ORDER BY id
		END
	END
GO


-- Execute Native Compilation Stored Procedure
EXEC dbo.QueryArrestsIM

-- Did SERIALIZABLE for In-Memory have to wait or fail?


--fin