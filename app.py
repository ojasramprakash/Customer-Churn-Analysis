"""Streamlit dashboard for the Customer Churn Analysis project.

Run:  streamlit run app.py
Data: db/churn.db (build it with `python scripts/load_to_sqlite.py`)
"""

from pathlib import Path
import sqlite3

import pandas as pd
import streamlit as st

DB = Path(__file__).parent / "db" / "churn.db"

st.set_page_config(page_title="Customer Churn Dashboard", layout="wide")


@st.cache_data
def query(sql: str) -> pd.DataFrame:
    with sqlite3.connect(DB) as con:
        return pd.read_sql(sql, con)


if not DB.exists():
    st.error("Database not found — run `python scripts/load_to_sqlite.py` first.")
    st.stop()

st.title("Customer Churn Dashboard")
st.caption("European retail bank · 10,000 customers · France / Germany / Spain")

# -- KPI cards -----------------------------------------------------------------
kpi = query(
    "SELECT COUNT(*) AS customers, "
    "SUM(exited) AS churned, "
    "ROUND(SUM(exited) * 100.0 / COUNT(*), 1) AS churn_rate, "
    "ROUND(SUM(CASE WHEN exited = 1 THEN balance ELSE 0 END), 0) AS balance_lost "
    "FROM customers"
).iloc[0]
c1, c2, c3, c4 = st.columns(4)
c1.metric("Customers", f"{kpi['customers']:,}")
c2.metric("Churn rate", f"{kpi['churn_rate']:.1f}%")
c3.metric("Churned customers", f"{kpi['churned']:,}")
c4.metric("Deposits lost to churn", f"${kpi['balance_lost']:,.0f}")

# -- Churn drivers --------------------------------------------------------------
st.subheader("Churn rate by segment")
seg_choice = st.selectbox(
    "Segment",
    ["Geography", "Gender", "NumOfProducts", "AgeBand", "IsActiveMember"],
)
# NOTE: segment breakdowns below are computed directly for clarity
seg_map = {
    "Geography": "geography",
    "Gender": "gender",
    "NumOfProducts": "CAST(num_products AS TEXT)",
    "AgeBand": "age_band",
    "IsActiveMember": "CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END",
}
col_expr = seg_map[seg_choice]
seg_df = query(
    f"SELECT {col_expr} AS segment, COUNT(*) AS customers, "
    f"ROUND(SUM(exited) * 100.0 / COUNT(*), 1) AS churn_rate_pct "
    f"FROM customers GROUP BY segment ORDER BY churn_rate_pct DESC"
)
st.bar_chart(seg_df.set_index("segment")["churn_rate_pct"])
st.caption("Germany (32.4%), ages 50–59 (56.0%), and holders of 3+ products "
           "(83–100%) churn far above the 20.4% average.")

# -- Tenure ----------------------------------------------------------------------
st.subheader("Churn rate by years of tenure")
ten = query(
    "SELECT tenure AS years, ROUND(SUM(exited) * 100.0 / COUNT(*), 1) AS churn_rate_pct "
    "FROM customers GROUP BY tenure ORDER BY tenure"
)
st.bar_chart(ten.set_index("years")["churn_rate_pct"])
st.caption("Churn is highest in the first year (23%) — onboarding is the "
           "moment that matters most.")

# -- Revenue at risk ---------------------------------------------------------------
st.subheader("Balance at risk")
st.dataframe(
    query(
        "SELECT 'Churned customers (deposits already gone)' AS risk_group, "
        "COUNT(*) AS customers, ROUND(SUM(balance), 2) AS balance_at_risk "
        "FROM customers WHERE exited = 1 "
        "UNION ALL "
        "SELECT 'High-risk active: inactive members with a single product', "
        "COUNT(*), ROUND(SUM(balance), 2) FROM customers "
        "WHERE exited = 0 AND is_active = 0 AND num_products = 1"
    ),
    use_container_width=True,
)

# -- Recommendations ---------------------------------------------------------------
st.subheader("Retention recommendations")
st.markdown(
    """
1. **Win the first year** — churn peaks at 23% in year 0. Trigger a structured
   onboarding journey (check-ins at 30/90/180 days).
2. **Get every customer to a second product** — 2-product holders churn at just
   7.6% vs 27.7% for single-product holders. But **stop pushing at two**:
   3-product holders churn at 83% — cross-sell past the second product looks
   forced and backfires.
3. **Re-engage inactives** — inactive members churn at 26.9% vs 14.3% for
   actives, and 1,597 inactive single-product members still hold **$162.5M**
   in deposits.
4. **Investigate Germany** — 32.4% churn, roughly double France/Spain.
   Pricing, service, or competitor issue worth a dedicated review.
5. **Watch the 50–59 cohort** — 56% churn, the highest of any age band.
"""
)

st.divider()
st.caption("All figures come from the SQL analysis in `sql/analysis_queries.sql`; "
           "result sets are saved under `outputs/`.")
