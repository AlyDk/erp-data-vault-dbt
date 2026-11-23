-- Staging: product master (ERP Production.Product).
with source as (
    select * from {{ source('bronze', 'product') }}
),

typed as (
    select
        cast(product_id as integer)                         as product_id,
        name                                                as product_name,
        product_number,
        make_flag = '1'                                     as is_manufactured,
        finished_goods_flag = '1'                           as is_finished_good,
        nullif(color, '')                                   as color,
        cast(safety_stock_level as integer)                 as safety_stock_level,
        cast(reorder_point as integer)                      as reorder_point,
        cast(standard_cost as decimal(19, 4))               as standard_cost,
        cast(list_price as decimal(19, 4))                  as list_price,
        nullif(size, '')                                    as size,
        cast(nullif(weight, '') as decimal(8, 2))           as weight,
        nullif(trim(product_line), '')                      as product_line,
        nullif(trim(class), '')                             as product_class,
        cast(nullif(product_subcategory_id, '') as integer) as product_subcategory_id,
        cast(sell_start_date as timestamp)                  as sell_start_date,
        cast(nullif(sell_end_date, '') as timestamp)        as sell_end_date,
        cast(modified_date as timestamp)                    as modified_date,
        _load_ts                                            as load_dts,
        _record_source                                      as record_source
    from source
)

select
    {{ hash_key('product_id') }}                     as hk_product,
    {{ hash_diff(['product_name', 'product_number', 'is_manufactured', 'is_finished_good',
                  'color', 'safety_stock_level', 'reorder_point', 'standard_cost',
                  'list_price', 'size', 'weight', 'product_line', 'product_class',
                  'product_subcategory_id', 'sell_start_date', 'sell_end_date']) }} as hd_product,
    *
from typed
