"""Demo: simulate a price change in the ERP so the Data Vault keeps history.

Changes the list price of one product in bronze and stamps a new load time,
as if a later extract had brought the change. Run dbt afterwards and the
product satellite holds two versions. Reset with:
    python scripts/load_bronze.py
    dbt run -s raw_vault --full-refresh
"""
from datetime import datetime, timezone
from pathlib import Path

import duckdb

WAREHOUSE = Path(__file__).resolve().parents[1] / "data" / "warehouse.duckdb"
PRODUCT_ID = "680"
NEW_PRICE = "1500.0000"
LOAD_TS = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")  # UTC, same as load_bronze.py

con = duckdb.connect(str(WAREHOUSE))
before = con.execute(
    "select list_price from bronze.product where product_id = ?", [PRODUCT_ID]
).fetchone()[0]
con.execute(
    """update bronze.product
       set list_price = ?, _load_ts = cast(? as timestamp)
       where product_id = ?""",
    [NEW_PRICE, LOAD_TS, PRODUCT_ID],
)
con.close()
print(f"Product {PRODUCT_ID}: list price {before} -> {NEW_PRICE} in bronze. Now run: dbt run -s raw_vault")
