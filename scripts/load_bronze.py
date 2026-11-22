"""Load: copy the latest landing files into the bronze schema of the DuckDB warehouse.

Bronze rules: every column kept as text, exactly as the source sent it,
plus three audit columns. Typing and cleaning happen later in dbt.
Each run replaces the bronze tables; history is kept in the Data Vault.
"""
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
LANDING = ROOT / "data" / "landing"
WAREHOUSE = ROOT / "data" / "warehouse.duckdb"
RECORD_SOURCE = "adventureworks_erp"

# Column order as defined in the AdventureWorks install script (instawdb.sql).
COLUMNS = {
    "SalesOrderHeader": [
        "sales_order_id", "revision_number", "order_date", "due_date", "ship_date",
        "status", "online_order_flag", "sales_order_number", "purchase_order_number",
        "account_number", "customer_id", "sales_person_id", "territory_id",
        "bill_to_address_id", "ship_to_address_id", "ship_method_id", "credit_card_id",
        "credit_card_approval_code", "currency_rate_id", "sub_total", "tax_amt",
        "freight", "total_due", "comment", "rowguid", "modified_date"],
    "SalesOrderDetail": [
        "sales_order_id", "sales_order_detail_id", "carrier_tracking_number",
        "order_qty", "product_id", "special_offer_id", "unit_price",
        "unit_price_discount", "line_total", "rowguid", "modified_date"],
    "Customer": [
        "customer_id", "person_id", "store_id", "territory_id", "account_number",
        "rowguid", "modified_date"],
    "SalesTerritory": [
        "territory_id", "name", "country_region_code", "territory_group", "sales_ytd",
        "sales_last_year", "cost_ytd", "cost_last_year", "rowguid", "modified_date"],
    "Product": [
        "product_id", "name", "product_number", "make_flag", "finished_goods_flag",
        "color", "safety_stock_level", "reorder_point", "standard_cost", "list_price",
        "size", "size_unit_measure_code", "weight_unit_measure_code", "weight",
        "days_to_manufacture", "product_line", "class", "style",
        "product_subcategory_id", "product_model_id", "sell_start_date",
        "sell_end_date", "discontinued_date", "rowguid", "modified_date"],
    "ProductSubcategory": [
        "product_subcategory_id", "product_category_id", "name", "rowguid",
        "modified_date"],
    "ProductCategory": ["product_category_id", "name", "rowguid", "modified_date"],
    "ProductInventory": [
        "product_id", "location_id", "shelf", "bin", "quantity", "rowguid",
        "modified_date"],
    "Location": ["location_id", "name", "cost_rate", "availability", "modified_date"],
    "TransactionHistory": [
        "transaction_id", "product_id", "reference_order_id", "reference_order_line_id",
        "transaction_date", "transaction_type", "quantity", "actual_cost",
        "modified_date"],
}


def snake(name: str) -> str:
    out = "".join("_" + c.lower() if c.isupper() else c for c in name)
    return out.lstrip("_")


def main() -> int:
    runs = sorted(p for p in LANDING.iterdir() if p.is_dir())
    if not runs:
        print("No landing folder found. Run scripts\\extract_source.py first.")
        return 1
    run_dir = runs[-1]
    manifest = json.loads((run_dir / "_manifest.json").read_text())
    expected = {f["table"]: f["rows"] for f in manifest["files"]}
    load_ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    con = duckdb.connect(str(WAREHOUSE))
    con.execute("CREATE SCHEMA IF NOT EXISTS bronze")
    failed = False

    for table, cols in COLUMNS.items():
        src = (run_dir / f"{table}.tsv").as_posix()
        col_spec = "{" + ", ".join(f"'{c}': 'VARCHAR'" for c in cols) + "}"
        target = f"bronze.{snake(table)}"
        con.execute(f"""
            CREATE OR REPLACE TABLE {target} AS
            SELECT *,
                   '{RECORD_SOURCE}'          AS _record_source,
                   '{run_dir.name}/{table}.tsv' AS _source_file,
                   TIMESTAMP '{load_ts}'      AS _load_ts
            FROM read_csv('{src}', delim='\\t', header=false, quote='',
                          escape='', columns={col_spec}, all_varchar=true,
                          null_padding=false, strict_mode=true)
        """)
        loaded = con.execute(f"SELECT count(*) FROM {target}").fetchone()[0]
        status = "OK" if loaded == expected[table] else "ROW COUNT MISMATCH"
        failed |= status != "OK"
        print(f"{target:<32} {loaded:>8} rows  expected {expected[table]:>8}  {status}")

    con.close()
    print(f"Bronze load from {run_dir.name} {'FAILED' if failed else 'complete'}: {WAREHOUSE}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())