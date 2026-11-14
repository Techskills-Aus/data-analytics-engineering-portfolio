with source as (

    select * from {{ source('raw', 'raw_encounter') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by encounter_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(encounter_id)             as encounter_id,
    trim(patient_id)               as patient_id,
    trim(facility_id)              as facility_id,
    trim(department_id)            as department_id,
    upper(trim(encounter_type))    as encounter_type,
    upper(trim(encounter_status))  as encounter_status,
    arrival_datetime,
    departure_datetime,
    upper(trim(arrival_mode))      as arrival_mode,
    triage_category,
    first_clinician_datetime,
    updated_at,
    ingestion_timestamp
from deduplicated
