/*
===============================================================================
Overall Purpose:
    This script serves as a comprehensive learning and testing tool for exploring 
    and manipulating data within the 'salesdb' database. It demonstrates:

    - Basic SELECT queries on customers and employees tables.
    - Use of JOINs (LEFT JOIN) to combine related tables (orders, customers, products, employees).
    - Combining and comparing datasets via UNION ALL, EXCEPT (using NOT IN in MySQL), and INTERSECT (via INNER JOIN).
    - Working with multiple tables storing similar data (orders and orders_archive).
    - String functions (CONCAT, UPPER) for formatting.
    - Numeric functions (ROUND) to control decimal precision.
    - Data type modification (ALTER TABLE MODIFY COLUMN).
    - Date/time extraction and formatting using YEAR, MONTH, DATE_FORMAT, etc.
    - Filtering by specific date parts and ordering results.
    - Illustrating date truncation concepts via formatting functions.

    Each section includes explanatory comments aimed at learners, showing the practical use 
    of SQL syntax and functions essential for querying and reporting in MySQL.
===============================================================================
*/

USE salesdb;

-- Retrieve a list of all customers (first and last names)
SELECT 
    firstname,
    lastname
FROM salesdb.customers
;

-- Retrieve a list of all employees (first and last names)
SELECT
    firstname,
    lastname
FROM salesdb.employees
;

/*
Retrieve all orders with related customer, product, and employee details using LEFT JOIN.
For each order, display:
- Order ID
- Customer's name
- Product name
- Sale amount
- Product price
- Salesperson's first name
*/
SELECT 
    o.orderid            AS "Order ID",
    c.firstname          AS "Customer's Name",
    p.product            AS "Product Name",
    o.sales              AS "Sales",
    p.price              AS "Price",
    e.firstname          AS "Sales Person's Name"
FROM salesdb.orders AS o
LEFT JOIN salesdb.customers AS c ON o.customerid = c.customerid
LEFT JOIN salesdb.products AS p ON o.productid = p.productid
LEFT JOIN salesdb.employees AS e ON o.salespersonid = e.employeeid
;

/*
Combine customers and employees (first and last names) into a single result set
using UNION ALL to include all records from both tables.
*/
SELECT 
    firstname,
    lastname
FROM salesdb.customers

UNION ALL

SELECT
    firstname,
    lastname
FROM salesdb.employees
;

/*
Find employees who are NOT customers.
MySQL does not support EXCEPT, so use NOT IN with a subquery instead.
*/
SELECT 
    firstname,
    lastname
FROM salesdb.employees
WHERE CONCAT(firstname, ' ', lastname) NOT IN (
    SELECT CONCAT(firstname, ' ', lastname) FROM salesdb.customers
)
;

/*
Find employees who are ALSO customers.
MySQL does not support INTERSECT, so use INNER JOIN to find common entries.
*/
SELECT
    e.firstname,
    e.lastname
FROM salesdb.employees e
INNER JOIN salesdb.customers c USING (firstname, lastname)
;

/*
Combine orders from two tables (orders and orders_archive) without duplicates.
Add a 'source' column to indicate source table.
Use UNION (not UNION ALL) to remove duplicates.
Sort by order ID.
*/
SELECT 
    'orders' AS source,
    orderid,
    customerid,
    productid,
    salespersonid,
    sales,
    orderdate,
    orderstatus,
    shipaddress,
    billaddress,
    quantity,
    sales,          -- repeated column, consider removing duplicate if present
    creationtime
FROM salesdb.orders

UNION 

SELECT 
    'orders_archive' AS source,
    orderid,
    customerid,
    productid,
    salespersonid,
    sales,
    orderdate,
    orderstatus,
    shipaddress,
    billaddress,
    quantity,
    sales,          -- repeated column here also
    creationtime
FROM salesdb.orders_archive

ORDER BY orderid
;

/*
Concatenate the first and last names of employees into a single uppercase string alias "FULLNAME".
*/
SELECT
    CONCAT(UPPER(firstname), ' ', UPPER(lastname)) AS "FULLNAME"
FROM salesdb.employees
;

/*
Demonstrate usage of ROUND function to round a number to different decimal places.
Example: Round 3.516 to 2, 1, and 0 decimal places.
*/
SELECT 
    3.516 AS "Value",
    ROUND(3.516, 2) AS "Round_value_2",
    ROUND(3.516, 1) AS "Round_value_1",
    ROUND(3.516, 0) AS "Round_value_0"
;

/*
Select orders showing their IDs and date/time columns.
*/
SELECT
    orderid,
    orderdate,
    shipdate,
    creationtime
FROM salesdb.orders
;

/*
Change the datatype of the 'creationtime' column in 'orders' table to DATETIME.
*/
ALTER TABLE salesdb.orders
MODIFY COLUMN creationtime DATETIME
;

/*
Change the datatype of 'creationtime' column in 'orders' table to TIMESTAMP.
*/
ALTER TABLE salesdb.orders
MODIFY COLUMN creationtime TIMESTAMP
;

/*
Extract individual components from 'creationtime' timestamp for detailed time analysis:
Year, Month, Day, Hour, Minute, Second, Week number, Quarter,
Day of week (1 = Sunday), Day of year, Day name (text).
*/
SELECT
    orderid,
    creationtime,
    YEAR(creationtime)          AS "Year",
    MONTH(creationtime)         AS "Month",
    DAY(creationtime)           AS "Day",
    HOUR(creationtime)          AS "Hour",
    MINUTE(creationtime)        AS "Minute",
    SECOND(creationtime)        AS "Second",
    WEEK(creationtime)          AS "Week",
    QUARTER(creationtime)       AS "Quarter",
    DAYOFWEEK(creationtime)     AS "Day of Week", /* 1=Sunday, 7=Saturday */
    DAYOFYEAR(creationtime)     AS "Day of Year", /* 1-366 */
    DAYNAME(creationtime)       AS "Day Name"
FROM salesdb.orders
;

/*
Filter and display orders created in February 2025.
Also displays extracted Month, Year, and "Year-Month" formatted string.
*/
SELECT
    orderid,
    creationtime,
    MONTH(creationtime)              AS "Month",         /* Extract month */
    YEAR(creationtime)               AS "Year",          /* Extract year */
    DATE_FORMAT(creationtime, '%Y-%m') AS "Year-Month"   /* Format year-month */
FROM salesdb.orders
WHERE MONTH(creationtime) = 2 AND YEAR(creationtime) = 2025 /* Filter Feb 2025 */
ORDER BY creationtime
;

/*
Demonstrate different DATE_FORMAT styles to display 'creationtime':
- ISO style, European style, long format, time only, abbreviated month, full timestamp, weekday and full date.
*/
SELECT
    orderid,
    creationtime,
    DATE_FORMAT(creationtime, '%Y-%m-%d')          AS "YYYY-MM-DD",
    DATE_FORMAT(creationtime, '%d/%m/%Y')          AS "DD/MM/YYYY",
    DATE_FORMAT(creationtime, '%M %d, %Y')         AS "Month Day, Year",
    DATE_FORMAT(creationtime, '%H:%i:%s')          AS "HH:MM:SS",       /* 24h:mm:ss */
    DATE_FORMAT(creationtime, '%b %d, %Y')         AS "Abbreviated Month Day, Year",
    DATE_FORMAT(creationtime, '%Y-%m-%d %H:%i:%s') AS "YYYY-MM-DD HH:MM:SS",
    DATE_FORMAT(creationtime, '%W, %M %d, %Y')     AS "Weekday, Month Day, Year",
    DATE_FORMAT(creationtime, '%W, %m, ''%y')      AS "Weekday, Month Year" /* Note: Extra quotes might be typo */
FROM salesdb.orders
;

/*
Simulate date truncation by extracting day, month, and year parts separately.
Show day name for added readability.
*/
SELECT
    orderid,
    creationtime,
    DATE_FORMAT(creationtime, '%d') AS "Truncated to Day",   /* Day part only */
    DATE_FORMAT(creationtime, '%m') AS "Truncated to Month", /* Month part only */
    DATE_FORMAT(creationtime, '%Y') AS "Truncated to Year",  /* Year part only */
    DAYNAME(creationtime)           AS "Day Name"             /* Name of the weekday */
