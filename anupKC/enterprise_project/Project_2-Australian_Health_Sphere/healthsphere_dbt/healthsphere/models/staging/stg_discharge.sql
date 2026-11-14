with source as (

    select * from {{ source('raw', 'raw_discharge') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by discharge_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(discharge_id)                 as discharge_id,
    trim(admission_id)                 as admission_id,
    discharge_datetime,
    medically_ready_datetime,
    upper(trim(discharge_disposition)) as discharge_disposition,
    upper(trim(discharge_status))      as discharge_status,
    updated_at,
    ingestion_timestamp
from deduplicated
