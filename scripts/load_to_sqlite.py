"""Load the Bank Customer Churn CSV into SQLite and build the analytics table.

Pipeline:
  1. Read data/churn_modelling.csv (column names normalized to snake_case).
  2. Create the database from sql/schema.sql and bulk-load staging_telco.
  3. Build the `customers` analytics table via sql/cleaning.sql — all
     business logic lives in SQL, not here.

Usage:
    python scripts/load_to_sqlite.py
"""

import sqlite3
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "churn_modelling.csv"
DB = ROOT / "db" / "churn.db"


def main() -> None:
    DB.parent.mkdir(parents=True, exist_ok=True)
    if DB.exists():
        DB.unlink()  # rebuild from scratch for reproducibility

    df = pd.read_csv(DATA)
    df = df.rename(columns={"RowNumber": "row_number", "CustomerId": "customer_id",
                             "Surname": "surname", "CreditScore": "credit_score",
                             "Geography": "geography", "Gender": "gender",
                             "Age": "age", "Tenure": "tenure", "Balance": "balance",
                             "NumOfProducts": "num_products", "HasCrCard": "has_card",
                             "IsActiveMember": "is_active", "EstimatedSalary": "salary",
                             "Exited": "exited"})
    # --- minimal cleaning: types only --------------------------------------
    for col in ("row_number", "credit_score", "age", "tenure",
                "num_products", "has_card", "is_active", "exited"):
        df[col] = df[col].astype(int)
    for col in ("balance", "salary"):
        df[col] = df[col].astype(float)
    for col in ("customer_id", "surname", "geography", "gender"):
        df[col] = df[col].astype(str).str.strip()
    assert df["customer_id"].is_unique, "duplicate customer_id in source"

    con = sqlite3.connect(DB)
    con.executescript((ROOT / "sql" / "schema.sql").read_text(encoding="utf-8"))
    df.to_sql("staging_telco", con, if_exists="append", index=False)
    con.executescript((ROOT / "sql" / "cleaning.sql").read_text(encoding="utf-8"))
    con.commit()

    n_stage = con.execute("SELECT COUNT(*) FROM staging_telco").fetchone()[0]
    n_cust = con.execute("SELECT COUNT(*) FROM customers").fetchone()[0]
    assert n_stage == n_cust == len(df), (n_stage, n_cust, len(df))
    con.close()
    print(f"OK: {n_cust:,} customers loaded into db/churn.db")


if __name__ == "__main__":
    main()