FROM salesdb.orders
;



USE salesdb;


/* 
Calculate differences between the 'creationtime' timestamp and the current time 
across various time units (seconds, minutes, hours, etc.), using TIMESTAMPDIFF().
Also, find the last day of the month for the creation date and show the previous 
and next months relative to the creation time.
*/
SELECT
    orderid,
    creationtime,
    quantity,

    TIMESTAMPDIFF(SECOND, creationtime, NOW()) AS "Difference in Seconds",      /* Difference in seconds */
    TIMESTAMPDIFF(MINUTE, creationtime, NOW()) AS "Difference in Minutes",      /* Difference in minutes */
    TIMESTAMPDIFF(HOUR, creationtime, NOW()) AS "Difference in Hours",          /* Difference in hours */
    TIMESTAMPDIFF(DAY, creationtime, NOW()) AS "Difference in Days",            /* Difference in days */
    TIMESTAMPDIFF(WEEK, creationtime, NOW()) AS "Difference in Weeks",          /* Difference in weeks */
    TIMESTAMPDIFF(MONTH, creationtime, NOW()) AS "Difference in Months",        /* Difference in months */
    TIMESTAMPDIFF(YEAR, creationtime, NOW()) AS "Difference in Years",          /* Difference in years */

    LAST_DAY(creationtime) AS "Last Day of Month",                             /* Last calendar day of creation month */

    DATE_ADD(creationtime, INTERVAL 1 MONTH) AS "Next Month",                  /* One month after creationtime */
    DATE_SUB(creationtime, INTERVAL 1 MONTH) AS "Previous Month"               /* One month before creationtime */

FROM salesdb.orders
;


/* 
Calculate future sales trends by applying various percentage increases and decreases 
to the 'quantity' and 'sales' columns, projecting scenarios such as 10% and 20% growth or decline.
*/
SELECT
    orderid,
    creationtime,
    quantity,
    sales,

    quantity AS "Current Quantity",                         /* Original order quantity */
    quantity * 1.1 AS "Future Trend (10% Increase)",       /* +10% quantity projection */
    quantity * 0.9 AS "Future Trend (10% Decrease)",       /* -10% quantity projection */
    quantity * 1.2 AS "Future Trend (20% Increase)",       /* +20% quantity projection */
    quantity * 0.8 AS "Future Trend (20% Decrease)",       /* -20% quantity projection */

    sales AS "Current Sales",                               /* Original sales value */
    sales * 1.1 AS "Future Sales (10% Increase)",          /* +10% sales projection */
    sales * 0.9 AS "Future Sales (10% Decrease)",          /* -10% sales projection */
    sales * 1.2 AS "Future Sales (20% Increase)",          /* +20% sales projection */
    sales * 0.8 AS "Future Sales (20% Decrease)"           /* -20% sales projection */

FROM salesdb.orders
;


/*
Aggregate sales from both the 'orders' and 'orders_archive' tables,
calculating future sales trends similarly as above.
The source column indicates the origin table for each record.
*/
SELECT
    'orders' AS source,
    orderid,
    sales,

    sales * 1.1 AS "Future Sales (10% Increase)",          /* +10% sales projection */
    sales * 0.9 AS "Future Sales (10% Decrease)",          /* -10% sales projection */
    sales * 1.2 AS "Future Sales (20% Increase)",          /* +20% sales projection */
    sales * 0.8 AS "Future Sales (20% Decrease)"           /* -20% sales projection */

FROM salesdb.orders

UNION ALL

SELECT
    'orders_archive' AS source,
    orderid,
    sales,

    sales * 1.1 AS "Future Sales (10% Increase)",          
    sales * 0.9 AS "Future Sales (10% Decrease)",          
    sales * 1.2 AS "Future Sales (20% Increase)",          
    sales * 0.8 AS "Future Sales (20% Decrease)"           

FROM salesdb.orders_archive

ORDER BY orderid
;


/*
Categorize sales values into 'High', 'Medium', 'Low', or 'No Sales' using nested IF() functions.
The result is ordered descending by sales to highlight highest sales first.
*/
SELECT
    orderid,
    sales,

    IF(
        sales > 20, 'High Sales',
        IF(
            sales BETWEEN 11 AND 20, 'Medium Sales',
            IF(
                sales BETWEEN 1 AND 10, 'Low Sales',
                'No Sales'
            )
        )
    ) AS "Sales Category"

FROM salesdb.orders

ORDER BY sales DESC
-- LIMIT 5 /* Uncomment to limit to top 5 by sales */
;


/*
Equivalent categorization using CASE statement, often preferred for readability.
*/
SELECT
    orderid,
    sales,

    CASE
        WHEN sales > 20 THEN 'High Sales'
        WHEN sales BETWEEN 11 AND 20 THEN 'Medium Sales'
        WHEN sales BETWEEN 1 AND 10 THEN 'Low Sales'
        ELSE 'No Sales'
    END AS "Sales Category"

FROM salesdb.orders

ORDER BY sales DESC
-- LIMIT 5 /* Uncomment to limit to top 5 by sales */
;


/*
Aggregate sales data by month and year (formatted as 'Year-Month'),
including total sales and total number of orders for each period.
*/
SELECT
    DATE_FORMAT(creationtime, '%Y-%M') AS "Year-Month",
    SUM(sales) AS "Total Sales",
    COUNT(orderid) AS "Total Orders"

FROM salesdb.orders

GROUP BY DATE_FORMAT(creationtime, '%Y-%M')

ORDER BY DATE_FORMAT(creationtime, '%Y-%M')
;


/*
Format 'creationtime' column into various culturally relevant date formats for display:
- DD/MM/YYYY (Common Europe)
- YYYY-MM-DD (ISO)
- Month Day, Year (Full textual month name)
*/
SELECT
    orderid,
    creationtime,
    DATE_FORMAT(creationtime, '%d/%m/%Y') AS "DD/MM/YYYY",
    DATE_FORMAT(creationtime, '%Y-%m-%d') AS "YYYY-MM-DD",
    DATE_FORMAT(creationtime, '%M %d, %Y') AS "Month Day, Year"

FROM salesdb.orders

WHERE creationtime IS NOT NULL

ORDER BY creationtime
;


/*
Casting 'creationtime' to various data types and string formats, useful for different processing needs.
*/
SELECT
    orderid,
    creationtime,
    CAST(creationtime AS DATE) AS "Creation Date",
    CAST(creationtime AS DATETIME) AS "Creation DateTime",
    CAST(creationtime AS CHAR) AS "Creation Time as String"

FROM salesdb.orders

WHERE creationtime IS NOT NULL

ORDER BY creationtime
;


/*
Demonstrate converting 'creationtime' to character strings and formatting times 
in AM/PM and 24-hour formats.
*/
SELECT
    orderid,
    creationtime,
    CONVERT(creationtime, CHAR) AS "Creation Time as String",
    DATE_FORMAT(creationtime, '%h:%i:%s %p') AS "Creation Time AM/PM",
    DATE_FORMAT(creationtime, '%Y-%m-%d %H:%i:%s') AS "Creation Time 24-Hour Format",
    DATE_FORMAT(creationtime, '%h:%i:%s %p') AS "Creation Time 12-Hour Format"

FROM salesdb.orders

WHERE creationtime IS NOT NULL

ORDER BY creationtime
;


/*
Demonstrate adding and subtracting various time intervals 
(day, month, year) from the 'creationtime' column using DATE_ADD() and DATE_SUB().
*/
SELECT
    orderid,
    creationtime,

    DATE_ADD(creationtime, INTERVAL 1 DAY) AS "Creation Time + 1 Day",
    DATE_ADD(creationtime, INTERVAL 1 MONTH) AS "Creation Time + 1 Month",
    DATE_ADD(creationtime, INTERVAL 1 YEAR) AS "Creation Time + 1 Year",

    DATE_SUB(creationtime, INTERVAL 1 DAY) AS "Creation Time - 1 Day",
    DATE_SUB(creationtime, INTERVAL 1 MONTH) AS "Creation Time - 1 Month",
    DATE_SUB(creationtime, INTERVAL 1 YEAR) AS "Creation Time - 1 Year"

