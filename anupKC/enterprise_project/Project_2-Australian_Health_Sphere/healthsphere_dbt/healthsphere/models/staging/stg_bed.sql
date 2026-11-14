with source as (

    select * from {{ source('raw', 'raw_bed') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by bed_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(bed_id)                    as bed_id,
    trim(department_id)             as department_id,
    trim(ward_name)                 as ward_name,
    trim(room_number)               as room_number,
    trim(bed_number)                as bed_number,
    upper(trim(bed_type))           as bed_type,
    upper(trim(operational_status)) as operational_status,
    updated_at,
    ingestion_timestamp
from deduplicated
