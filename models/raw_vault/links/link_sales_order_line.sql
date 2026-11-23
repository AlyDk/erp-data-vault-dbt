-- Link: order lines, connecting a sales order to a product.
-- sales_order_detail_id is a dependent child key: the same product can appear
-- on two lines of one order, so the line ID is part of the link's identity.
{{ config(unique_key='hk_sales_order_line') }}

with source_rows as (
    select hk_sales_order_line, hk_sales_order, hk_product, sales_order_detail_id,
           load_dts, record_source
    from {{ ref('stg_sales_order_detail') }}
),

first_seen as (
    select *
    from source_rows
    qualify row_number() over (partition by hk_sales_order_line order by load_dts) = 1
)

select hk_sales_order_line, hk_sales_order, hk_product, sales_order_detail_id,
       load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_sales_order_line not in (select hk_sales_order_line from {{ this }})
{% endif %}
