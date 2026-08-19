-- ------------------------------------------------------------
-- RUNNING TOTAL & AVERAGE PRICE ANALYSIS
-- ------------------------------------------------------------

-- Running Total Revenue & Cumulative Average Price
-- Purpose:
-- Analyze cumulative revenue and the average product price
-- over time.

SELECT
    order_date,
    revenue,

    -- Calculate cumulative revenue over time
    SUM(revenue) OVER (
        ORDER BY order_date
    ) AS running_total_revenue,

    -- Calculate cumulative average price over time
    AVG(avg_price) OVER (
        ORDER BY order_date
    ) AS cumulative_average_price

FROM (
    SELECT
        DATETRUNC(YEAR, order_date) AS order_date,
        SUM(sales_amount) AS revenue,
        AVG(price) AS avg_price
    FROM gold.sales
    WHERE order_date IS NOT NULL
    GROUP BY
        DATETRUNC(YEAR, order_date)
) AS t;


-- ------------------------------------------------------------
-- PRODUCT SALES PERFORMANCE ANALYSIS
-- ------------------------------------------------------------

-- Purpose:
-- Compare yearly product sales against the product's
-- historical average and previous year's sales.

WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.sales AS f
    LEFT JOIN gold.products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY
        YEAR(f.order_date),
        p.product_name
)

SELECT
    order_year,
    product_name,
    current_sales,

    -- Average Sales Analysis
    -- Compare yearly sales with the product's historical average
    AVG(current_sales) OVER (
        PARTITION BY product_name
    ) AS avg_sales,

    current_sales
        - AVG(current_sales) OVER (
            PARTITION BY product_name
        ) AS diff_avg,

    -- Classify sales performance against historical average
    CASE
        WHEN current_sales
            - AVG(current_sales) OVER (
                PARTITION BY product_name
            ) > 0
            THEN 'Above Avg'

        WHEN current_sales
            - AVG(current_sales) OVER (
                PARTITION BY product_name
            ) < 0
            THEN 'Below Avg'

        ELSE 'Avg'
    END AS avg_change,


    -- --------------------------------------------------------
    -- Year-over-Year Analysis
    -- --------------------------------------------------------

    -- Get sales from the previous available year
    LAG(current_sales) OVER (
        PARTITION BY product_name
        ORDER BY order_year
    ) AS previous_year_sales,

    -- Calculate absolute sales change from previous year
    current_sales
        - LAG(current_sales) OVER (
            PARTITION BY product_name
            ORDER BY order_year
        ) AS diff_previous_year,

    -- Calculate YoY sales growth percentage
    ROUND(
        (
            current_sales
            - LAG(current_sales) OVER (
                PARTITION BY product_name
                ORDER BY order_year
            )
        ) * 100.0
        / NULLIF(
            LAG(current_sales) OVER (
                PARTITION BY product_name
                ORDER BY order_year
            ),
            0
        ),
        2
    ) AS yoy_growth_percentage,

    -- Classify year-over-year sales performance
    CASE
        WHEN current_sales
            - LAG(current_sales) OVER (
                PARTITION BY product_name
                ORDER BY order_year
            ) > 0
            THEN 'Increase'

        WHEN current_sales
            - LAG(current_sales) OVER (
                PARTITION BY product_name
                ORDER BY order_year
            ) < 0
            THEN 'Decrease'

        ELSE 'No Change'
    END AS yoy_change

FROM yearly_product_sales
ORDER BY
    product_name,
    order_year;