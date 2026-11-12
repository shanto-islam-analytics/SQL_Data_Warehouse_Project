/*
===============================================================================
Stored Procedure : silver.load_silver
Layer            : Silver (Bronze -> Silver)
===============================================================================
Purpose:
    Runs the complete silver layer load in one command. For each of the six
    tables it truncates the target, applies the cleaning transformations to
    the bronze data, and inserts the result.

Tables loaded (in order):
    CRM : crm_cust_info, crm_prd_info, crm_sales_details
    ERP : erp_cust_az12, erp_loc_a101, erp_px_cat_g1v2

Features:
    - Prints progress, rows loaded and duration for every table.
    - Prints the total duration of the whole silver load.
    - Wrapped in TRY...CATCH: on failure, prints the error details and
      re-raises the error so the caller knows the load did not finish.

Parameters:
    None.

Usage:
    EXEC silver.load_silver;

Notes:
    - Run ddl_silver.sql first to create the silver tables.
    - Run bronze.load_bronze first so the bronze tables contain data.
    - The individual load_silver_*.sql scripts apply the same logic and are
      handy for testing or debugging a single table.
===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time       DATETIME,
            @end_time         DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time   DATETIME,
            @rows_loaded      INT;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        -- ====================================================================
        -- 1. silver.crm_cust_info
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data Into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,

            -- Remove unwanted spaces from names
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname)  AS cst_lastname,

            -- Normalize marital status values to a readable format
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,

            -- Normalize gender values to a readable format
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,

            cst_create_date
        FROM (
            -- Rank records per customer, newest first, to identify duplicates
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS t
        WHERE flag_last = 1;  -- Keep only the most recent record per customer

        SET @rows_loaded = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Loaded: ' + CAST(@rows_loaded AS NVARCHAR(20))
            + ' | Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        -- ====================================================================
        -- 2. silver.crm_prd_info
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data Into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            -- Derive category ID from the key prefix (e.g. 'CO-RF' -> 'CO_RF')
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

            -- Extract the product key without the category prefix
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

            prd_nm,

            -- Replace missing costs with 0
            ISNULL(prd_cost, 0) AS prd_cost,

            -- Map product line codes to descriptive values
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,

            -- Keep only the date portion
            CAST(prd_start_dt AS DATE) AS prd_start_dt,

            -- End date = day before the next version's start date (per product)
            CAST(
                DATEADD(
                    DAY, -1,
                    LEAD(prd_start_dt) OVER (
                        PARTITION BY prd_key
                        ORDER BY prd_start_dt
                    )
                ) AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @rows_loaded = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Loaded: ' + CAST(@rows_loaded AS NVARCHAR(20))
            + ' | Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        -- ====================================================================
        -- 3. silver.crm_sales_details
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data Into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Convert INT dates (yyyymmdd) to DATE; invalid values become NULL
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)
            END AS sls_order_dt,

            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE)
            END AS sls_ship_dt,

            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
            END AS sls_due_dt,

            -- Recalculate sales if missing, invalid, or inconsistent with quantity x price
            CASE
                WHEN sls_sales IS NULL
                  OR sls_sales <= 0
                  OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,

            sls_quantity,

            -- Derive price from sales / quantity if missing or invalid
            CASE
                WHEN sls_price IS NULL OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @rows_loaded = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Loaded: ' + CAST(@rows_loaded AS NVARCHAR(20))
            + ' | Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        -- ====================================================================
        -- 4. silver.erp_cust_az12
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            -- Remove the 'NAS' prefix if present (e.g. 'NASAW00011000' -> 'AW00011000')
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,

            -- Birthdates in the future are invalid, so set them to NULL
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,

            -- Normalize gender values and handle unknown cases
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @rows_loaded = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Loaded: ' + CAST(@rows_loaded AS NVARCHAR(20))
            + ' | Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        -- ====================================================================
        -- 5. silver.erp_loc_a101
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            -- Remove hyphens so the ID matches the CRM customer key
            REPLACE(cid, '-', '') AS cid,

            -- Normalize country codes and handle missing values
            CASE
                WHEN TRIM(cntry) = 'DE'                THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA')      THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @rows_loaded = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Loaded: ' + CAST(@rows_loaded AS NVARCHAR(20))
            + ' | Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        -- ====================================================================
        -- 6. silver.erp_px_cat_g1v2
        -- ====================================================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @rows_loaded = @@ROWCOUNT;
        SET @end_time = GETDATE();
        PRINT '>> Rows Loaded: ' + CAST(@rows_loaded AS NVARCHAR(20))
            + ' | Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';

        -- ====================================================================
        -- Summary
        -- ====================================================================
        SET @batch_end_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '================================================';
    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT '================================================';

        -- Re-raise the error so the caller knows the load failed
        THROW;
    END CATCH
END;
GO

-- ============================================================================
-- Run the load
-- ============================================================================
EXEC silver.load_silver;
GO
