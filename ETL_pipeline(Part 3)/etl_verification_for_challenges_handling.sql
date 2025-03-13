USE FlipKart_EDW;
GO

--1.  Verify date dimension implementation with range and key attributes
SELECT 
    COUNT(*) as TotalDateRecords,
    MIN(FullDate) as MinDate,
    MAX(FullDate) as MaxDate,
    COUNT(DISTINCT Year) as YearCount,
    COUNT(DISTINCT Month) as MonthCount
FROM dim_Date;


--2.  Verify SCD Type 2 implementation in Customer dimension
SELECT TOP 10
    CustomerSK, 
    CustomerID, 
    CustomerSegment,
    EffectiveDate,
    ExpirationDate,
    IsCurrent,
    CASE 
        WHEN CustomerSegment = 'Premium' THEN 'High Value'
        WHEN CustomerSegment = 'Standard' THEN 'Medium Value'
        ELSE 'Growth Target'
    END AS BusinessCategory
FROM dim_Customer
ORDER BY CustomerSK;

-- 3. Second verification of SCD Type 2 implementation
SELECT 
    CustomerSegment,
    COUNT(*) AS TotalCustomers,
    MIN(EffectiveDate) AS EarliestEffectiveDate,
    COUNT(CASE WHEN IsCurrent = 1 THEN 1 ELSE NULL END) AS CurrentRecords,
    COUNT(CASE WHEN IsCurrent = 0 THEN 1 ELSE NULL END) AS HistoricalRecords
FROM dim_Customer
GROUP BY CustomerSegment
ORDER BY CustomerSegment;


-- 4. Verify derived attributes across dimensions
SELECT 'Customer Segments' AS DerivedAttribute,
    CustomerSegment AS AttributeValue,
    COUNT(*) AS RecordCount
FROM dim_Customer
GROUP BY CustomerSegment
UNION ALL
SELECT 'Product Stock Status',
    StockStatus,
    COUNT(*)
FROM dim_Product
GROUP BY StockStatus
UNION ALL
SELECT 'Geographic Regions',
    Region,
    COUNT(*)
FROM dim_Location
GROUP BY Region
ORDER BY DerivedAttribute, AttributeValue;


--5. Verify fact_Sales population and dimension relationships
SELECT 
    COUNT(*) AS TotalFactRows,
    COUNT(DISTINCT TransactionID) AS DistinctTransactions,
    COUNT(DISTINCT OrderID) AS DistinctOrders,
    COUNT(DISTINCT CustomerSK) AS DistinctCustomers,
    COUNT(DISTINCT ProductSK) AS DistinctProducts,
    COUNT(DISTINCT LocationSK) AS DistinctLocations,
    COUNT(DISTINCT OrderDateSK) AS DistinctOrderDates,
    SUM(Quantity) AS TotalQuantity,
    SUM(Sales) AS TotalSales,
    AVG(Discount) AS AverageDiscount
FROM fact_Sales;


-- 6. Verify fact_CustomerPurchaseBehavior population and measure calculations
SELECT 
    COUNT(*) AS TotalCustomerRecords,
    COUNT(DISTINCT CustomerSK) AS DistinctCustomers,
    AVG(WineAmount) AS AvgWineAmount,
    AVG(FruitAmount) AS AvgFruitAmount,
    AVG(MeatAmount) AS AvgMeatAmount,
    AVG(FishAmount) AS AvgFishAmount,
    AVG(TotalSpend) AS AvgTotalSpend,
    MAX(WebPurchaseCount) AS MaxWebPurchases,
    MAX(StorePurchaseCount) AS MaxStorePurchases,
    SUM(TotalSpend) AS GrandTotalSpend
FROM fact_CustomerPurchaseBehavior;



