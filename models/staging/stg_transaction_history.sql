-- Staging: inventory movements (ERP Production.TransactionHistory).
-- Type W = work order, S = sales order, P = purchase order.
with source as (
    select * from {{ source('bronze', 'transaction_history') }}
),

typed as (
    select
        cast(transaction_id as integer)              as transaction_id,
        cast(product_id as integer)                  as product_id,
        cast(reference_order_id as integer)          as reference_order_id,
        cast(reference_order_line_id as integer)     as reference_order_line_id,
        cast(transaction_date as timestamp)          as transaction_date,
        transaction_type,
        cast(quantity as integer)                    as quantity,
        cast(actual_cost as decimal(19, 4))          as actual_cost,
        cast(modified_date as timestamp)             as modified_date,
        _load_ts                                     as load_dts,
        _record_source                               as record_source
    from source
)

select
    {{ hash_key('product_id') }}                     as hk_product,
    {{ hash_key(['transaction_id', 'product_id']) }} as hk_inventory_transaction,
    *
from typed
