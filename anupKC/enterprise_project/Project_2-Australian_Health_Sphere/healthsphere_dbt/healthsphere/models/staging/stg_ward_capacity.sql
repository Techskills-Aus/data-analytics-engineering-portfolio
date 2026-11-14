with source as (

    select * from {{ source('raw', 'raw_ward_capacity') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by snapshot_date, facility_id, department_id
        order by ingestion_timestamp desc
    ) = 1

)

select
    snapshot_date,
    trim(facility_id)     as facility_id,
    trim(department_id)   as department_id,
    planned_beds,
    available_beds,
    occupied_beds,
    unavailable_beds,
    snapshot_timestamp,
    ingestion_timestamp
from deduplicated
