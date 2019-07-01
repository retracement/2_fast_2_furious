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

/*******************************/
/* Concurrency through locking */
/*******************************/
-- In this section we will demonstrate how SQL Server
-- locking can effect concurrency

----------------------------------------------------------
-- In this example we will look at how escalation works --
----------------------------------------------------------
-- We will execute transactional updates in batches

-- Look at table
USE [2Fast2Furious]
GO
SET NOCOUNT ON
SELECT TOP 3 * FROM table1 
SELECT COUNT(*) AS 'Rows' FROM table1 


-- Look at active locks
EXEC sp_lock


-- Escalation occurs when > 5000 locks are taken


-- Start transaction and update < 1000 records
SET NOCOUNT OFF -- So we can see updates
BEGIN TRAN
	UPDATE table1
	SET batchid=1 WHERE id < 1000;


	-- Switch to session 2



	-- Update < 4999 records
	UPDATE table1
	SET batchid=1 WHERE id >= 1000 AND id < 6000;
	

	-- Switch to session 2
	-- (run EXEC sp_lock)


	-- Update batch > 5000 records
	UPDATE table1
	SET batchid=1 WHERE id > 6000 AND id < 12000;
	

	-- Switch to session 2
	-- (run EXEC sp_lock)


-- Rollback tran
ROLLBACK TRAN
-- fin