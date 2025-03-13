-- Extract data from source tables to staging tables
-- This simulates the extraction phase of ETL

-- Extract Customers data
INSERT INTO FlipKart_EDW.dbo.stg_Customers
SELECT 
    customer_id,
    year_birth,
    education,
    marital_status,
    income,
    kid_home,
    teen_home,
    dt_customer,
    recency,
    loyalty_score
FROM DB_FlipKart.dbo.Customers;

-- Extract CustomerPurchaseStats data
INSERT INTO FlipKart_EDW.dbo.stg_CustomerPurchaseStats
SELECT 
    customer_id,
    mnt_wines,
    mnt_fruits,
    mnt_meat_products,
    mnt_fish_products,
    mnt_sweet_products,
    mnt_gold_prods,
    num_deals_purchases,
    num_web_purchases,
    num_catalog_purchases,
    num_store_purchases,
    num_web_visits_month
FROM DB_FlipKart.dbo.CustomerPurchaseStats;

-- Extract Products data with category information
INSERT INTO FlipKart_EDW.dbo.stg_Products
SELECT 
    p.product_id,
    p.product_name,
    p.category_id,
    c.category_name,
    c.sub_category,
    p.brand,
    p.price,
    p.stock_quantity,
    p.discount,
    p.rating,
    p.supplier
FROM DB_FlipKart.dbo.Products p
JOIN DB_FlipKart.dbo.Categories c ON p.category_id = c.category_id;

-- Extract Orders data with location information
INSERT INTO FlipKart_EDW.dbo.stg_Orders
SELECT 
    o.order_id,
    o.order_date,
    o.customer_id,
    o.segment,
    o.location_id,
    l.country,
    l.state,
    l.city
FROM DB_FlipKart.dbo.Orders o
JOIN DB_FlipKart.dbo.Locations l ON o.location_id = l.location_id;

-- Extract OrderDetails data
INSERT INTO FlipKart_EDW.dbo.stg_OrderDetails
SELECT 
    transaction_id,
    order_id,
    product_id,
    ship_date,
    ship_mode,
    quantity,
    discount,
    sales,
    total_amount,
    payment_method,
    shipping_status
FROM DB_FlipKart.dbo.OrderDetails;

-- Verify extraction
SELECT 'stg_Customers' AS Table_Name, COUNT(*) AS Row_Count FROM FlipKart_EDW.dbo.stg_Customers
UNION ALL
SELECT 'stg_CustomerPurchaseStats', COUNT(*) FROM FlipKart_EDW.dbo.stg_CustomerPurchaseStats
UNION ALL
SELECT 'stg_Products', COUNT(*) FROM FlipKart_EDW.dbo.stg_Products
UNION ALL
SELECT 'stg_Orders', COUNT(*) FROM FlipKart_EDW.dbo.stg_Orders
UNION ALL
SELECT 'stg_OrderDetails', COUNT(*) FROM FlipKart_EDW.dbo.stg_OrderDetails;