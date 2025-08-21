USE SWIFTRIDE;

-- =====================================================
--  DIMENSION TABLES (SCD Type 2 where applicable)
-- =====================================================

-- Driver Dimension (Slowly Changing Dimension Type 2)
CREATE TABLE dim_drivers (
    driver_sk BIGINT NOT NULL,              -- Surrogate Key
    driver_id INT NOT NULL,                 -- Business Key
    driver_license VARCHAR(50) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    date_of_birth DATE,
    driver_rating DECIMAL(3,2),
    total_trips INT DEFAULT 0,
    vehicle_make VARCHAR(50),
    vehicle_model VARCHAR(50),
    vehicle_year INT,
    vehicle_license_plate VARCHAR(20),
    vehicle_type VARCHAR(30),               -- economy, premium, luxury
    driver_status VARCHAR(20),              -- active, inactive, suspended
    city_code VARCHAR(10),
    registration_date DATE,
    effective_start_date DATETIME2 DEFAULT SYSDATETIME(),
    effective_end_date DATETIME2 DEFAULT SYSDATETIME(),
    is_current BIT DEFAULT 1,
    created_at DATETIME DEFAULT SYSDATETIME(),
    updated_at DATETIME DEFAULT SYSDATETIME(),
    PRIMARY KEY (driver_sk)
);


-- Rider Dimension (SCD Type 2)
CREATE TABLE dim_riders (
    rider_sk BIGINT NOT NULL,               -- Surrogate Key
    rider_id INT NOT NULL,                  -- Business Key
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    date_of_birth DATE,
    rider_rating DECIMAL(3,2),
    total_trips INT DEFAULT 0,
    loyalty_tier VARCHAR(20),               -- bronze, silver, gold, platinum
    preferred_payment_method VARCHAR(30),
    rider_status VARCHAR(20),               -- active, inactive, suspended
    signup_date DATE,
    city_code VARCHAR(10),
    effective_start_date DATETIME DEFAULT SYSDATETIME(),
    effective_end_date DATETIME DEFAULT SYSDATETIME(),
    is_current BIT DEFAULT 1,
    created_at DATETIME DEFAULT SYSDATETIME(),
    updated_at DATETIME DEFAULT SYSDATETIME(),
    PRIMARY KEY (rider_sk)
);


-- Location Dimension
CREATE TABLE dim_locations (
    location_sk BIGINT NOT NULL,            -- Surrogate Key
    location_id VARCHAR(50) NOT NULL,       -- Business Key (lat_lng hash)
    address VARCHAR(500),
    street_name VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(20),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location_type VARCHAR(30),              -- pickup, dropoff, waypoint
    is_airport BIT DEFAULT 0,
    is_downtown BIT DEFAULT 1,
    zone_id VARCHAR(20),                    -- for surge pricing zones
    created_at DATETIME DEFAULT SYSDATETIME(),
    PRIMARY KEY (location_sk)
);


-- Time Dimension
CREATE TABLE dim_time (
    time_sk BIGINT NOT NULL,                -- Format: YYYYMMDDHH24MI
    full_date DATE,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week_of_year INT,
    day_of_month INT,
    day_of_year INT,
    day_of_week INT,                        -- 1=Monday, 7=Sunday
    day_name VARCHAR(20),
    hour_24 INT,
    hour_12 INT,
    am_pm VARCHAR(2),
    minute INT,
    is_weekend BIT,
    is_holiday BIT,
    holiday_name VARCHAR(100),
    business_hours VARCHAR(20),             -- morning, afternoon, evening, night
    rush_hour VARCHAR(20),                  -- morning_rush, evening_rush, off_peak
    PRIMARY KEY (time_sk)
);


-- Payment Method Dimension
CREATE TABLE dim_payment_methods (
    payment_method_sk BIGINT NOT NULL,
    payment_method_id INT NOT NULL,
    payment_type VARCHAR(30),               -- credit_card, debit_card, digital_wallet, cash
    provider VARCHAR(50),                   -- visa, mastercard, paypal, apple_pay, etc.
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT SYSDATETIME(),
    PRIMARY KEY (payment_method_sk)
);


-- Trip Status Dimension
CREATE TABLE dim_trip_status (
    trip_status_sk BIGINT NOT NULL,
    status_code VARCHAR(20) NOT NULL,
    status_name VARCHAR(50),
    status_description VARCHAR(200),
    is_completed BIT DEFAULT 0,
    is_cancelled BIT DEFAULT 0,
    PRIMARY KEY (trip_status_sk)
);


-- =====================================================
--  FACT TABLES
-- =====================================================


