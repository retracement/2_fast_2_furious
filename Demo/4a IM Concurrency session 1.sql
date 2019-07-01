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

/*******************************************/
/* Concurrency with In-Memory transactions */
/*******************************************/
-- In this section we will demonstrate how SQL Server
-- handles isolation with in-memory transactions


--------------------------------------------------------
-- In this example we will look at IMOLTP concurrency --
--------------------------------------------------------
-- We will see how IMOLTP enables concurrency

-- Open a transaction and update a record
SET NOCOUNT ON
USE [2Fast2Furious]
GO
IF @@TRANCOUNT <> 0 ROLLBACK

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


-- Run transaction under snapshot
IF @@TRANCOUNT <> 0 ROLLBACK

BEGIN TRAN
	UPDATE [dbo].[ArrestsIM] WITH (SNAPSHOT) SET charges = 0
	WHERE id = 3111


-- Switch to session 2


IF @@TRANCOUNT <> 0 ROLLBACK



--fin