/*
===============================================================================
Overall Purpose:
    This script is designed for testing and validating the quality of the 'cid' 
    column values in the 'bronze.erp_cust_az12' table before performing data integration.
    
    Specifically, it inspects records with a particular pattern in 'cid' and applies 
    a transformation to fix inconsistent prefixes (removing 'NAS' prefix when detected). 
    This is important because 'cid' is the key column used to link customer data 
    across different datasets.
===============================================================================
*/

USE DataWarehouse;


/* 
Check the quality of the 'cid' column,
focusing on records where 'cid' contains 'AW00011015'.
Displays original cid alongside birthdate and gender.
Note: The CASE statement below was incomplete and fixed in next query.
*/
SELECT
    cid,
    bdate,
    gen
FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011015%';


/*
Fix issues with 'cid' caused by unwanted 'NAS' prefix:
- For any 'cid' starting with 'NAS', remove this prefix.
- Otherwise, leave 'cid' unchanged.
Shows both original and transformed 'cid' alongside other fields
for comparison and validation.
*/
SELECT
    cid               AS old_cid,
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove first 3 chars ('NAS')
        ELSE cid
    END                AS cid,
    bdate,
    gen
FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011015%';


/*
Simple select to verify data contents in the 'silver.crm_cust_info' table.
Useful to check downstream data after any upstream fixes.
*/
SELECT *
FROM silver.crm_cust_info;