-- 7. Verify dimension-fact relationship integrity
SELECT 
    'Customer Dimension' as Relationship,
    COUNT(DISTINCT fs.CustomerSK) as FactDistinctCount,
    (SELECT COUNT(*) FROM dim_Customer) as DimTotalCount,
    (SELECT COUNT(*) FROM dim_Customer WHERE IsCurrent = 1) as CurrentDimCount,
    100.0 * COUNT(DISTINCT fs.CustomerSK) / 
        (SELECT COUNT(*) FROM dim_Customer WHERE IsCurrent = 1) as CoveragePercentage
FROM fact_Sales fs
UNION ALL
SELECT 
    'Product Dimension',
    COUNT(DISTINCT fs.ProductSK),
    (SELECT COUNT(*) FROM dim_Product),
    (SELECT COUNT(*) FROM dim_Product WHERE IsCurrent = 1),
    100.0 * COUNT(DISTINCT fs.ProductSK) / 
        (SELECT COUNT(*) FROM dim_Product WHERE IsCurrent = 1)
FROM fact_Sales fs
UNION ALL
SELECT 
    'Location Dimension',
    COUNT(DISTINCT fs.LocationSK),
    (SELECT COUNT(*) FROM dim_Location),
    (SELECT COUNT(*) FROM dim_Location WHERE IsCurrent = 1),
    100.0 * COUNT(DISTINCT fs.LocationSK) / 
        (SELECT COUNT(*) FROM dim_Location WHERE IsCurrent = 1)
FROM fact_Sales fs
UNION ALL
SELECT 
    'Date Dimension',
    COUNT(DISTINCT fs.OrderDateSK),
    (SELECT COUNT(*) FROM dim_Date),
    (SELECT COUNT(*) FROM dim_Date),
    100.0 * COUNT(DISTINCT fs.OrderDateSK) / 
        (SELECT COUNT(*) FROM dim_Date)
FROM fact_Sales fs;


-- Verify all dimension tables
SELECT 'dim_Customer' AS Table_Name, COUNT(*) AS Row_Count FROM dim_Customer
UNION ALL
SELECT 'dim_Product', COUNT(*) FROM dim_Product
UNION ALL
SELECT 'dim_Location', COUNT(*) FROM dim_Location
UNION ALL
SELECT 'dim_Date', COUNT(*) FROM dim_Date
UNION ALL
SELECT 'dim_PaymentMethod', COUNT(*) FROM dim_PaymentMethod
UNION ALL
SELECT 'dim_ShippingMethod', COUNT(*) FROM dim_ShippingMethod
UNION ALL
SELECT 'fact_Sales', COUNT(*) FROM fact_Sales
UNION ALL
SELECT 'fact_CustomerPurchaseBehavior', COUNT(*) FROM fact_CustomerPurchaseBehavior
ORDER BY Table_Name;


-- Verify fact table measures
SELECT 
    SUM(Quantity) as TotalQuantity,
    SUM(Sales) as TotalSales,
    SUM(TotalAmount) as GrandTotal,
    AVG(Discount) as AvgDiscount
FROM fact_Sales;



-- Check for NULL values in key fields across fact tables
SELECT 
    'fact_Sales' as TableName,
    SUM(CASE WHEN CustomerSK IS NULL THEN 1 ELSE 0 END) as NullCustomerSK,
    SUM(CASE WHEN ProductSK IS NULL THEN 1 ELSE 0 END) as NullProductSK,
    SUM(CASE WHEN LocationSK IS NULL THEN 1 ELSE 0 END) as NullLocationSK,
    SUM(CASE WHEN OrderDateSK IS NULL THEN 1 ELSE 0 END) as NullOrderDateSK,
    SUM(CASE WHEN ShipDateSK IS NULL THEN 1 ELSE 0 END) as NullShipDateSK,
    SUM(CASE WHEN PaymentMethodSK IS NULL THEN 1 ELSE 0 END) as NullPaymentMethodSK,
    SUM(CASE WHEN ShippingMethodSK IS NULL THEN 1 ELSE 0 END) as NullShippingMethodSK
