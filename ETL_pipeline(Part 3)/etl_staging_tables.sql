-- Create a new database for our data warehouse
--IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FlipKart_EDW')
--BEGIN
-- CREATE DATABASE FlipKart_EDW;
--END
--GO

USE FlipKart_EDW;
GO

-- Create staging tables to hold the extracted data
-- These tables will mirror our source tables structure

-- Staging table for Customers data
CREATE TABLE stg_Customers (
    customer_id INT,
    year_birth INT,
    education VARCHAR(50),
    marital_status VARCHAR(50),
    income INT,
    kid_home INT,
    teen_home INT,
    dt_customer DATE,
    recency INT,
    loyalty_score INT
);

-- Staging table for CustomerPurchaseStats data
CREATE TABLE stg_CustomerPurchaseStats (
    customer_id INT,
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
    num_web_visits_month INT
);

-- Staging table for Products data
CREATE TABLE stg_Products (
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category_id INT,
    category_name VARCHAR(100),
    sub_category VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10, 2),
    stock_quantity INT,
    discount INT,
    rating DECIMAL(3, 1),
    supplier VARCHAR(100)
);

-- Staging table for Orders data
CREATE TABLE stg_Orders (
    order_id VARCHAR(50),
    order_date DATE,
    customer_id INT,
    segment VARCHAR(50),
    location_id INT,
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100)
);

-- Staging table for OrderDetails data
CREATE TABLE stg_OrderDetails (
    transaction_id INT,
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    ship_date DATE,
    ship_mode VARCHAR(50),
    quantity INT,
    discount DECIMAL(5, 2),
    sales DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    shipping_status VARCHAR(50)
);
GO