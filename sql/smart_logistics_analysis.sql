-- ================================================================
-- Smart Logistics Delay Analysis – SQL‑First Pipeline
-- Author: Senior Data Analyst
-- Purpose: Data profiling, feature engineering, risk scoring
-- ================================================================

-- 1. SCHEMA & DATA LOADING
-- --------------------------------
-- If loading from CSV (PostgreSQL example):
-- COPY smart_logistics FROM 'smart_logistics_dataset.csv' DELIMITER ',' CSV HEADER;

-- Create table (if not exists)
CREATE TABLE IF NOT EXISTS smart_logistics (
    timestamp           TIMESTAMP,
    asset_id            VARCHAR(50),
    latitude            NUMERIC(10,6),
    longitude           NUMERIC(10,6),
    inventory_level     INTEGER,
    shipment_status     VARCHAR(50),
    temperature         NUMERIC(5,2),
    humidity            NUMERIC(5,2),
    traffic_status      VARCHAR(50),
    waiting_time        INTEGER,
    user_transaction_amount NUMERIC(10,2),
    user_purchase_frequency INTEGER,
    logistics_delay_reason VARCHAR(50),
    asset_utilization   NUMERIC(5,1),
    demand_forecast     INTEGER,
    logistics_delay     INTEGER
);

-- ================================================================
-- 2. EXPLORATORY DATA ANALYSIS (EDA)
-- ================================================================

-- 2.1 Basic Record Count & Time Range
SELECT 
    COUNT(*) AS total_records,
    MIN(timestamp) AS first_record,
    MAX(timestamp) AS last_record,
    COUNT(DISTINCT asset_id) AS total_assets
FROM smart_logistics;

-- 2.2 Target Variable Distribution
SELECT 
    logistics_delay,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM smart_logistics
GROUP BY logistics_delay;

-- 2.3 Status Distribution
SELECT 
    shipment_status,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct
FROM smart_logistics
GROUP BY shipment_status
ORDER BY count DESC;

-- 2.4 Delay Rate by Traffic Status (Key Insight)
SELECT 
    traffic_status,
    COUNT(*) AS total_trips,
    SUM(logistics_delay) AS delayed,
    ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS delay_rate_pct
FROM smart_logistics
GROUP BY traffic_status
ORDER BY delay_rate_pct DESC;

-- 2.5 Top Delay Reasons
SELECT 
    logistics_delay_reason,
    COUNT(*) AS delay_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM smart_logistics WHERE logistics_delay = 1), 2) AS pct_of_delays
FROM smart_logistics
WHERE logistics_delay = 1
GROUP BY logistics_delay_reason
ORDER BY delay_count DESC;

-- 2.6 Asset Performance (Bottom 5)
SELECT 
    asset_id,
    COUNT(*) AS trips,
    SUM(logistics_delay) AS delays,
    ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS delay_rate
FROM smart_logistics
GROUP BY asset_id
ORDER BY delay_rate DESC
LIMIT 5;

-- 2.7 Monthly Trend
SELECT 
    EXTRACT(YEAR FROM timestamp) AS year,
    EXTRACT(MONTH FROM timestamp) AS month,
    COUNT(*) AS trips,
    ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS delay_rate
FROM smart_logistics
GROUP BY year, month
ORDER BY year, month;

-- 2.8 Environmental Impact (binned)
SELECT 
    CASE 
        WHEN temperature < 20 THEN 'Below 20°C'
        WHEN temperature BETWEEN 20 AND 26 THEN '20-26°C (Optimal)'
        ELSE 'Above 26°C'
    END AS temp_bucket,
    ROUND(AVG(logistics_delay) * 100, 2) AS delay_rate_pct,
    COUNT(*) AS records
FROM smart_logistics
GROUP BY temp_bucket
ORDER BY delay_rate_pct DESC;

-- ================================================================
-- 3. FEATURE ENGINEERING (SQL View)
-- ================================================================