FROM fact_Sales
UNION ALL
SELECT 
    'fact_CustomerPurchaseBehavior',
    SUM(CASE WHEN CustomerSK IS NULL THEN 1 ELSE 0 END) as NullCustomerSK,
    0 as NullProductSK,
    0 as NullLocationSK,
    SUM(CASE WHEN DateSK IS NULL THEN 1 ELSE 0 END) as NullDateSK,
    0 as NullShipDateSK,
    0 as NullPaymentMethodSK,
    0 as NullShippingMethodSK
FROM fact_CustomerPurchaseBehavior;


-- ETL Challenges and Handling Verification Queries

-- 1. SCD Type 2 verification
-- 1a. Verify SCD Type 2 structure and attributes in Customer dimension
SELECT TOP 5
    CustomerSK, 
    CustomerID, 
    CustomerSegment,
    EffectiveDate,
    ExpirationDate,
    IsCurrent
FROM dim_Customer
ORDER BY CustomerSK;


-- 1b. Verify SCD Type 2 coverage by customer segment
SELECT 
    CustomerSegment,
    COUNT(*) AS TotalCustomers,
    COUNT(CASE WHEN IsCurrent = 1 THEN 1 ELSE NULL END) AS CurrentRecords,
    COUNT(CASE WHEN IsCurrent = 0 THEN 1 ELSE NULL END) AS HistoricalRecords
FROM dim_Customer
GROUP BY CustomerSegment
ORDER BY CustomerSegment;


-- 2. Date Dimension Verification

--2a. Verify date range and key attributes
SELECT 
    COUNT(*) as TotalDateRecords,
    MIN(FullDate) as MinDate,
    MAX(FullDate) as MaxDate,
    COUNT(DISTINCT Year) as YearCount,
    COUNT(DISTINCT Month) as MonthCount
FROM dim_Date;

--2b. Verify special date attributes like weekends and holidays
SELECT 
    Year,
    SUM(CASE WHEN IsWeekend = 1 THEN 1 ELSE 0 END) AS WeekendDays,
    SUM(CASE WHEN IsHoliday = 1 THEN 1 ELSE 0 END) AS Holidays,
    COUNT(*) AS TotalDays
FROM dim_Date
GROUP BY Year
ORDER BY Year;


--3. Surrogate Key Management
-- 3a. Verify surrogate key to natural key relationship
SELECT 'Customer' AS Dimension,
    COUNT(DISTINCT CustomerSK) AS SurrogateKeyCount,
    COUNT(DISTINCT CustomerID) AS NaturalKeyCount,
    CASE WHEN COUNT(DISTINCT CustomerSK) = COUNT(DISTINCT CustomerID) 
         THEN 'Matched' ELSE 'Mismatch' END AS KeyStatus
FROM dim_Customer
UNION ALL
SELECT 'Product',
    COUNT(DISTINCT ProductSK),
    COUNT(DISTINCT ProductID),
    CASE WHEN COUNT(DISTINCT ProductSK) = COUNT(DISTINCT ProductID) 
         THEN 'Matched' ELSE 'Mismatch' END
FROM dim_Product;


-- 3b. Verify surrogate key linkage in fact tables
SELECT 
    COUNT(*) AS TotalFactRows,
    COUNT(DISTINCT CustomerSK) AS DistinctCustomerSKs,
    COUNT(DISTINCT ProductSK) AS DistinctProductSKs,
    COUNT(DISTINCT LocationSK) AS DistinctLocationSKs
FROM fact_Sales;



-- 4.Data Type Conversions and Cleaning 

-- 4a. Verify proper date conversions in fact tables
SELECT 
    MIN(CONVERT(VARCHAR, d1.FullDate, 23)) AS EarliestOrderDate,
    MAX(CONVERT(VARCHAR, d1.FullDate, 23)) AS LatestOrderDate,
    MIN(CONVERT(VARCHAR, d2.FullDate, 23)) AS EarliestShipDate,
    MAX(CONVERT(VARCHAR, d2.FullDate, 23)) AS LatestShipDate
