/*
===============================================================================
Overall Purpose:
    This script is designed for testing and validating the data quality of the 
    sales details stored in the 'silver.crm_sales_details' table. The focus is on:

    - Correcting and converting integer date fields (sls_order_dt, sls_ship_dt, 
      sls_due_dt) stored as YYYYMMDD integers into proper SQL DATE types, 
      handling invalid or unexpected values by converting them to NULL.

    - Validating and fixing sales-related numeric fields (sls_sales, sls_quantity, sls_price) 
      to ensure consistency based on the formula: sls_sales ≈ sls_quantity * |sls_price|.

    - Performing validations to detect and report date inconsistencies (e.g. order date > ship date).

    - Exposing issues for further analysis, and demonstrating fixes where possible.

Note:
    The logic applies standard data cleaning rules, important before 
    data integration or analytical processing.
===============================================================================
*/

USE DataWarehouse;


/* 
Final integrated query that formats key date columns and fixes sales figures:

- Converts integer-formatted dates to SQL DATE types where valid; else NULL.
- Repairs sales amount where inconsistent with quantity and price.
- Calculates missing or invalid prices from sales and quantity where applicable.
*/
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE 
        WHEN sls_order_dt = 0 OR LEN(CONVERT(VARCHAR, sls_order_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_order_dt) AS DATE)
    END AS sls_order_date,

    CASE 
        WHEN sls_ship_dt = 0 OR LEN(CONVERT(VARCHAR, sls_ship_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_ship_dt) AS DATE)
    END AS sls_ship_date,

    CASE 
        WHEN sls_due_dt = 0 OR LEN(CONVERT(VARCHAR, sls_due_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_due_dt) AS DATE)
    END AS sls_due_date,

    -- Fix sls_sales if missing, zero, or inconsistent with quantity * abs(price)
    CASE 
        WHEN sls_sales IS NULL 
             OR sls_sales <= 0 
             OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    -- Fix sls_price if missing or zero, calculate from sales / quantity 
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM silver.crm_sales_details
;


/* -----------------------------------------------------------------------------
Validations on sls_order_dt (Order Date):

- Identify invalid dates:
   * Negative or zero values
   * Incorrect length — must be 8 digits (YYYYMMDD)
   * Outside plausible date range (between 1900-01-01 and 2050-01-01)
- Replace zero with NULL for reporting purposes
----------------------------------------------------------------------------- */
SELECT
    NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt < 0 
   OR sls_order_dt IS NULL
   OR LEN(CONVERT(VARCHAR, sls_order_dt)) != 8
   OR sls_order_dt > 20500101
   OR sls_order_dt < 19000101
;


/* -----------------------------------------------------------------------------
Convert and fix sls_order_dt to DATE, setting invalid values as NULL
----------------------------------------------------------------------------- */
SELECT
    CASE 
        WHEN sls_order_dt = 0 OR LEN(CONVERT(VARCHAR, sls_order_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_order_dt) AS DATE)
    END AS sls_order_date
FROM silver.crm_sales_details
;


/* -----------------------------------------------------------------------------
Repeat above validation and fix process for sls_ship_dt (Ship Date)
----------------------------------------------------------------------------- */
SELECT
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt < 0 
   OR sls_ship_dt IS NULL
   OR LEN(CONVERT(VARCHAR, sls_ship_dt)) != 8
   OR sls_ship_dt > 20500101
   OR sls_ship_dt < 19000101
;

SELECT
    CASE 
        WHEN sls_ship_dt = 0 OR LEN(CONVERT(VARCHAR, sls_ship_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_ship_dt) AS DATE)
    END AS sls_ship_date
FROM silver.crm_sales_details
;


/* -----------------------------------------------------------------------------
Repeat above validation and fix process for sls_due_dt (Due Date)
----------------------------------------------------------------------------- */
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt < 0 
   OR sls_due_dt IS NULL
   OR LEN(CONVERT(VARCHAR, sls_due_dt)) != 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101
;


/* -----------------------------------------------------------------------------
Validate logical ordering of dates per business rules:

Expected: sls_order_date < sls_ship_date < sls_due_date

Highlight records violating this sequence after date conversion.
----------------------------------------------------------------------------- */
SELECT
    CASE 
        WHEN sls_order_dt = 0 OR LEN(CONVERT(VARCHAR, sls_order_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_order_dt) AS DATE)
    END AS sls_order_date,

    CASE 
        WHEN sls_ship_dt = 0 OR LEN(CONVERT(VARCHAR, sls_ship_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_ship_dt) AS DATE)
    END AS sls_ship_date,

    CASE 
        WHEN sls_due_dt = 0 OR LEN(CONVERT(VARCHAR, sls_due_dt)) != 8 THEN NULL
        ELSE CAST(CONVERT(VARCHAR, sls_due_dt) AS DATE)
    END AS sls_due_date

FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
    OR sls_order_dt > sls_due_dt
;


/* -----------------------------------------------------------------------------
Check consistency of sales figures:

- Find records where sales amount not equal to quantity * price
- Also filter out non-positive or NULL values in any of the three columns
----------------------------------------------------------------------------- */
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
ORDER BY sls_sales, sls_quantity, sls_price
;


/* -----------------------------------------------------------------------------
Show rows where sales, quantity, or price fail validation rules.
This duplicates the above but may be used for manual inspection before fixes.
----------------------------------------------------------------------------- */
SELECT DISTINCT
    sls_sales,
    sls_price,
    sls_quantity
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
ORDER BY sls_sales, sls_quantity, sls_price
;


/* Final sanity check: fetch all rows (for manual or downstream inspection) */
SELECT * FROM silver.crm_sales_details;
