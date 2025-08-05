/*
Purpose: 
This SQL script performs comprehensive sales and customer analysis using the data from the DataWarehouse.
It covers:
- Viewing base dimension and fact tables.
- Time-series analysis of sales (yearly, monthly, cumulative).
- Performance analysis comparing sales with averages and previous years.
- Part-to-whole sales proportional analysis.
- Product segmentation by cost.
- Customer segmentation by spending and lifespan.
- Creating a detailed customer report with KPIs and segments.
*/

USE DataWarehouse;

-- VIEWING BASE TABLE DATA FOR VERIFICATION
SELECT * FROM gold.dim_customers;
SELECT * FROM gold.dim_products;
SELECT * FROM gold.sales_fact;


/* ============================
   1. CHANGE OVER TIME: Trend Analysis
   Analyze how total sales and customer activity evolve over time.
============================ */

-- Total sales aggregated by year
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_sales
FROM gold.sales_fact
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- Yearly total sales, distinct customers, and quantity sold
SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers, -- Unique customers to avoid double counting
    SUM(quantity) AS total_quantity
FROM gold.sales_fact
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- Monthly breakdown with customers count
SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers, -- Unique customers each month
    SUM(quantity) AS total_quantity
FROM gold.sales_fact
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);

-- Same monthly aggregation using DATETRUNC() for better date handling
SELECT
    DATETRUNC(MONTH, order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.sales_fact
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date);

-- Another variant using FORMAT() for more readable month-year format
SELECT
    FORMAT(order_date, '%y-MMM') AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.sales_fact
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, '%y-MMM')
ORDER BY FORMAT(order_date, '%y-MMM');


/* ============================
   2. CUMULATIVE ANALYSIS: Running Totals and Moving Averages
============================ */

-- Running total sales per month
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER(ORDER BY order_date) AS running_sales -- Calculates cumulative sales
FROM
(
    SELECT
        DATETRUNC(MONTH, order_date) AS order_date,
        SUM(sales_amount) AS total_sales
    FROM gold.sales_fact
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) t;

-- Running total partitioned by year, restarts at beginning of each year
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
FROM
(
    SELECT
        DATETRUNC(MONTH, order_date) AS order_date,
        SUM(sales_amount) AS total_sales
    FROM gold.sales_fact
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) t;

-- Running total and running average price partitioned by year
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_sales,
    SUM(avg_price) OVER(PARTITION BY YEAR(order_date) ORDER BY order_date) AS running_avg
FROM
(
    SELECT
        DATETRUNC(MONTH, order_date) AS order_date,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.sales_fact
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date)
) t;

-- More index-friendly version by precomputing year in the inner query
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY order_date_yr ORDER BY order_date) AS running_sales,
    SUM(avg_price) OVER(PARTITION BY order_date_yr ORDER BY order_date) AS running_avg
FROM
(
    SELECT
        DATETRUNC(MONTH, order_date) AS order_date,
        YEAR(order_date) AS order_date_yr,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.sales_fact
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date), YEAR(order_date)
) t;

/* Using CTE and casting for precise cumulative average calculation */
WITH monthlyagg AS
(
    SELECT
        DATETRUNC(MONTH, order_date) AS order_date,
        YEAR(order_date) AS order_date_yr,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.sales_fact
    WHERE order_date IS NOT NULL
    GROUP BY DATETRUNC(MONTH, order_date), YEAR(order_date)
)
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY order_date_yr ORDER BY order_date) AS running_sales,
    SUM(CAST(total_sales AS DECIMAL(18,2)) * CAST(avg_price AS DECIMAL(18,2))) OVER(PARTITION BY order_date_yr ORDER BY order_date)
      / SUM(CAST(total_sales AS DECIMAL(38,4))) OVER(PARTITION BY order_date_yr ORDER BY order_date) AS running_avg
FROM monthlyagg
ORDER BY order_date;


/* ============================
   3. PERFORMANCE ANALYSIS: Comparing Current vs Target Values
============================ */

