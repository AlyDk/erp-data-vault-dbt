-- Hub: one row per sales order business key, insert-only.
{{ config(unique_key='hk_sales_order') }}

with source_keys as (
    select hk_sales_order, sales_order_id, load_dts, record_source from {{ ref('stg_sales_order_header') }}
    union all
    select hk_sales_order, sales_order_id, load_dts, record_source from {{ ref('stg_sales_order_detail') }}
),

first_seen as (
    select *
    from source_keys
    qualify row_number() over (partition by hk_sales_order order by load_dts, record_source) = 1
)

select hk_sales_order, sales_order_id, load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_sales_order not in (select hk_sales_order from {{ this }})
{% endif %}
