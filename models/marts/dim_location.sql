-- Location dimension: warehouses and production locations.
with current_location as (
    select *
    from {{ ref('sat_location') }}
    qualify row_number() over (partition by hk_location order by load_dts desc) = 1
)

select
    h.hk_location                                    as location_key,
    h.location_id,
    l.location_name,
    l.cost_rate,
    l.availability
from {{ ref('hub_location') }} h
left join current_location l using (hk_location)
