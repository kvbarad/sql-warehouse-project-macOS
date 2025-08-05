
USE DataWarehouse;

/*
-- Purpose: 
-- This script creates/updates three core views in the gold data layer to support analytics:
-- 1. gold.dim_customers: Customer dimension view consolidating customer details from CRM and ERP source systems.
-- 2. gold.dim_products: Product dimension view that combines product metadata with category hierarchy.
-- 3. gold.sales_fact: Sales fact view combining sales transactions with enriched customer and product keys.
-- 
-- These gold-layer views standardize and integrate data from multiple silver-layer sources to enable enterprise reporting and analysis.
*/



PRINT '==========================================';
PRINT '>> LOADING GOLD LAYER TABLES';
PRINT '==========================================';

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO



CREATE OR ALTER VIEW gold.dim_customers AS


SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS firstname,
    ci.cst_lastname AS lastname,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr  -- AS CRM CUST INFO IS MASTER
        ELSE COALESCE(ca.gen, 'N/A')
    END AS gender,
    ca.bdate AS birth_date,
    lo.cntry AS country,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_101 AS lo
ON ci.cst_key = lo.cid
;

GO

PRINT '==========================================';
PRINT '>> DROPPING gold.dim_products VIEW TABLE';
PRINT '==========================================';

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO


CREATE OR ALTER VIEW gold.dim_products AS


SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    REPLACE(pn.cat_id, '_', '-') AS category_id,
    pc.CAT AS category,
    pc.SUBCAT AS subcategory,
    pn.prd_line AS product_line,
    pn.prd_cost,
    pn.prd_start_dt AS start_date,
    pc.MAINTENANCE AS maintenance
FROM silver.crm_prd_info AS pn
    LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON REPLACE(pn.cat_id, '_', '-') = pc.ID
WHERE prd_end_dt IS NULL -- FILTER out the historical DATA
;

GO

PRINT '==========================================';
PRINT '>> DROPPING gold.sales_fact VIEW TABLE';
PRINT '==========================================';

IF OBJECT_ID('gold.sales_fact', 'V') IS NOT NULL
    DROP VIEW gold.sales_fact;

GO



CREATE OR ALTER VIEW gold.sales_fact AS


SELECT
sd.sls_ord_num AS order_number,
pd.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS cu
ON sd.sls_cust_id = cu.customer_id
LEFT JOIN gold.dim_products AS pd
ON sd.sls_prd_key = pd.product_number
;

GO

/*
-- Purpose: 
-- This script creates/updates three core views in the gold data layer to support analytics:
-- 1. gold.dim_customers: Customer dimension view consolidating customer details from CRM and ERP source systems.
-- 2. gold.dim_products: Product dimension view that combines product metadata with category hierarchy.
-- 3. gold.sales_fact: Sales fact view combining sales transactions with enriched customer and product keys.
-- 
-- These gold-layer views standardize and integrate data from multiple silver-layer sources to enable enterprise reporting and analysis.
*/

PRINT '==========================================';
PRINT '>> LOADING GOLD LAYER TABLES';
PRINT '==========================================';

-- Drop dim_customers view if it exists to refresh with latest logic
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    -- vv Surrogate key for customer dimension, assigned sequentially
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
    ci.cst_id                           AS customer_id,
    ci.cst_key                          AS customer_number,
    ci.cst_firstname                    AS firstname,
    ci.cst_lastname                     AS lastname,
    ci.cst_marital_status               AS marital_status,
    -- ^^ Prefer gender from CRM; if 'N/A' use ERP gender. Default to 'N/A' if both unavailable.
    CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr  
        ELSE COALESCE(ca.gen, 'N/A')
    END                                 AS gender,
    ca.bdate                            AS birth_date,
    lo.cntry                            AS country,
    ci.cst_create_date                  AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_101 AS lo
    ON ci.cst_key = lo.cid;
GO

PRINT '==========================================';
PRINT '>> DROPPING gold.dim_products VIEW TABLE';
PRINT '==========================================';

-- Drop dim_products view if exists to refresh with latest product mapping
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE OR ALTER VIEW gold.dim_products AS
SELECT
    -- Surrogate product key created from product start date and product key columns
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id                                          AS product_id,
    pn.prd_key                                         AS product_number,
    pn.prd_nm                                               AS product_name,
    REPLACE(pn.cat_id, '_', '-')                            AS category_id,  -- Normalize category IDs by replacing underscore with dash
    pc.CAT                                                  AS category,
    pc.SUBCAT                                               AS subcategory,
    pn.prd_line                                             AS product_line,
    pn.prd_cost,
    pn.prd_start_dt                                         AS start_date,
    pc.MAINTENANCE                                          AS maintenance
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON REPLACE(pn.cat_id, '_', '-') = pc.ID
WHERE prd_end_dt IS NULL; -- Only include active products (filter out historical/inactive)
GO

PRINT '==========================================';
PRINT '>> DROPPING gold.sales_fact VIEW TABLE';
PRINT '==========================================';

-- Drop sales_fact view if exists to refresh
IF OBJECT_ID('gold.sales_fact', 'V') IS NOT NULL
    DROP VIEW gold.sales_fact;
GO

CREATE OR ALTER VIEW gold.sales_fact AS
SELECT
    sd.sls_ord_num  AS order_number,
    pd.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.customer_id
LEFT JOIN gold.dim_products AS pd
    ON sd.sls_prd_key = pd.product_number;
GO

SELECT COUNT(*) FROM gold.dim_customers;

SELECT COUNT(*) FROM gold.dim_products;

SELECT COUNT(*) FROM gold.sales_fact;

/* CHECK the NUMBER OF ROWS IN EACH TABLE */

SELECT 'gold.dim_customers' AS customers, COUNT(*) AS total_customers FROM gold.dim_customers
UNION ALL
SELECT 'gold.dim_products' AS products, COUNT(*) AS total_products FROM gold.dim_products
UNION ALL
SELECT 'gold.sales_fact' AS sales, COUNT(*) AS total_sales FROM gold.sales_fact;
