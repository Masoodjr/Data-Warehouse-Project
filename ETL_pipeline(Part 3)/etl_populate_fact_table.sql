USE FlipKart_EDW;
GO

-- Populate fact_Sales table
INSERT INTO fact_Sales (
    TransactionID, OrderID, CustomerSK, ProductSK, LocationSK,
    OrderDateSK, ShipDateSK, PaymentMethodSK, ShippingMethodSK,
    Quantity, Discount, Sales, TotalAmount, ShippingStatus
)
SELECT 
    od.transaction_id,
    od.order_id,
    c.CustomerSK,
    p.ProductSK,
    l.LocationSK,
    CONVERT(INT, FORMAT(o.order_date, 'yyyyMMdd')) AS OrderDateSK, 
    CONVERT(INT, FORMAT(od.ship_date, 'yyyyMMdd')) AS ShipDateSK,
    pm.PaymentMethodSK,
    sm.ShippingMethodSK,
    od.quantity,
    od.discount,
    od.sales,
    od.total_amount,
    od.shipping_status
FROM stg_OrderDetails od
JOIN stg_Orders o ON od.order_id = o.order_id
JOIN dim_Customer c ON o.customer_id = c.CustomerID AND c.IsCurrent = 1
JOIN dim_Product p ON od.product_id = p.ProductID AND p.IsCurrent = 1
JOIN dim_Location l ON o.location_id = l.LocationID AND l.IsCurrent = 1
JOIN dim_PaymentMethod pm ON od.payment_method = pm.PaymentMethodName
JOIN dim_ShippingMethod sm ON od.ship_mode = sm.ShipMode
-- Join to dim_Date for OrderDate
JOIN dim_Date dord ON CONVERT(INT, FORMAT(o.order_date, 'yyyyMMdd')) = dord.DateSK
-- Join to dim_Date for ShipDate
JOIN dim_Date dship ON CONVERT(INT, FORMAT(od.ship_date, 'yyyyMMdd')) = dship.DateSK;

-- Populate fact_CustomerPurchaseBehavior
INSERT INTO fact_CustomerPurchaseBehavior (
    CustomerSK, DateSK, WineAmount, FruitAmount, MeatAmount,
    FishAmount, SweetAmount, GoldAmount, DealsCount,
    WebPurchaseCount, CatalogPurchaseCount, StorePurchaseCount,
    WebVisitCount, TotalSpend
)
SELECT 
    c.CustomerSK,
    -- Use the most recent date in dim_Date that's not in the future
    (SELECT MAX(DateSK) FROM dim_Date WHERE FullDate <= GETDATE()) AS DateSK,
    cp.mnt_wines AS WineAmount,
    cp.mnt_fruits AS FruitAmount,
    cp.mnt_meat_products AS MeatAmount,
    cp.mnt_fish_products AS FishAmount,
    cp.mnt_sweet_products AS SweetAmount,
    cp.mnt_gold_prods AS GoldAmount,
    cp.num_deals_purchases AS DealsCount,
    cp.num_web_purchases AS WebPurchaseCount,
    cp.num_catalog_purchases AS CatalogPurchaseCount,
    cp.num_store_purchases AS StorePurchaseCount,
    cp.num_web_visits_month AS WebVisitCount,
    -- Calculate total spend across all product categories
    (cp.mnt_wines + cp.mnt_fruits + cp.mnt_meat_products + 
     cp.mnt_fish_products + cp.mnt_sweet_products + cp.mnt_gold_prods) AS TotalSpend
FROM stg_CustomerPurchaseStats cp
JOIN dim_Customer c ON cp.customer_id = c.CustomerID AND c.IsCurrent = 1;

-- Display count of populated fact tables
SELECT 'fact_Sales' AS Table_Name, COUNT(*) AS Row_Count FROM fact_Sales
UNION ALL
SELECT 'fact_CustomerPurchaseBehavior', COUNT(*) FROM fact_CustomerPurchaseBehavior;