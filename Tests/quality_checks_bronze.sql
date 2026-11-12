/*
===============================================================================
Quality Checks : Bronze Layer
Script         : quality_checks_bronze.sql
===============================================================================
Purpose:
    Verifies that the bronze layer was loaded completely, and profiles the
    known data issues in the raw data. Bronze holds raw source data as-is,
    so issues found here are EXPECTED. They are not fixed in bronze; they are
    handled by the transformations in silver.load_silver.

Checks performed:
    1. Row counts per table (load completeness)
    2. Empty table detection
    3. Data issue profile: one row per issue with the number of affected rows

How to read the results:
    - Row counts must match the source CSV files (number of lines minus the
      header line). A mismatch means the load is incomplete.
    - Empty tables must return no rows.
    - In the issue profile, a non-zero count is normal and documents what
      silver cleans. Compare it with quality_checks_silver.sql, where the
      same issues must be resolved.

Notes:
    - Space checks use DATALENGTH because SQL Server ignores trailing spaces
      when comparing strings.
    - Run this script after: EXEC bronze.load_bronze;
===============================================================================
*/

USE DataWarehouse;
GO

-- ============================================================================
-- 1. Row counts per table
-- Compare each count with the source CSV file (lines minus header).
-- ============================================================================

SELECT 'bronze.crm_cust_info' AS table_name, COUNT(*) AS row_count FROM bronze.crm_cust_info
UNION ALL
SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
UNION ALL
SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
UNION ALL
SELECT 'bronze.erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
UNION ALL
SELECT 'bronze.erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
UNION ALL
SELECT 'bronze.erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2;

-- ============================================================================
-- 2. Empty table detection
-- Expectation: No Results
-- ============================================================================

SELECT table_name
FROM (
    SELECT 'bronze.crm_cust_info' AS table_name, COUNT(*) AS row_count FROM bronze.crm_cust_info
    UNION ALL
    SELECT 'bronze.crm_prd_info', COUNT(*) FROM bronze.crm_prd_info
    UNION ALL
    SELECT 'bronze.crm_sales_details', COUNT(*) FROM bronze.crm_sales_details
    UNION ALL
    SELECT 'bronze.erp_cust_az12', COUNT(*) FROM bronze.erp_cust_az12
    UNION ALL
    SELECT 'bronze.erp_loc_a101', COUNT(*) FROM bronze.erp_loc_a101
    UNION ALL
    SELECT 'bronze.erp_px_cat_g1v2', COUNT(*) FROM bronze.erp_px_cat_g1v2
) AS t
WHERE row_count = 0;

-- ============================================================================
-- 3. Data issue profile (informational)
-- Non-zero counts are expected here and are fixed in silver.load_silver.
-- ============================================================================


-- ---- crm_cust_info ----

SELECT 'crm_cust_info: NULL cst_id' AS check_name, COUNT(*) AS issue_rows
FROM bronze.crm_cust_info
WHERE cst_id IS NULL
UNION ALL
SELECT 'crm_cust_info: extra rows from duplicate cst_id', COUNT(*) - COUNT(DISTINCT cst_id)
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL
UNION ALL
SELECT 'crm_cust_info: names with extra spaces', COUNT(*)
FROM bronze.crm_cust_info
WHERE DATALENGTH(cst_firstname) <> DATALENGTH(TRIM(cst_firstname))
   OR DATALENGTH(cst_lastname)  <> DATALENGTH(TRIM(cst_lastname))
UNION ALL
SELECT 'crm_cust_info: marital status is not S or M', COUNT(*)
FROM bronze.crm_cust_info
WHERE UPPER(TRIM(cst_marital_status)) NOT IN ('S', 'M') OR cst_marital_status IS NULL
UNION ALL
SELECT 'crm_cust_info: gender is not F or M', COUNT(*)
FROM bronze.crm_cust_info
WHERE UPPER(TRIM(cst_gndr)) NOT IN ('F', 'M') OR cst_gndr IS NULL


-- ---- crm_prd_info ----

UNION ALL
SELECT 'crm_prd_info: NULL prd_cost', COUNT(*)
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL
UNION ALL
SELECT 'crm_prd_info: negative prd_cost', COUNT(*)
FROM bronze.crm_prd_info
WHERE prd_cost < 0
UNION ALL
SELECT 'crm_prd_info: end date before start date', COUNT(*)
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt
UNION ALL
SELECT 'crm_prd_info: prd_line is not M, R, S or T', COUNT(*)
FROM bronze.crm_prd_info
WHERE UPPER(TRIM(prd_line)) NOT IN ('M', 'R', 'S', 'T') OR prd_line IS NULL


-- ---- crm_sales_details ---- 

UNION ALL
SELECT 'crm_sales_details: invalid order date', COUNT(*)
FROM bronze.crm_sales_details
WHERE sls_order_dt = 0 OR LEN(sls_order_dt) <> 8
UNION ALL
SELECT 'crm_sales_details: invalid ship date', COUNT(*)
FROM bronze.crm_sales_details
WHERE sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8
UNION ALL
SELECT 'crm_sales_details: invalid due date', COUNT(*)
FROM bronze.crm_sales_details
WHERE sls_due_dt = 0 OR LEN(sls_due_dt) <> 8
UNION ALL
SELECT 'crm_sales_details: sales is NULL, <= 0 or not quantity x price', COUNT(*)
FROM bronze.crm_sales_details
WHERE sls_sales IS NULL
   OR sls_sales <= 0
   OR sls_sales <> sls_quantity * sls_price
UNION ALL
SELECT 'crm_sales_details: price is NULL or <= 0', COUNT(*)
FROM bronze.crm_sales_details
WHERE sls_price IS NULL OR sls_price <= 0


-- ---- erp_cust_az12 ----

UNION ALL
SELECT 'erp_cust_az12: cid with NAS prefix', COUNT(*)
FROM bronze.erp_cust_az12
WHERE cid LIKE 'NAS%'
UNION ALL
SELECT 'erp_cust_az12: birthdate in the future', COUNT(*)
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE()
UNION ALL
SELECT 'erp_cust_az12: birthdate before 1924-01-01', COUNT(*)
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01'
UNION ALL
SELECT 'erp_cust_az12: gender needs standardizing', COUNT(*)
FROM bronze.erp_cust_az12
WHERE gen IS NULL
   OR UPPER(TRIM(gen)) NOT IN ('FEMALE', 'MALE')


-- ---- erp_loc_a101 ----

UNION ALL
SELECT 'erp_loc_a101: cid containing a hyphen', COUNT(*)
FROM bronze.erp_loc_a101
WHERE cid LIKE '%-%'
UNION ALL
SELECT 'erp_loc_a101: country is a code, blank or NULL', COUNT(*)
FROM bronze.erp_loc_a101
WHERE cntry IS NULL OR TRIM(cntry) IN ('', 'DE', 'US', 'USA')


-- ---- erp_px_cat_g1v2 ----

UNION ALL
SELECT 'erp_px_cat_g1v2: values with extra spaces', COUNT(*)
FROM bronze.erp_px_cat_g1v2
WHERE DATALENGTH(cat)         <> DATALENGTH(TRIM(cat))
   OR DATALENGTH(subcat)      <> DATALENGTH(TRIM(subcat))
   OR DATALENGTH(maintenance) <> DATALENGTH(TRIM(maintenance));
GO