CREATE OR REPLACE VIEW logistics_features AS
WITH base AS (
    SELECT 
        *,
        -- Time features
        EXTRACT(YEAR FROM timestamp) AS year,
        EXTRACT(MONTH FROM timestamp) AS month,
        EXTRACT(DAY FROM timestamp) AS day,
        EXTRACT(HOUR FROM timestamp) AS hour,
        EXTRACT(DOW FROM timestamp) AS day_of_week,  -- 0=Sunday, 6=Saturday
        -- Season (using month)
        CASE 
            WHEN EXTRACT(MONTH FROM timestamp) IN (12,1,2) THEN 0  -- Winter
            WHEN EXTRACT(MONTH FROM timestamp) IN (3,4,5) THEN 1   -- Spring
            WHEN EXTRACT(MONTH FROM timestamp) IN (6,7,8) THEN 2   -- Summer
            ELSE 3                                                  -- Fall
        END AS season,
        -- Flag: is weekend?
        CASE WHEN EXTRACT(DOW FROM timestamp) IN (0,6) THEN 1 ELSE 0 END AS is_weekend,
        -- Categorical encodings (via CASE)
        CASE shipment_status
            WHEN 'In Transit' THEN 0
            WHEN 'Delivered' THEN 1
            WHEN 'Delayed' THEN 2
            ELSE 3
        END AS shipment_status_enc,
        CASE traffic_status
            WHEN 'Clear' THEN 0
            WHEN 'Detour' THEN 1
            WHEN 'Heavy' THEN 2
            ELSE 3
        END AS traffic_status_enc,
        CASE logistics_delay_reason
            WHEN 'None' THEN 0
            WHEN 'Weather' THEN 1
            WHEN 'Traffic' THEN 2
            WHEN 'Mechanical Failure' THEN 3
            ELSE 4
        END AS delay_reason_enc
    FROM smart_logistics
)
SELECT 
    *,
    -- Derived interactions (for risk scoring)
    (CASE WHEN traffic_status = 'Heavy' THEN 1 ELSE 0 END) AS heavy_traffic_flag,
    (CASE WHEN humidity > 75 THEN 1 ELSE 0 END) AS high_humidity_flag,
    (CASE WHEN waiting_time > 45 THEN 1 ELSE 0 END) AS long_wait_flag,
    (asset_utilization / 100.0) AS utilization_ratio
FROM base;

-- ================================================================
-- 4. BUILD A RISK SCORE (SIMULATED MODEL IN SQL)
-- ================================================================
-- Based on the feature importance we found in Python, we can create
-- a weighted risk score that ranks shipments by delay likelihood.

CREATE OR REPLACE VIEW delay_risk_scores AS
WITH weights AS (
    SELECT 
        -- These weights approximate the coefficients from our XGBoost model
        0.19 AS traffic_weight,
        0.17 AS wait_weight,
        0.15 AS util_weight,
        0.12 AS temp_weight,
        0.10 AS humidity_weight,
        0.09 AS inv_weight,
        0.05 AS freq_weight,
        0.04 AS forecast_weight
),
scaled_features AS (
    SELECT 
        *,
        -- Min‑max scaling emulation (using 5th and 95th percentiles as bounds)
        -- For production, use actual saved scaling parameters
        (waiting_time - 10.0) / 50.0 AS scaled_wait,
        (asset_utilization - 50.0) / 40.0 AS scaled_util,
        (temperature - 18.0) / 12.0 AS scaled_temp,
        (humidity - 50.0) / 30.0 AS scaled_humid,
        (inventory_level - 100.0) / 400.0 AS scaled_inv,
        (user_purchase_frequency - 1.0) / 9.0 AS scaled_freq,
        (demand_forecast - 100.0) / 200.0 AS scaled_forecast
    FROM logistics_features
)
SELECT 
    f.*,
    ROUND(
        0.19 * f.traffic_status_enc + 
        0.17 * sf.scaled_wait +
        0.15 * sf.scaled_util +
        0.12 * sf.scaled_temp +
        0.10 * sf.scaled_humid +
        0.09 * sf.scaled_inv +
        0.05 * sf.scaled_freq +
        0.04 * sf.scaled_forecast
        , 4) AS risk_score,
    -- Risk bucket for easy reporting
    CASE 
        WHEN 0.19 * f.traffic_status_enc + 0.17 * sf.scaled_wait + 0.15 * sf.scaled_util > 0.5 
            THEN 'High Risk'
        WHEN 0.19 * f.traffic_status_enc + 0.17 * sf.scaled_wait > 0.3 
            THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM logistics_features f
JOIN scaled_features sf ON f.timestamp = sf.timestamp AND f.asset_id = sf.asset_id
CROSS JOIN weights;

-- ================================================================
-- 5. ACTIONABLE BUSINESS INSIGHTS (QUERIES)
-- ================================================================

