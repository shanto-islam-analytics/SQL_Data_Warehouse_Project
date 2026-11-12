/*
===============================================================================
Quality Checks : Silver Layer
Script         : quality_checks_silver.sql
===============================================================================
Purpose:
    Validates the data quality of the silver layer after silver.load_silver
    has run. Each check is a standalone query with a stated expectation.

Checks performed:
    - Primary key integrity (NULLs and duplicates)
    - Unwanted leading/trailing spaces in text columns
    - Data standardization and consistency of category columns
    - Invalid or out-of-order dates
    - Business rules (sales = quantity x price)
    - Referential integrity between related tables

How to read the results:
    Unless a check says otherwise, "Expectation: No Results" means the query
    must return zero rows. Any returned row is a data quality issue that
    should be investigated and fixed in silver.load_silver.

Notes:
    - Space checks use DATALENGTH because SQL Server ignores trailing spaces
      when comparing strings, so "col != TRIM(col)" would miss them.
    - Run this script after: EXEC silver.load_silver;
===============================================================================
*/

USE DataWarehouse;
GO

-- ============================================================================
-- 1. silver.crm_cust_info
-- ============================================================================

-- Check for NULLs or duplicates in the primary key
-- Expectation: No Results

SELECT
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No Results

SELECT cst_key, cst_firstname, cst_lastname
FROM silver.crm_cust_info
WHERE DATALENGTH(cst_key)       <> DATALENGTH(TRIM(cst_key))
   OR DATALENGTH(cst_firstname) <> DATALENGTH(TRIM(cst_firstname))
   OR DATALENGTH(cst_lastname)  <> DATALENGTH(TRIM(cst_lastname));

-- Data standardization and consistency
-- Expectation: only Single / Married / n/a and Male / Female / n/a

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;


-- ============================================================================
-- 2. silver.crm_prd_info
-- ============================================================================

-- Check for NULLs or duplicates in the primary key
-- Expectation: No Results

SELECT
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces
-- Expectation: No Results

SELECT prd_nm
FROM silver.crm_prd_info
WHERE DATALENGTH(prd_nm) <> DATALENGTH(TRIM(prd_nm));

-- Check for NULL or negative costs
-- Expectation: No Results

SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardization and consistency
-- Expectation: only Mountain / Road / Other Sales / Touring / n/a

SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for invalid date orders (end date before start date)
-- Expectation: No Results

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ============================================================================
-- 3. silver.crm_sales_details
-- ============================================================================

-- Check for invalid date orders (order date after ship or due date)
-- Expectation: No Results

SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Business rule: sales = quantity x price, and no NULL, zero or negative values
-- Expectation: No Results

SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales    IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales    <= 0    OR sls_quantity <= 0    OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- ============================================================================
-- 4. silver.erp_cust_az12
-- ============================================================================

-- Check for birthdates in the future
-- Expectation: No Results

SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Check for unusually old birthdates (informational, not an error)
-- These are kept as-is and should be reviewed with the data owner.

SELECT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01';

-- Data standardization and consistency
-- Expectation: only Male / Female / n/a

SELECT DISTINCT gen
FROM silver.erp_cust_az12;


-- ============================================================================
-- 5. silver.erp_loc_a101
-- ============================================================================

-- Check that customer IDs no longer contain hyphens
-- Expectation: No Results

SELECT cid
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- Data standardization and consistency
-- Expectation: full country names only, no codes (DE, US, USA) and no blanks

SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ============================================================================
-- 6. silver.erp_px_cat_g1v2
-- ============================================================================

-- Check for unwanted spaces
-- Expectation: No Results

SELECT *
FROM silver.erp_px_cat_g1v2
WHERE DATALENGTH(cat)         <> DATALENGTH(TRIM(cat))
   OR DATALENGTH(subcat)      <> DATALENGTH(TRIM(subcat))
   OR DATALENGTH(maintenance) <> DATALENGTH(TRIM(maintenance));

-- Data standardization and consistency
-- Expectation: only Yes / No

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;


-- ============================================================================
-- 7. Referential integrity between tables
-- ============================================================================

-- Sales rows whose product does not exist in the product table
-- Expectation: No Results

SELECT DISTINCT s.sls_prd_key
FROM silver.crm_sales_details AS s
LEFT JOIN silver.crm_prd_info AS p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;

-- Sales rows whose customer does not exist in the customer table
-- Expectation: No Results

SELECT DISTINCT s.sls_cust_id
FROM silver.crm_sales_details AS s
LEFT JOIN silver.crm_cust_info AS c
    ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL;

-- Products whose category is missing in the ERP category table
-- Expectation: No Results, or a small known list. Investigate anything else.

SELECT DISTINCT p.cat_id
FROM silver.crm_prd_info AS p
LEFT JOIN silver.erp_px_cat_g1v2 AS c
    ON p.cat_id = c.id
WHERE c.id IS NULL;

-- CRM customers missing in the ERP customer tables (IDs must match after cleaning)
-- Expectation: No Results, or a small known list. Investigate anything else.

SELECT c.cst_key
FROM silver.crm_cust_info AS c
LEFT JOIN silver.erp_cust_az12 AS a
    ON c.cst_key = a.cid
LEFT JOIN silver.erp_loc_a101 AS l
    ON c.cst_key = l.cid
WHERE a.cid IS NULL
   OR l.cid IS NULL;
GO
