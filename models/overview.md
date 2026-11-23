{% docs __overview__ %}
# ERP sales and inventory warehouse (Data Vault 2.0)

Portfolio case study by Ali Dakak. It models the sales and inventory processes of an
ERP system (Microsoft AdventureWorks sample data) the way a consultancy would deliver it
for a client.

**Layers**

1. **Bronze** (Python): the ERP export copied as-is, every column as text, with audit columns
   `_record_source`, `_source_file` and `_load_ts`.
2. **Staging** (dbt views): typed columns plus Data Vault hash keys and hash diffs.
3. **Raw Vault** (dbt incremental, insert-only): hubs for customer, product, sales order and
   location; links for order to customer, order lines and product stock; satellites that
   keep the full history of every attribute.
4. **Marts** (dbt tables): star schema for reporting in Power BI.

**Quality gates**: key uniqueness, referential integrity between links and hubs, one
version per key and load, and a reconciliation of order lines to order headers.

Open the lineage graph (bottom right) to see how data flows from source to mart.
{% enddocs %}