-- 5.1 High‑Risk Shipments (next 24h simulation)
SELECT 
    asset_id,
    timestamp,
    risk_score,
    risk_category,
    traffic_status,
    waiting_time,
    temperature,
    humidity
FROM delay_risk_scores
WHERE risk_category = 'High Risk'
ORDER BY risk_score DESC
LIMIT 20;

-- 5.2 Operational Summary (KPI dashboard)
WITH asset_stats AS (
    SELECT 
        asset_id,
        COUNT(*) AS trips,
        ROUND(AVG(waiting_time), 1) AS avg_wait_min,
        ROUND(AVG(asset_utilization), 1) AS avg_util_pct,
        ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS delay_rate,
        ROW_NUMBER() OVER (ORDER BY SUM(logistics_delay) / COUNT(*) DESC) AS risk_rank
    FROM smart_logistics
    GROUP BY asset_id
)
SELECT 
    *,
    CASE WHEN risk_rank <= 3 THEN 'Needs Maintenance' ELSE 'Good' END AS maintenance_priority
FROM asset_stats
ORDER BY delay_rate DESC;

-- 5.3 Monthly Load & Delay Forecast
SELECT 
    month,
    COUNT(*) AS trips,
    ROUND(AVG(demand_forecast), 2) AS avg_forecast,
    ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS actual_delay_rate,
    -- Simple moving average for trend
    ROUND(AVG(100.0 * SUM(logistics_delay) / COUNT(*)) OVER (
        ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS ma3_delay_trend
FROM smart_logistics
GROUP BY month
ORDER BY month;

-- 5.4 Root‑Cause Analysis: High Humidity + Heavy Traffic
SELECT 
    CASE WHEN humidity > 75 AND traffic_status = 'Heavy' THEN 'High Humidity + Heavy Traffic' 
         WHEN traffic_status = 'Heavy' THEN 'Heavy Traffic Only'
         WHEN humidity > 75 THEN 'High Humidity Only'
         ELSE 'None'
    END AS combo_condition,
    COUNT(*) AS occurrences,
    ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS delay_rate
FROM smart_logistics
GROUP BY combo_condition
ORDER BY delay_rate DESC;

-- 5.5 Asset Utilization vs. Delay (Low Utilization = More Delays?)
SELECT 
    CASE 
        WHEN asset_utilization < 70 THEN 'Underutilized (<70%)'
        WHEN asset_utilization BETWEEN 70 AND 85 THEN 'Normal (70-85%)'
        ELSE 'Overutilized (>85%)'
    END AS util_bucket,
    COUNT(*) AS trips,
    ROUND(AVG(waiting_time), 1) AS avg_wait,
    ROUND(100.0 * SUM(logistics_delay) / COUNT(*), 2) AS delay_rate
FROM smart_logistics
GROUP BY util_bucket
ORDER BY delay_rate DESC;

-- ================================================================
-- 6. FINAL PREP TABLE FOR PYTHON MODELING
-- ================================================================
-- Export this view to CSV or feed directly into Python

CREATE OR REPLACE VIEW model_ready_data AS
SELECT 
    timestamp,
    asset_id,
    latitude,
    longitude,
    inventory_level,
    temperature,
    humidity,
    waiting_time,
    user_transaction_amount,
    user_purchase_frequency,
    asset_utilization,
    demand_forecast,
    -- encoded features
    shipment_status_enc,
    traffic_status_enc,
    delay_reason_enc,
    month,
    hour,
    day_of_week,
    season,
    is_weekend,
    heavy_traffic_flag,
    high_humidity_flag,
    long_wait_flag,
    logistics_delay  -- target
FROM logistics_features;

-- ================================================================
-- 7. EXPORT TO CSV (PostgreSQL example)
-- ================================================================
-- \COPY (SELECT * FROM model_ready_data) TO 'model_ready_data.csv' DELIMITER ',' CSV HEADER;

-- ================================================================
-- 8. PERFORMANCE OPTIMIZATION (Indexes)
-- ================================================================

CREATE INDEX idx_logistics_timestamp ON smart_logistics(timestamp);
CREATE INDEX idx_logistics_asset ON smart_logistics(asset_id);
CREATE INDEX idx_logistics_traffic ON smart_logistics(traffic_status);
CREATE INDEX idx_logistics_delay ON smart_logistics(logistics_delay);

-- ================================================================
-- END OF SQL SCRIPT
-- ================================================================