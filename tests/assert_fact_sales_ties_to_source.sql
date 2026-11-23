-- Reconciliation: total sales in the mart must equal the ERP order line totals
-- in bronze (tolerance 0.01). Returns a row only when they differ.
with source_total as (
    select sum(cast(line_total as decimal(38, 6))) as amount
    from {{ source('bronze', 'sales_order_detail') }}
),

mart_total as (
    select sum(sales_amount) as amount
    from {{ ref('fact_sales') }}
)

select s.amount as source_amount, m.amount as mart_amount
from source_total s, mart_total m
where abs(s.amount - m.amount) > 0.01
