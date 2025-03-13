
-- Verification for DDL Database

USE DB_FlipKart;
go

-- 1. Verify table structure of all normalized tables
-- This shows the schema of each table with columns and data types
SELECT 
    t.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.IS_NULLABLE,
    CASE 
        WHEN pk.CONSTRAINT_TYPE = 'PRIMARY KEY' THEN 'PK'
        ELSE ''
    END AS KEY_TYPE
FROM 
    INFORMATION_SCHEMA.TABLES t
JOIN 
    INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME
LEFT JOIN (
    SELECT 
        ku.TABLE_NAME,
        ku.COLUMN_NAME,
        tc.CONSTRAINT_TYPE
    FROM 
        INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN 
        INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
    WHERE 
        tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
) pk ON c.TABLE_NAME = pk.TABLE_NAME AND c.COLUMN_NAME = pk.COLUMN_NAME
WHERE 
    t.TABLE_TYPE = 'BASE TABLE' 
    AND t.TABLE_CATALOG = 'DB_FlipKart'
    AND t.TABLE_SCHEMA = 'dbo'
ORDER BY 
    t.TABLE_NAME, 
    c.ORDINAL_POSITION;

-- 2. Verify foreign key relationships
-- This shows all foreign key constraints in the database
SELECT 
    fk.name AS FK_Name,
    OBJECT_NAME(fk.parent_object_id) AS Table_Name,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Column_Name,
    OBJECT_NAME(fk.referenced_object_id) AS Referenced_Table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Referenced_Column
FROM 
    sys.foreign_keys fk
INNER JOIN 
    sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY 
    Table_Name, 
    Column_Name;


-- 3. Verify record counts in each table
-- This shows how many rows are in each normalized table
SELECT 'Customers' AS Table_Name, COUNT(*) AS Row_Count FROM Customers
UNION ALL
SELECT 'CustomerPurchaseStats', COUNT(*) FROM CustomerPurchaseStats
UNION ALL
SELECT 'Categories', COUNT(*) FROM Categories
UNION ALL
SELECT 'Products', COUNT(*) FROM Products
UNION ALL
SELECT 'Locations', COUNT(*) FROM Locations
UNION ALL
SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL
SELECT 'OrderDetails', COUNT(*) FROM OrderDetails
ORDER BY Table_Name;



-- Verification for Loading Raw Data into Normalised Database


--Query 1: Verify sample data from each table
-- Shows sample data from each table to verify data was loaded correctly
SELECT TOP 5 * FROM Customers;
SELECT TOP 5 * FROM CustomerPurchaseStats;
SELECT TOP 5 * FROM Categories;
SELECT TOP 5 * FROM Products;
SELECT TOP 5 * FROM Locations;
SELECT TOP 5 * FROM Orders;
SELECT TOP 5 * FROM OrderDetails;


--Query 2: Verify data integrity across related tables
-- Shows data relationships to verify integrity across tables
SELECT TOP 5 
    o.order_id, 
    o.customer_id,
    c.year_birth,
    c.education,
    o.location_id,
    l.country,
    l.state,
    l.city
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Locations l ON o.location_id = l.location_id
ORDER BY o.order_id;

SELECT TOP 5
    od.transaction_id,
    od.order_id,
    od.product_id,
    p.product_name,
    p.category_id,
    cat.category_name,
    cat.sub_category
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
JOIN Categories cat ON p.category_id = cat.category_id
ORDER BY od.transaction_id;


--3.  Shows statistical measures to verify data quality
SELECT 
    'Sales Statistics' AS Data_Check,
    COUNT(*) AS Total_Transactions,
    SUM(quantity) AS Total_Quantity,
    MIN(sales) AS Min_Sale,
    MAX(sales) AS Max_Sale,
    AVG(sales) AS Avg_Sale,
    SUM(total_amount) AS Total_Revenue
FROM OrderDetails;

SELECT
    'Product Statistics' AS Data_Check,
    COUNT(*) AS Total_Products,
    MIN(price) AS Min_Price,
    MAX(price) AS Max_Price,
    AVG(price) AS Avg_Price,
    COUNT(DISTINCT category_id) AS Distinct_Categories
FROM Products;

SELECT
    'Customer Statistics' AS Data_Check, 
    COUNT(*) AS Total_Customers,
    AVG(year_birth) AS Avg_Birth_Year,
    MIN(income) AS Min_Income,
    MAX(income) AS Max_Income,
    AVG(income) AS Avg_Income
FROM Customers;