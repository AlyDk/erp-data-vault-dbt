-- Customer dimension: current customer attributes plus sales territory.
with current_customer as (
    select *
    from {{ ref('sat_customer') }}
    qualify row_number() over (partition by hk_customer order by load_dts desc) = 1
)

select
    h.hk_customer                                   as customer_key,
    h.customer_id,
    c.account_number,
    case when c.store_id is not null then 'Store' else 'Individual' end as customer_type,
    coalesce(t.territory_name, 'Unknown')           as territory_name,
    coalesce(t.country_region_code, 'Unknown')      as country_code,
    coalesce(t.territory_group, 'Unknown')          as territory_group
from {{ ref('hub_customer') }} h
left join current_customer c using (hk_customer)
left join {{ ref('stg_sales_territory') }} t on t.territory_id = c.territory_id
