
USE FlipKart_EDW;
go

--Analytical Query Type 1: Sales Performance Analysis
--Query 1.1: Sales Performance by Product Category and Quarter

-- Sales Performance by Product Category and Quarter
SELECT 
    dp.CategoryName,
    dd.Year,
    dd.Quarter,
    SUM(fs.Quantity) AS TotalQuantity,
    SUM(fs.Sales) AS TotalSales,
    COUNT(DISTINCT fs.OrderID) AS NumberOfOrders,
    SUM(fs.Sales)/COUNT(DISTINCT fs.OrderID) AS AvgOrderValue
FROM fact_Sales fs
JOIN dim_Product dp ON fs.ProductSK = dp.ProductSK
JOIN dim_Date dd ON fs.OrderDateSK = dd.DateSK
WHERE dp.IsCurrent = 1
GROUP BY dp.CategoryName, dd.Year, dd.Quarter
ORDER BY dp.CategoryName, dd.Year, dd.Quarter;


--1.2  Product Performance Analysis with Price and Discount Impact
SELECT 
    dp.CategoryName,
    dp.SubCategory,
    dp.Brand,
    COUNT(DISTINCT fs.ProductSK) AS NumberOfProducts,
    SUM(fs.Quantity) AS TotalUnitsSold,
    SUM(fs.Sales) AS TotalRevenue,
    AVG(dp.Price) AS AvgPrice,
    AVG(fs.Discount) AS AvgDiscount,
    SUM(fs.Sales)/SUM(fs.Quantity) AS AvgSellingPrice,
    SUM(fs.Quantity)/COUNT(DISTINCT fs.OrderID) AS UnitsPerOrder
FROM fact_Sales fs
JOIN dim_Product dp ON fs.ProductSK = dp.ProductSK
JOIN dim_Date dd ON fs.OrderDateSK = dd.DateSK
WHERE dp.IsCurrent = 1
GROUP BY dp.CategoryName, dp.SubCategory, dp.Brand
ORDER BY TotalRevenue DESC;


-- Type 2: Customer Segmentation Analysis

--Query 2.1: Customer Segment Profitability Analysis

-- Customer Segment Profitability Analysis
SELECT 
    dc.CustomerSegment,
    COUNT(DISTINCT dc.CustomerSK) AS CustomerCount,
    SUM(fs.Sales) AS TotalSales,
    SUM(fs.Sales)/COUNT(DISTINCT dc.CustomerSK) AS SalesPerCustomer,
    COUNT(DISTINCT fs.OrderID) AS TotalOrders,
    COUNT(DISTINCT fs.OrderID)/COUNT(DISTINCT dc.CustomerSK) AS OrdersPerCustomer,
    SUM(fs.Quantity) AS TotalItems,
    SUM(fs.Quantity)/COUNT(DISTINCT fs.OrderID) AS ItemsPerOrder,
    SUM(fs.Sales)/COUNT(DISTINCT fs.OrderID) AS AvgOrderValue
FROM fact_Sales fs
JOIN dim_Customer dc ON fs.CustomerSK = dc.CustomerSK
WHERE dc.IsCurrent = 1
GROUP BY dc.CustomerSegment
ORDER BY SalesPerCustomer DESC;


--Analytical Query Type 3: Geographic Sales Analysis
--Query 3.1: Regional Sales Performance with Shipping Analysis

-- Regional Sales Performance with Shipping Analysis

SELECT 
    dl.Region,
    dl.Country,
    COUNT(DISTINCT fs.OrderID) AS OrderCount,
    SUM(fs.Sales) AS TotalSales,
    AVG(fs.Sales) AS AvgOrderValue,
    AVG(DATEDIFF(day, CONVERT(date, dd_order.FullDate), CONVERT(date, dd_ship.FullDate))) AS AvgShippingDays,
    -- Replacing the STRING_AGG with a simpler approach
    LEFT(
        (SELECT TOP 3 dsm2.ShipMode + ', ' 
         FROM fact_Sales fs2
         JOIN dim_ShippingMethod dsm2 ON fs2.ShippingMethodSK = dsm2.ShippingMethodSK
         JOIN dim_Location dl2 ON fs2.LocationSK = dl2.LocationSK
         WHERE dl2.Region = dl.Region AND dl2.Country = dl.Country
         GROUP BY dsm2.ShipMode
         ORDER BY COUNT(*) DESC
         FOR XML PATH('')), 
        1000) AS ShippingModes,
    COUNT(DISTINCT CASE WHEN fs.ShippingStatus = 'Delivered' THEN fs.OrderID END) * 100.0 / 
        NULLIF(COUNT(DISTINCT fs.OrderID), 0) AS DeliverySuccessRate
FROM fact_Sales fs
JOIN dim_Location dl ON fs.LocationSK = dl.LocationSK
JOIN dim_Date dd_order ON fs.OrderDateSK = dd_order.DateSK
JOIN dim_Date dd_ship ON fs.ShipDateSK = dd_ship.DateSK
JOIN dim_ShippingMethod dsm ON fs.ShippingMethodSK = dsm.ShippingMethodSK
WHERE dl.IsCurrent = 1
GROUP BY dl.Region, dl.Country
ORDER BY TotalSales DESC;



-- City-Level Sales with Category Analysis