FROM fact_Sales fs
JOIN dim_Date d1 ON fs.OrderDateSK = d1.DateSK
JOIN dim_Date d2 ON fs.ShipDateSK = d2.DateSK;

-- 4b. Verify NULL handling and data ranges
SELECT 
    MIN(Income) AS MinIncome,
    MAX(Income) AS MaxIncome,
    AVG(Income) AS AvgIncome,
    SUM(CASE WHEN Income IS NULL THEN 1 ELSE 0 END) AS NullIncomeCount
FROM dim_Customer;


-- FINAL VERIFICATION: 

--1. Extract Phase Verification

-- Verify successful extraction from source to staging tables
SELECT 'Extraction Phase Verification' AS Verification_Step;

-- Verify source database record counts
SELECT 'DB_FlipKart.Customers' AS Source_Table, COUNT(*) AS Record_Count FROM DB_FlipKart.dbo.Customers
UNION ALL
SELECT 'DB_FlipKart.Products', COUNT(*) FROM DB_FlipKart.dbo.Products
UNION ALL
SELECT 'DB_FlipKart.Orders', COUNT(*) FROM DB_FlipKart.dbo.Orders;

-- Verify staging tables record counts
SELECT 'stg_Customers' AS Staging_Table, COUNT(*) AS Record_Count FROM FlipKart_EDW.dbo.stg_Customers
UNION ALL
SELECT 'stg_Products', COUNT(*) FROM FlipKart_EDW.dbo.stg_Products
UNION ALL
SELECT 'stg_Orders', COUNT(*) FROM FlipKart_EDW.dbo.stg_Orders;

-- Verify record counts match between source and staging
SELECT 
    'Customers' AS Entity,
    (SELECT COUNT(*) FROM DB_FlipKart.dbo.Customers) AS Source_Count,
    (SELECT COUNT(*) FROM FlipKart_EDW.dbo.stg_Customers) AS Staging_Count,
    CASE WHEN (SELECT COUNT(*) FROM DB_FlipKart.dbo.Customers) = (SELECT COUNT(*) FROM FlipKart_EDW.dbo.stg_Customers)
         THEN 'SUCCESS' ELSE 'FAILED' END AS Extraction_Status
UNION ALL
SELECT 
    'Products',
    (SELECT COUNT(*) FROM DB_FlipKart.dbo.Products),
    (SELECT COUNT(*) FROM FlipKart_EDW.dbo.stg_Products),
    CASE WHEN (SELECT COUNT(*) FROM DB_FlipKart.dbo.Products) = (SELECT COUNT(*) FROM FlipKart_EDW.dbo.stg_Products)
         THEN 'SUCCESS' ELSE 'FAILED' END
UNION ALL
SELECT 
    'Orders',
    (SELECT COUNT(*) FROM DB_FlipKart.dbo.Orders),
    (SELECT COUNT(*) FROM FlipKart_EDW.dbo.stg_Orders),
    CASE WHEN (SELECT COUNT(*) FROM DB_FlipKart.dbo.Orders) = (SELECT COUNT(*) FROM FlipKart_EDW.dbo.stg_Orders)
         THEN 'SUCCESS' ELSE 'FAILED' END;


-- 2.Transform Phase Verification

-- Verify successful transformation through dimension creation and population
SELECT 'Transformation Phase Verification' AS Verification_Step;

-- Verify dimension tables were created with correct structure
SELECT 
    'dim_Customer' AS Dimension_Table,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Customer' AND COLUMN_NAME = 'CustomerSK'
    ) THEN 'SUCCESS' ELSE 'FAILED' END AS Surrogate_Key_Created,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Customer' AND COLUMN_NAME = 'IsCurrent'
    ) THEN 'SUCCESS' ELSE 'FAILED' END AS SCD_Type2_Created
UNION ALL
SELECT 
    'dim_Product',
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Product' AND COLUMN_NAME = 'ProductSK'
    ) THEN 'SUCCESS' ELSE 'FAILED' END,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Product' AND COLUMN_NAME = 'IsCurrent'
    ) THEN 'SUCCESS' ELSE 'FAILED' END;

