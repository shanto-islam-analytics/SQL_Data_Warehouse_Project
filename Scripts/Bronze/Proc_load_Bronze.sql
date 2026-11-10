/*
-------------------------------------------------------------------------------
Procedure Name : bronze.load_bronze
Data Flow      : Source -> Bronze
-------------------------------------------------------------------------------
Description:
    Populates the 'bronze' schema with data read from external CSV files.
    Steps performed:
      1. Empties each bronze table (TRUNCATE) before a fresh load.
      2. Loads the CSV contents into the tables using BULK INSERT.

Input / Output:
    No input parameters and no return value.

How to run:
    EXEC bronze.load_bronze;
-------------------------------------------------------------------------------
*/
CREATE OR ALTER PROCEDURE bronze.lode_bronze AS 
BEGIN
	DECLARE @start_time DateTime, @end_time DateTime, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		Print '===================================================================';
		print 'Loading Bronze layer';
		print '===================================================================';

		print '-------------------------------------------------------------------';
		print 'Loading CRM Tables';
		print '-------------------------------------------------------------------';

		SET @start_time	= GETDATE();
		print '>>Truncate Table:bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		print'>>Inserting data into:bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\SHANTO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\01_datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',' ,
			TABLOCK
		);
		SELECT COUNT(*) FROM bronze.crm_cust_info;

		SET @end_time = GETDATE();
		print '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		print'>> ----------------';

		SET @start_time	= GETDATE();
		print '>>Truncate Table:bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info;

		print'>>Inserting data into:bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\SHANTO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\01_datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',' ,
			TABLOCK
		);

		SELECT COUNT(*) FROM bronze.crm_prd_info;

		SET @end_time = GETDATE();
		print '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		print'>> ----------------';

		SET @start_time	= GETDATE();
		print '>>Truncate Table:bronze.crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details;

		print'>>Inserting data into:bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\SHANTO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\01_datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',' ,
			TABLOCK
		);

		SELECT COUNT(*) FROM bronze.crm_sales_details;
		SET @end_time = GETDATE();
		print '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		print'>> ----------------';

		print '------------------------------------------------------------------';
		print 'Loading ERP Tables';
		print '------------------------------------------------------------------';

		SET @start_time	= GETDATE();
		print '>>Truncate Table:bronze.erp_cust_AZ12'
		TRUNCATE TABLE bronze.erp_cust_AZ12;

		print'>>Inserting data into:bronze.erp_cust_AZ12';
		BULK INSERT bronze.erp_cust_AZ12
		FROM 'C:\Users\SHANTO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\01_datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',' ,
			TABLOCK
		);

		SELECT COUNT(*) FROM bronze.erp_cust_AZ12;

		SET @end_time = GETDATE();
		print '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		print'>> ----------------';
		

		SET @start_time	= GETDATE();
		print '>>Truncate Table:bronze.erp_Loc_A101'
		TRUNCATE TABLE bronze.erp_Loc_A101;

		print'>>Inserting data into:bronze.erp_Loc_A101';
		BULK INSERT bronze.erp_Loc_A101
		FROM 'C:\Users\SHANTO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\01_datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',' ,
			TABLOCK
		);

		SELECT COUNT(*) FROM bronze.erp_Loc_A101;

		SET @end_time = GETDATE();
		print '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		print'>> ----------------';

		SET @start_time	= GETDATE();
		print '>>Truncate Table:bronze.erp_PX_CAT_G1V2'
		TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;
		print'>>Inserting data into:bronze.erp_PX_CAT_G1V2';
		BULK INSERT bronze.erp_PX_CAT_G1V2
		FROM 'C:\Users\SHANTO\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\01_datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',' ,
			TABLOCK
		);

		SELECT COUNT(*) FROM bronze.erp_PX_CAT_G1V2;

		SET @end_time = GETDATE();
		print '>> Load Duration:' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		print'>> ----------------';

		SET @batch_end_time = GETDATE();
		print '======================================='
		print 'Loading Bronze Layer is Completed';
		print '  - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
		print '======================================='
	END TRY
	BEGIN CATCH
	print '==================================================='
	print 'ERROR OCCURED DURING LOADING BRONZE LAYER'
	print 'Error message' + ERROR_MESSAGE();
	print 'Error message' + CAST (ERROR_NUMBER() AS NVARCHAR);
	print 'Error message' + CAST (ERROR_STATE() AS NVARCHAR);
	print '==================================================='
	END CATCH
END