FROM salesdb.orders

WHERE creationtime IS NOT NULL

ORDER BY creationtime
;



USE salesdb;


/* 
Calculate differences between 'orderdate' and 'shipdate' in various units:
- DATEDIFF() returns difference in days.
- TIMESTAMPDIFF() returns difference in specified units: YEAR, MONTH, DAY.
Filter out rows where either date is NULL and order by orderid.
*/
SELECT
    orderid,
    orderdate,
    shipdate,
    DATEDIFF(shipdate, orderdate) AS "Difference in Days",                 /* Days difference */
    TIMESTAMPDIFF(YEAR, orderdate, shipdate) AS "Difference in Years",      /* Years difference */
    TIMESTAMPDIFF(MONTH, orderdate, shipdate) AS "Difference in Months",    /* Months difference */
    TIMESTAMPDIFF(DAY, orderdate, shipdate) AS "Difference in Days"         /* Days difference duplicated for illustration */
FROM salesdb.orders
WHERE orderdate IS NOT NULL AND shipdate IS NOT NULL                       /* Exclude NULL dates for accuracy */
ORDER BY orderid;


/* 
Check for NULL values in 'creationtime' and indicate their presence with ISNULL().
Display meaningful status messages using IF().
Filter excludes rows where creationtime is NULL, so 'Is Creation Time NULL' always false here.
*/
SELECT
    orderid,
    creationtime,
    ISNULL(creationtime) AS "Is Creation Time NULL",                        /* Boolean 0 or 1 indicating NULL */
    IF(ISNULL(creationtime), 'Creation Time is NULL', 'Creation Time is NOT NULL') 
        AS "Creation Time Status"                                            /* User-friendly text status */
FROM salesdb.orders
WHERE creationtime IS NOT NULL                                              /* Only rows with creationtime */
ORDER BY orderid;


/* 
Check NULL status of shipping and billing address, 
return flags and descriptive messages.
Only considers rows where at least one address is not NULL.
Order by both address columns for readability.
*/
SELECT
    shipaddress,
    billaddress,
    ISNULL(shipaddress) AS "Is Ship Address NULL",
    ISNULL(billaddress) AS "Is Bill Address NULL",
    IF(ISNULL(shipaddress), 'Ship Address is NULL', 'Ship Address is NOT NULL'),
    IF(ISNULL(billaddress), 'Bill Address is NULL', 'Bill Address is NOT NULL')
FROM salesdb.orders
WHERE shipaddress IS NOT NULL OR billaddress IS NOT NULL
ORDER BY shipaddress, billaddress;


/* 
Trim leading and trailing spaces from address fields to cleanse data,
and replace any NULLs with default text.
Useful to standardize address output for reporting or further processing.
*/
SELECT
    shipaddress,
    billaddress,
    TRIM(shipaddress) AS "Trimmed Ship Address",                            /* Cleaned ship address */
    TRIM(billaddress) AS "Trimmed Bill Address",                            /* Cleaned bill address */
    IFNULL(shipaddress, 'No Ship Address') AS "Ship Address",               /* Replace NULL with default */
    IFNULL(billaddress, 'No Bill Address') AS "Bill Address"
FROM salesdb.orders
WHERE shipaddress IS NOT NULL OR billaddress IS NOT NULL
ORDER BY shipaddress, billaddress;


/* 
Return the first non-NULL address from shipaddress or billaddress fields.
Also individually handle each address field with defaults if NULL.
Trim spaces to normalize data for consistency.
*/
SELECT
    orderid,
    shipaddress,
    billaddress,
    TRIM(billaddress) AS "Trimmed Bill Address",
    TRIM(shipaddress) AS "Trimmed Ship Address",
    COALESCE(shipaddress, billaddress, 'No Address') AS "First Non-NULL Address", /* Returns first non-NULL */
    COALESCE(shipaddress, 'No Ship Address') AS "Ship Address",
    COALESCE(billaddress, 'No Bill Address') AS "Bill Address"
FROM salesdb.orders
WHERE shipaddress IS NOT NULL OR billaddress IS NOT NULL
ORDER BY shipaddress, billaddress;


/* 
Same as above but without separate defaults for each address field,
only returns first non-null address.
*/
SELECT
    orderid,
    shipaddress,
    billaddress,
    TRIM(billaddress) AS "Trimmed Bill Address",
    TRIM(shipaddress) AS "Trimmed Ship Address",
    COALESCE(shipaddress, billaddress, 'No Address') AS "First Non-NULL Address"
FROM salesdb.orders
WHERE shipaddress IS NOT NULL OR billaddress IS NOT NULL
ORDER BY shipaddress, billaddress;


/* 
Return NULL if shipping and billing addresses are identical, 
otherwise return the shipaddress.
Also provide a textual flag indicating if addresses match.
*/
SELECT
    orderid,
    shipaddress,
    billaddress,
    TRIM(shipaddress) AS "Trimmed Ship Address",
    TRIM(billaddress) AS "Trimmed Bill Address",
    NULLIF(shipaddress, billaddress) AS "Ship Address if Different from Bill Address", /* NULL if equal */
    IF(shipaddress = billaddress, 'Ship Address is same as Bill Address', 'Ship Address is different from Bill Address') AS "Address Comparison"
FROM salesdb.orders
WHERE shipaddress IS NOT NULL OR billaddress IS NOT NULL
ORDER BY shipaddress, billaddress;


/* 
Categorize orders by their status using CASE expression,
mapping each status to a descriptive label.
Exclude NULL statuses for consistency.
*/
SELECT
    orderid,
    orderstatus,
    CASE
        WHEN orderstatus = 'Pending' THEN 'Order is Pending'
        WHEN orderstatus = 'Shipped' THEN 'Order has been Shipped'
        WHEN orderstatus = 'Delivered' THEN 'Order has been Delivered'
        WHEN orderstatus = 'Cancelled' THEN 'Order has been Cancelled'
        ELSE 'Unknown Order Status'
    END AS "Order Status Description"
FROM salesdb.orders
WHERE orderstatus IS NOT NULL
ORDER BY orderid;


/* 
Aggregate sales by order status:
- Count number of orders in each status
- Sum total sales per status
Exclude NULL statuses.
*/
SELECT
    orderstatus,
    COUNT(orderid) AS "Number of Orders",
    SUM(sales) AS "Total Sales"
FROM salesdb.orders
WHERE orderstatus IS NOT NULL
GROUP BY orderstatus
ORDER BY orderstatus;


/* 
Filter aggregated results using HAVING clause,
only include statuses where total sales exceed 100.
*/
SELECT
    orderstatus,
    COUNT(orderid) AS "Number of Orders",
    SUM(sales) AS "Total Sales"
FROM salesdb.orders
WHERE orderstatus IS NOT NULL
GROUP BY orderstatus
HAVING SUM(sales) > 100
ORDER BY orderstatus;


/* 
Concatenate first and last names of customers into full names,
providing a placeholder for NULL last names.
Add 10 bonus points to customer score; default score zero if NULL.
Filter out customers without first names.
*/
SELECT
    customerid,
    firstname,
    lastname,
    score,
    CONCAT(firstname, ' ', COALESCE(lastname, ' __')) AS "Full Name",
    COALESCE(score, 0) + 10 AS "Updated Score"
FROM salesdb.customers
WHERE firstname IS NOT NULL
ORDER BY customerid;


/* 
Sort customers by score ascending and flag NULL scores explicitly,
which appear last in the order.
*/
SELECT
    firstname,
    lastname,
    score,
    CONCAT(firstname, ' ', COALESCE(lastname, ' __')) AS "Full Name",
    CASE WHEN score IS NULL THEN 1 ELSE 0 END AS "Null Score Flag"
