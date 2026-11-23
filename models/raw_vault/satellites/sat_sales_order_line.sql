-- Satellite: quantities and prices per order line, attached to link_sales_order_line.
-- Insert-only history. A new row is added only when the hash diff changes.
{{ config(incremental_strategy='append') }}

with source_rows as (
    select hk_sales_order_line, hd_sales_order_line, carrier_tracking_number, order_qty, special_offer_id, unit_price,
           unit_price_discount, line_total, load_dts, record_source
    from {{ ref('stg_sales_order_detail') }}
    qualify row_number() over (partition by hk_sales_order_line order by load_dts desc) = 1
)

{% if is_incremental() %}
, latest as (
    select hk_sales_order_line, hd_sales_order_line
    from {{ this }}
    qualify row_number() over (partition by hk_sales_order_line order by load_dts desc) = 1
)
{% endif %}

select s.*
from source_rows s
{% if is_incremental() %}
left join latest l on l.hk_sales_order_line = s.hk_sales_order_line
where l.hk_sales_order_line is null or l.hd_sales_order_line <> s.hd_sales_order_line
{% endif %}