-- Main Trip Fact Table
CREATE TABLE fact_trips (
    trip_sk BIGINT NOT NULL,                -- Surrogate Key
    trip_id VARCHAR(50) NOT NULL,           -- Business Key
    

-- Foreign Keys to Dimensions
    driver_sk BIGINT,
    rider_sk BIGINT,
    pickup_location_sk BIGINT,
    dropoff_location_sk BIGINT,
    pickup_time_sk BIGINT,
    dropoff_time_sk BIGINT,
    trip_status_sk BIGINT,
    

-- Trip Metrics
    requested_timestamp DATETIME,
    pickup_timestamp DATETIME,
    dropoff_timestamp DATETIME,
    cancelled_timestamp DATETIME,
 
 
-- Distance and Duration
    estimated_distance_miles DECIMAL(8,2),
    actual_distance_miles DECIMAL(8,2),
    estimated_duration_minutes INT,
    actual_duration_minutes INT,
    wait_time_minutes INT,                  -- time rider waited for pickup
    

-- Financial Metrics
    base_fare DECIMAL(10,2),
    distance_fare DECIMAL(10,2),
    time_fare DECIMAL(10,2),
    surge_multiplier DECIMAL(4,2) DEFAULT 1.0,
    surge_fare DECIMAL(10,2),
    tolls_fare DECIMAL(10,2),
    tips_amount DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    total_fare DECIMAL(10,2),
    driver_earnings DECIMAL(10,2),
    company_commission DECIMAL(10,2),
    

-- Ratings
    rider_rating_given DECIMAL(3,2),        -- rating rider gave to driver
    driver_rating_given DECIMAL(3,2),       -- rating driver gave to rider
   
   
-- Trip Characteristics
    trip_type VARCHAR(30),                  -- standard, pool, premium, scheduled
    passenger_count INT DEFAULT 1,
    special_requests VARCHAR(500),          -- pet, wheelchair, etc.
  
  
-- System Fields
created_at DATETIME DEFAULT GETDATE(),
updated_at DATETIME DEFAULT GETDATE(),

PRIMARY KEY (trip_sk),
FOREIGN KEY (driver_sk) REFERENCES dim_drivers(driver_sk),
FOREIGN KEY (rider_sk) REFERENCES dim_riders(rider_sk),
FOREIGN KEY (pickup_location_sk) REFERENCES dim_locations(location_sk),
FOREIGN KEY (dropoff_location_sk) REFERENCES dim_locations(location_sk),
FOREIGN KEY (pickup_time_sk) REFERENCES dim_time(time_sk),
FOREIGN KEY (dropoff_time_sk) REFERENCES dim_time(time_sk),
FOREIGN KEY (trip_status_sk) REFERENCES dim_trip_status(trip_status_sk)
);


-- Payment Fact Table
CREATE TABLE fact_payments (
    payment_sk BIGINT NOT NULL,
    payment_id VARCHAR(50) NOT NULL,
    trip_sk BIGINT NOT NULL,
    payment_method_sk BIGINT,
    payment_time_sk BIGINT,
    

-- Payment Details
    payment_amount DECIMAL(10,2),
    processing_fee DECIMAL(10,2),
    payment_status VARCHAR(20),             -- pending, completed, failed, refunded
    transaction_id VARCHAR(100),
    payment_timestamp TIMESTAMP,
    

-- System Fields
created_at DATETIME DEFAULT GETDATE(),

PRIMARY KEY (payment_sk),
FOREIGN KEY (trip_sk) REFERENCES fact_trips(trip_sk),
FOREIGN KEY (payment_method_sk) REFERENCES dim_payment_methods(payment_method_sk),
FOREIGN KEY (payment_time_sk) REFERENCES dim_time(time_sk)
);


-- Driver Activity Fact (Daily Aggregated)
CREATE TABLE fact_driver_daily (
    driver_daily_sk BIGINT NOT NULL,
    driver_sk BIGINT NOT NULL,
    activity_date DATE,
    city_code VARCHAR(10),

    
 -- Activity Metrics
    hours_online DECIMAL(5,2),
    hours_driving DECIMAL(5,2),
    total_trips INT,
    completed_trips INT,
    cancelled_trips INT,
    

-- Financial Metrics
    gross_earnings DECIMAL(10,2),
    net_earnings DECIMAL(10,2),
    total_miles_driven DECIMAL(8,2),
    
-- Performance Metrics
    acceptance_rate DECIMAL(5,2),           -- % of trip requests accepted
    cancellation_rate DECIMAL(5,2),        -- % of accepted trips cancelled
    average_rating DECIMAL(3,2),
 
 
-- System Fields
   created_at DATETIME DEFAULT GETDATE(),

PRIMARY KEY (driver_daily_sk),
FOREIGN KEY (driver_sk) REFERENCES dim_drivers(driver_sk)
);


-- =====================================================
-- 3. STAGING TABLES (for ETL processes)
-- =====================================================

