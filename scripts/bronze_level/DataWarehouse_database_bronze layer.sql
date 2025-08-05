/*
====================================================================
Script Overall Purpose:
    This script sets up a fresh data warehouse environment named 'DataWarehouse'. 
    It ensures there are no pre-existing objects that may cause conflicts by 
    dropping and recreating the database and all bronze-level tables and schemas. 
    The script also organizes the storage of raw, cleansed, and analytics-ready data 
    using the 'bronze', 'silver', and 'gold' schemas, and provides a robust 
    data loading procedure with error handling and performance tracking.
    
    WARNING: 
        Executing this script will permanently drop the entire 'DataWarehouse' 
        database if it exists. Use with caution and ensure valid backups are in place.
====================================================================
*/

USE master;
GO

-- Forcefully drop and re-create DataWarehouse to ensure a clean environment.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Set SINGLE_USER to forcibly disconnect all sessions.
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- New empty database for staging, cleansing, and analytics.
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create schemas to logically separate stages in the data pipeline. 
CREATE SCHEMA bronze;  -- Raw, ingested data with minimal or no transformation.
GO
CREATE SCHEMA silver;  -- Cleansed, conformed data.
GO
CREATE SCHEMA gold;    -- Final, analytics-ready curated data.
GO

/* ===============================================================
   Drop and Recreate Raw Source Tables in BRONZE Schema
   Ensures table structure is consistent and existing data is cleared.
   =============================================================== */

-- Customer Master: likely primary ingestion point from source system for customers.
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO

CREATE TABLE bronze.crm_cust_info
(
    cst_id             INT,              -- Customer's source system identifier (should be unique, but not enforced here).
    cst_key            NVARCHAR(50),     -- Surrogate/business key; could differ from source ID.
    cst_firstname      NVARCHAR(50),     -- Customer's first name (free text).
    cst_lastname       NVARCHAR(50),     -- Customer's last name.
    cst_marital_status NVARCHAR(50),     -- Values are not constrained to a fixed set.
    cst_gndr           NVARCHAR(50),     -- Gender, as free text; could benefit from standardization.
    cst_create_date    DATE              -- Creation date in the source system ("born" in CRM).
);
GO

-- Product Master: represents products as defined in source system.
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info
(
    prd_id        INT,               -- Product's numeric identifier as in source.
    prd_key       NVARCHAR(50),      -- Business key; text-based for linking between systems.
    prd_nm        NVARCHAR(50),      -- Readable product name.
    prd_cost      INT,               -- Unit cost, integer type (monetary unit unspecified).
    prd_line      NVARCHAR(50),      -- Product line for grouping.
    prd_start_dt  DATETIME,          -- Availability/launch date.
    prd_end_dt    DATETIME           -- Discontinuation/expiry date (could be NULL for active).
);
GO

-- Sales Transaction Details: unvalidated, as in raw staging.
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details
(
    sls_ord_num   NVARCHAR(50),      -- Order number, no enforced constraints.
    sls_prd_key   NVARCHAR(50),      -- Product key as string, not a real FK.
    sls_cust_id   INT,               -- Customer ID, not tightly coupled as a FK.
    sls_order_dt  INT,               -- Order date stored as INT (suspicious: may represent YYYYMMDD or similar).
    sls_ship_dt   INT,               -- Shipping date also INT format.
    sls_due_dt    INT,               -- Due date in INT.
    sls_sales     INT,               -- Total sales amount/amount for line.
    sls_quantity  INT,               -- Quantity sold.
    sls_price     INT                -- Price per unit (raw from source, may need cleansing).
);
GO

-- ERP Customer Info: alternate or supplemental customer data, must be joined via cid.
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12
(
    cid   NVARCHAR(50),                 -- ERP customer identifier, join key for related tables below.
    bdate DATE,                         -- Birthdate, formatted as date (can be used for demographics).
    gen   NVARCHAR(50)                  -- Gender, unconstrained string per ERP conventions.
);
GO

