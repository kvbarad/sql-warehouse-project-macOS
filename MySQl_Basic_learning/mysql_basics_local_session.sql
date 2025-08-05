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


