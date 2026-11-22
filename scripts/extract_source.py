"""Extract: download AdventureWorks ERP source files into data/landing/<run_date>/.

Source: Microsoft sql-server-samples, AdventureWorks OLTP export
(tab-delimited, no header row). Standard library only.
"""
import hashlib
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE_URL = ("https://raw.githubusercontent.com/microsoft/sql-server-samples/"
            "master/samples/databases/adventure-works/oltp-install-script/")

TABLES = [
    "SalesOrderHeader", "SalesOrderDetail", "Customer", "SalesTerritory",
    "Product", "ProductSubcategory", "ProductCategory",
    "ProductInventory", "Location", "TransactionHistory",
]

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    run_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    out_dir = ROOT / "data" / "landing" / run_date
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {"run_date": run_date, "source": BASE_URL, "files": []}

    for table in TABLES:
        url = f"{BASE_URL}{table}.csv"
        target = out_dir / f"{table}.tsv"
        with urllib.request.urlopen(url, timeout=60) as resp:
            data = resp.read()
        target.write_bytes(data)
        rows = data.count(b"\n")
        manifest["files"].append({
            "table": table,
            "file": target.name,
            "bytes": len(data),
            "rows": rows,
            "sha256": hashlib.sha256(data).hexdigest(),
        })
        print(f"{table:<20} {rows:>8} rows  {len(data):>10} bytes")

    (out_dir / "_manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"Done: {len(TABLES)} files in {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())