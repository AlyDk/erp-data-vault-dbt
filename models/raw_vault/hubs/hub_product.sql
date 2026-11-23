-- Hub: one row per product business key, insert-only.
-- Fed by the product master, order lines, stock and inventory movements.
{{ config(unique_key='hk_product') }}

with source_keys as (
    select hk_product, product_id, load_dts, record_source from {{ ref('stg_product') }}
    union all
    select hk_product, product_id, load_dts, record_source from {{ ref('stg_sales_order_detail') }}
    union all
    select hk_product, product_id, load_dts, record_source from {{ ref('stg_product_inventory') }}
    union all
    select hk_product, product_id, load_dts, record_source from {{ ref('stg_transaction_history') }}
),

first_seen as (
    select *
    from source_keys
    qualify row_number() over (partition by hk_product order by load_dts, record_source) = 1
)

select hk_product, product_id, load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_product not in (select hk_product from {{ this }})
{% endif %}
