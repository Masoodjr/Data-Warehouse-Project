USE FlipKart_EDW;
GO

-- Populate the Customer dimension with SCD Type 2 logic
INSERT INTO dim_Customer (
    CustomerID, YearBirth, Education, MaritalStatus, Income,
    KidHome, TeenHome, CustomerSince, Recency, LoyaltyScore,
    CustomerSegment, EffectiveDate, ExpirationDate, IsCurrent
)
SELECT 
    c.customer_id,
    c.year_birth,
    c.education,
    c.marital_status,
    c.income,
    c.kid_home,
    c.teen_home,
    c.dt_customer AS CustomerSince,
    c.recency,
    c.loyalty_score,
    -- Derive customer segment based on loyalty score
    CASE 
        WHEN c.loyalty_score >= 80 THEN 'Premium'
        WHEN c.loyalty_score >= 50 THEN 'Standard'
        ELSE 'Basic'
    END AS CustomerSegment,
    CONVERT(DATE, GETDATE()) AS EffectiveDate,  -- Current data is effective from today
    NULL AS ExpirationDate,                     -- No expiration for current data
    1 AS IsCurrent                              -- Current flag set to true
FROM stg_Customers c;

-- Populate the Product dimension with SCD Type 2 logic
INSERT INTO dim_Product (
    ProductID, ProductName, CategoryID, CategoryName, SubCategory,
    Brand, Price, StockStatus, Discount, Rating, Supplier,
    EffectiveDate, ExpirationDate, IsCurrent
)
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    p.category_name,
    p.sub_category,
    p.brand,
    p.price,
    -- Derive stock status based on stock quantity
    CASE 
        WHEN p.stock_quantity > 100 THEN 'High Stock'
        WHEN p.stock_quantity > 50 THEN 'Medium Stock'
        WHEN p.stock_quantity > 0 THEN 'Low Stock'
        ELSE 'Out of Stock'
    END AS StockStatus,
    p.discount,
    p.rating,
    p.supplier,
    CONVERT(DATE, GETDATE()) AS EffectiveDate,  -- Current data is effective from today
    NULL AS ExpirationDate,                     -- No expiration for current data
    1 AS IsCurrent                              -- Current flag set to true
FROM stg_Products p;

-- Display count of populated dimensions
SELECT 'dim_Customer' AS Table_Name, COUNT(*) AS Row_Count FROM dim_Customer
UNION ALL
SELECT 'dim_Product', COUNT(*) FROM dim_Product;