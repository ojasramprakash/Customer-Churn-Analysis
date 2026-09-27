-- ============================================================================
-- cleaning.sql — data quality checks + analytics table build
--
-- Run:  sqlite3 db/churn.db < sql/cleaning.sql
-- (scripts/load_to_sqlite.py runs schema.sql + this file for you.)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- A. DATA QUALITY CHECKS — every check below should return 0 problem rows
-- ----------------------------------------------------------------------------
SELECT 'null_customer_id'   AS check_name, COUNT(*) AS bad_rows FROM staging_telco WHERE customer_id IS NULL OR TRIM(customer_id) = ''
UNION ALL
SELECT 'duplicate_customer_id', (SELECT COUNT(*) FROM staging_telco) - (SELECT COUNT(DISTINCT customer_id) FROM staging_telco)
UNION ALL
SELECT 'bad_exited_flag',  COUNT(*) FROM staging_telco WHERE exited NOT IN (0, 1)
UNION ALL
SELECT 'bad_binary_flags', COUNT(*) FROM staging_telco WHERE has_card NOT IN (0, 1) OR is_active NOT IN (0, 1)
UNION ALL
SELECT 'negative_age',     COUNT(*) FROM staging_telco WHERE age < 0 OR age > 100
UNION ALL
SELECT 'negative_balance', COUNT(*) FROM staging_telco WHERE balance < 0
UNION ALL
SELECT 'tenure_out_of_range', COUNT(*) FROM staging_telco WHERE tenure < 0 OR tenure > 10;

-- ----------------------------------------------------------------------------
-- B. BUILD THE ANALYTICS TABLE
-- ----------------------------------------------------------------------------
INSERT INTO customers (
    customer_id, geography, gender, age, age_band, tenure,
    credit_score, balance, num_products, has_card, is_active, salary, exited
)
SELECT
    customer_id,
    geography,
    gender,
    age,
    CASE
        WHEN age < 30 THEN '<30'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        ELSE '60+'
    END AS age_band,
    tenure,
    credit_score,
    balance,
    num_products,
    has_card,
    is_active,
    salary,
    exited
FROM staging_telco;

-- C. Reconciliation.
SELECT 'staging_rows'   AS tbl, COUNT(*) AS n FROM staging_telco
UNION ALL
SELECT 'customers_rows', COUNT(*) FROM customers
UNION ALL
SELECT 'churned',       SUM(exited) FROM customers
UNION ALL
SELECT 'retained',      COUNT(*) - SUM(exited) FROM customers;
