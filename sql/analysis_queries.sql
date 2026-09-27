-- ============================================================================
-- analysis_queries.sql — business questions answered in SQL
--
-- Each question is a single, runnable query. Run them all:
--   sqlite3 db/churn.db < sql/analysis_queries.sql
-- Or export every result set to CSV:
--   python scripts/export_query_results.py
-- ============================================================================

-- ===========================================================================
-- Q1 | q1_churn_overview | What is the overall churn rate, and how do churned vs retained customers differ?
SELECT
    COUNT(*)                                                    AS customers,
    SUM(exited)                                                 AS churned_customers,
    ROUND(SUM(exited) * 100.0 / COUNT(*), 1)                    AS churn_rate_pct,
    ROUND(AVG(CASE WHEN exited = 1 THEN tenure END), 1)         AS avg_tenure_churned,
    ROUND(AVG(CASE WHEN exited = 0 THEN tenure END), 1)         AS avg_tenure_retained,
    ROUND(AVG(CASE WHEN exited = 1 THEN credit_score END), 0)   AS avg_credit_churned,
    ROUND(AVG(CASE WHEN exited = 0 THEN credit_score END), 0)   AS avg_credit_retained,
    ROUND(AVG(CASE WHEN exited = 1 THEN balance END), 2)        AS avg_balance_churned,
    ROUND(AVG(CASE WHEN exited = 0 THEN balance END), 2)        AS avg_balance_retained,
    ROUND(AVG(CASE WHEN exited = 1 THEN age END), 1)            AS avg_age_churned,
    ROUND(AVG(CASE WHEN exited = 0 THEN age END), 1)            AS avg_age_retained
FROM customers;

-- ===========================================================================
-- Q2 | q2_churn_by_segment | Which customer segments have the highest churn?
SELECT 'Geography' AS segment_type, geography AS segment,
       COUNT(*) AS customers, ROUND(SUM(exited) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM customers GROUP BY geography
UNION ALL
SELECT 'Gender', gender, COUNT(*), ROUND(SUM(exited) * 100.0 / COUNT(*), 1)
FROM customers GROUP BY gender
UNION ALL
SELECT 'NumOfProducts', CAST(num_products AS TEXT), COUNT(*), ROUND(SUM(exited) * 100.0 / COUNT(*), 1)
FROM customers GROUP BY num_products
UNION ALL
SELECT 'AgeBand', age_band, COUNT(*), ROUND(SUM(exited) * 100.0 / COUNT(*), 1)
FROM customers GROUP BY age_band
UNION ALL
SELECT 'IsActiveMember', CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END,
       COUNT(*), ROUND(SUM(exited) * 100.0 / COUNT(*), 1)
FROM customers GROUP BY is_active
ORDER BY segment_type, churn_rate_pct DESC;

-- ===========================================================================
-- Q3 | q3_revenue_at_risk | How much deposit balance is at risk?
SELECT
    'Churned customers (deposits already walked out the door)' AS risk_group,
    COUNT(*)                          AS customers,
    ROUND(SUM(balance), 2)             AS balance_at_risk
FROM customers WHERE exited = 1
UNION ALL
SELECT
    'High-risk active: inactive members holding a single product',
    COUNT(*),
    ROUND(SUM(balance), 2)
FROM customers
WHERE exited = 0 AND is_active = 0 AND num_products = 1;

-- ===========================================================================
-- Q4 | q4_tenure_churn | How does churn vary with years of tenure?
SELECT
    tenure AS tenure_years,
    COUNT(*) AS customers,
    ROUND(SUM(exited) * 100.0 / COUNT(*), 1) AS churn_rate_pct
FROM customers
GROUP BY tenure
ORDER BY tenure;