FROM salesdb.customers
ORDER BY score;


/* 
Basic selects to review full contents of the following tables:
- customers
- employees
- orders
- orders_archive
Useful for exploratory learning.
*/
SELECT * FROM salesdb.customers;
SELECT * FROM salesdb.employees;
SELECT * FROM salesdb.orders;
SELECT * FROM salesdb.orders_archive;



USE salesdb;

/* 
Categorize customers by their 'score' column using a CASE statement:

- Assign descriptive labels for score ranges: High, Medium, Low.
- Handle NULL and out-of-range scores by labeling as 'No Score'.
- Concatenate first and last names (using COALESCE for NULL lastnames).
- Order by score descending for clarity of top scorers.

Note: The original WHEN NULL THEN 'No Score' was incorrect; replaced with proper NULL handling.
*/
SELECT
    customerid,
    firstname,
    lastname,
    score,
    CONCAT(firstname, ' ', COALESCE(lastname, ' __')) AS "Full Name",  -- Concatenate names with placeholder
    CASE 
        WHEN score IS NULL THEN 'No Score'
        WHEN score > 500 THEN 'High Score'
        WHEN score BETWEEN 400 AND 500 THEN 'Medium Score'
        WHEN score BETWEEN 100 AND 400 THEN 'Low Score'
        ELSE 'No Score'
    END AS "Score Category"
FROM salesdb.customers
ORDER BY score DESC;


/* 
Basic selects to display the full content of main tables.
Useful for exploratory analysis and verifying data.
*/
SELECT * FROM salesdb.customers;
SELECT * FROM salesdb.employees;
SELECT * FROM salesdb.orders;
SELECT * FROM salesdb.orders_archive;


/* 
Aggregate sales data for each customer to reveal order counts, sum, average, max, and min sales.
Group results by customerid to get customer-wise summaries.
*/
SELECT
    customerid,
    COUNT(*) AS "Total Orders",
    SUM(sales) AS "Total Sales",
    AVG(sales) AS "Average Sales",
    MAX(sales) AS "Maximum Sales",
    MIN(sales) AS "Minimum Sales"
FROM salesdb.orders
GROUP BY customerid;


/* 
Calculate total sales per product (with orderid and orderdate details),
using window functions partitioned by productid.
*/
SELECT
    orderid,
    orderdate,
    productid,
    SUM(sales) OVER (PARTITION BY productid) AS "Total Sales"
FROM salesdb.orders;


/* 
Aggregate sales across product and order status partitions. 
Also calculate overall total sales.
*/
SELECT
    orderid,
    orderdate,
    productid,
    orderstatus,
    sales,
    SUM(sales) OVER (PARTITION BY productid, orderstatus) AS "ProductSalesByStatus",
    SUM(sales) OVER () AS "Total Sales",
    SUM(sales) OVER (PARTITION BY productid) AS "Total Sales by Product"
FROM salesdb.orders;


/* 
Rank orders based on sales amount descending using RANK() window function.
*/
SELECT
    orderid,
    orderdate,
    productid,
    sales,
    RANK() OVER (ORDER BY sales DESC) AS "Sales Rank"
FROM salesdb.orders;


