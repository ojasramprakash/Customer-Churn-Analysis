# Customer Churn Analysis — Bank Customer Churn

End-to-end SQL + Streamlit churn analysis on **10,000 customers** of a European
retail bank (France / Germany / Spain).

## Business questions

1. **Churn rate & drivers** — what is overall churn, and how do churned vs retained customers differ?
2. **High-risk segments** — which customer segments churn the most?
3. **Revenue at risk** — how much deposit balance has churned or is at risk?
4. **Retention recommendations** — what should the bank do?

## Key findings

| Question | Finding |
|---|---|
| Churn rate | **20.4%** — 2,037 of 10,000 customers churned |
| Drivers | Churned customers are **older (44.8 vs 37.4 yrs)**, hold **higher balances ($91.1K vs $72.7K)**, and score slightly lower on credit (645 vs 652). Tenure is nearly identical (4.9 vs 5.0 yrs) — churn is *not* about how long they've stayed |
| Highest-risk segments | **Ages 50–59: 56.0%** churn · **Germany: 32.4%** (vs 16% France/Spain) · **3 products: 82.7%** · **4 products: 100%** (60 customers) · **Inactive members: 26.9%** vs 14.3% active · Female: 25.1% vs male 16.5% |
| Revenue at risk | Churned customers walked away with **$185.6M in deposits**; a further **$162.5M** sits with 1,597 high-risk actives (inactive, single-product holders) |
| Tenure | Churn peaks in **year 0 (23.0%)**, then flattens to 17–22% — onboarding is the moment that matters |

### The 2-product sweet spot

Customers with **2 products churn at just 7.6%**, vs 27.7% for single-product holders. But pushing past two backfires: 3-product holders churn at 82.7%. The retention play is "get everyone to a second product — then stop selling and start serving."

## Retention recommendations

1. **Win the first year** — structured onboarding (30/90/180-day check-ins); year-0 churn is 23%.
2. **Get every customer to a second product** — the single biggest lever (27.7% → 7.6%), but don't force a third.
3. **Re-engage inactives** — 26.9% churn vs 14.3%; $162.5M of their deposits is still on the books.
4. **Investigate Germany** — 32.4% churn, ~2× France/Spain; pricing, service, or competitor issue.
5. **Watch the 50–59 cohort** — 56% churn, the highest of any age band.

## Dataset

- **Name:** Bank Customer Churn Modelling dataset (Kaggle "Churn_Modelling")
- **Source:** public GitHub mirror
  `https://raw.githubusercontent.com/erkansirin78/datasets/refs/heads/master/Churn_Modelling.csv` (vendored in `data/`)
- **Rows:** 10,000 customers × 14 columns: `RowNumber, CustomerId, Surname, CreditScore, Geography, Gender, Age, Tenure, Balance, NumOfProducts, HasCrCard, IsActiveMember, EstimatedSalary, Exited`
- **Target:** `Exited` (1 = churned, 0 = retained)

## Data model

Raw rows land in `staging_telco`; `sql/cleaning.sql` validates them (null keys, duplicate `CustomerId`, flag domains, negative balances, tenure range — **zero** problems found) and builds the `customers` analytics table with a derived `age_band`.

## Project structure

```
customer-churn-analysis/
├── data/churn_modelling.csv      # raw dataset (vendored)
├── sql/
│   ├── schema.sql                # DDL: staging + analytics table
│   ├── cleaning.sql              # quality checks + customers build
│   └── analysis_queries.sql      # the 4 business questions, one query each
├── scripts/
│   ├── load_to_sqlite.py         # CSV -> SQLite pipeline (runs schema + cleaning)
│   └── export_query_results.py   # executes each query, saves CSVs to outputs/
├── outputs/                      # every result set as CSV (regenerate any time)
├── db/                           # churn.db — generated, gitignored
├── app.py                        # Streamlit dashboard
├── requirements.txt
├── .gitignore
└── PUSH_TO_GITHUB.md             # exact commands to publish this repo
```

## Reproduce

```bash
python3 -m venv .venv && source .venv/bin/activate   # macOS/Linux
pip install -r requirements.txt

python scripts/load_to_sqlite.py      # build db/churn.db from the raw CSV
python scripts/export_query_results.py # run all queries -> outputs/*.csv
streamlit run app.py                   # launch the dashboard
```

## Skills demonstrated

- **SQL:** `CASE` bucketing, multi-facet segmentation with `UNION ALL`, conditional aggregates (`AVG(CASE WHEN ...)`), window-free share calculations, reconciliation checks
- **Python:** pandas ETL (type coercion, uniqueness assertions), `sqlite3` pipelines, query/result export automation
- **Streamlit:** KPI cards, interactive segment explorer, bar charts, recommendation write-up driven by the numbers
