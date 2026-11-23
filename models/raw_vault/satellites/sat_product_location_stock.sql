-- Satellite: stock on hand per product and location, attached to link_product_location.
-- Insert-only history. A new row is added only when the hash diff changes.
{{ config(incremental_strategy='append') }}

with source_rows as (
    select hk_product_location, hd_product_location, shelf, bin, quantity, load_dts, record_source
    from {{ ref('stg_product_inventory') }}
    qualify row_number() over (partition by hk_product_location order by load_dts desc) = 1
)

{% if is_incremental() %}
, latest as (
    select hk_product_location, hd_product_location
    from {{ this }}
    qualify row_number() over (partition by hk_product_location order by load_dts desc) = 1
)
{% endif %}

select s.*
from source_rows s
{% if is_incremental() %}
left join latest l on l.hk_product_location = s.hk_product_location
where l.hk_product_location is null or l.hd_product_location <> s.hd_product_location
{% endif %}
