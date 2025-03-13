USE FlipKart_EDW;
GO

-- Verify the existence of dimension tables and their row counts
SELECT 
    'dim_Customer' AS Dimension_Table,
    (SELECT COUNT(*) FROM dim_Customer) AS Row_Count,
    'CustomerSK, CustomerID, CustomerSegment' AS Key_Columns
UNION ALL
SELECT 
    'dim_Product',
    (SELECT COUNT(*) FROM dim_Product),
    'ProductSK, ProductID, CategoryName'
UNION ALL
SELECT 
    'dim_Location',
    (SELECT COUNT(*) FROM dim_Location),
    'LocationSK, LocationID, Country, State, City'
UNION ALL
SELECT 
    'dim_Date',
    (SELECT COUNT(*) FROM dim_Date),
    'DateSK, FullDate, Year, Month'
UNION ALL
SELECT 
    'dim_PaymentMethod',
    (SELECT COUNT(*) FROM dim_PaymentMethod),
    'PaymentMethodSK, PaymentMethodName'
UNION ALL
SELECT 
    'dim_ShippingMethod',
    (SELECT COUNT(*) FROM dim_ShippingMethod),
    'ShippingMethodSK, ShipMode'
ORDER BY Row_Count DESC;

-- Verify ETL transformation evidence - show sample of derived attributes
SELECT TOP 5 
    CustomerSK, 
    CustomerID,
    CustomerSegment,  -- Derived attribute from ETL
    EffectiveDate,    -- SCD Type 2 attribute from ETL
    IsCurrent         -- SCD Type 2 attribute from ETL
FROM dim_Customer;

SELECT TOP 5
    ProductSK,
    ProductID,
    CategoryName,     -- Denormalized from Categories
    StockStatus       -- Derived attribute from ETL
FROM dim_Product;

SELECT TOP 5
    LocationSK,
    Country,
    State,
    City,
    Region            -- Derived attribute from ETL
FROM dim_Location;


-- Final Verification

-- Verify the existence and row counts of all dimension and fact tables
SELECT 
    'Dimension Tables' AS TableType,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
     WHERE TABLE_NAME LIKE 'dim_%' AND TABLE_TYPE = 'BASE TABLE') AS TableCount
UNION ALL
SELECT 
    'Fact Tables',
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
     WHERE TABLE_NAME LIKE 'fact_%' AND TABLE_TYPE = 'BASE TABLE')
UNION ALL
SELECT '----------------------', NULL
UNION ALL
SELECT 'dim_Customer', COUNT(*) FROM dim_Customer
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
SELECT '----------------------', NULL
UNION ALL
SELECT 'fact_Sales', COUNT(*) FROM fact_Sales
UNION ALL
SELECT 'fact_CustomerPurchaseBehavior', COUNT(*) FROM fact_CustomerPurchaseBehavior;


-- 2. Dimensions Verification

-- Customer Dimension design
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_Customer'
ORDER BY ORDINAL_POSITION;


-- Product Dimension design with derived attributes
SELECT TOP 5
    ProductSK,
    ProductID,
    CategoryName,
    StockStatus
FROM dim_Product;


-- Location Dimension with derived region
SELECT TOP 5
    LocationSK,
    Country,
    State,
    City,
    Region
FROM dim_Location;


-- Date Dimension structure
SELECT 
    COUNT(*) as TotalDateRecords,
    MIN(FullDate) as MinDate,
    MAX(FullDate) as MaxDate,
    COUNT(DISTINCT Year) as YearCount
FROM dim_Date;


-- Payment and Shipping Method dimensions
SELECT 'dim_PaymentMethod' AS Dimension, COUNT(*) AS Count FROM dim_PaymentMethod
UNION ALL
SELECT 'dim_ShippingMethod', COUNT(*) FROM dim_ShippingMethod;


-- 2. Fact Tables

-- Sales Fact table structure with dimension relationships
SELECT 
    'Customer Dimension' as Relationship,
    COUNT(DISTINCT fs.CustomerSK) as FactDistinctCount,
    (SELECT COUNT(*) FROM dim_Customer) as DimTotalCount
FROM fact_Sales fs
UNION ALL
SELECT 'Product Dimension', COUNT(DISTINCT fs.ProductSK), (SELECT COUNT(*) FROM dim_Product) FROM fact_Sales fs
UNION ALL
SELECT 'Location Dimension', COUNT(DISTINCT fs.LocationSK), (SELECT COUNT(*) FROM dim_Location) FROM fact_Sales fs;