/* 
Calculate cumulative sales for each order status sorted by orderdate using frame clause:

- Unbounded Preceding to Current Row: cumulative sum up to current order.
*/
SELECT
    orderid,
    orderdate,
    productid,
    orderstatus,
    sales,
    SUM(sales) OVER (
        PARTITION BY orderstatus
        ORDER BY orderdate
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS "ProductSalesByStatus"
FROM salesdb.orders;


/* 
Calculate cumulative sales from current row to end (Unbounded Following):

- Frame specification: Current Row to Unbounded Following
*/
SELECT
    orderid,
    orderdate,
    productid,
    orderstatus,
    sales,
    SUM(sales) OVER (
        PARTITION BY orderstatus
        ORDER BY orderdate
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS "ProductSalesByStatus"
FROM salesdb.orders;


/* 
Count total orders overall and per customer using window functions.
*/
SELECT
    orderid,
    orderdate,
    customerid,
    COUNT(*) OVER () AS "Total Orders",                -- Total orders in the dataset
    COUNT(*) OVER (PARTITION BY customerid) AS "Orders by Customer"   -- Orders per customer
FROM salesdb.orders;


/* 
Total customers and count of customer scores (non-null score rows).
*/
SELECT
    *,
    COUNT(*) OVER () AS "Total Customers",
    COUNT(score) OVER () AS "Total Customers with Scores"
FROM salesdb.customers;


/* 
Identify duplicate orders in orders_archive by counting occurrences of orderid.
Return only duplicated records for action.
*/
SELECT *
FROM (
    SELECT
        orderid,
        COUNT(*) OVER(PARTITION BY orderid) AS CHKPK
    FROM salesdb.orders_archive
) AS CHK
WHERE CHKPK > 1;


/* 
Calculate sales summary per order with window functions:

- Total sales overall
- Sum of sales per product
- Provide order details for context.
*/
SELECT
    orderid,
    orderdate,
    sales,
    productid,
    SUM(sales) OVER () AS TotalSales,
    SUM(sales) OVER (PARTITION BY productid) AS SumByProduct
FROM salesdb.orders;


/* 
Calculate and rank products by percentage contribution to total sales.

- perbyeachprod: sales as % of overall total sales per row.
- perbyprodtype: Percentage of total sales per product, rounded.
- Sorted descending by perbyeachprod to show largest contributors first.
*/
SELECT
    orderid,
    sales,
    productid,
    SUM(sales) OVER () AS TotalSales,
    SUM(sales) OVER (PARTITION BY productid) AS SumByProduct,
    sales / SUM(sales) OVER () * 100 AS perbyeachprod,
    ROUND(SUM(sales) OVER (PARTITION BY productid)) / SUM(sales) OVER () * 100 AS perbyprodtype
FROM salesdb.orders
ORDER BY perbyeachprod DESC;


/* 
Calculate average sales overall and per product using window functions.
*/
SELECT
    orderid,
    sales,
    productid,
    AVG(sales) OVER () AS AvgSales,
    AVG(sales) OVER (PARTITION BY productid) AS AvgByProd
FROM salesdb.orders;


/* 
Calculate average customer scores handling NULLs using COALESCE.
Include raw and adjusted averages for comparison.
*/
SELECT
    customerid,
    firstname,
    lastname,
    score,
    COALESCE(score, 0) AS newscore,
    AVG(score) OVER () AS avgscore,
    AVG(COALESCE(score, 0)) OVER () AS nonullavgscore
FROM salesdb.customers;


/* 
Filter orders where sales exceed average sales across all orders.
Demonstrate using a nested query with window function AVG().
*/
SELECT *
FROM (
    SELECT
        orderid,
        sales,
        AVG(sales) OVER () AS avgsales
    FROM salesdb.orders
    ORDER BY sales DESC
) t
WHERE sales > avgsales;


/* 
Find min and max sales overall and per product.
*/
SELECT
    orderid,
    orderdate,
    productid,
    sales,
    MIN(sales) OVER () AS minimum,
    MAX(sales) OVER () AS maximum,
    MIN(sales) OVER (PARTITION BY productid) AS minprod,
    MAX(sales) OVER (PARTITION BY productid) AS maxprod
FROM salesdb.orders;


/* 
Calculate deviation of each sales value from overall min and max.
Negative value indicates below min or max.
*/
SELECT
    orderid,
    orderdate,
    productid,
    sales,
    MIN(sales) OVER () AS minimum,
    MAX(sales) OVER () AS maximum,
    sales - MAX(sales) OVER () AS dev_MAX,
    sales - MIN(sales) OVER () AS dev_MIN
FROM salesdb.orders;


/* 
Identify employees with the highest salaries:

- Use window function MAX() over entire table to find highest salary.
- Return only employees matching that highest salary.
*/
SELECT *
FROM (
    SELECT
        employeeid,
        firstname,
        salary,
        MAX(salary) OVER () AS highsalary
    FROM salesdb.employees
) t
WHERE salary = highsalary;


/* 
Demonstrate moving averages of sales:

- AVG() per product overall.
- AVG() over orderdate (no partition).
- AVG() per product ordered over time.
*/
SELECT
    orderid,
    productid,
    orderdate,
    sales,
    AVG(sales) OVER (PARTITION BY productid) AS avgbyprod,
    AVG(sales) OVER (ORDER BY orderdate) AS avgbymonth,
    AVG(sales) OVER (PARTITION BY productid ORDER BY orderdate) AS PROavgbyMM
FROM salesdb.orders;


/* 
Moving averages including frame specifications:

- 1 order following (next order).
- 1 order preceding (previous order).
*/
SELECT
    orderid,
    productid,
    sales,
    AVG(sales) OVER (
        PARTITION BY productid 
        ORDER BY orderdate 
        ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING
    ) AS one_roll_avg,
    AVG(sales) OVER (
        PARTITION BY productid 
        ORDER BY orderdate 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS one_prev_avg
FROM salesdb.orders;


/* 
Moving average using only previous order frame.
*/
SELECT
    orderid,
    productid,
    sales,
    AVG(sales) OVER (
        PARTITION BY productid 
        ORDER BY orderdate 
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS one_roll_avg
FROM salesdb.orders;


/* 
Ranking orders on sales (highest first) using ROW_NUMBER().
Each row gets a unique rank in ordered sequence.
*/
SELECT
    orderid,
    productid,
    sales,
    ROW_NUMBER() OVER (ORDER BY sales DESC) AS sales_rank
FROM salesdb.orders;


/* 
Ranking orders using RANK(), which can assign the same rank to ties,
and ROW_NUMBER() for unique ranking.
*/
SELECT
    orderid,
    productid,
    sales,
    ROW_NUMBER() OVER (ORDER BY sales DESC) AS rank_row,
    RANK() OVER (ORDER BY sales DESC) AS rank_rank1
FROM salesdb.orders;


/* 
Ranking with DENSE_RANK():

- Like RANK() but does not skip ranks on ties.
*/
SELECT
    orderid,
    productid,
    sales,
    ROW_NUMBER() OVER (ORDER BY sales DESC) AS rank_row,
    RANK() OVER (ORDER BY sales DESC) AS rank_rank1,
    DENSE_RANK() OVER (ORDER BY sales DESC) AS dense_rank
FROM salesdb.orders;


/* 
Find highest and lowest sales rank within each product using ROW_NUMBER().
*/
SELECT
    orderid,
    productid,
    sales,
    ROW_NUMBER() OVER (PARTITION BY productid ORDER BY sales DESC) AS rank_desc,
    ROW_NUMBER() OVER (PARTITION BY productid ORDER BY sales ASC) AS rank_asc
FROM salesdb.orders;


/* 
Filter top sales ranks with descriptive labels using CASE statement.
*/
SELECT
    *,
    CASE
        WHEN rank_desc = 1 THEN 'FIRST'
        WHEN rank_desc = 2 THEN 'SECOND'
        WHEN rank_desc = 3 THEN 'THIRD'
        WHEN rank_desc = 4 THEN 'FOURTH'
        ELSE 'LOWEST'
    END AS rank_p
FROM
(
    SELECT
        orderid,
        productid,
        sales,
        ROW_NUMBER() OVER (PARTITION BY productid ORDER BY sales DESC) AS rank_desc
    FROM salesdb.orders
) t;  -- Alias for inline view (‘t’)


/*
===============================================================================
Overall Purpose:
    This script provides an extensive learning and demonstration resource for MySQL,
    covering:

    - Filtering and ranking rows with window functions (ROW_NUMBER).
    - Aggregating and ranking sales data per customer.
    - Assigning unique row identifiers to avoid duplicates.
    - Identifying and managing duplicate rows using window functions.
    - Using NTILE to evenly split data into buckets and categorize records.
    - Calculating cumulative distribution and percent rank.
    - Performing month-over-month sales performance analysis with LAG and window functions.
    - Ranking customers by loyalty metrics like average days between orders.
    - Exploring metadata using INFORMATION_SCHEMA.
    - Using subqueries and scalar aggregates.
    - Demonstrating joins and CTEs (Common Table Expressions) including recursive CTEs.
    - Creating and using Views and CTAS (Create Table As Select) for reporting.
===============================================================================
*/


-- Filter to get the top 3 highest sales per product using ROW_NUMBER and subquery filtering

SELECT
    *
FROM
(
    SELECT
        orderid,
        productid,
        sales,
        ROW_NUMBER() OVER (PARTITION BY productid ORDER BY sales DESC) AS RANK_DESC
    FROM salesdb.orders
) t /* 't' is an alias for the derived table */
WHERE RANK_DESC <= 3
;


-- Show all orders for reference before aggregation

SELECT * FROM salesdb.orders;


-- Aggregate total sales per customer and rank customers based on their total sales

SELECT
    orderid,
    customerid,
    sales,
    SUM(sales) AS Total_sales,
    ROW_NUMBER() OVER (ORDER BY SUM(sales)) AS sales_RANK
FROM salesdb.orders
GROUP BY customerid
;


-- Assign unique IDs to rows in Orders Archive table to distinguish duplicates
-- Window function ROW_NUMBER used with ordering on orderid and orderdate
-- Alias OA used for clarity and to avoid errors involving use of *

SELECT
    ROW_NUMBER() OVER (ORDER BY orderid, orderdate) AS UNIQID,
    OA.*
FROM salesdb.orders_archive AS OA
;


-- View all orders_archive rows before deduplication

SELECT * FROM salesdb.orders_archive;


-- Retrieve unique rows from orders_archive by filtering only the first occurrence (UNIQID = 1)

SELECT *
FROM
(
    SELECT
        ROW_NUMBER() OVER (PARTITION BY orderid ORDER BY creationtime) AS UNIQID,
        OA.*
    FROM salesdb.orders_archive AS OA
) t
WHERE UNIQID = 1
;


-- Marking duplicates with descriptive tags according to their occurrence number (UNIQID)

SELECT
    *,
    CASE
        WHEN UNIQID = 1 THEN 'UNIQUE'
        WHEN UNIQID = 2 THEN 'DUPLICATE1'
        WHEN UNIQID = 3 THEN 'DUPLICATE2'
        WHEN UNIQID = 4 THEN 'DUPLICATE3'
        ELSE 'N/A'
    END AS UNIQTRCK
FROM
(
    SELECT
        ROW_NUMBER() OVER (PARTITION BY orderid ORDER BY creationtime) AS UNIQID,
        OA.*
    FROM salesdb.orders_archive AS OA
) t


/* 
NTILE function examples: evenly distribute rows into buckets by sales ascending.
Buckets can be 1 to 5 groups.
Larger groups get the extra rows if division not exact.
*/

SELECT * FROM salesdb.orders;

SELECT
    orderid,
    sales,
    NTILE(1) OVER (ORDER BY sales ASC) AS 1bucket,
    NTILE(2) OVER (ORDER BY sales ASC) AS 2bucket,
    NTILE(3) OVER (ORDER BY sales ASC) AS 3bucket,
    NTILE(4) OVER (ORDER BY sales ASC) AS 4bucket,
    NTILE(5) OVER (ORDER BY sales ASC) AS 5bucket
FROM salesdb.orders
;


/* 
Classify orders into High, Medium, and Low sales categories based on NTILE buckets (3 buckets).
*/

SELECT
    *,
    CASE
        WHEN 3_catg_bucket = 3 THEN 'HIGH'
        WHEN 3_catg_bucket = 2 THEN 'MEDIUM'
        WHEN 3_catg_bucket = 1 THEN 'LOW'
    END AS sales_RANK
FROM
(
    SELECT
        orderid,
        sales,
        NTILE(3) OVER (ORDER BY sales ASC) AS 3_catg_bucket
    FROM salesdb.orders
) t
;


/* 
Cumulative distribution functions:
- CUME_DIST returns relative rank of a value within ordered set.
- PERCENT_RANK returns percentile ranking between 0 and 1.
- Rounded percent rank for easier interpretation.
*/

SELECT * FROM salesdb.orders;

SELECT
    orderid,
    sales,
    CUME_DIST() OVER (ORDER BY sales) AS C_DISTRIBUTION,
    PERCENT_RANK() OVER (ORDER BY sales) AS PERCENT_DISTRIBUTION,
    ROUND(PERCENT_RANK() OVER (ORDER BY sales), 2) AS PERCENT_DISTRIBUTION_ROUNDED
FROM salesdb.orders
;


/* 
Month-over-month sales performance analysis using window functions LAG and aggregate.
Calculates sales differences and growth percentages from previous month.
*/

SELECT * FROM salesdb.orders;

SELECT
    orderid,
    orderdate,
    sales,
    MONTH(orderdate) AS MONTH,
    DATE_FORMAT(orderdate, '%M') AS MONTH_NAME
FROM salesdb.orders
;

SELECT
    *,
    MONTHLY_SALES - PREV_MON_SALES AS MoM_CHANGE,
    (MONTHLY_SALES - PREV_MON_SALES) / PREV_MON_SALES * 100 AS MoM_PERCENT_CHANGE
FROM
(
    SELECT
        MONTH(orderdate) AS ORDERMONTH,
        SUM(sales) AS MONTHLY_SALES,
        LAG(SUM(sales)) OVER (ORDER BY MONTH(orderdate)) AS PREV_MON_SALES
    FROM salesdb.orders
    GROUP BY MONTH(orderdate)
) t
;


/* 
Improved MoM calculation with rounding and float conversion for precision and readability
*/

SELECT
    *,
    MONTHLY_SALES - PREV_MON_SALES AS MoM_CHANGE,
    ROUND(CAST((MONTHLY_SALES - PREV_MON_SALES) AS FLOAT) / PREV_MON_SALES * 100, 2) AS MoM_PERCENT_CHANGE
FROM
(
    SELECT
        MONTH(orderdate) AS ORDERMONTH,
        SUM(sales) AS MONTHLY_SALES,
        LAG(SUM(sales)) OVER (ORDER BY MONTH(orderdate)) AS PREV_MON_SALES
    FROM salesdb.orders
    GROUP BY MONTH(orderdate)
) t
;


/* 
Rank customers by average days between their orders to analyze loyalty.
Uses LEAD function to get next order date per customer.
RANK assigns ranking by increasing average order frequency. 
COALESCE guards against NULL averages substituting a large number.
*/

SELECT * FROM salesdb.orders;

SELECT
    customerid,
    AVG(ORDER_FREQ) AS AVG_DAYS,
    RANK() OVER (ORDER BY COALESCE(AVG(ORDER_FREQ), 999)) AS CUST_RANK
FROM
(
    SELECT
        orderid,
        customerid,
        orderdate,
        LEAD(orderdate) OVER (PARTITION BY customerid ORDER BY orderdate) AS NEXT_ORDER,
        TIMESTAMPDIFF(DAY, orderdate, LEAD(orderdate) OVER (PARTITION BY customerid ORDER BY orderdate)) AS ORDER_FREQ
    FROM salesdb.orders
) t
GROUP BY customerid
;


/* 
Retrieve distinct column names across database tables using INFORMATION_SCHEMA,
to understand metadata — useful for discovery and learning about database structure.
*/

SELECT DISTINCT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS;


/* 
Find products priced above the average price of all products using a subquery with window function.
*/

SELECT * FROM salesdb.products;

SELECT
    *
FROM
(
    SELECT
        productid,
        price,
        AVG(price) OVER () AS AVG_PRICE
    FROM salesdb.products
) t
WHERE price > AVG_PRICE
;


/* 
Rank customers by their total sales using a CTE-style subquery and RANK window function.
*/

SELECT
    *,
    RANK() OVER (ORDER BY Total_sales DESC) AS CUST_RANK
FROM
(
    SELECT
        customerid,
        SUM(sales) AS Total_sales
    FROM salesdb.orders
    GROUP BY customerid
) t;


/* 
Scalar subquery example: show product details plus total orders count.
*/

SELECT
    productid,
    product,
    price,
    (
        SELECT COUNT(*)
        FROM salesdb.orders
    ) AS Total_orders
FROM salesdb.products;


/* 
Join example: combining customer info with total order counts per customer using LEFT JOIN.
*/

SELECT
    *
FROM salesdb.customers AS c
LEFT JOIN
(
    SELECT
        customerid,
        COUNT(*) AS Total_orders
    FROM salesdb.orders
    GROUP BY customerid
) AS o ON c.customerid = o.customerid;


/* 
Using a scalar subquery with WHERE clause to filter products priced higher than average.
*/

SELECT * FROM salesdb.products;

SELECT
    productid,
    product,
    price
FROM salesdb.products
WHERE price >
(
    SELECT AVG(price)
    FROM salesdb.products
);


/* 
Using IN operator with subquery to filter orders by customers located in Germany.
*/

SELECT *
FROM salesdb.orders
WHERE customerid IN
(
    SELECT customerid FROM salesdb.customers WHERE country = 'Germany'
);


/* 
Two methods to find orders by customers not in Germany:
1) Using IN with country != 'Germany'
2) Using NOT IN with customers in Germany
*/

SELECT *
FROM salesdb.orders
WHERE customerid IN
(
    SELECT customerid FROM salesdb.customers WHERE country != 'Germany'
);

SELECT *
FROM salesdb.orders
WHERE customerid NOT IN
(
    SELECT customerid FROM salesdb.customers WHERE country = 'Germany'
);


/* 
Use of ANY operator to find female employees whose salary is greater than
any male employee salary.
*/

SELECT * FROM salesdb.employees;

SELECT
    employeeid,
    firstname,
    gender,
    salary
FROM salesdb.employees
WHERE gender = 'F' AND salary > ANY
(
    SELECT salary FROM salesdb.employees WHERE gender = 'M'
);


/* 
Scalar subquery example: count total orders per customer.
*/

SELECT *
FROM salesdb.orders;

SELECT
    *,
    (
        SELECT COUNT(*)
        FROM salesdb.orders o
        WHERE o.customerid = c.customerid
    ) AS Orders
FROM salesdb.customers c;

SELECT COUNT(*) AS Orders FROM salesdb.orders;


/* 
EXISTS operator example to find orders placed by customers in Germany.
*/

SELECT * FROM salesdb.orders;
SELECT * FROM salesdb.customers;

SELECT *
FROM salesdb.orders o
WHERE EXISTS
(
    SELECT 1 FROM salesdb.customers c WHERE country = 'Germany' AND o.customerid = c.customerid
);


/* 
Equivalent JOIN to get orders for customers in Germany.
*/

SELECT DISTINCT c.country, o.*
FROM salesdb.orders o
JOIN salesdb.customers c ON o.customerid = c.customerid
WHERE country = 'Germany';


/* 
Common Table Expressions (CTE) examples:

- Use WITH to define reusable query parts.
- Show non-recursive and recursive CTEs.
- Demonstrate ranking customers and segmenting them.
- Generate numeric sequences recursively.
- Display employee hierarchy levels.

CTEs help simplify complex queries and improve readability and maintainability.
*/


-- Total sales per customer CTE

WITH CTE_sales AS
(
    SELECT customerid, SUM(sales) AS customersales
    FROM salesdb.orders
    GROUP BY customerid
),
-- Last order date per customer CTE
CTE_lastorder AS
(
    SELECT customerid, MAX(orderdate) AS last_date
    FROM salesdb.orders
    GROUP BY customerid
)
SELECT
    ct.customersales,
    cl.last_date,
    c.*
FROM salesdb.customers c
LEFT JOIN CTE_sales ct ON c.customerid = ct.customerid
LEFT JOIN CTE_lastorder cl ON c.customerid = cl.customerid
;


/* 
Recursive CTE generating a sequence from 1 to 1100 (with limitation).
*/

SET cte_max_recursion_depth = 2000;

WITH RECURSIVE nseries AS
(
    SELECT 1 AS sequencenumber
    UNION ALL
    SELECT sequencenumber + 1
    FROM nseries
    WHERE sequencenumber < 1100
)
SELECT * FROM nseries;

SHOW VARIABLES LIKE 'cte_max_recursion_depth';
SET cte_max_recursion_depth = 2000;


/* 
Recursive CTE example to show employee hierarchy with level info.
*/

WITH RECURSIVE CTE_EMP_LEVEL AS
(
    -- Anchor member: Employees with no manager (top-level)
    SELECT employeeid, firstname, lastname, managerid, 1 AS LEVEL
    FROM salesdb.employees
    WHERE managerid IS NULL
    UNION ALL
    -- Recursive member: Employees whose manager is in previous level
    SELECT emp.employeeid, emp.firstname, emp.lastname, emp.managerid, LEVEL + 1
    FROM salesdb.employees emp
    INNER JOIN CTE_EMP_LEVEL lvl ON emp.managerid = lvl.employeeid
)
SELECT * FROM CTE_EMP_LEVEL;


/* 
Views:

- Virtual tables stored as queries to simplify complex querying.
- Can be created, replaced, selected from, and dropped.
- Useful for abstraction and reuse of frequently used query logic.
*/

-- Create or replace monthly sales view

CREATE OR REPLACE VIEW salesdb.V_MONTHLY_SALES AS
SELECT
    DATE_FORMAT(orderdate, '%Y-%m') AS ORDERMONTH,
    SUM(sales) AS totalsales,
    COUNT(orderid) AS totalorders,
    SUM(quantity) AS totalquantity
FROM salesdb.orders
GROUP BY DATE_FORMAT(orderdate, '%Y-%m');

-- Query the view

SELECT * FROM salesdb.V_MONTHLY_SALES;

/* Running total of sales per month from the view */

SELECT
    *,
    SUM(totalsales) OVER (ORDER BY ORDERMONTH) AS RUNNING_SALES,
    SUM(totalsales) OVER (ORDER BY ORDERMONTH ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS RUNNING_SALES_1
FROM salesdb.V_MONTHLY_SALES;


/* Drop a view if it exists (MySQL syntax) */

DROP VIEW IF EXISTS salesdb.V_MONTHLY_SALES;


/* Simple example of using view to combine orders, products, customers, and employees */

CREATE OR REPLACE VIEW salesdb.SALES_VIEW AS
SELECT
    o.orderid,
    p.product,
    p.category,
    DATE_FORMAT(o.orderdate, '%Y_%m_%d') AS ORDERDATE,
    CONCAT(COALESCE(c.firstname, ''), ' ', COALESCE(c.lastname, '')) AS CUSTOMER_NAME,
    c.country,
    CONCAT(COALESCE(e.firstname, ''), ' ', COALESCE(e.lastname, '')) AS EMP_NAME,
    e.department,
    o.sales
FROM salesdb.orders o
LEFT JOIN salesdb.products p ON p.productid = o.productid
LEFT JOIN salesdb.customers c ON c.customerid = o.customerid
LEFT JOIN salesdb.employees e ON e.employeeid = o.salespersonid;


-- Query the combined sales view

SELECT * FROM salesdb.SALES_VIEW;


/* 
Example of a restricted view for EU sales team,
excluding USA-related data by filtering on customer country.
*/

CREATE OR REPLACE VIEW salesdb.SALES_VIEW_EU AS
SELECT
    o.orderid,
    p.product,
    p.category,
    DATE_FORMAT(o.orderdate, '%Y_%m_%d') AS ORDERDATE,
    CONCAT(COALESCE(c.firstname, ''), ' ', COALESCE(c.lastname, '')) AS CUSTOMER_NAME,
    c.country,
    CONCAT(COALESCE(e.firstname, ''), ' ', COALESCE(e.lastname, '')) AS EMP_NAME,
    e.department,
    o.sales
FROM salesdb.orders o
LEFT JOIN salesdb.products p ON p.productid = o.productid
LEFT JOIN salesdb.customers c ON c.customerid = o.customerid
LEFT JOIN salesdb.employees e ON e.employeeid = o.salespersonid
WHERE c.country != 'USA';


-- Query the EU sales view

SELECT * FROM salesdb.SALES_VIEW_EU;


/* 
Create Table As Select (CTAS) example:
Useful for snapshot copies of data.
Usually better to use views if live data is needed.
*/

CREATE TABLE salesdb.CTAS_SALES_VIEW AS
SELECT
    o.orderid,
    p.product,
    p.category,
    DATE_FORMAT(o.orderdate, '%Y_%m_%d') AS ORDERDATE,
    CONCAT(COALESCE(c.firstname, ''), ' ', COALESCE(c.lastname, '')) AS CUSTOMER_NAME,
    c.country,
    CONCAT(COALESCE(e.firstname, ''), ' ', COALESCE(e.lastname, '')) AS EMP_NAME,
    e.department,
    o.sales
FROM salesdb.orders o
LEFT JOIN salesdb.products p ON p.productid = o.productid
LEFT JOIN salesdb.customers c ON c.customerid = o.customerid
LEFT JOIN salesdb.employees e ON e.employeeid = o.salespersonid;


-- Query the CTAS table

SELECT * FROM salesdb.CTAS_SALES_VIEW;


-- Drop the CTAS table if exists

DROP TABLE IF EXISTS salesdb.CTAS_SALES_VIEW;


/*
===============================================================================
Overall Purpose:
    This script demonstrates advanced SQL concepts and techniques including:
    - Create Table As Select (CTAS) and Temporary Table usage for snapshotting data.
    - Stored procedures (static and dynamic) for encapsulating logic.
    - Triggers for automatic logging upon data manipulation.
    - Index creation and understanding clustering in MySQL.
    - Database restoration and querying (SQL Server examples included).
    - Querying and reporting with JOINs and aggregations from star-schema like structures.
    - Use of SQL hints, partition functions, filegroups, and partition schemes (mostly SQL Server concepts).
    - Table partitioning creation, data insertion, and querying benefits (SQL Server).
    
    The script blends MySQL and SQL Server syntax/examples for educational purposes.

    Detailed comments explain concepts, syntax rationale, and expected behaviors.
===============================================================================
*/

USE salesdb;


/* 
Display all customers for exploration and verification.
*/
SELECT *
FROM salesdb.customers;


/* 
Static Stored Procedure Example:
- Procedure to get total customers and average score for customers in USA.
- Stored procedures group reusable logic on the server side.
*/
DELIMITER $$

CREATE PROCEDURE getcustsummary()
BEGIN
    SELECT
        COUNT(*) AS totalcustomers,
        AVG(score) AS avgscore
    FROM salesdb.customers
    WHERE country = 'USA';
END$$

DELIMITER ;

/* Verify procedure creation and details */
SHOW PROCEDURE STATUS WHERE Name = 'getcustsummary';
SHOW PROCEDURE STATUS WHERE Db = 'salesdb' AND Name = 'getcustsummary';

/* Call the stored procedure */
CALL salesdb.getcustsummary();


/* 
Dynamic Stored Procedure Example:
- Accepts country name as input parameter.
- Returns total customers and average score per specified country.
- Demonstrates parameter usage in procedures.
*/
DELIMITER $$

CREATE PROCEDURE getcustsummary(IN in_country VARCHAR(50))
BEGIN
    SELECT
        COUNT(*) AS totalcustomers,
        AVG(score) AS avgscore
    FROM salesdb.customers
    WHERE country = in_country;
END$$

DELIMITER ;

/* Verify and call the dynamic procedure */
SHOW PROCEDURE STATUS WHERE Name = 'getcustsummary';
CALL salesdb.getcustsummary('Germany');


/* 
Test for presence of NULL scores for customers in USA, useful for data quality check.
*/
SELECT 1
FROM salesdb.customers
WHERE score IS NULL AND country = 'USA';


/* 
Triggers 
- Special stored procedures that execute on certain table events (e.g., AFTER INSERT).
- Below are examples for SQL Server and MySQL for inserting log records after employee insert.
*/

/* SQL Server Trigger Example */
/*
CREATE TRIGGER tgr_insert_employee ON salesdb.employees
AFTER INSERT
AS
BEGIN
    INSERT INTO salesdb.employeelog (EMP_ID, LOG_MSG, LOGDATE)
    SELECT
        EMP_ID,
        'NEW EMPLOYEE ADDED' + CAST(EMP_ID AS VARCHAR(128)),
        GETDATE()
    FROM INSERTED;
END
*/


/* 
MySQL Trigger Example:
- Creates an employeelog table to store logs.
- Defines an AFTER INSERT trigger on employees to log insertions automatically.
*/
CREATE TABLE IF NOT EXISTS salesdb.employeelog
(
    EMP_ID INT,
    LOG_MSG VARCHAR(255),
    LOGDATE DATETIME
);

ALTER TABLE salesdb.employeelog
CHANGE EMP_ID employeeid INT;


DELIMITER $$
CREATE TRIGGER tgr_insert_emp
AFTER INSERT ON salesdb.employees
FOR EACH ROW
BEGIN
    INSERT INTO salesdb.employeelog (employeeid, LOG_MSG, LOGDATE)
    VALUES (
        NEW.employeeid,
        CONCAT('New EMP added ', NEW.employeeid),
        NOW()
    );
END$$
DELIMITER ;


/* 
Test trigger by inserting a new employee, then verify emp log and employees table.
*/
INSERT INTO salesdb.employees
VALUES (6, 'Maria', 'Smith', 'Finance', '1986-06-16', 'F', 85000, 3);

SELECT * FROM salesdb.employeelog;
SELECT * FROM salesdb.employees WHERE employeeid = 6;

/* 
Describe the employees table structure.
*/
DESCRIBE salesdb.employees;

/* List all triggers in the employees table */
USE salesdb;
SHOW TRIGGERS LIKE 'employees';


/* 
Indexes:
- Create a new table customersDB as snapshot of customers.
- Modify primary key on customerid.
- Demonstrate index creation and explain clustered index behavior in MySQL.
*/
CREATE TABLE salesdb.customersDB AS
SELECT * FROM salesdb.customers;

SELECT * FROM salesdb.customersDB;

ALTER TABLE salesdb.customersDB
CHANGE customerid customerid INT PRIMARY KEY;

/* Create a simple non-clustered index */
CREATE INDEX idx_customerDB_customerid ON salesdb.customersDB (customerid);

/* 
Attempt to create clustered index (not supported explicitly in MySQL).
Explanation:
- MySQL InnoDB uses PRIMARY KEY as clustered index automatically.
- Only one clustered index per table is allowed.
*/
CREATE CLUSTERED INDEX idx_CL_customerDB_customerid ON salesdb.customersDB (customerid);
/* This will cause syntax error because clustered index is implicit in InnoDB engine */


-- Inspect indexes on customersDB table
SHOW INDEX FROM salesdb.customersDB;

/* View indexes for all tables in salesdb schema */
SELECT *
FROM information_schema.statistics
WHERE TABLE_SCHEMA = 'salesdb';


/* 
SQL Server examples - database restore and querying (for context, not executable in MySQL)
*/

USE [master];
GO
RESTORE DATABASE [AdventureWorks2022]
FROM DISK = '/var/opt/mssql/backup/AdventureWorks2022.bak'
WITH MOVE 'AdventureWorks2022' TO '/var/opt/mssql/data/AdventureWorks2022_Data.mdf',
MOVE 'AdventureWorks2022_log' TO '/var/opt/mssql/data/AdventureWorks2022_Log.ldf',
FILE = 1, NOUNLOAD, STATS = 5;
GO

SELECT * FROM AdventureWorks2022;

-- Example querying AdventureWorksDW2022 star schema

USE AdventureWorksDW2022;
SELECT
    d.CalendarYear,
    p.EnglishProductName,
    SUM(f.SalesAmount) AS TotalSales
FROM FactInternetSales f
JOIN DimProduct p ON f.ProductKey = p.ProductKey
JOIN DimDate d ON f.OrderDateKey = d.DateKey
GROUP BY d.CalendarYear, p.EnglishProductName
ORDER BY d.CalendarYear, TotalSales DESC;


/* 
SQL hints to provide optimizer instructions (example for SQL Server).
*/
USE salesDB;
SELECT
    o.Sales,
    c.Country
FROM sales.Orders o
JOIN sales.Customers c WITH (INDEX([PK_customers]))
ON o.OrderID = c.CustomerID
OPTION (HASH JOIN);


/* 
Partitioning example in SQL Server:
Defines partition function, filegroups, partition scheme, and partitioned tables.
Includes data insertion and validation querying to demonstrate partition benefit.
Note: Partitioning features differ between SQL Server and MySQL.
*/

CREATE PARTITION FUNCTION partitionbyyear (DATE)
AS RANGE LEFT FOR VALUES ('2023-12-31', '2024-12-31', '2025-12-31');

-- Add filegroups for partitions
ALTER DATABASE salesDB ADD FILEGROUP FG_2023;
ALTER DATABASE salesDB ADD FILEGROUP FG_2024;
ALTER DATABASE salesDB ADD FILEGROUP FG_2025;
ALTER DATABASE salesDB ADD FILEGROUP FG_2026;

-- Add physical data files for the filegroups (paths must be adjusted per environment)
ALTER DATABASE SalesDB ADD FILE
(
    Name = P_2023,
    FILENAME = '/var/opt/mssql/data/SalesDB_P_2023.ndf'
)
TO FILEGROUP FG_2023;

-- Additional file adds for other years skipped for brevity

-- Create Partition Scheme
CREATE PARTITION SCHEME sch_partitionbyyear
AS PARTITION partitionbyyear
TO (FG_2023, FG_2024, FG_2025, FG_2026);

-- Create partitioned table on orderdate column
CREATE TABLE Sales.Orders_partitioned
(
    orderid INT,
    orderdate DATE,
    sales INT
) ON sch_partitionbyyear (orderdate);

-- Insert sample partitioned data
INSERT INTO Sales.Orders_partitioned VALUES (1, '2023-05-09', 9000);
INSERT INTO Sales.Orders_partitioned VALUES (2, '2024-08-09', 3000);
INSERT INTO Sales.Orders_partitioned VALUES (3, '2026-08-09', 3000);
INSERT INTO Sales.Orders_partitioned VALUES (4, '2023-08-09', 3000);

SELECT * FROM Sales.Orders_partitioned;

-- Check partitions and filegroups mapping
SELECT
    p.partition_number AS partitionnumber,
    fg.name AS partitionfilegroup,
    p.rows AS numberofrows
FROM sys.partitions p
JOIN sys.destination_data_spaces dds ON p.partition_number = dds.destination_id
JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
WHERE OBJECT_NAME(p.object_id) = 'Orders_partitioned';

/*
Demonstrate partitioned vs non-partitioned tables and effects on querying.
*/


-- Create duplicate non-partitioned table from partitioned table
SELECT * INTO Sales.Orders_N_partitioned FROM Sales.Orders_partitioned;

-- Insert rows avoiding duplicates using NOT EXISTS
INSERT INTO Sales.Orders_N_partitioned
SELECT * FROM Sales.Orders_partitioned op
WHERE NOT EXISTS (SELECT 1 FROM Sales.Orders_N_partitioned onp WHERE op.orderid = onp.orderid);

-- Sample queries to illustrate partitioned table usage

SELECT * FROM Sales.Orders_partitioned WHERE orderdate = '2023-02-02';  -- Should be efficient, returning matching row(s)
SELECT * FROM Sales.Orders_N_partitioned WHERE orderdate = '2023-02-02'; -- Full scan likely, all rows returned

SELECT * FROM Sales.Orders_partitioned WHERE orderdate IN ('2023-02-02', '2026-03-03');
SELECT * FROM Sales.Orders_N_partitioned WHERE orderdate IN ('2023-02-02', '2026-03-03');
