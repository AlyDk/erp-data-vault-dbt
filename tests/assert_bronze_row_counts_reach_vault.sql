-- Completeness: every source order and order line must reach the vault.
-- Returns a row for each entity whose counts differ.
select 'sales_order' as entity, b.n as bronze_rows, v.n as vault_rows
from (select count(*) n from {{ source('bronze', 'sales_order_header') }}) b,
     (select count(*) n from {{ ref('hub_sales_order') }}) v
where b.n <> v.n
union all
select 'sales_order_line', b.n, v.n
from (select count(*) n from {{ source('bronze', 'sales_order_detail') }}) b,
     (select count(*) n from {{ ref('link_sales_order_line') }}) v
where b.n <> v.n
