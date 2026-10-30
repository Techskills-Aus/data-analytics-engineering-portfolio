with source as (

    select * from {{ source('raw', 'raw_diagnosis') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by diagnosis_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(diagnosis_id)             as diagnosis_id,
    trim(encounter_id)             as encounter_id,
    upper(trim(diagnosis_code))    as diagnosis_code,
    trim(diagnosis_description)    as diagnosis_description,
    upper(trim(diagnosis_group))   as diagnosis_group,
    upper(trim(diagnosis_type))    as diagnosis_type,
    recorded_datetime,
    updated_at,
    ingestion_timestamp
from deduplicated
