with source as (

    select * from {{ source('raw', 'raw_staff_roster') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by shift_id
        order by ingestion_timestamp desc
    ) = 1

)

select
    trim(shift_id)              as shift_id,
    trim(employee_id)           as employee_id,
    trim(facility_id)           as facility_id,
    trim(department_id)         as department_id,
    shift_date,
    upper(trim(shift_name))     as shift_name,
    start_time,
    end_time,
    upper(trim(role_name))      as role_name,
    planned_hours,
    worked_hours,
    upper(trim(shift_status))   as shift_status,
    ingestion_timestamp
from deduplicated
