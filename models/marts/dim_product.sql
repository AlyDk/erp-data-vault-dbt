-- Product dimension: current product attributes with subcategory and category.
with current_product as (
    select *
    from {{ ref('sat_product') }}
    qualify row_number() over (partition by hk_product order by load_dts desc) = 1
)

select
    h.hk_product                                     as product_key,
    h.product_id,
    p.product_number,
    p.product_name,
    coalesce(c.product_category_name, 'Uncategorised')    as product_category,
    coalesce(s.product_subcategory_name, 'Uncategorised') as product_subcategory,
    p.color,
    p.size,
    p.standard_cost,
    p.list_price,
    p.is_finished_good,
    p.safety_stock_level,
    p.reorder_point,
    p.sell_end_date is null                          as is_active
from {{ ref('hub_product') }} h
left join current_product p using (hk_product)
left join {{ ref('stg_product_subcategory') }} s on s.product_subcategory_id = p.product_subcategory_id
left join {{ ref('stg_product_category') }} c on c.product_category_id = s.product_category_id
