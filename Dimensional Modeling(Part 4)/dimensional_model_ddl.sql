USE FlipKart_EDW;
GO

-- Create dimension tables with surrogate keys and additional attributes for the star schema
-- 1. Customer Dimension (handles SCD Type 2 with effective dates and current flag)
CREATE TABLE dim_Customer (
    CustomerSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate key
    CustomerID INT NOT NULL,                 -- Natural/business key
    YearBirth INT NOT NULL,
    Education VARCHAR(50) NOT NULL,
    MaritalStatus VARCHAR(50) NOT NULL,
    Income INT,
    KidHome INT NOT NULL,
    TeenHome INT NOT NULL,
    CustomerSince DATE NOT NULL,
    Recency INT NOT NULL,
    LoyaltyScore INT NOT NULL,
    CustomerSegment VARCHAR(50) NOT NULL,    -- Derived attribute based on loyalty
    EffectiveDate DATE NOT NULL,             -- SCD Type 2 attribute
    ExpirationDate DATE NULL,                -- SCD Type 2 attribute
    IsCurrent BIT NOT NULL                   -- SCD Type 2 attribute
);

-- 2. Product Dimension
CREATE TABLE dim_Product (
    ProductSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate key
    ProductID VARCHAR(50) NOT NULL,          -- Natural/business key
    ProductName VARCHAR(255) NOT NULL,
    CategoryID INT NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    SubCategory VARCHAR(100) NOT NULL,
    Brand VARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    StockStatus VARCHAR(50) NOT NULL,        -- Derived attribute
    Discount INT NOT NULL,
    Rating DECIMAL(3, 1),
    Supplier VARCHAR(100) NOT NULL,
    EffectiveDate DATE NOT NULL,             -- SCD Type 2 attribute
    ExpirationDate DATE NULL,                -- SCD Type 2 attribute
    IsCurrent BIT NOT NULL                   -- SCD Type 2 attribute
);

-- 3. Location Dimension
CREATE TABLE dim_Location (
    LocationSK INT IDENTITY(1,1) PRIMARY KEY, -- Surrogate key
    LocationID INT NOT NULL,                  -- Natural/business key
    Country VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Region VARCHAR(50) NOT NULL,              -- Derived attribute
    EffectiveDate DATE NOT NULL,              -- SCD Type 2 attribute
    ExpirationDate DATE NULL,                 -- SCD Type 2 attribute
    IsCurrent BIT NOT NULL                    -- SCD Type 2 attribute
);

-- 4. Date Dimension
CREATE TABLE dim_Date (
    DateSK INT PRIMARY KEY,        -- Surrogate key (based on YYYYMMDD format)
    FullDate DATE NOT NULL UNIQUE,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(10) NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfYear INT NOT NULL,
    WeekOfYear INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    Quarter INT NOT NULL,
    QuarterName VARCHAR(6) NOT NULL,
    Year INT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL
);

-- 5. Payment Method Dimension
CREATE TABLE dim_PaymentMethod (
    PaymentMethodSK INT IDENTITY(1,1) PRIMARY KEY,
    PaymentMethodName VARCHAR(50) NOT NULL UNIQUE
);

-- 6. Shipping Method Dimension
CREATE TABLE dim_ShippingMethod (
    ShippingMethodSK INT IDENTITY(1,1) PRIMARY KEY,
    ShipMode VARCHAR(50) NOT NULL UNIQUE
);

-- Create Fact tables
-- 1. Sales Fact Table
CREATE TABLE fact_Sales (
    SalesFactSK INT IDENTITY(1,1) PRIMARY KEY,
    TransactionID INT NOT NULL,
    OrderID VARCHAR(50) NOT NULL,
    CustomerSK INT NOT NULL,
    ProductSK INT NOT NULL,
    LocationSK INT NOT NULL,
    OrderDateSK INT NOT NULL,
    ShipDateSK INT NOT NULL,
    PaymentMethodSK INT NOT NULL,
    ShippingMethodSK INT NOT NULL,
    Quantity INT NOT NULL,
    Discount DECIMAL(5, 2) NOT NULL,
    Sales DECIMAL(10, 2) NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    ShippingStatus VARCHAR(50) NOT NULL,
    FOREIGN KEY (CustomerSK) REFERENCES dim_Customer(CustomerSK),
    FOREIGN KEY (ProductSK) REFERENCES dim_Product(ProductSK),
    FOREIGN KEY (LocationSK) REFERENCES dim_Location(LocationSK),
    FOREIGN KEY (OrderDateSK) REFERENCES dim_Date(DateSK),
    FOREIGN KEY (ShipDateSK) REFERENCES dim_Date(DateSK),
    FOREIGN KEY (PaymentMethodSK) REFERENCES dim_PaymentMethod(PaymentMethodSK),
    FOREIGN KEY (ShippingMethodSK) REFERENCES dim_ShippingMethod(ShippingMethodSK)
);

-- 2. Customer Purchase Behavior Fact Table (conformed dimension with fact_Sales)
CREATE TABLE fact_CustomerPurchaseBehavior (
    BehaviorFactSK INT IDENTITY(1,1) PRIMARY KEY,
    CustomerSK INT NOT NULL,
    DateSK INT NOT NULL,           -- Last update date
    WineAmount INT NOT NULL,
    FruitAmount INT NOT NULL,
    MeatAmount INT NOT NULL,
    FishAmount INT NOT NULL,
    SweetAmount INT NOT NULL,
    GoldAmount INT NOT NULL,
    DealsCount INT NOT NULL,
    WebPurchaseCount INT NOT NULL,
    CatalogPurchaseCount INT NOT NULL,
    StorePurchaseCount INT NOT NULL,
    WebVisitCount INT NOT NULL,
    TotalSpend DECIMAL(10, 2) NOT NULL,  -- Calculated measure
    FOREIGN KEY (CustomerSK) REFERENCES dim_Customer(CustomerSK),
    FOREIGN KEY (DateSK) REFERENCES dim_Date(DateSK)
);