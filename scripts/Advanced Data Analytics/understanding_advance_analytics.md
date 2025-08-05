Rules Implemented in the SQL Query
Time-Series Sales Analysis
Sales and customer counts are aggregated by year and month.
Null order dates are excluded to ensure data accuracy.
Distinct customers are counted per time period to avoid double counting.
Cumulative Measures
Running total/cumulative sales are calculated monthly and yearly.
Running averages for price are computed to reflect trends in pricing.
Performance Analysis
Product yearly sales are compared against the product average sales and previous year's sales using window functions such as AVG() and LAG().
This reveals growth or decline performance by product.
Part-to-Whole Proportional Analysis
Sales are aggregated by product category.
The percentage contribution of each category to total sales is calculated.

Product Segmentation
Products are segmented into cost buckets:
below 100
100-500
500-1000
1000-1500
above 1500
The number of products in each cost segment is counted.
Customer Segmentation Rules
Customers are classified into three segments:
VIP: Lifespan ≥ 12 months and total spending ≥ 5,000€
Regular: Lifespan ≥ 12 months and spending < 5,000€
New: Lifespan < 12 months regardless of spend
Lifespan is calculated as the number of months between first and last orders.
Recency is defined as months passed since the last order.