-- Aggregate product sales yearly with product names
WITH products_sales_yearly AS
(
    SELECT
        YEAR(s.order_date) AS order_year,
        p.product_name,
        SUM(s.sales_amount) AS total_sales
    FROM gold.sales_fact s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    WHERE s.order_date IS NOT NULL
    GROUP BY YEAR(s.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    total_sales,
    AVG(total_sales) OVER (PARTITION BY product_name) AS avg_sales, -- Average yearly sales per product
    COALESCE(LAG(total_sales) OVER (PARTITION BY product_name ORDER BY order_year), 0) AS prev_yearsales -- Previous year sales using LAG()
FROM products_sales_yearly
ORDER BY product_name, order_year;


/* ============================
   4. PART-TO-WHOLE PROPORTIONAL ANALYSIS
============================ */

-- Category contribution to total sales using CTE
WITH category_sales AS
(
    SELECT
        p.category,
        SUM(s.price) AS total_sales
    FROM gold.sales_fact s
    LEFT JOIN gold.dim_products p ON s.product_key = p.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER() AS overall_sales, -- Total sales across all categories
    CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER()) * 100, 2), '%') AS cat_sales_percent
FROM category_sales
ORDER BY total_sales DESC;


/* ============================
   5. DATA SEGMENTATION
============================ */

-- Segment products by cost ranges and count per range
WITH product_range AS
(
    SELECT
        product_key,
        product_name,
        prd_cost,
        CASE
            WHEN prd_cost < 100 THEN 'below 100'
            WHEN prd_cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN prd_cost BETWEEN 500 AND 1000 THEN '500-1000'
            WHEN prd_cost BETWEEN 1000 AND 1500 THEN '1000-1500'
            ELSE 'above 1500'
        END AS cost_range
    FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_range
GROUP BY cost_range
ORDER BY total_products DESC;


/* ============================
   6. CUSTOMER SEGMENTATION BY SPENDING & LIFESPAN
============================ */

WITH customer_spend AS
(
    SELECT
        c.customer_key,
        SUM(s.sales_amount) AS total_spend,
        MIN(s.order_date) AS first_order_date,
        MAX(s.order_date) AS last_order_date,
        COALESCE(DATEDIFF(MONTH, MIN(s.order_date), MAX(s.order_date)), 0) AS lifespan -- months active
    FROM gold.sales_fact s
    LEFT JOIN gold.dim_customers c ON s.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT
    CASE 
        WHEN lifespan >= 12 AND total_spend >= 5000 THEN 'vip'
        WHEN lifespan >= 12 AND total_spend < 5000 THEN 'regular'
        ELSE 'new'
    END AS customer_segment,
    COUNT(customer_key) AS total_customers
FROM customer_spend
GROUP BY customer_segment
ORDER BY total_customers DESC;


/* ============================
   7. DETAILED CUSTOMER REPORT WITH SEGMENTS
============================ */

-- Create or replace a view that consolidates customer metrics and segments

IF OBJECT_ID('dbo.customer_report', 'V') IS NOT NULL
    DROP VIEW dbo.customer_report;
GO

CREATE VIEW dbo.customer_report AS
WITH base_query AS
(
    SELECT
        s.order_number,
        s.product_key,
        s.order_date,
        s.sales_amount,
        s.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.firstname, ' ', c.lastname) AS customer_name,
        DATEDIFF(YEAR, c.birth_date, GETDATE()) AS age
    FROM gold.sales_fact s
    LEFT JOIN gold.dim_customers c ON s.customer_key = c.customer_key
    WHERE s.order_date IS NOT NULL
),
customer_aggregation AS
(
    SELECT
        customer_key,
        customer_number,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
        MAX(order_date) AS last_ordered
    FROM base_query
    GROUP BY customer_key, customer_number, age
)
SELECT
    customer_key,
    customer_number,
    CASE
        WHEN age < 20 THEN 'below 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    CASE 
        WHEN lifespan >= 12 AND total_sales >= 5000 THEN 'vip'
        WHEN lifespan >= 12 AND total_sales < 5000 THEN 'regular'
        ELSE 'new'
    END AS customer_segment,
    last_ordered,
    DATEDIFF(MONTH, last_ordered, GETDATE()) AS recency, -- How many months since last order
    CASE WHEN total_orders = 0 THEN 0 ELSE total_sales / total_orders END AS avg_price, -- Average order value per customer
    CASE WHEN lifespan = 0 THEN total_sales ELSE total_sales / lifespan END AS avg_monthly_spend -- Average monthly spend
FROM customer_aggregation;