-- Raw trip data from application logs
CREATE TABLE staging_raw_trips (
    trip_id VARCHAR(50),
    driver_id INT,
    rider_id INT,
    pickup_lat DECIMAL(10,8),
    pickup_lng DECIMAL(11,8),
    dropoff_lat DECIMAL(10,8),
    dropoff_lng DECIMAL(11,8),
    requested_at DATETIME2,
    pickup_at DATETIME2,
    dropoff_at DATETIME2,
    status VARCHAR(20),
    fare_breakdown NVARCHAR(MAX) CHECK (ISJSON(fare_breakdown) = 1), -- JSON field
    raw_data NVARCHAR(MAX) CHECK (ISJSON(raw_data) = 1),             -- JSON field
    ingestion_timestamp DATETIME2 DEFAULT GETDATE(),
    processed BIT DEFAULT 0,
    ingestion_date DATE
);



-- =====================================================
--  INDEXES FOR PERFORMANCE
-- =====================================================

-- Fact table indexes
CREATE INDEX idx_fact_trips_driver ON fact_trips(driver_sk);
CREATE INDEX idx_fact_trips_rider ON fact_trips(rider_sk);
CREATE INDEX idx_fact_trips_pickup_time ON fact_trips(pickup_timestamp);
CREATE INDEX idx_fact_trips_total_fare ON fact_trips(total_fare);


-- Dimension table indexes
CREATE INDEX idx_dim_drivers_business_key ON dim_drivers(driver_id);
CREATE INDEX idx_dim_riders_business_key ON dim_riders(rider_id);
CREATE INDEX idx_dim_locations_coordinates ON dim_locations(latitude, longitude);



-- =====================================================
--  VIEWS BUSINESS QUERIES
-- =====================================================

-- Trip Summary View (SQL Server syntax)

GO 
CREATE VIEW v_trip_summary AS
SELECT 
    ft.trip_id,
    dd.first_name + ' ' + dd.last_name AS driver_name,
    dr.first_name + ' ' + dr.last_name AS rider_name,
    pl.address AS pickup_address,
    dl.address AS dropoff_address,
    ft.pickup_timestamp,
    ft.dropoff_timestamp,
    ft.actual_duration_minutes,
    ft.actual_distance_miles,
    ft.total_fare,
    ft.rider_rating_given,
    ft.driver_rating_given
FROM fact_trips ft
INNER JOIN dim_drivers dd ON ft.driver_sk = dd.driver_sk AND dd.is_current = 1
INNER JOIN dim_riders dr ON ft.rider_sk = dr.rider_sk AND dr.is_current = 1
INNER JOIN dim_locations pl ON ft.pickup_location_sk = pl.location_sk
INNER JOIN dim_locations dl ON ft.dropoff_location_sk = dl.location_sk;
GO


-- Daily Revenue Summary View (SQL Server syntax)
GO
CREATE VIEW v_daily_revenue AS
SELECT 
    CAST(ft.pickup_timestamp AS DATE) AS trip_date,
    pl.city,
    COUNT(*) AS total_trips,
    SUM(ft.total_fare) AS total_revenue,
    AVG(ft.total_fare) AS avg_fare,
    SUM(ft.driver_earnings) AS driver_earnings,
    SUM(ft.company_commission) AS company_revenue
FROM fact_trips ft
INNER JOIN dim_locations pl ON ft.pickup_location_sk = pl.location_sk
WHERE ft.trip_status_sk = (SELECT trip_status_sk FROM dim_trip_status WHERE status_code = 'COMPLETED')
GROUP BY CAST(ft.pickup_timestamp AS DATE), pl.city;
GO



-- Top Performing Drivers View
GO
CREATE VIEW v_top_drivers AS
SELECT TOP 100
    dd.first_name + ' ' + dd.last_name AS driver_name,
    dd.city_code,
    dd.driver_rating,
    dd.total_trips,
    fdd.average_rating AS recent_rating,
    fdd.gross_earnings AS monthly_earnings,
    fdd.acceptance_rate
FROM dim_drivers dd
INNER JOIN fact_driver_daily fdd ON dd.driver_sk = fdd.driver_sk
WHERE dd.is_current = 1
  AND fdd.activity_date >= DATEADD(MONTH, -1, GETDATE())
ORDER BY dd.driver_rating DESC, dd.total_trips DESC;
GO


-- City Performance Summary
GO
CREATE VIEW v_city_performance AS
SELECT 
    pl.city,
    COUNT(DISTINCT ft.trip_id) AS total_trips,
    COUNT(DISTINCT ft.driver_sk) AS active_drivers,
    COUNT(DISTINCT ft.rider_sk) AS active_riders,
    AVG(ft.total_fare) AS avg_fare,
    AVG(ft.actual_duration_minutes) AS avg_trip_duration,
    SUM(CASE WHEN ft.rider_rating_given >= 4.0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS rider_satisfaction_rate
FROM fact_trips ft
INNER JOIN dim_locations pl ON ft.pickup_location_sk = pl.location_sk
WHERE ft.pickup_timestamp >= DATEADD(MONTH, -1, GETDATE())
GROUP BY pl.city;
GO