-- ERP Location Info: customer geographic information from ERP source.
IF OBJECT_ID('bronze.erp_loc_101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_101;
GO

CREATE TABLE bronze.erp_loc_101
(
    cid    NVARCHAR(50),                -- Customer identifier for join to erp_cust_az12.
    cntry  NVARCHAR(50)                 -- Customer's country as string; not domain-limited.
);
GO

-- ERP Product Categories and Maintenance: product master data supplement.
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2
(
    ID           NVARCHAR(50),          -- Product or item ID as per ERP catalog.
    CAT          NVARCHAR(50),          -- Category label; no referential integrity.
    SUBCAT       NVARCHAR(50),          -- Sub-category.
    MAINTENANCE  NVARCHAR(50)           -- Maintenance status/type/flag, unconstrained.
);
GO

/* ===========================================================================
   Bulk Data Loading Procedure for Bronze Stage with Timing and Error Logging
   Establishes repeatable import and verification, with robust error handling.
   =========================================================================== */

USE DataWarehouse;
GO

-- Remove and redefine the data load procedure for modular repeatability.
IF OBJECT_ID('bronze.load_bronze', 'P') IS NOT NULL
    DROP PROCEDURE bronze.load_bronze;
GO

CREATE PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE 
        @start_time         DATETIME,
        @end_time           DATETIME,
        @batch_start_time   DATETIME,
        @batch_end_time     DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '=====================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=====================================';

        -- CRM source tables load section
        PRINT '=====================================';
        PRINT 'Loading CRM Tables';
        PRINT '=====================================';

        -- CUSTOMER MASTER LOAD
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;
        PRINT '>> Inserting Data into Table: bronze.crm_cust_info';

        BULK INSERT bronze.crm_cust_info
        FROM '/var/opt/mssql/backup/cust_info.csv'
        WITH (
            FIRSTROW        = 2,                                        -- Skip header row
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            FORMAT          = 'CSV',
            ERRORFILE       = '/var/opt/mssql/backup/cust_info_errors.log',  -- Capture rejected rows for debugging.
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: ' 
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- PRODUCT MASTER LOAD
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;
        PRINT '>> Inserting Data into Table: bronze.crm_prd_info';

        BULK INSERT bronze.crm_prd_info
        FROM '/var/opt/mssql/backup/prd_info.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            FORMAT          = 'CSV',
            ERRORFILE       = '/var/opt/mssql/backup/prd_info_error.log',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';
        
        -- SALES DETAILS LOAD
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;
        PRINT '>> Inserting Data into Table: bronze.crm_sales_details';

        BULK INSERT bronze.crm_sales_details
        FROM '/var/opt/mssql/backup/sales_details.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            FORMAT          = 'CSV',
            -- ERRORFILE    = '/var/opt/mssql/backup/sales_details_error.log',  -- May uncomment for troubleshooting loads.
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ERP source tables load section
        PRINT '=====================================';
        PRINT 'Loading ERP Tables';
        PRINT '=====================================';

        -- ERP CUSTOMER
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;
        PRINT '>> Inserting Data into Table: bronze.erp_cust_az12';

        BULK INSERT bronze.erp_cust_az12
        FROM '/var/opt/mssql/backup/CUST_AZ12.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            FORMAT          = 'CSV',
            ERRORFILE       = '/var/opt/mssql/backup/CUST_AZ12_error.log',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ERP LOCATION
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.erp_loc_101';
        TRUNCATE TABLE bronze.erp_loc_101;
        PRINT '>> Inserting Data into Table: bronze.erp_loc_101';

        BULK INSERT bronze.erp_loc_101
        FROM '/var/opt/mssql/backup/LOC_A101.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            FORMAT          = 'CSV'
            -- ERRORFILE    = '/var/opt/mssql/backup/LOC_A101_error.log',  -- Uncomment for error diagnostics.
            -- TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ERP PRODUCT CATEGORY SUPPLEMENT
        SET @start_time = GETDATE();
        PRINT '>> Truncating bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        PRINT '>> Inserting Data into Table: bronze.erp_px_cat_g1v2';

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM '/var/opt/mssql/backup/PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR   = '\n',
            FORMAT          = 'CSV'
            -- ERRORFILE    = '/var/opt/mssql/backup/PX_CAT_G1V2_error.log', -- Uncomment for error tracing
            -- TABLOCK
        );
        
        SET @end_time = GETDATE();
        PRINT '>> Loading Duration: '
            + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seconds';
   
        -- Batch duration reporting
        SET @batch_end_time = GETDATE();
        PRINT '========================================';
        PRINT '>> BRONZE Layer Duration is Complete <<';
        PRINT '>> Total BRONZE Layer Load Duration: ' 
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) 
            + ' Seconds';
        PRINT '========================================';

    END TRY
    BEGIN CATCH
        PRINT '============================================';
        PRINT 'ERROR OCCURRED DURING LOADING THE BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '============================================';
    END CATCH
END
GO

-- Example verification: confirm ERP category table was populated.
SELECT * FROM bronze.erp_px_cat_g1v2;
