-- ------------------------------------------------------------
-- OVER TIME ANALYSIS
-- ------------------------------------------------------------


-- Sales Trend per Year
-- Purpose: Analyze annual revenue trends over time.

SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount) AS revenue
FROM gold.sales
GROUP BY
    YEAR(order_date)
ORDER BY
    order_year;


-- Sales Trend per Month
-- Purpose: Analyze monthly revenue patterns over time.

SELECT
    YEAR(order_date) AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS revenue
FROM gold.sales
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY
    order_year,
    order_month;


-- Total Orders per Year
-- Purpose: Analyze transaction volume over time.

SELECT
    YEAR(order_date) AS order_year,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.sales
GROUP BY
    YEAR(order_date)
ORDER BY
    order_year;


-- Total Quantity Sold per Year
-- Purpose: Analyze the number of units sold over time.

SELECT
    YEAR(order_date) AS order_year,
    SUM(quantity) AS total_quantity
FROM gold.sales
GROUP BY
    YEAR(order_date)
ORDER BY
    order_year;


-- Active Customers per Year
-- Purpose: Measure the number of customers making purchases each year.

SELECT
    YEAR(order_date) AS order_year,
    COUNT(DISTINCT customer_key) AS active_customers
FROM gold.sales
GROUP BY
    YEAR(order_date)
ORDER BY
    order_year;


-- Average Order Value per Year
-- Purpose: Analyze the average transaction value over time.

SELECT
    YEAR(order_date) AS order_year,
    SUM(sales_amount)
        / COUNT(DISTINCT order_number) AS average_order_value
FROM gold.sales
GROUP BY
    YEAR(order_date)
ORDER BY
    order_year;


-- Revenue by Category per Year
-- Purpose: Analyze category revenue performance over time.

SELECT
    YEAR(s.order_date) AS order_year,
    p.category,
    SUM(s.sales_amount) AS revenue
FROM gold.sales AS s
LEFT JOIN gold.products AS p
    ON s.product_key = p.product_key
GROUP BY
    YEAR(s.order_date),
    p.category
ORDER BY
    order_year,
    revenue DESC;


-- Top Products per Year
-- Purpose: Identify the top-performing products by revenue each year.

WITH yearly_product_sales AS (
    SELECT
        YEAR(s.order_date) AS order_year,
        p.product_name,
        SUM(s.sales_amount) AS revenue
    FROM gold.sales AS s
    LEFT JOIN gold.products AS p
        ON s.product_key = p.product_key
    GROUP BY
        YEAR(s.order_date),
        p.product_name
),
ranked_products AS (
    SELECT
        order_year,
        product_name,
        revenue,
        ROW_NUMBER() OVER (
            PARTITION BY order_year
            ORDER BY revenue DESC
        ) AS product_rank
    FROM yearly_product_sales
)

SELECT
    order_year,
    product_name,
    revenue,
    product_rank
FROM ranked_products
WHERE product_rank <= 10
ORDER BY
    order_year,
    product_rank;


-- Revenue by Country per Year
-- Purpose: Analyze country revenue contribution over time.

SELECT
    YEAR(s.order_date) AS order_year,
    c.country,
    SUM(s.sales_amount) AS revenue
FROM gold.sales AS s
LEFT JOIN gold.customers AS c
    ON s.customer_key = c.customer_key
GROUP BY
    YEAR(s.order_date),
    c.country
ORDER BY
    order_year,
    revenue DESC;


-- Revenue Growth per Year
-- Purpose: Measure annual revenue growth compared
-- with the previous year.

WITH yearly_sales AS (
    SELECT
        YEAR(order_date) AS order_year,
        SUM(sales_amount) AS revenue
    FROM gold.sales
    GROUP BY
        YEAR(order_date)
)

SELECT
    order_year,
    revenue,

    -- Revenue from the previous year
    LAG(revenue) OVER (
        ORDER BY order_year
    ) AS previous_revenue,

    -- Absolute revenue change
    revenue
        - LAG(revenue) OVER (
            ORDER BY order_year
        ) AS revenue_change,

    -- Revenue growth percentage
    ROUND(
        (
            revenue
            - LAG(revenue) OVER (
                ORDER BY order_year
            )
        ) * 100.0
        / NULLIF(
            LAG(revenue) OVER (
                ORDER BY order_year
            ),
            0
        ),
        2
    ) AS revenue_growth_percentage

FROM yearly_sales
ORDER BY
    order_year;