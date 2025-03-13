

USE DB_FlipKart;

-- Create temporary tables to load the raw CSV data
CREATE TABLE #temp_customers (
    customer_id INT,
    year_birth INT,
    education VARCHAR(50),
    marital_status VARCHAR(50),
    income INT,
    kid_home INT,
    teen_home INT,
    dt_customer VARCHAR(50),
    recency INT,
    mnt_wines INT,
    mnt_fruits INT,
    mnt_meat_products INT,
    mnt_fish_products INT,
    mnt_sweet_products INT,
    mnt_gold_prods INT,
    num_deals_purchases INT,
    num_web_purchases INT,
    num_catalog_purchases INT,
    num_store_purchases INT,
    num_web_visits_month INT,
    loyalty_score INT
);

CREATE TABLE #temp_products (
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10, 2),
    stock_quantity INT,
    discount INT,
    rating DECIMAL(3, 1),
    supplier VARCHAR(100)
);

CREATE TABLE #temp_sales (
    transaction_id INT,
    order_id VARCHAR(50),
    order_date VARCHAR(50),
    ship_date VARCHAR(50),
    ship_mode VARCHAR(50),
    customer_id INT,
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    product_id VARCHAR(50),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    product_name VARCHAR(255),
    sales DECIMAL(10, 2),
    quantity INT,
    discount DECIMAL(5, 2),
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    shipping_status VARCHAR(50)
);

-- Load data from CSV files into temporary tables
BULK INSERT #temp_customers
FROM 'C:\Users\masood\Downloads\Data Warehouse Project\Raw Data Folder\customers_FlipKart.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

BULK INSERT #temp_products
FROM 'C:\Users\masood\Downloads\Data Warehouse Project\Raw Data Folder\products_FlipKart.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

BULK INSERT #temp_sales
FROM 'C:\Users\masood\Downloads\Data Warehouse Project\Raw Data Folder\sales_Flipkart.csv'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);

-- Create staging tables to handle deduplication
-- Customers staging
SELECT 
    customer_id,
    year_birth,
    education,
    marital_status,
    ISNULL(income, 0) AS income,
    kid_home,
    teen_home,
    CASE WHEN ISDATE(dt_customer) = 1 THEN CONVERT(DATE, dt_customer) ELSE '1900-01-01' END AS dt_customer,
    recency,
    loyalty_score,
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
INTO #stage_customers
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY (SELECT NULL)) AS rn
    FROM #temp_customers
) t
WHERE t.rn = 1;

-- Categories staging
SELECT DISTINCT 
    category AS category_name, 
    sub_category
INTO #stage_categories
FROM #temp_products;

-- Products staging
SELECT 
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    price,
    stock_quantity,
    discount,
    rating,
    supplier
INTO #stage_products
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY (SELECT NULL)) AS rn
    FROM #temp_products
) t
WHERE t.rn = 1;

-- Locations staging
SELECT DISTINCT 
    country, 
    state, 
    city
INTO #stage_locations
FROM #temp_sales;

-- Orders staging
SELECT 
    order_id,
    CASE WHEN ISDATE(order_date) = 1 THEN CONVERT(DATE, order_date) ELSE '1900-01-01' END AS order_date,
    customer_id,
    segment,
    country,
    state,
    city
INTO #stage_orders
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY (SELECT NULL)) AS rn
    FROM #temp_sales
) t
WHERE t.rn = 1;

-- Transactions staging
SELECT 
    transaction_id,
    order_id,
    product_id,
    CASE WHEN ISDATE(ship_date) = 1 THEN CONVERT(DATE, ship_date) ELSE '1900-01-01' END AS ship_date,
    ship_mode,
    quantity,
    discount,
    sales,
    total_amount,
    payment_method,
    shipping_status
INTO #stage_transactions
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY (SELECT NULL)) AS rn
    FROM #temp_sales
) t
WHERE t.rn = 1;

-- Load data into the normalized tables in the correct order
-- 1. Insert categories
INSERT INTO Categories (category_name, sub_category)
SELECT category_name, sub_category FROM #stage_categories;

-- 2. Insert locations
INSERT INTO Locations (country, state, city)
SELECT country, state, city FROM #stage_locations;

-- 3. Insert customers
INSERT INTO Customers (customer_id, year_birth, education, marital_status, income, kid_home, teen_home, dt_customer, recency, loyalty_score)
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
FROM #stage_customers;

-- 4. Insert customer purchase stats
INSERT INTO CustomerPurchaseStats (customer_id, mnt_wines, mnt_fruits, mnt_meat_products, mnt_fish_products, mnt_sweet_products, mnt_gold_prods, num_deals_purchases, num_web_purchases, num_catalog_purchases, num_store_purchases, num_web_visits_month)
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
FROM #stage_customers;

-- 5. Insert products (with category_id lookup)
INSERT INTO Products (product_id, product_name, category_id, brand, price, stock_quantity, discount, rating, supplier)
SELECT 
    p.product_id,
    p.product_name,
    c.category_id,
    p.brand,
    p.price,
    p.stock_quantity,
    p.discount,
    p.rating,
    p.supplier
FROM #stage_products p
JOIN Categories c ON p.category = c.category_name AND p.sub_category = c.sub_category;

-- 6. Insert orders (with customer and location lookup)
INSERT INTO Orders (order_id, order_date, customer_id, segment, location_id)
SELECT 
    o.order_id,
    o.order_date,
    o.customer_id,
    o.segment,
    l.location_id
FROM #stage_orders o
JOIN Locations l ON o.country = l.country AND o.state = l.state AND o.city = l.city
-- Only include orders with valid customers
WHERE EXISTS (SELECT 1 FROM Customers c WHERE o.customer_id = c.customer_id);

-- 7. Insert order details (with order and product lookup)
INSERT INTO OrderDetails (transaction_id, order_id, product_id, ship_date, ship_mode, quantity, discount, sales, total_amount, payment_method, shipping_status)
SELECT 
    t.transaction_id,
    t.order_id,
    t.product_id,
    t.ship_date,
    t.ship_mode,
    t.quantity,
    t.discount,
    t.sales,
    t.total_amount,
    t.payment_method,
    t.shipping_status
FROM #stage_transactions t
-- Only include transactions with valid orders and products
WHERE EXISTS (SELECT 1 FROM Orders o WHERE t.order_id = o.order_id)
AND EXISTS (SELECT 1 FROM Products p WHERE t.product_id = p.product_id);

-- Clean up temporary tables
DROP TABLE IF EXISTS #temp_customers;
DROP TABLE IF EXISTS #temp_products;
DROP TABLE IF EXISTS #temp_sales;
DROP TABLE IF EXISTS #stage_customers;
DROP TABLE IF EXISTS #stage_categories;
DROP TABLE IF EXISTS #stage_products;
DROP TABLE IF EXISTS #stage_locations;
DROP TABLE IF EXISTS #stage_orders;
DROP TABLE IF EXISTS #stage_transactions;

-- Verify data loaded successfully
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
SELECT 'OrderDetails', COUNT(*) FROM OrderDetails;