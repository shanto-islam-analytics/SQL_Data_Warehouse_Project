/*
===============================================================================
Script : ddl_gold.sql
Layer  : Gold
===============================================================================
Purpose:
    Creates the views of the gold layer (the business-ready star schema).
    Gold views read from the silver layer and expose clean, integrated,
    business-friendly data for reporting and analytics.

Views in this script:
    - gold.dim_customers : customer dimension
    - gold.dim_products  : product dimension (current products only)
    - gold.fact_sales    : sales fact (one row per order line)

Notes:
    - The gold schema must exist (created in init_database.sql).
    - Views are re-creatable: CREATE OR ALTER replaces an existing view.
    - Run silver.load_silver before querying these views.

Usage:
    SELECT * FROM gold.dim_customers;
===============================================================================
*/

USE DataWarehouse;
GO

-- =============================================================================
-- Dimension: gold.dim_customers
-- =============================================================================
-- Integrates customer data from three silver tables:
--     silver.crm_cust_info  : master customer record (CRM)
--     silver.erp_cust_az12  : birthdate and backup gender (ERP)
--     silver.erp_loc_a101   : country (ERP)
--
-- Grain: one row per customer.
-- =============================================================================


CREATE OR ALTER VIEW gold.dim_customers AS
SELECT

    -- Surrogate key: a generated unique key, independent of source systems

    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,

    -- Business identifiers

    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,

    -- Customer attributes

    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,

    -- CRM is the master source for gender; fall back to ERP when CRM is unknown

    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Dimension: gold.dim_products
-- =============================================================================
-- Integrates product data from two silver tables:
--     silver.crm_prd_info    : product master data (CRM)
--     silver.erp_px_cat_g1v2 : category, subcategory, maintenance (ERP)
--
-- Grain: one row per product (current version only).
-- =============================================================================


CREATE OR ALTER VIEW gold.dim_products AS
SELECT

    -- Surrogate key: a generated unique key, independent of source systems

    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,

    -- Business identifiers

    pn.prd_id AS product_id,
    pn.prd_key AS product_number,

    -- Product attributes

    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance AS maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;  -- Keep only the current version; filter out historical data
GO

-- =============================================================================
-- Fact: gold.fact_sales
-- =============================================================================
-- Sales transactions from silver.crm_sales_details, connected to the
-- dimensions through their surrogate keys (star schema):
--     gold.dim_products  via product_number
--     gold.dim_customers via customer_id
--
-- Grain: one row per order line (order_number + product).
-- Must be created after the two dimension views above.
-- =============================================================================

CREATE OR ALTER VIEW gold.fact_sales AS
SELECT

    -- Order identifier

    sd.sls_ord_num AS order_number,

    -- Surrogate keys linking to the dimensions

    pr.product_key AS product_key,
    cu.customer_key AS customer_key,

    -- Dates

    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,

    -- Measures

    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO