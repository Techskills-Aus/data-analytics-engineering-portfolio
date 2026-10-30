with source as (

    select * from {{ source('raw', 'raw_procedure') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by procedure_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(procedure_id)              as procedure_id,
    trim(encounter_id)              as encounter_id,
    upper(trim(procedure_code))     as procedure_code,
    trim(procedure_description)     as procedure_description,
    upper(trim(procedure_type))     as procedure_type,
    procedure_datetime,
    upper(trim(procedure_status))   as procedure_status,
    updated_at,
    ingestion_timestamp
from deduplicated
