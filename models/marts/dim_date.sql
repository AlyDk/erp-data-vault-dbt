-- Date dimension covering every order date, from the first to the last order year.
with bounds as (
    select
        date_trunc('year', min(order_date))::date                              as start_date,
        (date_trunc('year', max(order_date)) + interval 1 year - interval 1 day)::date as end_date
    from {{ ref('sat_sales_order') }}
),

days as (
    select unnest(generate_series(start_date, end_date, interval 1 day))::date as date_day
    from bounds
)

select
    cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
    date_day,
    year(date_day)                                 as year,
    quarter(date_day)                              as quarter,
    'Q' || quarter(date_day)                       as quarter_name,
    month(date_day)                                as month,
    strftime(date_day, '%b')                       as month_name,
    strftime(date_day, '%Y-%m')                    as year_month,
    isodow(date_day)                               as day_of_week,
    strftime(date_day, '%a')                       as day_name,
    isodow(date_day) in (6, 7)                     as is_weekend
from days
