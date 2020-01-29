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

-------------------------------------------------------------
-- In this example we will see if a query is "fast" enough --
-------------------------------------------------------------
-- Execute the query (we are returning a single record)
-- Is it fast enough?
USE [2Fast2Furious]
GO
SET STATISTICS TIME ON
SELECT id, batchid FROM table1 WHERE id = 50999
SET STATISTICS TIME OFF



-- Display Estimated query plan
-- Run again and look at statistics io 
SET STATISTICS IO ON
SELECT batchid FROM table1 WHERE id = 50999
SET STATISTICS IO OFF



-- In SqlQueryStress run the following 
-- 100 iterations, 10 threads
UPDATE table1 SET batchid = batchid 
WHERE id = (1+ ABS(CHECKSUM(NewId())) % 50998)
-- 1000 updates took?
-- The same problem searching for your data also exists for updates


-- Lets create a clustered index to satisfy the query predicate
-- and included cCREATE CLUSTERED INDEX IX_table1_id ON table1 (id)olumns



-- Run the update again
-- How long does it take this time?


-- Display Estimated query plan again
-- Run again and look at statistics io 
SET STATISTICS IO ON
SELECT batchid FROM table1 WHERE id = 50999
SET STATISTICS IO OFF

-- Better?

-- Bad indexing strategy and poorly written queries
-- can substantially effect your data access patterns
-- A QUERY IS FAST ENOUGH IF IT ACCESSES THE MINIMUM
-- AMOUNT OF PAGES POSSIBLE IN ORDER TO SATISFY
