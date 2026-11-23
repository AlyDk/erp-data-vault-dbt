"""Export the star schema marts to Parquet files for Power BI.

Power BI Desktop reads Parquet natively, so no database driver is needed.
Decimal columns are written as double, because Power Query rejects
Parquet decimals with precision above 28.
Output: data/export/<table>.parquet
"""
import sys
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
WAREHOUSE = ROOT / "data" / "warehouse.duckdb"
EXPORT = ROOT / "data" / "export"
TABLES = ["dim_date", "dim_customer", "dim_product", "dim_location", "fact_sales", "fact_inventory"]


def main() -> int:
    EXPORT.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(WAREHOUSE), read_only=True)
    for table in TABLES:
        target = (EXPORT / f"{table}.parquet").as_posix()
        columns = con.execute(
            "SELECT column_name, data_type FROM information_schema.columns "
            "WHERE table_schema = 'marts' AND table_name = ? ORDER BY ordinal_position",
            [table],
        ).fetchall()
        select_list = ", ".join(
            f'CAST("{name}" AS DOUBLE) AS "{name}"' if dtype.startswith("DECIMAL") else f'"{name}"'
            for name, dtype in columns
        )
        con.execute(f"COPY (SELECT {select_list} FROM marts.{table}) TO '{target}' (FORMAT parquet)")
        rows = con.execute(f"SELECT count(*) FROM read_parquet('{target}')").fetchone()[0]
        print(f"{table:<16} {rows:>8} rows -> data/export/{table}.parquet")
    con.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
