with source as (

    select * from {{ source('raw', 'raw_patient_transfer') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by transfer_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(transfer_id)             as transfer_id,
    trim(admission_id)            as admission_id,
    trim(from_department_id)      as from_department_id,
    trim(to_department_id)        as to_department_id,
    trim(from_bed_id)             as from_bed_id,
    trim(to_bed_id)               as to_bed_id,
    transfer_datetime,
    upper(trim(transfer_reason))  as transfer_reason,
    updated_at,
    ingestion_timestamp
from deduplicated
