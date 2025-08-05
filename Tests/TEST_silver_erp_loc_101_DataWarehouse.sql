USE DataWarehouse;

SELECT * FROM silver.erp_loc_101;


/* Post Insert Test cntry COLUMN's */

SELECT
REPLACE(cid, '-', '') AS cid,
CASE
    WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) = 'DE' THEN 'Germany'
    WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) = '' OR cntry IS NULL THEN 'N/A'
    WHEN UPPER(REPLACE(REPLACE(TRIM(cntry), CHAR(13), ''), CHAR(10), '')) IN ('US', 'USA') THEN 'United States'
ELSE TRIM(cntry)
END AS cntry
FROM silver.erp_loc_101;

SELECT DISTINCT
cntry
FROM silver.erp_loc_101
ORDER BY cntry;

SELECT * FROM silver.erp_loc_101;
SELECT * FROM bronze.erp_px_cat_g1v2;
SELECT prd_key FROM silver.crm_prd_info;
