-- STORED PROCEDURE: Load Silver Layer
-- Purpose:
-- Clean, transform, and load data from Bronze Layer
-- into the Silver Layer.

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    BEGIN TRY
        -- CRM Customer
        -- Purpose:
        -- Clean customer names, normalize marital status
        -- and gender, and keep the latest record per customer.

        TRUNCATE TABLE silver.crm_cust_info;

        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),

            -- Normalize marital status
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S'
                    THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M'
                    THEN 'Married'
                ELSE 'n/a'
            END,

            -- Normalize gender
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'F'
                    THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M'
                    THEN 'Male'
                ELSE 'n/a'
            END,

            cst_create_date

        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id
                    ORDER BY cst_create_date DESC
                ) AS row_num
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) AS customer

        -- Keep only the latest record for each customer
        WHERE row_num = 1;

        -- CRM Product
        -- Purpose:
        -- Transform product keys, handle missing costs,
        -- normalize product lines, and calculate product
        -- validity periods.

        TRUNCATE TABLE silver.crm_prd_info;

        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            -- Extract and standardize category ID
            REPLACE(
                SUBSTRING(prd_key, 1, 5),
                '-',
                '_'
            ),

            -- Extract product key
            SUBSTRING(prd_key, 7, LEN(prd_key)),

            prd_nm,

            -- Replace missing product cost with 0
            ISNULL(prd_cost, 0),

            -- Normalize product line
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M'
                    THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R'
                    THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S'
                    THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T'
                    THEN 'Touring'
                ELSE 'n/a'
            END,

            CAST(prd_start_dt AS DATE),

            -- Set end date to one day before
            -- the next product start date
            CAST(
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) - 1
                AS DATE
            )

        FROM bronze.crm_prd_info;

        -- CRM Sales
        -- Purpose:
        -- Standardize dates and correct invalid sales,
        -- quantity, and price values.

        TRUNCATE TABLE silver.crm_sales_details;

        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            -- Convert valid order dates into DATE
            CASE
                WHEN sls_order_dt = 0
                     OR LEN(sls_order_dt) <> 8
                    THEN NULL
                ELSE CAST(
                    CAST(sls_order_dt AS VARCHAR) AS DATE
                )
            END,

            -- Convert valid shipping dates into DATE
            CASE
                WHEN sls_ship_dt = 0
                     OR LEN(sls_ship_dt) <> 8
                    THEN NULL
                ELSE CAST(
                    CAST(sls_ship_dt AS VARCHAR) AS DATE
                )
            END,

            -- Convert valid due dates into DATE
            CASE
                WHEN sls_due_dt = 0
                     OR LEN(sls_due_dt) <> 8
                    THEN NULL
                ELSE CAST(
                    CAST(sls_due_dt AS VARCHAR) AS DATE
                )
            END,

            -- Recalculate sales when the original value
            -- is missing, invalid, or inconsistent
            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales <> sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END,

            sls_quantity,

            -- Derive price when the original price is invalid
            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END

        FROM bronze.crm_sales_details;

        -- ERP Customer
        -- Purpose:
        -- Standardize customer IDs, remove invalid birthdates,
        -- and normalize gender values.

        TRUNCATE TABLE silver.erp_cust_az12;

        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT

            -- Remove NAS prefix from customer ID
            CASE
                WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END,

            -- Remove future birthdates
            CASE
                WHEN bdate > GETDATE()
                    THEN NULL
                ELSE bdate
            END,

            -- Normalize gender
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                    THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                    THEN 'Male'
                ELSE 'n/a'
            END

        FROM bronze.erp_cust_az12;
        -- ERP Location
        -- Purpose:
        -- Standardize customer IDs and country names.

        TRUNCATE TABLE silver.erp_loc_a101;

        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT

            -- Remove '-' from customer ID
            REPLACE(cid, '-', ''),

            -- Normalize country values
            CASE
                WHEN TRIM(cntry) = 'DE'
                    THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA')
                    THEN 'United States'
                WHEN TRIM(cntry) = ''
                     OR cntry IS NULL
                    THEN 'n/a'
                ELSE TRIM(cntry)
            END

        FROM bronze.erp_loc_a101;
        -- ERP Product Category
        -- Purpose:
        -- Load product category information from Bronze
        -- into the Silver Layer.

        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;


    END TRY

    -- Error Handling
    -- Purpose:
    -- Capture errors that occur during the Silver Layer load.

    BEGIN CATCH

        PRINT 'Error occurred while loading Silver Layer.';
        PRINT 'Error Number: '
            + CAST(ERROR_NUMBER() AS NVARCHAR);

        PRINT 'Error Message: '
            + ERROR_MESSAGE();

        PRINT 'Error State: '
            + CAST(ERROR_STATE() AS NVARCHAR);

    END CATCH

END;
GO


-- Execute Silver Layer Load

EXEC silver.load_silver;