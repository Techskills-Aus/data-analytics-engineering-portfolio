with source as (

    select * from {{ source('raw', 'raw_department') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by department_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(department_id)           as department_id,
    trim(facility_id)             as facility_id,
    upper(trim(department_code))  as department_code,
    trim(department_name)         as department_name,
    upper(trim(department_class)) as department_class,
    planned_capacity,
    is_active,
    updated_at,
    ingestion_timestamp
from deduplicated
