-- Link: which product is stocked at which location. Insert-only.
{{ config(unique_key='hk_product_location') }}

with source_rows as (
    select hk_product_location, hk_product, hk_location, load_dts, record_source
    from {{ ref('stg_product_inventory') }}
),

first_seen as (
    select *
    from source_rows
    qualify row_number() over (partition by hk_product_location order by load_dts) = 1
)

select hk_product_location, hk_product, hk_location, load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_product_location not in (select hk_product_location from {{ this }})
{% endif %}
