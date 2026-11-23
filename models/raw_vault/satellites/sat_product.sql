-- Satellite: product attributes and prices, attached to hub_product.
-- Insert-only history. A new row is added only when the hash diff changes.
{{ config(incremental_strategy='append') }}

with source_rows as (
    select hk_product, hd_product, product_name, product_number, is_manufactured, is_finished_good, color,
           safety_stock_level, reorder_point, standard_cost, list_price, size, weight,
           product_line, product_class, product_subcategory_id, sell_start_date, sell_end_date, load_dts, record_source
    from {{ ref('stg_product') }}
    qualify row_number() over (partition by hk_product order by load_dts desc) = 1
)

{% if is_incremental() %}
, latest as (
    select hk_product, hd_product
    from {{ this }}
    qualify row_number() over (partition by hk_product order by load_dts desc) = 1
)
{% endif %}

select s.*
from source_rows s
{% if is_incremental() %}
left join latest l on l.hk_product = s.hk_product
where l.hk_product is null or l.hd_product <> s.hd_product
{% endif %}