SELECT TOP 20
    dl.Country,
    dl.State,
    dl.City,
    COUNT(DISTINCT fs.OrderID) AS OrderCount,
    SUM(fs.Sales) AS TotalSales,
    COUNT(DISTINCT fs.CustomerSK) AS UniqueCustomers,
    SUM(fs.Sales)/COUNT(DISTINCT fs.CustomerSK) AS SalesPerCustomer,
    -- Replacing STRING_AGG with alternative approach
    LEFT(
        (SELECT TOP 3 dp2.CategoryName + ', ' 
         FROM fact_Sales fs2
         JOIN dim_Product dp2 ON fs2.ProductSK = dp2.ProductSK
         JOIN dim_Location dl2 ON fs2.LocationSK = dl2.LocationSK
         WHERE dl2.City = dl.City AND dl2.State = dl.State AND dl2.Country = dl.Country
         GROUP BY dp2.CategoryName
         ORDER BY SUM(fs2.Sales) DESC
         FOR XML PATH('')), 
        1000) AS TopCategories
FROM fact_Sales fs
JOIN dim_Location dl ON fs.LocationSK = dl.LocationSK
JOIN dim_Product dp ON fs.ProductSK = dp.ProductSK
WHERE dl.IsCurrent = 1 AND dp.IsCurrent = 1
GROUP BY dl.Country, dl.State, dl.City
ORDER BY TotalSales DESC;


--Type 4: Complex Multi-Dimensional Analysis
--Query 4.1: Comprehensive Sales Analysis by Multiple Dimensions

-- Complex Multi-Dimensional Sales Analysis
SELECT 
    dd.Year,
    dd.Quarter,
    dp.CategoryName,
    dl.Region,
    dc.CustomerSegment,
    dsm.ShipMode,
    dpm.PaymentMethodName,
    COUNT(DISTINCT fs.OrderID) AS OrderCount,
    COUNT(DISTINCT fs.CustomerSK) AS CustomerCount,
    SUM(fs.Quantity) AS TotalQuantity,
    SUM(fs.Sales) AS TotalSales,
    SUM(fs.TotalAmount) AS GrandTotal,
    AVG(fs.Discount) AS AvgDiscountRate,
    SUM(fs.Sales)/COUNT(DISTINCT fs.OrderID) AS AvgOrderValue,
    SUM(fs.Quantity)/COUNT(DISTINCT fs.OrderID) AS AvgOrderSize
FROM fact_Sales fs
JOIN dim_Date dd ON fs.OrderDateSK = dd.DateSK
JOIN dim_Product dp ON fs.ProductSK = dp.ProductSK
JOIN dim_Location dl ON fs.LocationSK = dl.LocationSK
JOIN dim_Customer dc ON fs.CustomerSK = dc.CustomerSK
JOIN dim_ShippingMethod dsm ON fs.ShippingMethodSK = dsm.ShippingMethodSK
JOIN dim_PaymentMethod dpm ON fs.PaymentMethodSK = dpm.PaymentMethodSK
WHERE dp.IsCurrent = 1 AND dl.IsCurrent = 1 AND dc.IsCurrent = 1
GROUP BY 
    dd.Year,
    dd.Quarter,
    dp.CategoryName,
    dl.Region,
    dc.CustomerSegment,
    dsm.ShipMode,
    dpm.PaymentMethodName
ORDER BY TotalSales DESC;


--4.2 Customer Lifetime Value and Purchase Pattern Analysis
WITH CustomerPurchases AS (
    SELECT 
        dc.CustomerSK,
        dc.CustomerID,
        dc.CustomerSegment,
        dc.YearBirth,
        dc.MaritalStatus,
        dc.Income,
        MIN(dd.FullDate) AS FirstPurchaseDate,
        MAX(dd.FullDate) AS LastPurchaseDate,
        DATEDIFF(day, MIN(dd.FullDate), MAX(dd.FullDate)) AS CustomerLifespan,
        COUNT(DISTINCT fs.OrderID) AS TotalOrders,
        SUM(fs.Sales) AS TotalSpend,
        COUNT(DISTINCT dp.CategoryName) AS CategoryCount,
        -- Replace STRING_AGG with alternative approach
        LEFT(
            (SELECT TOP 3 dp2.CategoryName + ', ' 
             FROM fact_Sales fs2
             JOIN dim_Product dp2 ON fs2.ProductSK = dp2.ProductSK
             WHERE fs2.CustomerSK = dc.CustomerSK
             GROUP BY dp2.CategoryName
             ORDER BY COUNT(*) DESC
             FOR XML PATH('')), 
            1000) AS PurchasedCategories
    FROM fact_Sales fs
    JOIN dim_Customer dc ON fs.CustomerSK = dc.CustomerSK
    JOIN dim_Date dd ON fs.OrderDateSK = dd.DateSK
    JOIN dim_Product dp ON fs.ProductSK = dp.ProductSK
    WHERE dc.IsCurrent = 1 AND dp.IsCurrent = 1
    GROUP BY 
        dc.CustomerSK,
        dc.CustomerID,
        dc.CustomerSegment,
        dc.YearBirth,
        dc.MaritalStatus,
        dc.Income
)
SELECT 
    CustomerSegment,
    COUNT(CustomerSK) AS CustomerCount,
    AVG(TotalSpend) AS AvgLifetimeValue,
    AVG(TotalOrders) AS AvgOrderCount,
    AVG(CASE WHEN CustomerLifespan > 0 THEN TotalOrders * 365.0 / CustomerLifespan ELSE NULL END) AS AvgYearlyOrderFrequency,
    AVG(TotalSpend / NULLIF(TotalOrders, 0)) AS AvgOrderValue,
    AVG(CategoryCount) AS AvgCategoryCount,
    AVG(DATEDIFF(day, FirstPurchaseDate, LastPurchaseDate)) AS AvgCustomerLifespanDays
FROM CustomerPurchases
GROUP BY CustomerSegment
ORDER BY AvgLifetimeValue DESC;