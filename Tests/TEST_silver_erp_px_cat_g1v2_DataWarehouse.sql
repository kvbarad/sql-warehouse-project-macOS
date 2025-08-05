USE DataWarehouse;

SELECT * FROM silver.erp_px_cat_g1v2;


/* PRE Insert Test ID COLUMN */

SELECT DISTINCT * FROM silver.erp_px_cat_g1v2;

/* FIXING ID COLUMN */

SELECT
ID AS old_ID,
REPLACE(ID, '_', '-') AS ID,
CAT,
SUBCAT,
TRIM(MAINTENANCE) AS MAINTENACE
FROM bronze.erp_px_cat_g1v2;
