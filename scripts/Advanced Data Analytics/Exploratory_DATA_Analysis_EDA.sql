/*
===============================================================================
Overall Purpose:
    This script is designed as a learning and exploratory tool for 
    understanding the structure and data contained within the DataWarehouse. 
    It performs multiple checks and data explorations across the gold and silver 
    schemas, focusing on CRM, ERP, and sales data. 
     
    The script includes dimension/value explorations, range computations, key metrics 
    aggregations, magnitude analyses by categories/dimensions, and ranking queries 
    to identify top and bottom performers. 
===============================================================================
*/

USE DataWarehouse;

-- Quick data sanity checks on top 1000 rows from key tables in gold and silver layers
SELECT TOP 1000 * FROM gold.dim_customers;
SELECT TOP 1000 * FROM silver.crm_prd_info;
SELECT TOP 1000 * FROM silver.crm_sales_details;

SELECT TOP 1000 * FROM silver.erp_cust_az12;
SELECT TOP 1000 * FROM silver.erp_loc_101;
SELECT TOP 1000 * FROM silver.erp_px_cat_g1v2;


/* 1. DATA EXPLORATION */

/* Explore all objects (tables, views) across the current database */
SELECT * FROM INFORMATION_SCHEMA.TABLES;

/* Explore all columns across all tables */
SELECT * FROM INFORMATION_SCHEMA.COLUMNS;

/* Explore all columns for a specific table */
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


/* 2. DIMENSIONS EXPLORATION */

/* List distinct countries of customers to get an understanding of geographic footprint */
SELECT DISTINCT country FROM gold.dim_customers;

/* Explore product categorization hierarchies */
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products;

-- Same as above but ordered for better readability
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY category, subcategory, product_name;


/* 3. DATE EXPLORATION */

/* Inspect sales fact to understand order date distributions */
SELECT * FROM gold.sales_fact;

/* Calculate date range of orders in years, months, days */
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) AS order_range_years,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months,
    DATEDIFF(DAY, MIN(order_date), MAX(order_date)) AS order_range_days
FROM gold.sales_fact;

/* Identify the age range of customers */
SELECT * FROM gold.dim_customers;

SELECT
    MIN(birth_date) AS oldest_birth_date,
    DATEDIFF(YEAR, MIN(birth_date), GETDATE()) AS oldest_age_years,
    MAX(birth_date) AS youngest_birth_date,
    DATEDIFF(YEAR, MAX(birth_date), GETDATE()) AS youngest_age_years
FROM gold.dim_customers;


/* 4. MEASURES EXPLORATIONS */

/* Filter out sales rows where quantity sold is more than 1, typically to study bulk orders */
SELECT * FROM gold.sales_fact
WHERE quantity > 1;

/* Basic counts for quantities, items, and total sales for business overview */
SELECT COUNT(quantity) AS total_quantity FROM gold.sales_fact;
SELECT COUNT(quantity) AS totalitems_sold FROM gold.sales_fact;

SELECT SUM(price) AS totalsales_usd$ FROM gold.sales_fact;
SELECT AVG(price) AS avgsales_usd$ FROM gold.sales_fact;

SELECT COUNT(order_number) AS totalorders FROM gold.sales_fact;
SELECT COUNT(DISTINCT order_number) AS totalorders_distinct FROM gold.sales_fact;

SELECT COUNT(product_name) AS total_products FROM gold.dim_products;
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

/* Customers that placed orders (some customers may exist without orders) */
SELECT COUNT(customer_key) AS total_customers FROM gold.sales_fact;
SELECT COUNT(DISTINCT customer_key) AS total_customers_distinct FROM gold.sales_fact;

