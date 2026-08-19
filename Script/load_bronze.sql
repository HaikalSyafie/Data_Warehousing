CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    PRINT 'Loading data into Bronze layer';


    -- CRM: Customer Information
    TRUNCATE TABLE bronze.crm_cust_info;

    BULK INSERT bronze.crm_cust_info
    FROM 'D:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );


    -- CRM: Product Information
    TRUNCATE TABLE bronze.crm_prd_info;

    BULK INSERT bronze.crm_prd_info
    FROM 'D:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );


    -- CRM: Sales Details
    TRUNCATE TABLE bronze.crm_sales_details;

    BULK INSERT bronze.crm_sales_details
    FROM 'D:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );


    -- ERP: Location
    TRUNCATE TABLE bronze.erp_loc_a101;

    BULK INSERT bronze.erp_loc_a101
    FROM 'D:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );


    -- ERP: Customer
    TRUNCATE TABLE bronze.erp_cust_az12;

    BULK INSERT bronze.erp_cust_az12
    FROM 'D:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );


    -- ERP: Product Category
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    BULK INSERT bronze.erp_px_cat_g1v2
    FROM 'D:\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        TABLOCK
    );

END;
GO

EXEC bronze.load_bronze;
GO
