/*
Superstore Sales Analysis SQL Insights
-------------------------------------
This script contains SQL queries to extract business insights from the Superstore sales dataset.
Each query is preceded by a description of the business question it answers.
Assumes a table named `superstore` with columns as described in the data dictionary.
*/

-- Q1) What percentage of total orders were shipped on the same date?
-- Returns: Percentage of orders shipped on the same day as ordered.
SELECT
    ROUND((COUNT(DISTINCT Order_ID) / (SELECT COUNT(DISTINCT Order_ID) AS total_orders FROM superstore)) * 100, 2) AS Same_Day_Shipping_Percentage
FROM
    superstore
WHERE
    Order_Date = Ship_Date;

-- Q2) Name top 3 customers with highest total value of orders?
-- Returns: Customer_Name, TotalOrderValue for top 3 customers.
SELECT
    Customer_Name,
    ROUND(SUM(sales), 3) AS TotalOrderValue
FROM
    superstore
GROUP BY
    Customer_Name
ORDER BY
    SUM(sales) DESC
LIMIT 3;

-- Q3) Find the top 5 items with the highest average sales per day?
-- Returns: Product_ID, Average_Sales for top 5 products.
SELECT
    Product_ID,
    ROUND(AVG(sales), 3) AS Average_Sales
FROM
    superstore
GROUP BY
    Product_ID
ORDER BY
    Average_Sales DESC
LIMIT 5;

-- Q4) Find the average order value for each customer, and rank the customers by their average order value.
-- Returns: Customer_Name, avg_order_value, sales_rank.
SELECT
    Customer_Name,
    ROUND(AVG(sales), 3) AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY AVG(sales) DESC) AS sales_rank
FROM
    superstore
GROUP BY
    Customer_Name;

-- Q5) Give the name of customers who ordered highest and lowest orders from each city.
-- Returns: City, highest_order, highest_order_customer, lowest_order, lowest_order_customer.
WITH cte AS (
    SELECT
        City,
        ROUND(MAX(sales), 4) AS highest_order,
        ROUND(MIN(sales), 4) AS lowest_order
    FROM
        superstore
    GROUP BY
        City
),
highest_orders AS (
    SELECT
        s.City,
        cte.highest_order,
        cte.lowest_order,
        s.Customer_Name
    FROM
        superstore s
    INNER JOIN
        cte ON s.City = cte.City
    WHERE
        s.Sales = cte.highest_order
),
lowest_orders AS (
    SELECT
        s.City,
        cte.highest_order,
        cte.lowest_order,
        s.Customer_Name
    FROM
        superstore s
    INNER JOIN
        cte ON s.City = cte.City
    WHERE
        s.Sales = cte.lowest_order
)
SELECT
    h.City,
    h.highest_order,
    h.Customer_Name AS highest_order_customer,
    l.lowest_order,
    l.Customer_Name AS lowest_order_customer
FROM
    highest_orders h
INNER JOIN
    lowest_orders l ON h.City = l.City
ORDER BY
    h.City;

-- Q6) What is the most demanded sub-category in the west region?
-- Returns: Sub_Category, total_quantity for the West region.
SELECT
    Sub_Category,
    ROUND(SUM(sales), 3) AS total_quantity
FROM
    superstore
WHERE
    Region = 'West'
GROUP BY
    Sub_Category
ORDER BY
    total_quantity DESC
LIMIT 1;

-- Q7) Which order has the highest number of items?
-- Returns: order_id, num_item for the order with the most items.
SELECT
    order_id,
    COUNT(order_id) AS num_item
FROM
    superstore
GROUP BY
    order_id
ORDER BY
    num_item DESC
LIMIT 1;

-- Q8) Which order has the highest cumulative value?
-- Returns: order_id, order_value for the highest value order.
SELECT
    order_id,
    ROUND(SUM(sales), 3) AS order_value
FROM
    superstore
GROUP BY
    order_id
ORDER BY
    order_value DESC
LIMIT 1;

-- Q9) Which segment’s order is more likely to be shipped via first class?
-- Returns: segment, num_of_ordr for First Class shipping.
SELECT
    segment,
    COUNT(order_id) AS num_of_ordr
FROM
    superstore
WHERE
    ship_mode = 'First Class'
GROUP BY
    segment
ORDER BY
    num_of_ordr DESC;

-- Q10) Which city is least contributing to total revenue?
-- Returns: city, TotalSales for the lowest revenue city.
SELECT
    city,
    ROUND(SUM(sales), 3) AS TotalSales
FROM
    superstore
GROUP BY
    city
ORDER BY
    TotalSales ASC
LIMIT 1;

-- Q11) What is the average time for orders to get shipped after order is placed?
-- Returns: avg_ship_time (in days).
SELECT
    AVG(DATEDIFF(ship_date, order_date)) AS avg_ship_time
FROM
    superstore;

-- Q12) Which segment places the highest number of orders from each state and which segment places the largest individual orders from each state?
-- Returns: state, segment for highest number of orders per state.
WITH cte AS (
    SELECT
        state,
        segment,
        COUNT(order_id) AS num_orders,
        RANK() OVER (PARTITION BY state ORDER BY COUNT(order_id) DESC) AS state_rank
    FROM
        superstore
    GROUP BY
        state,
        segment
)
SELECT
    state,
    segment
FROM
    cte
WHERE
    state_rank = 1;

-- Q13) Find all the customers who individually ordered on 3 consecutive days where each day’s total order was more than 50 in value.
-- Returns: Customer_ID, Customer_Name for qualifying customers.
WITH cte AS (
    SELECT
        Customer_ID,
        Customer_Name,
        Order_ID,
        Order_Date,
        ROUND(SUM(sales), 3) AS order_value,
        DATEDIFF(Order_Date, LAG(Order_Date) OVER (PARTITION BY Customer_ID ORDER BY Order_Date ASC)) AS date_diff
    FROM
        superstore
    GROUP BY
        Customer_ID,
        Customer_Name,
        Order_ID,
        Order_Date
    HAVING
        SUM(sales) > 50
)
SELECT
    Customer_ID,
    Customer_Name
FROM
    cte
WHERE
    date_diff = 1;

-- Q14) Find the maximum number of days for which total sales on each day kept rising.
-- Returns: max_rising_days (integer).
WITH sales_sequence AS (
    SELECT
        Order_Date,
        SUM(Sales) AS TotalSales,
        ROW_NUMBER() OVER (ORDER BY Order_Date) AS rn
    FROM
        superstore
    GROUP BY
        Order_Date
),
rising_days AS (
    SELECT
        s1.Order_Date,
        COUNT(*) AS rising_day_count
    FROM
        sales_sequence s1
    INNER JOIN
        sales_sequence s2 ON s1.TotalSales < s2.TotalSales AND s1.rn < s2.rn
    GROUP BY
        s1.Order_Date
)
SELECT
    MAX(rising_day_count) AS max_rising_days
FROM
    rising_days;
