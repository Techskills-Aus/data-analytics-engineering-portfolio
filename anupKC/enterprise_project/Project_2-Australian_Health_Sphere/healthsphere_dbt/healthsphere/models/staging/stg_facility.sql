with source as (

    select * from {{ source('raw', 'raw_facility') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by facility_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(facility_id)           as facility_id,
    trim(facility_name)         as facility_name,
    upper(trim(state_code))     as state_code,
    initcap(trim(city))         as city,
    trim(postcode)              as postcode,
    upper(trim(region_type))    as region_type,
    opened_date,
    is_active,
    updated_at,
    ingestion_timestamp
from deduplicated
