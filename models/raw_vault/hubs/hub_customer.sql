-- Hub: one row per customer business key, insert-only.
-- Fed by the customer master and by customer IDs on sales orders.
{{ config(unique_key='hk_customer') }}

with source_keys as (
    select hk_customer, customer_id, load_dts, record_source from {{ ref('stg_customer') }}
    union all
    select hk_customer, customer_id, load_dts, record_source from {{ ref('stg_sales_order_header') }}
),

first_seen as (
    select *
    from source_keys
    qualify row_number() over (partition by hk_customer order by load_dts, record_source) = 1
)

select hk_customer, customer_id, load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_customer not in (select hk_customer from {{ this }})
{% endif %}
