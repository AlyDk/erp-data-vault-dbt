-- Satellite: order header status, dates and amounts, attached to hub_sales_order.
-- Insert-only history. A new row is added only when the hash diff changes.
{{ config(incremental_strategy='append') }}

with source_rows as (
    select hk_sales_order, hd_sales_order, revision_number, order_date, due_date, ship_date, status, is_online_order,
           sales_order_number, purchase_order_number, sales_person_id, territory_id,
           ship_method_id, sub_total, tax_amt, freight, total_due, load_dts, record_source
    from {{ ref('stg_sales_order_header') }}
    qualify row_number() over (partition by hk_sales_order order by load_dts desc) = 1
)

{% if is_incremental() %}
, latest as (
    select hk_sales_order, hd_sales_order
    from {{ this }}
    qualify row_number() over (partition by hk_sales_order order by load_dts desc) = 1
)
{% endif %}

select s.*
from source_rows s
{% if is_incremental() %}
left join latest l on l.hk_sales_order = s.hk_sales_order
where l.hk_sales_order is null or l.hd_sales_order <> s.hd_sales_order
{% endif %}
