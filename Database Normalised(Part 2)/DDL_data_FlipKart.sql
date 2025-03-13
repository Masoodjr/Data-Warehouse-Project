--CREATE DATABASE DB_FlipKart;
--END
GO

USE DB_FlipKart;
GO

-- Create normalized tables (7 tables total)
--For Customer_FlipKart dataset
-- 1. Customers table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    year_birth INT NOT NULL,
    education VARCHAR(50) NOT NULL,
    marital_status VARCHAR(50) NOT NULL,
    income INT,
    kid_home INT NOT NULL,
    teen_home INT NOT NULL,
    dt_customer DATE NOT NULL,
    recency INT NOT NULL,
    loyalty_score INT NOT NULL
);

-- 2. CustomerPurchaseStats table
CREATE TABLE CustomerPurchaseStats (
    customer_id INT PRIMARY KEY,
    mnt_wines INT NOT NULL,
    mnt_fruits INT NOT NULL,
    mnt_meat_products INT NOT NULL,
    mnt_fish_products INT NOT NULL,
    mnt_sweet_products INT NOT NULL,
    mnt_gold_prods INT NOT NULL,
    num_deals_purchases INT NOT NULL,
    num_web_purchases INT NOT NULL,
    num_catalog_purchases INT NOT NULL,
    num_store_purchases INT NOT NULL,
    num_web_visits_month INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

--For Products_FlipKart dataaset
-- 3. Categories table
CREATE TABLE Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    sub_category VARCHAR(100) NOT NULL,
    CONSTRAINT UC_Category UNIQUE (category_name, sub_category)
);

-- 4. Products table
CREATE TABLE Products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category_id INT NOT NULL,
    brand VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL,
    discount INT NOT NULL,
    rating DECIMAL(3, 1),
    supplier VARCHAR(100) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);


--For Sales_FlipKart Dataset
-- 5. Locations table
CREATE TABLE Locations (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    CONSTRAINT UC_Location UNIQUE (country, state, city)
);

-- 6. Orders table
CREATE TABLE Orders (
    order_id VARCHAR(50) PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL,
    segment VARCHAR(50) NOT NULL,
    location_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (location_id) REFERENCES Locations(location_id)
);

-- 7. OrderDetails table
CREATE TABLE OrderDetails (
    transaction_id INT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode VARCHAR(50) NOT NULL,
    quantity INT NOT NULL,
    discount DECIMAL(5, 2) NOT NULL,
    sales DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    shipping_status VARCHAR(50) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
GO