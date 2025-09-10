# SWIFTRIDE-
# SwiftRide Data Warehouse

A comprehensive data warehouse solution for ridesharing analytics, built using dimensional modeling principles to support business intelligence and reporting needs.

## Overview

SwiftRide Data Warehouse is designed to handle large-scale ridesharing data with a focus on:
- **Trip Analytics**: Complete trip lifecycle tracking and analysis
- **Driver Performance**: Comprehensive driver metrics and KPIs
- **Revenue Optimization**: Financial analytics and commission tracking
- **Customer Insights**: Rider behavior and satisfaction analysis
- **Operational Intelligence**: Real-time and historical operational metrics

## Architecture

### Dimensional Model Design
The warehouse follows a **star schema** approach with **Slowly Changing Dimensions (SCD Type 2)** for historical tracking:

#### Dimension Tables
- **`dim_drivers`** - Driver information with SCD Type 2 for historical changes
- **`dim_riders`** - Rider profiles with loyalty and preference tracking
- **`dim_locations`** - Geographic data with zone and area classifications
- **`dim_time`** - Complete time dimension with business calendar
- **`dim_payment_methods`** - Payment type and provider information
- **`dim_trip_status`** - Trip lifecycle status definitions

#### Fact Tables
- **`fact_trips`** - Core trip transactions and metrics
- **`fact_payments`** - Payment processing and financial transactions
- **`fact_driver_daily`** - Daily aggregated driver performance metrics

#### Staging Layer
- **`staging_raw_trips`** - Raw data ingestion from operational systems

##  Database Schema

### Key Features
- **Surrogate Keys**: All dimensions use surrogate keys for better performance
- **Business Keys**: Maintained for data lineage and integration
- **JSON Support**: Flexible schema for raw data and fare breakdowns
- **Temporal Tracking**: Effective date ranges for historical analysis
- **Performance Optimization**: Strategic indexing for common query patterns

### Data Types & Constraints
- Decimal precision for financial calculations
- JSON validation for semi-structured data
- Referential integrity with foreign key constraints
- Default values and timestamps for audit trails

##  Analytics Capabilities

### Pre-built Views
1. **`v_trip_summary`** - Complete trip details with driver/rider information
2. **`v_daily_revenue`** - Revenue analytics by date and city
3. **`v_top_drivers`** - Driver performance rankings and metrics
4. **`v_city_performance`** - Geographic performance analysis

### Key Metrics Supported
- **Financial KPIs**: Revenue, commissions, driver earnings, surge pricing
- **Operational Metrics**: Trip completion rates, wait times, distances
- **Quality Metrics**: Driver/rider ratings, satisfaction scores
- **Performance Indicators**: Acceptance rates, cancellation rates, utilization

##  Getting Started

### Prerequisites
- SQL Server 2016+ (uses DATETIME2, JSON support)
- Sufficient storage for historical data retention
- ETL/ELT tools for data pipeline integration

### Installation
1. Create the SWIFTRIDE database
2. Execute the SQL script to create all tables and views
3. Set up your ETL processes to populate staging tables
4. Configure data refresh schedules

```sql
-- Create the database
CREATE DATABASE SWIFTRIDE;
GO

-- Execute the schema creation script
USE SWIFTRIDE;
-- Run SWIFTRIDE.SQL.sql
```

## Sample Queries

### Top Performing Cities
```sql
SELECT * FROM v_city_performance
ORDER BY total_trips DESC;
```

### Revenue Trends
```sql
SELECT trip_date, SUM(total_revenue) as daily_revenue
FROM v_daily_revenue
GROUP BY trip_date
ORDER BY trip_date DESC;
```

### Driver Performance Analysis
```sql
SELECT * FROM v_top_drivers
WHERE monthly_earnings > 5000
ORDER BY recent_rating DESC;
```

##  Performance Optimization

### Indexing Strategy
- **Fact Table Indexes**: Foreign keys, timestamps, and frequently filtered columns
- **Dimension Indexes**: Business keys and commonly joined attributes
- **Composite Indexes**: Multi-column indexes for complex queries

### Query Optimization Tips
- Use surrogate keys for joins
- Leverage time dimension for date range queries
- Utilize materialized views for frequent aggregations
- Implement partitioning for large fact tables

##  Data Pipeline Integration

### Staging Process
1. **Raw Data Ingestion**: Load operational data into `staging_raw_trips`
2. **Data Validation**: Verify data quality and completeness
3. **Dimension Loading**: Populate dimension tables with SCD logic
4. **Fact Loading**: Transform and load fact table data
5. **Aggregation**: Update daily summary tables

### ETL Considerations
- Handle late-arriving data with appropriate business logic
- Implement error handling and data quality checks
- Schedule regular dimension updates for SCD processing
- Monitor data freshness and pipeline performance

## 🔍 Monitoring & Maintenance

### Key Monitoring Points
- Data freshness timestamps
- Row counts and growth trends
- Query performance metrics
- ETL process completion status

### Maintenance Tasks
- Regular index maintenance and statistics updates
- Historical data archival policies
- Backup and recovery procedures
- Performance tuning and optimization reviews

##  Business Use Cases

### Executive Dashboards
- Revenue and profitability analysis
- Market share and growth metrics
- Operational efficiency indicators

### Operations Management
- Driver utilization and performance
- Fleet optimization insights
- Service quality monitoring

### Customer Analytics
- Rider behavior and preferences
- Loyalty program effectiveness
- Demand forecasting

### Financial Analysis
- Commission optimization
- Pricing strategy analysis
- Cost structure evaluation



