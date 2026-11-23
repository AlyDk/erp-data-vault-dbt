-- Staging: warehouse and production locations (ERP Production.Location).
with source as (
    select * from {{ source('bronze', 'location') }}
),

typed as (
    select
        cast(location_id as integer)                 as location_id,
        name                                         as location_name,
        cast(cost_rate as decimal(10, 4))            as cost_rate,
        cast(availability as decimal(8, 2))          as availability,
        cast(modified_date as timestamp)             as modified_date,
        _load_ts                                     as load_dts,
        _record_source                               as record_source
    from source
)

select
    {{ hash_key('location_id') }}                    as hk_location,
    {{ hash_diff(['location_name', 'cost_rate', 'availability']) }} as hd_location,
    *
from typed
