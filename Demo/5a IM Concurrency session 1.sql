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


-----------------------------------------------------------------------
-- In this example we will look at the use of isolation hints IMOLTP --
-----------------------------------------------------------------------
-- We will see how IMOLTP handles explicit transactions

-- Rollback open transactions
SET NOCOUNT ON
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK

-- Open a transaction and update a record
-- Attempt to update a record under transaction
BEGIN TRAN
	UPDATE [dbo].[ArrestsIM] SET charges = 0
	WHERE id = 3111

/*
Msg 41368, Level 16, State 0, Line 2
Accessing memory optimized tables using the READ COMMITTED isolation level is supported only 
for autocommit transactions. It is not supported for explicit or implicit transactions. Provide 
a supported isolation level for the memory optimized table using a table hint, such as WITH (SNAPSHOT).

Presenters note: this operation can therefore either operate as a single (autocommit statement) or we
are forced to a different isolation
*/



--------------------------------------------------------
-- In this example we will look at IMOLTP concurrency --
--------------------------------------------------------
-- Run transaction under snapshot
IF @@TRANCOUNT <> 0 ROLLBACK

BEGIN TRAN
	UPDATE [dbo].[ArrestsIM] WITH (SNAPSHOT) SET charges = 0
	WHERE id = 6


-- Switch to session 2


IF @@TRANCOUNT <> 0 ROLLBACK



--fin