/*
===============================================================================
Script Name : init_database.sql
Project     : SQL Data Warehouse Project
Platform    : Microsoft SQL Server (T-SQL) | Tested in SSMS
===============================================================================

Purpose:
    Creates the 'DataWarehouse' database and the three schemas of the
    Medallion Architecture inside it:

        bronze  ->  raw data, loaded as-is from the source systems
        silver  ->  cleaned and standardized data
        gold    ->  business-ready data for reporting and analytics

    If a database named 'DataWarehouse' already exists, it is dropped and
    recreated from scratch.

WARNING:
    Running this script will DROP the entire 'DataWarehouse' database if it
    exists. All data in it will be permanently deleted.
    Make sure you have a proper backup before running this script.

Usage Notes:
    - Run the whole script at once (F5 in SSMS). No database needs to be
      selected beforehand; the script switches databases by itself.
    - Do NOT remove the GO separators. CREATE SCHEMA must be the first
      statement in its batch, otherwise SQL Server raises Msg 111.
===============================================================================
*/

-- ============================================================================
-- Step 1: Switch to the master database
-- (a database cannot be dropped while you are connected to it)
-- ============================================================================
USE master;
GO

-- ============================================================================
-- Step 2: Drop the 'DataWarehouse' database if it already exists
-- ============================================================================
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
    PRINT 'Existing database [DataWarehouse] has been dropped.';
END;
GO

-- ============================================================================
-- Step 3: Create the 'DataWarehouse' database
-- ============================================================================
CREATE DATABASE DataWarehouse;
GO

PRINT 'Database [DataWarehouse] has been created.';
GO

-- ============================================================================
-- Step 4: Switch to the new database
-- (all schemas below are created inside DataWarehouse, not master)
-- ============================================================================
USE DataWarehouse;
GO

-- ============================================================================
-- Step 5: Create the schemas (one batch per schema)
-- ============================================================================

-- Bronze layer: raw data
CREATE SCHEMA bronze;
GO

-- Silver layer: cleaned and standardized data
CREATE SCHEMA silver;
GO

-- Gold layer: business-ready data
CREATE SCHEMA gold;
GO

-- ============================================================================
-- Step 6: Verify the result (should return bronze, gold, silver)
-- ============================================================================
SELECT name AS schema_name
FROM sys.schemas
WHERE name IN (N'bronze', N'silver', N'gold')
ORDER BY name;
GO
