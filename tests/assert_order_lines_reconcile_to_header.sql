-- Reconciliation: for every order, the sum of its line totals must equal the
-- header sub total (tolerance 0.01 for rounding). Returns the orders that fail.
with lines as (
    select l.hk_sales_order, sum(s.line_total) as lines_total
    from {{ ref('link_sales_order_line') }} l
    join {{ ref('sat_sales_order_line') }} s using (hk_sales_order_line)
    group by l.hk_sales_order
),

headers as (
    select hk_sales_order, sub_total
    from {{ ref('sat_sales_order') }}
    qualify row_number() over (partition by hk_sales_order order by load_dts desc) = 1
)

select h.hk_sales_order, h.sub_total, l.lines_total
from headers h
join lines l using (hk_sales_order)
where abs(h.sub_total - l.lines_total) > 0.01
