with source as (

    select * from {{ source('raw', 'raw_admission') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by admission_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(admission_id)            as admission_id,
    trim(encounter_id)            as encounter_id,
    trim(patient_id)              as patient_id,
    trim(facility_id)             as facility_id,
    trim(department_id)           as department_id,
    trim(bed_id)                  as bed_id,
    upper(trim(admission_type))   as admission_type,
    admission_datetime,
    expected_discharge_date,
    upper(trim(admission_status)) as admission_status,
    updated_at,
    ingestion_timestamp
from deduplicated
