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
/* Drop Database 2Fast2Furious */
/*******************************/
USE master
GO
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = '2Fast2Furious')
BEGIN
	ALTER DATABASE [2Fast2Furious] 
		SET READ_ONLY WITH ROLLBACK IMMEDIATE;
		DROP DATABASE [2Fast2Furious];
END

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = '2Fast2Furious')
BEGIN
	PRINT 'Warning 2Fast2Furious database still exists'
END

/*********************************/
/* Create Database 2Fast2Furious */
/*********************************/
USE master
GO
-- Change these paths for your environment
-- DECLARE @defaultdatapath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA' --SQL2016
-- DECLARE @defaultlogpath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA'
DECLARE @defaultdatapath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA' --SQL2016
DECLARE @defaultlogpath NVARCHAR(512) = 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA' -- SQL2017

DECLARE @createdb VARCHAR(MAX)=
'CREATE DATABASE [2Fast2Furious]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N''2Fast2Furious_data'', FILENAME = N''' + @defaultdatapath + '\2Fast2Furious_data.mdf'' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N''2Fast2Furious_log'', FILENAME = N''' + @defaultlogpath + '\2Fast2Furious_log.ldf'' , SIZE = 1GB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )'
EXEC(@createdb)
GO
ALTER DATABASE [2Fast2Furious] SET RECOVERY SIMPLE
ALTER DATABASE [2Fast2Furious] SET AUTO_CREATE_STATISTICS OFF;
GO

-- Allow the use of on-disk SNAPSHOT ISOLATION in the database
-- this is used in one of the demos and is set to allow ahead
-- of time for convenience
ALTER DATABASE [2Fast2Furious] SET ALLOW_SNAPSHOT_ISOLATION ON
GO

--for ref only
/*
ALTER DATABASE [2Fast2Furious] SET READ_COMMITTED_SNAPSHOT ON WITH NO_WAIT
GO
*/

/*********************/
/* Create Table Cars */
/*********************/
USE [2Fast2Furious]
GO
CREATE TABLE Cars (id uniqueidentifier DEFAULT NEWID(), carname VARCHAR(20), lastservice datetime DEFAULT getdate(), SpeedMPH INT, Details CHAR (7000) CONSTRAINT [PK__Cars] PRIMARY KEY CLUSTERED ([id]))
GO


/*********************/
/* Create Table table1 */
/*********************/
USE [2Fast2Furious]
GO
SET NOCOUNT ON
CREATE TABLE table1 (id INT, batchid INT, inv INT)
GO
DECLARE @x INT = 1
WHILE @x < 51000
BEGIN
	INSERT INTO table1 VALUES (@x,0, ABS(50998-@x))
	SET @x = @x+1
END