-- Hub: one row per warehouse or production location, insert-only.
{{ config(unique_key='hk_location') }}

with source_keys as (
    select hk_location, location_id, load_dts, record_source from {{ ref('stg_location') }}
    union all
    select hk_location, location_id, load_dts, record_source from {{ ref('stg_product_inventory') }}
),

first_seen as (
    select *
    from source_keys
    qualify row_number() over (partition by hk_location order by load_dts, record_source) = 1
)

select hk_location, location_id, load_dts, record_source
from first_seen
{% if is_incremental() %}
where hk_location not in (select hk_location from {{ this }})
{% endif %}
