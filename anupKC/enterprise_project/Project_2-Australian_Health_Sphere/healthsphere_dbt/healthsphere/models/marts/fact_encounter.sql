{{
    config(
        materialized='incremental',
        unique_key='encounter_id',
        incremental_strategy='merge'
    )
}}

select
    encounter_id,
    patient_id,
    facility_id,
    department_id,
    encounter_type,
    encounter_status,
    arrival_datetime,
    arrival_datetime::date as arrival_date,
    first_clinician_datetime,
    departure_datetime,
    arrival_mode,
    triage_category,
    waiting_minutes,
    time_in_department_minutes,
    updated_at
from {{ ref('int_encounters') }}

{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
