USE FlipKart_EDW;
GO

-- Populate dim_Date with dates from 2010 to 2025
-- This is a common approach for pre-loading date dimensions
DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate DATE = '2025-12-31';

-- Temporary table to generate dates
WITH DateCTE AS (
    SELECT @StartDate AS FullDate
    UNION ALL
    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateCTE
    WHERE DATEADD(DAY, 1, FullDate) <= @EndDate
)

-- Insert generated dates into dim_Date
INSERT INTO dim_Date (
    DateSK, FullDate, DayOfWeek, DayName, DayOfMonth, DayOfYear,
    WeekOfYear, Month, MonthName, Quarter, QuarterName, Year, 
    IsWeekend, IsHoliday
)
SELECT
    CONVERT(INT, FORMAT(FullDate, 'yyyyMMdd')) AS DateSK,
    FullDate,
    DATEPART(WEEKDAY, FullDate) AS DayOfWeek,
    DATENAME(WEEKDAY, FullDate) AS DayName,
    DATEPART(DAY, FullDate) AS DayOfMonth,
    DATEPART(DAYOFYEAR, FullDate) AS DayOfYear,
    DATEPART(WEEK, FullDate) AS WeekOfYear,
    DATEPART(MONTH, FullDate) AS Month,
    DATENAME(MONTH, FullDate) AS MonthName,
    DATEPART(QUARTER, FullDate) AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, FullDate) AS VARCHAR(1)) AS QuarterName,
    DATEPART(YEAR, FullDate) AS Year,
    CASE WHEN DATEPART(WEEKDAY, FullDate) IN (1, 7) THEN 1 ELSE 0 END AS IsWeekend,
    CASE WHEN (MONTH(FullDate) = 1 AND DAY(FullDate) = 1) OR
              (MONTH(FullDate) = 7 AND DAY(FullDate) = 4) OR
              (MONTH(FullDate) = 12 AND DAY(FullDate) = 25)
         THEN 1 ELSE 0 END AS IsHoliday
FROM DateCTE
OPTION (MAXRECURSION 10000);
GO

-- Next, let's populate the smaller dimensions
-- Payment Methods dimension
INSERT INTO dim_PaymentMethod (PaymentMethodName)
SELECT DISTINCT payment_method
FROM stg_OrderDetails;

-- Shipping Methods dimension
INSERT INTO dim_ShippingMethod (ShipMode)
SELECT DISTINCT ship_mode
FROM stg_OrderDetails;

-- Now, let's implement SCD Type 2 logic for the Location dimension
INSERT INTO dim_Location (
    LocationID, Country, State, City, Region,
    EffectiveDate, ExpirationDate, IsCurrent
)
SELECT 
    l.location_id,
    l.country,
    l.state,
    l.city,
    -- Simple region derivation based on country
    CASE 
        WHEN l.country = 'USA' THEN 'North America'
        WHEN l.country IN ('UK', 'France', 'Germany', 'Italy', 'Spain') THEN 'Europe'
        WHEN l.country IN ('China', 'Japan', 'India') THEN 'Asia'
        ELSE 'Other'
    END AS Region,
    CONVERT(DATE, GETDATE()) AS EffectiveDate,  -- Current data is effective from today
    NULL AS ExpirationDate,                    -- No expiration for current data
    1 AS IsCurrent                             -- Current flag set to true
FROM (
    SELECT DISTINCT location_id, country, state, city
    FROM stg_Orders
) l;

-- Display the count of populated dimensions
SELECT 'dim_Date' AS Table_Name, COUNT(*) AS Row_Count FROM dim_Date
UNION ALL
SELECT 'dim_PaymentMethod', COUNT(*) FROM dim_PaymentMethod
UNION ALL
SELECT 'dim_ShippingMethod', COUNT(*) FROM dim_ShippingMethod
UNION ALL
SELECT 'dim_Location', COUNT(*) FROM dim_Location;