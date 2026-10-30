select
    facility_id,
    facility_name,
    state_code,
    city,
    postcode,
    region_type,
    opened_date,
    is_active
from {{ ref('stg_facility') }}