-- Verify derived attributes were created
SELECT 
    'Derived Attributes' AS Transformation_Check,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Customer' AND COLUMN_NAME = 'CustomerSegment'
    ) THEN 'SUCCESS' ELSE 'FAILED' END AS Customer_Segmentation,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Product' AND COLUMN_NAME = 'StockStatus'
    ) THEN 'SUCCESS' ELSE 'FAILED' END AS Product_Stock_Status,
    CASE WHEN EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'dim_Location' AND COLUMN_NAME = 'Region'
    ) THEN 'SUCCESS' ELSE 'FAILED' END AS Geographic_Region;

-- Verify dimensions were populated
SELECT 
    Table_Name, 
    Record_Count,
    CASE WHEN Record_Count > 0 THEN 'SUCCESS' ELSE 'FAILED' END AS Population_Status
FROM (
    SELECT 'dim_Customer' AS Table_Name, COUNT(*) AS Record_Count FROM dim_Customer
    UNION ALL
    SELECT 'dim_Product', COUNT(*) FROM dim_Product
    UNION ALL
    SELECT 'dim_Location', COUNT(*) FROM dim_Location
    UNION ALL
    SELECT 'dim_Date', COUNT(*) FROM dim_Date
) AS Dimensions
ORDER BY Table_Name;


-- 3. Load Phase Verification

-- Verify successful loading into fact tables
SELECT 'Load Phase Verification' AS Verification_Step;

-- Verify fact tables were created and populated
SELECT 
    'Fact Tables' AS Load_Check,
    (SELECT COUNT(*) FROM fact_Sales) AS Sales_Fact_Count,
    (SELECT COUNT(*) FROM fact_CustomerPurchaseBehavior) AS Behavior_Fact_Count,
    CASE WHEN (SELECT COUNT(*) FROM fact_Sales) > 0 AND 
              (SELECT COUNT(*) FROM fact_CustomerPurchaseBehavior) > 0 
         THEN 'SUCCESS' ELSE 'FAILED' END AS Fact_Loading_Status;

-- Verify dimension keys were properly linked to facts
SELECT 
    'Dimension-Fact Links' AS Integrity_Check,
    CASE WHEN (
        SELECT COUNT(*) FROM fact_Sales 
        WHERE CustomerSK IS NULL OR ProductSK IS NULL OR LocationSK IS NULL
    ) = 0 THEN 'SUCCESS' ELSE 'FAILED' END AS Foreign_Key_Integrity;

-- Verify measures were correctly loaded
SELECT
    'Fact Measures' AS Measures_Check,
    CASE WHEN (SELECT SUM(Quantity) FROM fact_Sales) > 0 THEN 'SUCCESS' ELSE 'FAILED' END AS Quantity_Loaded,
    CASE WHEN (SELECT SUM(Sales) FROM fact_Sales) > 0 THEN 'SUCCESS' ELSE 'FAILED' END AS Sales_Loaded,
    CASE WHEN (SELECT SUM(TotalSpend) FROM fact_CustomerPurchaseBehavior) > 0 THEN 'SUCCESS' ELSE 'FAILED' END AS TotalSpend_Loaded;

-- Verify overall ETL success
SELECT 
    'Overall ETL Process' AS Final_Verification,
    CASE WHEN (
        (SELECT COUNT(*) FROM dim_Customer) > 0 AND
        (SELECT COUNT(*) FROM dim_Product) > 0 AND
        (SELECT COUNT(*) FROM dim_Location) > 0 AND
        (SELECT COUNT(*) FROM dim_Date) > 0 AND
        (SELECT COUNT(*) FROM fact_Sales) > 0 AND
        (SELECT COUNT(*) FROM fact_CustomerPurchaseBehavior) > 0
    ) THEN 'COMPLETE SUCCESS' ELSE 'FAILED' END AS ETL_Status;

