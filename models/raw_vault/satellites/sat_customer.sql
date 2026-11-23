-- Satellite: customer attributes, attached to hub_customer.
-- Insert-only history. A new row is added only when the hash diff changes.
{{ config(incremental_strategy='append') }}

with source_rows as (
    select hk_customer, hd_customer, person_id, store_id, territory_id, account_number, load_dts, record_source
    from {{ ref('stg_customer') }}
    qualify row_number() over (partition by hk_customer order by load_dts desc) = 1
)

{% if is_incremental() %}
, latest as (
    select hk_customer, hd_customer
    from {{ this }}
    qualify row_number() over (partition by hk_customer order by load_dts desc) = 1
)
{% endif %}

select s.*
from source_rows s
{% if is_incremental() %}
left join latest l on l.hk_customer = s.hk_customer
where l.hk_customer is null or l.hd_customer <> s.hd_customer
{% endif %}