-- Customer Purchase Behavior Fact measures
SELECT
    AVG(WineAmount) as AvgWineAmount,
    AVG(FruitAmount) as AvgFruitAmount,
    AVG(MeatAmount) as AvgMeatAmount,
    AVG(TotalSpend) as AvgTotalSpend,
    MAX(WebPurchaseCount) as MaxWebPurchases,
    MAX(StorePurchaseCount) as MaxStorePurchases
FROM fact_CustomerPurchaseBehavior;


--3 . Derived Dimesions verification

-- Verify Customer dimension structure
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_Customer'
ORDER BY ORDINAL_POSITION;

-- Verify Customer segmentation derivation
SELECT CustomerSegment, COUNT(*) AS CustomerCount
FROM dim_Customer
WHERE IsCurrent = 1
GROUP BY CustomerSegment
ORDER BY CustomerSegment;

-- Verification of Customer dimension derivation
SELECT c.customer_id, c.loyalty_score, dc.CustomerSegment
FROM DB_FlipKart.dbo.Customers c
JOIN FlipKart_EDW.dbo.dim_Customer dc ON c.customer_id = dc.CustomerID
WHERE dc.IsCurrent = 1
ORDER BY c.customer_id;


-- b. Product

-- Verify Product dimension denormalization
SELECT CategoryName, COUNT(*) AS ProductCount
FROM dim_Product
WHERE IsCurrent = 1
GROUP BY CategoryName
ORDER BY ProductCount DESC;

-- Verify Stock Status derivation
SELECT StockStatus, COUNT(*) AS ProductCount
FROM dim_Product
WHERE IsCurrent = 1
GROUP BY StockStatus
ORDER BY ProductCount DESC;


-- Verification of Product dimension denormalization
SELECT 
    p.product_id, 
    p.product_name,
    c.category_name,
    c.sub_category,
    dp.StockStatus
FROM DB_FlipKart.dbo.Products p
JOIN DB_FlipKart.dbo.Categories c ON p.category_id = c.category_id
JOIN FlipKart_EDW.dbo.dim_Product dp ON p.product_id = dp.ProductID
WHERE dp.IsCurrent = 1
ORDER BY p.product_id;


-- C. Location

-- Verification of Location dimension derivation
SELECT 
    l.country, 
    l.state, 
    l.city,
    dl.Region
FROM DB_FlipKart.dbo.Locations l
JOIN FlipKart_EDW.dbo.dim_Location dl 
    ON l.country = dl.Country 
    AND l.state = dl.State 
    AND l.city = dl.City
WHERE dl.IsCurrent = 1
ORDER BY dl.Region, l.country;


-- Verify Location hierarchy
SELECT Country, COUNT(DISTINCT State) AS StateCount, 
       COUNT(DISTINCT City) AS CityCount
FROM dim_Location
WHERE IsCurrent = 1
GROUP BY Country
ORDER BY StateCount DESC;

-- Verify Region derivation
SELECT Region, COUNT(*) AS LocationCount
FROM dim_Location
WHERE IsCurrent = 1
GROUP BY Region
ORDER BY LocationCount DESC;

-- D. Date

-- Verification of Date dimension attributes
SELECT 
    Year,
    COUNT(*) AS TotalDays,
    SUM(CASE WHEN IsWeekend = 1 THEN 1 ELSE 0 END) AS WeekendDays,
    SUM(CASE WHEN IsHoliday = 1 THEN 1 ELSE 0 END) AS Holidays
FROM dim_Date
GROUP BY Year
ORDER BY Year;


-- E. 

-- Verify Payment Methods
SELECT PaymentMethodName, 
       COUNT(*) AS TransactionCount
FROM dim_PaymentMethod pm
JOIN fact_Sales fs ON pm.PaymentMethodSK = fs.PaymentMethodSK
GROUP BY PaymentMethodName
ORDER BY TransactionCount DESC;

-- Verify Shipping Methods
SELECT ShipMode, 
       COUNT(*) AS TransactionCount
FROM dim_ShippingMethod sm
JOIN fact_Sales fs ON sm.ShippingMethodSK = fs.ShippingMethodSK
GROUP BY ShipMode
ORDER BY TransactionCount DESC;