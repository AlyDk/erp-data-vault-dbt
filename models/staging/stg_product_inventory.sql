-- Staging: stock on hand per product and location (ERP Production.ProductInventory).
with source as (
    select * from {{ source('bronze', 'product_inventory') }}
),

typed as (
    select
        cast(product_id as integer)                  as product_id,
        cast(location_id as integer)                 as location_id,
        shelf,
        cast(bin as integer)                         as bin,
        cast(quantity as integer)                    as quantity,
        cast(modified_date as timestamp)             as modified_date,
        _load_ts                                     as load_dts,
        _record_source                               as record_source
    from source
)

select
    {{ hash_key('product_id') }}                     as hk_product,
    {{ hash_key('location_id') }}                    as hk_location,
    {{ hash_key(['product_id', 'location_id']) }}    as hk_product_location,
    {{ hash_diff(['shelf', 'bin', 'quantity']) }}    as hd_product_location,
    *
from typed
