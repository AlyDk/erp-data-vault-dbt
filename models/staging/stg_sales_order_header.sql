-- Staging: sales order header (ERP Sales.SalesOrderHeader).
with source as (
    select * from {{ source('bronze', 'sales_order_header') }}
),

typed as (
    select
        cast(sales_order_id as integer)              as sales_order_id,
        cast(customer_id as integer)                 as customer_id,
        cast(revision_number as integer)             as revision_number,
        cast(order_date as timestamp)                as order_date,
        cast(due_date as timestamp)                  as due_date,
        cast(nullif(ship_date, '') as timestamp)     as ship_date,
        cast(status as integer)                      as status,
        online_order_flag = '1'                      as is_online_order,
        sales_order_number,
        nullif(purchase_order_number, '')            as purchase_order_number,
        cast(nullif(sales_person_id, '') as integer) as sales_person_id,
        cast(nullif(territory_id, '') as integer)    as territory_id,
        cast(ship_method_id as integer)              as ship_method_id,
        cast(sub_total as decimal(19, 4))            as sub_total,
        cast(tax_amt as decimal(19, 4))              as tax_amt,
        cast(freight as decimal(19, 4))              as freight,
        cast(total_due as decimal(19, 4))            as total_due,
        cast(modified_date as timestamp)             as modified_date,
        _load_ts                                     as load_dts,
        _record_source                               as record_source
    from source
)

select
    {{ hash_key('sales_order_id') }}                 as hk_sales_order,
    {{ hash_key('customer_id') }}                    as hk_customer,
    {{ hash_key(['sales_order_id', 'customer_id']) }} as hk_sales_order_customer,
    {{ hash_diff(['revision_number', 'order_date', 'due_date', 'ship_date', 'status',
                  'is_online_order', 'sales_order_number', 'purchase_order_number',
                  'sales_person_id', 'territory_id', 'ship_method_id',
                  'sub_total', 'tax_amt', 'freight', 'total_due']) }} as hd_sales_order,
    *
from typed