/* Aggregate Report: Summarize all key metrics in a single result set using UNION ALL */
SELECT 'total_sales' AS measure_list, SUM(sales_amount) AS measured_values FROM gold.sales_fact
UNION ALL
SELECT 'total_sold_items' AS measure_list, COUNT(quantity) AS measured_values FROM gold.sales_fact
UNION ALL
SELECT 'total_products' AS measure_list, COUNT(product_name) AS measured_values FROM gold.dim_products
UNION ALL
SELECT 'avg_sales_price' AS measure_list, AVG(price) AS measured_values FROM gold.sales_fact
UNION ALL
SELECT 'total_customers' AS measure_list, COUNT(customer_key) AS measured_values FROM gold.dim_customers
UNION ALL
SELECT 'total_no_orders' AS measure_list, COUNT(DISTINCT order_number) AS measured_values FROM gold.sales_fact;


/* 5. MAGNITUDE ANALYSIS */

/* Analyze customer distribution by country */
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

/* Analyze customer distribution by gender */
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

/* Analyze product counts by category */
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

/* Average product cost by category */
SELECT
    category,
    AVG(prd_cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

/* Total revenue by product category */
SELECT
    p.category,
    SUM(sf.sales_amount) AS total_revenue
FROM gold.sales_fact AS sf
LEFT JOIN gold.dim_products AS p ON sf.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

/* Total revenue per customer */
SELECT
    customer_key,
    SUM(sales_amount) AS total_revenue
FROM gold.sales_fact
GROUP BY customer_key
ORDER BY total_revenue DESC;

/* Total revenue per customer with names */
SELECT
    c.customer_key,
    c.firstname,
    c.lastname,
    SUM(s.sales_amount) AS total_revenue
FROM gold.sales_fact AS s
LEFT JOIN gold.dim_customers c ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.firstname, c.lastname
ORDER BY total_revenue DESC;

/* Total revenue by concatenated customer name */
SELECT
    CONCAT(c.firstname, ' ', c.lastname) AS customername,
    SUM(s.sales_amount) AS total_revenue
FROM gold.sales_fact AS s
LEFT JOIN gold.dim_customers c ON s.customer_key = c.customer_key
GROUP BY CONCAT(c.firstname, ' ', c.lastname)
ORDER BY total_revenue DESC;

/* Total quantity sold by country */
SELECT
    country,
    SUM(quantity) AS total_sales
FROM gold.sales_fact AS s
LEFT JOIN gold.dim_customers AS c ON s.customer_key = c.customer_key
GROUP BY country
ORDER BY total_sales DESC;

/* Total quantity and revenue by product category and customer country */
SELECT
    p.category,
    c.country,
    SUM(sf.quantity) AS total_quantity,
    SUM(sf.sales_amount) AS total_revenue
FROM gold.sales_fact AS sf
LEFT JOIN gold.dim_products AS p ON sf.product_key = p.product_key
LEFT JOIN gold.dim_customers AS c ON sf.customer_key = c.customer_key
GROUP BY p.category, c.country
ORDER BY total_revenue DESC;


/* 6. RANKING ANALYSIS */

/* Top 5 products by total revenue */
SELECT TOP 5
    p.product_name,
    SUM(sf.sales_amount) AS total_revenue
FROM gold.dim_products AS p
LEFT JOIN gold.sales_fact AS sf ON p.product_key = sf.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

/* Top 5 products by total revenue using ROW_NUMBER for large datasets */
SELECT * FROM (
    SELECT
        p.product_name,
        SUM(sf.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(sf.sales_amount) DESC) AS rank_product
    FROM gold.dim_products AS p
    LEFT JOIN gold.sales_fact AS sf ON p.product_key = sf.product_key
    GROUP BY p.product_name
) t 
WHERE rank_product <= 5;

/* Bottom 5 products by total revenue */
SELECT TOP 5
    p.product_name,
    SUM(sf.sales_amount) AS total_revenue
FROM gold.sales_fact AS sf
LEFT JOIN gold.dim_products AS p ON sf.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC;

/* Bottom 5 products by total revenue using ROW_NUMBER */
SELECT * FROM (
    SELECT
        p.product_name,
        SUM(sf.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(sf.sales_amount)) AS rank_product
    FROM gold.sales_fact AS sf
    LEFT JOIN gold.dim_products AS p ON sf.product_key = p.product_key
    GROUP BY p.product_name
) t 
WHERE rank_product <= 5;

