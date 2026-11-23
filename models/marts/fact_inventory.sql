-- Inventory fact. Grain: one row per product and location, current stock on hand.
with current_stock as (
    select *
    from {{ ref('sat_product_location_stock') }}
    qualify row_number() over (partition by hk_product_location order by load_dts desc) = 1
)

select
    l.hk_product_location                            as stock_key,
    l.hk_product                                     as product_key,
    l.hk_location                                    as location_key,
    s.shelf,
    s.bin,
    s.quantity                                       as quantity_on_hand,
    s.quantity * p.standard_cost                     as stock_value_at_standard_cost,
    cast(strftime(s.load_dts, '%Y%m%d') as integer)  as snapshot_date_key
from {{ ref('link_product_location') }} l
join current_stock s using (hk_product_location)
left join {{ ref('dim_product') }} p on p.product_key = l.hk_product
