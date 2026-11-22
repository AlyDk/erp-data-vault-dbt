-- Staging: type the bronze columns and add Data Vault hash keys.
with source as (
    select * from {{ source('bronze', 'customer') }}
),

typed as (
    select
        cast(customer_id as integer)                 as customer_id,
        cast(nullif(person_id, '') as integer)       as person_id,
        cast(nullif(store_id, '') as integer)        as store_id,
        cast(nullif(territory_id, '') as integer)    as territory_id,
        nullif(account_number, '')                   as account_number,
        cast(modified_date as timestamp)             as modified_date,
        _load_ts                                     as load_dts,
        _record_source                               as record_source
    from source
)

select
    {{ hash_key('customer_id') }}                    as hk_customer,
    {{ hash_diff(['person_id', 'store_id', 'territory_id', 'account_number']) }} as hd_customer,
    *
from typed