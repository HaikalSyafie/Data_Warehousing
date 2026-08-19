
-- GOLD LAYER
-- Create Customer, Product, and Sales Views


-- Customer Dimension
-- Purpose: Create a business-ready customer dimension
-- by combining CRM customer data with ERP customer and location data.

IF OBJECT_ID('gold.customers', 'V') IS NOT NULL
    DROP VIEW gold.customers;
GO

CREATE VIEW gold.customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.cst_id) AS customer_key, -- Generate surrogate key
    c.cst_id             AS customer_id,                   -- Original customer ID
    c.cst_key            AS customer_number,               -- Customer business key
    c.cst_firstname      AS first_name,                    -- Customer first name
    c.cst_lastname       AS last_name,                     -- Customer last name
    cl.cntry             AS country,                       -- Customer country
    c.cst_marital_status AS marital_status,                -- Customer marital status

    -- Use CRM gender as the primary source
    -- and ERP gender as a fallback when CRM is unavailable
    CASE
        WHEN c.cst_gndr != 'n/a' THEN c.cst_gndr
        ELSE COALESCE(ec.gen, 'n/a')
    END AS gender,

    ec.bdate          AS birthdate,                         -- Customer birthdate
    c.cst_create_date AS create_date                        -- Customer creation date

FROM silver.crm_cust_info AS c

-- Enrich customer data with ERP demographic information
LEFT JOIN silver.erp_cust_az12 AS ec
    ON c.cst_key = ec.cid

-- Enrich customer data with location information
LEFT JOIN silver.erp_loc_a101 AS cl
    ON c.cst_key = cl.cid;
GO


-- Product Dimension
-- Purpose: Create a business-ready product dimension
-- by combining CRM product data with ERP category information.

IF OBJECT_ID('gold.products', 'V') IS NOT NULL
    DROP VIEW gold.products;
GO

CREATE VIEW gold.products AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,                    -- Generate surrogate key

    pn.prd_id       AS product_id,       -- Original product ID
    pn.prd_key      AS product_number,   -- Product business key
    pn.prd_nm       AS product_name,     -- Product name
    pn.cat_id       AS category_id,      -- Category ID
    pc.cat          AS category,         -- Product category
    pc.subcat       AS subcategory,      -- Product subcategory
    pc.maintenance  AS maintenance,     -- Product maintenance type
    pn.prd_cost     AS cost,             -- Product cost
    pn.prd_line     AS product_line,     -- Product line
    pn.prd_start_dt AS start_date        -- Product start date

FROM silver.crm_prd_info AS pn

-- Enrich product data with category information
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
    ON pn.cat_id = pc.id

-- Keep only the current/latest product records
WHERE pn.prd_end_dt IS NULL;
GO


-- Sales Fact
-- Purpose: Create a business-ready sales fact table
-- by connecting sales transactions with customer and product dimensions.

IF OBJECT_ID('gold.sales', 'V') IS NOT NULL
    DROP VIEW gold.sales;
GO

CREATE VIEW gold.sales AS
SELECT
    sd.sls_ord_num  AS order_number,      -- Sales order number
    pr.product_key  AS product_key,       -- Product surrogate key
    cu.customer_key AS customer_key,      -- Customer surrogate key
    sd.sls_order_dt AS order_date,        -- Order date
    sd.sls_ship_dt  AS shipping_date,     -- Shipping date
    sd.sls_due_dt   AS due_date,          -- Due date
    sd.sls_sales    AS sales_amount,      -- Sales amount
    sd.sls_quantity AS quantity,          -- Quantity sold
    sd.sls_price    AS price              -- Product selling price

FROM silver.crm_sales_details AS sd

-- Connect sales transactions to the product dimension
LEFT JOIN gold.products AS pr
    ON sd.sls_prd_key = pr.product_number

-- Connect sales transactions to the customer dimension
LEFT JOIN gold.customers AS cu
    ON sd.sls_cust_id = cu.customer_id;
GO