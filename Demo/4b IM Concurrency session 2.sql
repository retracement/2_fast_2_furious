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


-- One record has been updated in the table
-- on-disk read committed should block......
-- query all table records under read committed
SET NOCOUNT ON
USE [2Fast2Furious]
GO
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SELECT * FROM [dbo].[ArrestsIM]


-- lets repeat under serializable
SET NOCOUNT ON
USE [2Fast2Furious]
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
SELECT * FROM [dbo].[ArrestsIM]

/*
Msg 41333, Level 16, State 1, Line 37
The following transactions must access memory optimized tables and natively compiled modules under 
snapshot isolation: RepeatableRead transactions, Serializable transactions, and transactions that 
access tables that are not memory optimized in RepeatableRead or Serializable isolation.
*/

-- Attempt to create Native Compilation Stored Procedure
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
USE [2Fast2Furious]
GO

CREATE PROCEDURE dbo.QueryArrestsIM
	WITH NATIVE_COMPILATION,
	SCHEMABINDING,
	EXECUTE AS OWNER
AS
	BEGIN ATOMIC WITH -- Create tran if no open or create savepoint
		(TRANSACTION ISOLATION LEVEL = SERIALIZABLE,
		LANGUAGE = N'british' -- language required
		)
		BEGIN
			select * from [dbo].[ArrestsIM]
		END
	END
GO

-- Note the error :)


-- Try again
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
			select id, Arrest_Date, Charges, Details from [dbo].[ArrestsIM]
		END
	END
GO


-- Execute Native Compilation Stored Procedure
EXEC dbo.QueryArrestsIM

-- Did SERIALIZABLE for In-Memory have to wait?


-- Switch back to session 1


--fin