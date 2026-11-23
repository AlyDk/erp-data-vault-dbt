-- Staging: sales territories, a reference table (ERP Sales.SalesTerritory).
select
    cast(territory_id as integer)                    as territory_id,
    name                                             as territory_name,
    country_region_code,
    territory_group,
    _load_ts                                         as load_dts,
    _record_source                                   as record_source
from {{ source('bronze', 'sales_territory') }}
