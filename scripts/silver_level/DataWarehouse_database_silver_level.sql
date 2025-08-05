/* The Codes/Syntax are similar to the bronze table creation, only change done 
is the name of table 
and extra row added ' dwh_create_date    DATETIME2 DEFAULT GETDATE()' to capture the metadata */

-- Purpose: Drop and recreate key raw source (silver) tables to ensure a consistent starting state for ETL or data ingestion.
--          Removes any existing versions of the tables, then creates them with standardized columns and types.

-- Purpose: Ensures the silver.crm_cust_info table always exists with the defined structure by dropping it if present, then recreating it.


IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info
(
    cst_id             INT,                   -- Customer identifier, assumed unique per customer (no primary key constraint specified)
    cst_key            NVARCHAR(50),          -- Potential business or surrogate key for customer (clarify usage in documentation)
    cst_firstname      NVARCHAR(50),          -- First name of the customer
    cst_lastname       NVARCHAR(50),          -- Last name of the customer
    cst_marital_status NVARCHAR(50),          -- Marital status; expects string labels (e.g., 'Single', 'Married'), not enforced by constraint
    cst_gndr           NVARCHAR(50),          -- Gender as free-text; no enumerated constraint
    cst_create_date    DATE,                   -- Customer record creation date
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO


-- Drop and recreate silver.crm_prd_info (product info) table
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info
(
    prd_id         INT,              -- Product identifier; uniqueness not enforced
    cat_id         NVARCHAR(50),
    prd_key        NVARCHAR(50),     -- Potential business/surrogate key for the product
    prd_nm         NVARCHAR(50),     -- Product name
    prd_cost       INT,              -- Cost (currency unit not specified)
    prd_line       NVARCHAR(50),     -- Product line/category
    prd_start_dt   DATETIME,         -- Product available/start date
    prd_end_dt     DATETIME,          -- Product end/discontinuation date
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

-- Drop and recreate silver.crm_sales_details (sales transactions) table
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details
(
    sls_ord_num    NVARCHAR(50),     -- Order number
    sls_prd_key    NVARCHAR(50),     -- Foreign key to prd_key (not enforced)
    sls_cust_id    INT,              -- Foreign key to cst_id (not enforced)
    sls_order_dt   DATE,             -- Order date
    sls_ship_dt    DATE,             -- Ship date
    sls_due_dt     DATE,             -- Due date
    sls_sales      INT,              -- Sales amount
    sls_quantity   INT,              -- Quantity sold
    sls_price      INT,               -- Unit price (currency unit not specified)
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

-- Drop and recreate silver.erp_cust_az12 (external/ERP customer info) table
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12
(
    cid    NVARCHAR(50),             -- Customer identifier
    bdate  DATE,                     -- Birthdate
    gen    NVARCHAR(50),              -- Gender
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

-- Drop and recreate silver.erp_loc_101 (external/ERP location info) table
IF OBJECT_ID('silver.erp_loc_101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_101;
GO

CREATE TABLE silver.erp_loc_101
(
    cid    NVARCHAR(50),             -- Customer identifier (likely foreign key to erp_cust_az12.cid)
    cntry  NVARCHAR(50),              -- Country
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

-- Drop and recreate silver.erp_px_cat_g1v2 (external/ERP product category) table
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2
(
    ID           NVARCHAR(50),       -- Product/Item identifier
    CAT          NVARCHAR(50),       -- Main category
    SUBCAT       NVARCHAR(50),       -- Subcategory
    MAINTENANCE  NVARCHAR(50),        -- Maintenance flag/type
    dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
GO

/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
USE DataWarehouse;

/* CODING AND DOCUMENTATION BY USER */

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
BEGIN TRY
SET @batch_start_time = GETDATE();
PRINT '==========================================';
PRINT '>> Starting SILVER LAYER';
PRINT '==========================================';
PRINT '==========================================';
SET @start_time = GETDATE();
PRINT '==========================================';
PRINT '>> TRUNCATING silver.crm_cust_info';
PRINT '==========================================';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '==========================================';
PRINT '>> INSERTING INTO TABLE silver.crm_cust_info';
PRINT '==========================================';
INSERT INTO silver.crm_cust_info
(
    cst_id             ,                   -- Customer identifier, assumed unique per customer (no primary key constraint specified)
    cst_key            ,          -- Potential business or surrogate key for customer (clarify usage in documentation)
    cst_firstname      ,          -- First name of the customer
    cst_lastname       ,          -- Last name of the customer
    cst_marital_status ,          -- Marital status; expects string labels (e.g., 'Single', 'Married'), not enforced by constraint
    cst_gndr           ,          -- Gender as free-text; no enumerated constraint
    cst_create_date                       -- Customer record creation date

)

SELECT
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
     WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
     ELSE 'N/A'
     END cst_marital_status,
CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
     WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
     ELSE 'N/A'
     END cst_gndr,
cst_create_date
FROM (
        SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS date_order

FROM bronze.crm_cust_info
)t WHERE cst_id IS NOT NULL AND date_order = 1;
SET @end_time = GETDATE();
PRINT '==========================================';
PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)+ 'Seconds';
PRINT '==========================================';

PRINT '==========================================';
SET @start_time = GETDATE();
PRINT '==========================================';
PRINT '>> TRUNCATING silver.crm_prd_info';
PRINT '==========================================';
TRUNCATE TABLE silver.crm_prd_info;
PRINT '==========================================';
PRINT '>> INSERTING INTO TABLE silver.crm_prd_info';
PRINT '==========================================';
INSERT INTO silver.crm_prd_info
(
    prd_id         ,              -- Product identifier; uniqueness not enforced
    cat_id         ,
    prd_key        ,     -- Potential business/surrogate key for the product
    prd_nm         ,     -- Product name
    prd_cost       ,              -- Cost (currency unit not specified)
    prd_line       ,     -- Product line/category
    prd_start_dt   ,         -- Product available/start date
    prd_end_dt               -- Product end/discontinuation date
)
SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
        prd_nm,
        ISNULL(prd_cost, 0) AS prd_cost,
        CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Sports'
                WHEN 'T' THEN 'Touring'
                ELSE 'N/A'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info
;
SET @end_time = GETDATE();
PRINT '==========================================';
PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
PRINT '==========================================';

PRINT '==========================================';
SET @start_time = GETDATE();
PRINT '==========================================';
PRINT '>> TRUNCATING silver.crm_sales_details';
PRINT '==========================================';
TRUNCATE TABLE silver.crm_sales_details;
PRINT '==========================================';
PRINT '>> INSERTING INTO TABLE silver.crm_sales_details';
PRINT '==========================================';
INSERT INTO silver.crm_sales_details
(
    sls_ord_num   ,     -- Order number
    sls_prd_key   ,     -- Foreign key to prd_key (not enforced)
    sls_cust_id   ,              -- Foreign key to cst_id (not enforced)
    sls_order_dt  ,             -- Order date
    sls_ship_dt   ,             -- Ship date
    sls_due_dt    ,             -- Due date
    sls_sales     ,              -- Sales amount
    sls_quantity  ,              -- Quantity sold
    sls_price                    -- Unit price (currency unit not specified)
)

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
    END AS sls_order_dt,

    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
    END AS sls_ship_dt,

    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
    END AS sls_due_dt,

    CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE WHEN sls_price IS NULL OR sls_price <=0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details
;
SET @end_time = GETDATE();
PRINT '==========================================';
PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
PRINT '==========================================';

PRINT '==========================================';
SET @start_time = GETDATE();
PRINT '==========================================';
PRINT '>> TRUNCATING silver.erp_cust_az12';
PRINT '==========================================';
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '==========================================';
PRINT '>> INSERTING INTO TABLE silver.erp_cust_az12';
PRINT '==========================================';
INSERT INTO silver.erp_cust_az12
(
    cid,
    bdate,
    gen
)
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
    ELSE cid
END AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
END AS bdate,
CASE 
    WHEN gen IS NULL THEN 'N/A'
    WHEN UPPER(REPLACE(REPLACE(TRIM(gen), CHAR(13), ''), CHAR(10), '')) IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(REPLACE(REPLACE(TRIM(gen), CHAR(13), ''), CHAR(10), '')) IN ('M', 'MALE') THEN 'Male'
    ELSE 'N/A'
END AS gen
FROM bronze.erp_cust_az12;
SET @end_time = GETDATE();
PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';

SET @start_time = GETDATE();
PRINT '>> TRUNCATING silver.erp_loc_101';
TRUNCATE TABLE silver.erp_loc_101;
PRINT '>> INSERTING INTO TABLE silver.erp_loc_101';
INSERT INTO silver.erp_loc_101
(
    cid,
    cntry
)
SELECT
REPLACE(cid, '-', '') AS cid,
CASE
    WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) = 'DE' THEN 'Germany'
    WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) = '' OR cntry IS NULL THEN 'N/A'
    WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) IN ('US', 'USA') THEN 'United States'
ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_101;
SET @end_time = GETDATE();
PRINT '==========================================';
PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
PRINT '==========================================';

PRINT '==========================================';
SET @start_time = GETDATE();
PRINT '==========================================';
PRINT '>> TRUNCATING silver.erp_px_cat_g1v2';
PRINT '==========================================';
TRUNCATE TABLE silver.erp_px_cat_g1v2;
PRINT '==========================================';
PRINT '>> INSERTING INTO TABLE silver.erp_px_cat_g1v2';
PRINT '==========================================';
INSERT INTO silver.erp_px_cat_g1v2
(
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
)
SELECT
    REPLACE(ID, '_', '-') AS ID,
    CAT,
    SUBCAT,
    TRIM(MAINTENANCE) AS MAINTENANCE
FROM bronze.erp_px_cat_g1v2;
SET @end_time = GETDATE();
PRINT '==========================================';
PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
PRINT '==========================================';

SET @batch_end_time = GETDATE();
PRINT '==========================================';
PRINT '>> SILVER LAYER DURATION COMPLETE';
PRINT '>> TOTAL Silver Layer DURATION TIME: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'Seconds';
PRINT '==========================================';
PRINT '==========================================';

END TRY
BEGIN CATCH
PRINT '==========================================';
PRINT '==========================================';
PRINT 'Error Occured During Loading SILVER LAYER';
PRINT 'Error Message: ' + ERROR_MESSAGE();
PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
PRINT 'Error Sate: ' + CAST(ERROR_STATE() AS NVARCHAR);
PRINT '==========================================';
PRINT '==========================================';
END CATCH
END

EXEC silver.load_silver;

USE DataWarehouse;
-- CRM DATA TOP 1000 CHECK
SELECT TOP 1000 * FROM silver.crm_cust_info;
SELECT TOP 1000 * FROM silver.crm_prd_info;
SELECT TOP 1000 * FROM silver.crm_sales_details;

-- ERP DATA TOP 1000 CHECK
SELECT TOP 1000 * FROM silver.erp_cust_az12;
SELECT TOP 1000 * FROM silver.erp_loc_101;
SELECT TOP 1000 * FROM silver.erp_px_cat_g1v2;


/* DOCUMENTATION USING PERPLEXITY */

-- Purpose:
-- Refreshes ("cleans and stages") all tables in the 'silver' schema by truncating them
-- and bulk-loading transformed/cleaned data from the 'bronze' layer (raw ingest tables).
-- Implements business logic and data quality checks per table; prints durations and errors.

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE
        @start_time        DATETIME,
        @end_time          DATETIME,
        @batch_start_time  DATETIME,
        @batch_end_time    DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '==========================================';
        PRINT '>> Starting SILVER LAYER';
        PRINT '==========================================';

        ------------------------------------------------------------------------------
        -- silver.crm_cust_info: Customer dimension table with deduplication and cleaning
        ------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> INSERTING INTO TABLE silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,                -- Assumed unique customer identifier
            cst_key,               -- Surrogate/business key
            cst_firstname,
            cst_lastname,
            cst_marital_status,    -- Normalized to 'Single', 'Married', or 'N/A'
            cst_gndr,              -- Normalized to 'Male', 'Female', or 'N/A'
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'N/A'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'N/A'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY cst_id
                       ORDER BY cst_create_date DESC
                   ) AS date_order
            FROM bronze.crm_cust_info
        ) t
        WHERE cst_id IS NOT NULL AND date_order = 1;  -- Keep latest record per cst_id

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ------------------------------------------------------------------------------
        -- silver.crm_prd_info: Product dimension with category and period derivation
        ------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> INSERTING INTO TABLE silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,        -- Normalized (see below)
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,       -- Derive category id, replace '-' with '_'
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Sports'
                WHEN 'T' THEN 'Touring'
                ELSE 'N/A'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            -- End date = day before next start date (LEAD); null if no next
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ------------------------------------------------------------------------------
        -- silver.crm_sales_details: Sales fact table with type & math validation
        ------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> INSERTING INTO TABLE silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,      -- Amount; recalculated if questionable
            sls_quantity,
            sls_price       -- Unit price; recalculated if questionable
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            -- Attempt to parse date if in 'YYYYMMDD' text format, otherwise NULL
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8
                THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8
                THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8
                THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            -- If amount is invalid/mismatched, recalculate as qty * ABS(price)
            CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            -- If price missing/invalid, recalc as amount / quantity (avoid divide by zero)
            CASE WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ------------------------------------------------------------------------------
        -- silver.erp_cust_az12: ERP customer dimension with cleaning
        ------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> INSERTING INTO TABLE silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            -- Remove 'NAS' prefix from customer IDs
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END AS cid,
            -- Remove future bdates
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate,
            -- Standardize gender with newline/CR cleaning
            CASE
                WHEN gen IS NULL THEN 'N/A'
                WHEN UPPER(REPLACE(REPLACE(TRIM(gen), CHAR(13), ''), CHAR(10), ''))
                    IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(REPLACE(REPLACE(TRIM(gen), CHAR(13), ''), CHAR(10), ''))
                    IN ('M', 'MALE') THEN 'Male'
                ELSE 'N/A'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ------------------------------------------------------------------------------
        -- silver.erp_loc_101: ERP location/country dimension with cleaning
        ------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING silver.erp_loc_101';
        TRUNCATE TABLE silver.erp_loc_101;

        PRINT '>> INSERTING INTO TABLE silver.erp_loc_101';
        INSERT INTO silver.erp_loc_101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE
                WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) = 'DE' THEN 'Germany'
                WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) = '' OR cntry IS NULL THEN 'N/A'
                WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) IN ('US', 'USA') THEN 'United States'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_101;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ------------------------------------------------------------------------------
        -- silver.erp_px_cat_g1v2: ERP product category mapping with cleaning
        ------------------------------------------------------------------------------
        SET @start_time = GETDATE();
        PRINT '>> TRUNCATING silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> INSERTING INTO TABLE silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            ID,
            CAT,
            SUBCAT,
            MAINTENANCE
        )
        SELECT
            REPLACE(ID, '_', '-') AS ID,
            CAT,
            SUBCAT,
            TRIM(MAINTENANCE) AS MAINTENANCE
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        ------------------------------------------------------------------------------
        -- Batch Completion & Duration
        ------------------------------------------------------------------------------
        SET @batch_end_time = GETDATE();
        PRINT '==========================================';
        PRINT '>> SILVER LAYER DURATION COMPLETE';
        PRINT '>> TOTAL Silver Layer DURATION TIME: '
             + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR)
             + ' Seconds';
        PRINT '==========================================';

    END TRY
    BEGIN CATCH
        PRINT '==========================================';
        PRINT 'Error Occurred During Loading SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number:  ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State:   ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==========================================';
    END CATCH
