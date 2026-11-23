-- Staging: product categories, a reference table (ERP Production.ProductCategory).
select
    cast(product_category_id as integer)             as product_category_id,
    name                                             as product_category_name,
    _load_ts                                         as load_dts,
    _record_source                                   as record_source
from {{ source('bronze', 'product_category') }}
