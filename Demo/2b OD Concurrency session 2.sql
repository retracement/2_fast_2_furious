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
