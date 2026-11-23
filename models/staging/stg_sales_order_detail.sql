-- Staging: sales order lines (ERP Sales.SalesOrderDetail).
with source as (
    select * from {{ source('bronze', 'sales_order_detail') }}
),

typed as (
    select
        cast(sales_order_id as integer)              as sales_order_id,
        cast(sales_order_detail_id as integer)       as sales_order_detail_id,
        cast(product_id as integer)                  as product_id,
        nullif(carrier_tracking_number, '')          as carrier_tracking_number,
        cast(order_qty as integer)                   as order_qty,
        cast(special_offer_id as integer)            as special_offer_id,
        cast(unit_price as decimal(19, 4))           as unit_price,
        cast(unit_price_discount as decimal(19, 4))  as unit_price_discount,
        cast(line_total as decimal(38, 6))           as line_total,
        cast(modified_date as timestamp)             as modified_date,
        _load_ts                                     as load_dts,
        _record_source                               as record_source
    from source
)

select
    {{ hash_key('sales_order_id') }}                 as hk_sales_order,
    {{ hash_key('product_id') }}                     as hk_product,
    {{ hash_key(['sales_order_id', 'sales_order_detail_id', 'product_id']) }} as hk_sales_order_line,
    {{ hash_diff(['carrier_tracking_number', 'order_qty', 'special_offer_id',
                  'unit_price', 'unit_price_discount', 'line_total']) }} as hd_sales_order_line,
    *
from typed
