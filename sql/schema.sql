-- ============================================================================
-- schema.sql — DDL for the Bank Customer Churn SQLite warehouse
--
-- Staging holds the raw CSV; cleaning.sql builds the analytics table.
--
-- Run:  sqlite3 db/churn.db < sql/schema.sql
-- (scripts/load_to_sqlite.py runs this for you.)
-- ============================================================================

DROP TABLE IF EXISTS staging_telco;
CREATE TABLE staging_telco (
    row_number    INTEGER,
    customer_id   TEXT,
    surname       TEXT,
    credit_score  INTEGER,
    geography     TEXT,
    gender        TEXT,
    age           INTEGER,
    tenure        INTEGER,   -- years with the bank (0-10)
    balance       REAL,
    num_products  INTEGER,
    has_card      INTEGER,   -- 0/1
    is_active     INTEGER,   -- 0/1
    salary        REAL,
    exited        INTEGER    -- 1 = churned, 0 = retained
);

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id  TEXT PRIMARY KEY,
    geography    TEXT NOT NULL,   -- France / Germany / Spain
    gender       TEXT NOT NULL,
    age          INTEGER NOT NULL,
    age_band     TEXT NOT NULL,   -- <30 / 30-39 / 40-49 / 50-59 / 60+
    tenure       INTEGER NOT NULL,
    credit_score INTEGER NOT NULL,
    balance      REAL NOT NULL,
    num_products INTEGER NOT NULL,
    has_card     INTEGER NOT NULL,
    is_active    INTEGER NOT NULL,
    salary       REAL NOT NULL,
    exited       INTEGER NOT NULL -- 1 = churned, 0 = retained
);

CREATE INDEX IF NOT EXISTS idx_cust_exited    ON customers(exited);
CREATE INDEX IF NOT EXISTS idx_cust_geography ON customers(geography);
CREATE INDEX IF NOT EXISTS idx_cust_tenure    ON customers(tenure);
