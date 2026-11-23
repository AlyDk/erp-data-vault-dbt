-- Link: which customer placed which sales order. Insert-only.
{{ config(unique_key='hk_sales_order_customer') }}

with source_rows as (
    select hk_sales_order_customer, hk_sales_order, hk_customer, load_dts, record_source
    from {{ ref('stg_sales_order_header') }}
),

first_seen as (
    select *
    from source_rows
    qualify row_number() over (partition by hk_sales_order_customer order by load_dts) = 1
)

select hk_sales_order_customer, hk_sales_order, hk_customer, load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_sales_order_customer not in (select hk_sales_order_customer from {{ this }})
{% endif %}
