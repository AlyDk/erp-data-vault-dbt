-- Satellite: location name, cost rate and availability, attached to hub_location.
-- Insert-only history. A new row is added only when the hash diff changes.
{{ config(incremental_strategy='append') }}

with source_rows as (
    select hk_location, hd_location, location_name, cost_rate, availability, load_dts, record_source
    from {{ ref('stg_location') }}
    qualify row_number() over (partition by hk_location order by load_dts desc) = 1
)

{% if is_incremental() %}
, latest as (
    select hk_location, hd_location
    from {{ this }}
    qualify row_number() over (partition by hk_location order by load_dts desc) = 1
)
{% endif %}

select s.*
from source_rows s
{% if is_incremental() %}
left join latest l on l.hk_location = s.hk_location
where l.hk_location is null or l.hd_location <> s.hd_location
{% endif %}
