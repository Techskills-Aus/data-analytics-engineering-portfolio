with encounters as (

    select * from {{ ref('stg_encounter') }}

)

select
    encounter_id,
    patient_id,
    facility_id,
    department_id,
    encounter_type,
    encounter_status,
    arrival_datetime,
    first_clinician_datetime,
    departure_datetime,
    arrival_mode,
    triage_category,
    datediff('minute', arrival_datetime, first_clinician_datetime)
        as waiting_minutes,
    datediff('minute', arrival_datetime, departure_datetime)
        as time_in_department_minutes,
    updated_at
from encounters
