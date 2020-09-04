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
-- Is it fast enough? (note the execution time)
USE [2Fast2Furious]
GO
SET STATISTICS TIME ON
SELECT id, batchid FROM table1 WHERE id = 50999
SET STATISTICS TIME OFF


-- Include actual execution plan
-- Run again
	-- Look at the query cost on the query plan
	-- Look at statistics io
SET STATISTICS IO ON
SELECT id, batchid FROM table1 WHERE id = 50999
SET STATISTICS IO OFF


-- Lets do updates using same access pattern
-- In SqlQueryStress run the following 
-- 100 iterations, 10 threads

-- Update a random rows in parallel
UPDATE table1 SET batchid = batchid 
WHERE id = (1+ ABS(CHECKSUM(NewId())) % 50998)
-- 1000 updates took?
-- The same access pattern searching for your data also exists for updates
-- You can see this if you look at the execution plan


-- Lets create a clustered index to satisfy the query predicate
-- and included columns
CREATE CLUSTERED INDEX IX_table1_id ON table1 (id)


-- Run the update again
-- How long does it take this time?


-- Run SELECT again and look at statistics io
-- Display Estimated query plan
SET STATISTICS IO ON
SELECT batchid FROM table1 WHERE id = 50999
SET STATISTICS IO OFF

-- Better?
-- If quicker, why?  

-- Presenters Note 1:
-- Bad indexing strategy and poorly written queries
-- can substantially effect your data access patterns
-- This about access patterns, data reads/writes, locking, 
-- blocking, and even deadlocking - ALL exacerbated by concurrency.

-- Presenters Note 2:
-- A QUERY IS FAST ENOUGH IF IT ACCESSES THE MINIMUM
-- AMOUNT OF PAGES POSSIBLE IN ORDER TO SATISFY THE
-- RESULT SET




--- /*IGNORE FOR NOW OUT OF SCOPE IN DEMO*/
---TO ADD SORTS, JOINS, KEY COLUMNS/ INCLUDES