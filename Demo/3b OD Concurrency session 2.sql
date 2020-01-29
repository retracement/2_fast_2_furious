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

/*******************************/
/* Concurrency through locking */
/*******************************/
-- In this section we will demonstrate how SQL Server
-- locking can effect concurrency

----------------------------------------------------------
-- In this example we will look at how escalation works --
----------------------------------------------------------
-- We will execute transactional updates in batches

-- Look at open locks
USE [2Fast2Furious]
GO
SET NOCOUNT ON

EXEC sp_lock
-- Once escalation occurs, skip the switch back


-- Switch to session 1 (these will be repeated until we escalate)


-- lets now try querying the table
SELECT TOP (1) * FROM table1


-- Switch to session 1
