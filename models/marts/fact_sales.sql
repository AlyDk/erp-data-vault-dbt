-- Sales fact. Grain: one row per sales order line.
with order_line as (
    select *
    from {{ ref('sat_sales_order_line') }}
    qualify row_number() over (partition by hk_sales_order_line order by load_dts desc) = 1
),

order_header as (
    select *
    from {{ ref('sat_sales_order') }}
    qualify row_number() over (partition by hk_sales_order order by load_dts desc) = 1
)

select
    l.hk_sales_order_line                            as sales_line_key,
    so.sales_order_id,
    l.sales_order_detail_id                          as sales_order_line_id,
    oh.sales_order_number,
    cast(strftime(oh.order_date, '%Y%m%d') as integer) as order_date_key,
    cast(strftime(oh.ship_date, '%Y%m%d') as integer)  as ship_date_key,
    oc.hk_customer                                   as customer_key,
    l.hk_product                                     as product_key,
    oh.is_online_order,
    ol.order_qty,
    ol.unit_price,
    ol.unit_price_discount,
    ol.line_total                                    as sales_amount,
    ol.order_qty * p.standard_cost                   as cost_amount_at_current_cost
from {{ ref('link_sales_order_line') }} l
join order_line ol using (hk_sales_order_line)
join {{ ref('hub_sales_order') }} so using (hk_sales_order)
join order_header oh using (hk_sales_order)
join {{ ref('link_sales_order_customer') }} oc using (hk_sales_order)
left join {{ ref('dim_product') }} p on p.product_key = l.hk_product