END


EXEC silver.load_silver;



/*
Document: Business Rules Implemented by the Query
Layer Promotion:
The procedure takes cleansed/staged data from the bronze layer and moves it into the silver layer, applying business cleaning/standardization rules.
Deduplication:
crm_cust_info: For each customer ID, keeps only the record with the most recent cst_create_date (using ROW_NUMBER), removing duplicates.
Data Standardization:
Marital status and gender are standardized from coded/free-text formats into 'Single', 'Married', 'Male', 'Female', or 'N/A'.
Product category codes are extracted and normalized.
Product and date-related fields in sales data are validated and cleaned (e.g., reconstruct sales and price amount if calculations or data are missing/inconsistent).
Type Integrity and Null/Cleaning:
Dates that are zeros or not in 'YYYYMMDD' formats are set to NULL.
Product costs default to zero if missing.
Invalid or future birth dates are set to NULL.
Text/ID Cleansing:
Customer IDs are cleaned of "NAS" prefixes or internal dashes.
Trailing and leading spaces, as well as carriage returns/newlines, are stripped from key text columns.
Consistent Labeling:
Country codes are translated to 'Germany', 'United States', or 'N/A' as appropriate, and all unexpected, blank, or NULL values default to 'N/A'.
Idempotency & Auditability:
Layer tables are truncated before loading.
Load durations for each step are printed for future run-time monitoring.
Errors are caught and logged in detail.
3. Document: How the Query Works (Step-by-Step)
At a High Level
The procedure loads each 'silver' table via a truncate+insert, pulling from the matching 'bronze' source.
Each insert applies cleansing, validation, and normalization logic specific to that dataset.
Table-by-table Details
a. silver.crm_cust_info
Truncates the table.
For each customer (by cst_id), selects only their latest record.
Trims name fields and standardizes marital status ('S'/'M' → text, otherwise 'N/A').
Standardizes gender ('F'/'M' → text, otherwise 'N/A').
Loads the cleaned data in.
b. silver.crm_prd_info
Truncates the table.
Processes product records:
Extracts/cleans cat_id from the start of prd_key.
Normalizes product line code to verbose text.
Defaults product cost if missing.
Calculates date ranges: each prd_end_dt is the day before the next version's prd_start_dt.
Loads the result.
c. silver.crm_sales_details
Truncates the table.
Selects from bronze sales records:
Parses dates only if they look correct.
Corrects sales amounts if they don’t match price × quantity, or are invalid.
Fills in price from amount/quantity if needed.
Inserts the result.
d. silver.erp_cust_az12
Truncates the table.
Cleans up ERP customer IDs (removes 'NAS'), invalid birthdates (future dates→NULL), standardizes gender (even through extraneous whitespace and line breaks).
Loads the cleaned records.
e. silver.erp_loc_101
Truncates.
Cleans IDs (removes all dashes).
Cleans country codes by removing whitespace, carriage returns, and newlines, converts to uppercase, and then matches:
'DE'→'Germany', 'US'/'USA'→'United States', blank/NULL→'N/A', otherwise trimmed code passed as is.
f. silver.erp_px_cat_g1v2
Truncates.
Cleans IDs by swapping '_' for '-'; trims maintenance values.
Loads as is otherwise.
Final Steps
Prints duration of each load, plus total time.
If an error occurs at any point, it prints the error details (number, message, state).
How Data Cleaning Functions Work (TRIM, REPLACE/CHAR)
TRIM(col), LTRIM(RTRIM(col)): Removes spaces from either end.
REPLACE(col, CHAR(13), ''): Removes carriage return characters (for data pasted in with newlines).
REPLACE(col, CHAR(10), ''): Removes line feed/newline characters.
This is crucial in data imported from text/CSV/Excel with invisible whitespace.
UPPER(...): Ensures comparisons against keys like 'F', 'M', 'DE', etc., are NOT case-sensitive.
In summary:
The procedure performs a strong layer of data quality and standardization, ensuring all staged (silver) tables are reliably consistent for downstream analytics and reporting. Key cleaning and logic rules are called out via inline comments and are modularized by table for clear traceability and run monitoring.
*/
