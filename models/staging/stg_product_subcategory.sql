-- Staging: product subcategories, a reference table (ERP Production.ProductSubcategory).
select
    cast(product_subcategory_id as integer)          as product_subcategory_id,
    cast(product_category_id as integer)             as product_category_id,
    name                                             as product_subcategory_name,
    _load_ts                                         as load_dts,
    _record_source                                   as record_source
from {{ source('bronze', 'product_subcategory') }}
