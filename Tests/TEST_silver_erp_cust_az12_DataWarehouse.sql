/*
===============================================================================
Overall Purpose:
    This script is designed for testing and cleaning customer data in the 
    'silver.erp_cust_az12' table, focusing on the 'cid', 'bdate' (birthdate), and 'gen' 
    (gender) columns. 

    Specifically, it: 
    - Identifies and corrects 'cid' values that have unwanted 'NAS' prefixes, 
      which affect customer data linking.
    - Verifies that all cleaned 'cid' values exist in the 'silver.crm_cust_info' 
      customer master table to ensure referential integrity.
    - Checks and cleans the 'bdate' column by detecting future dates and invalid 
      historical values, setting those to NULL or flagging them for review.
    - Explores distinct gender values present for data consistency inspection.
    
    This process aims at preparing accurate, clean foundational data for subsequent 
    business analytics and integration.
===============================================================================
*/

USE DataWarehouse;

/* 
Initial Inspection:
Query records where 'cid' contains the pattern 'AW00011015'.
Note: The CASE statement before was incomplete and removed here for correctness.
*/
SELECT
    cid,
    bdate,
    gen
FROM silver.erp_cust_az12
WHERE cid LIKE '%AW00011015%'
;


/*
Fixing 'cid' Values:
- Remove leading "NAS" prefix from 'cid' where present, to standardize IDs.
- Show original and fixed 'cid' alongside birthdate and gender.
*/
SELECT
    cid AS old_cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    bdate,
    gen
FROM silver.erp_cust_az12
;


/*
Referential Integrity Testing:
- Filter for cleaned 'cid' values that *do not* exist in the customer master table's 'cst_key' column.
- Helps to identify orphaned or non-matching customer IDs that may need correction or investigation.
*/
SELECT
    cid AS old_cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    bdate,
    gen
FROM silver.erp_cust_az12
WHERE CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END NOT IN (SELECT DISTINCT cst_key FROM silver.crm_cust_info)
;


/*
Check for Future Birthdates:
- Identifies records with birthdates greater than the current date, likely data errors.
- Uses cleaned 'cid' for clarity.
*/
SELECT
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    bdate,
    gen
FROM silver.erp_cust_az12
WHERE bdate > GETDATE()
;


/*
Fixing Birthdates:
- Replace any future birthdates with NULL to avoid invalid age calculations.
- Returns the cleaned 'cid', corrected birthdate, and gender.
*/
SELECT
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,
    gen
FROM silver.erp_cust_az12
;


/* 
Explore outlying birthdates for further quality control:
- List distinct birthdates earlier than 1924-01-01 or in the future.
- Helps identify obviously erroneous historical dates.
*/
SELECT DISTINCT bdate FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();


/* 
List distinct birthdates that are in the future.
Allows targeted review and correction of future dates not previously cleaned.
*/
SELECT DISTINCT bdate FROM silver.erp_cust_az12
WHERE bdate > GETDATE()
;


/*
Explore distinct gender values to understand data consistency,
e.g., whether a standard set of values is used or various unexpected entries occur.
*/
SELECT DISTINCT gen FROM silver.erp_cust_az12;


/* 
Fetch entire contents of the table for reference or manual inspection.
Note: May be expensive on large datasets; use with caution.
*/
SELECT * FROM silver.erp_cust_az12;
