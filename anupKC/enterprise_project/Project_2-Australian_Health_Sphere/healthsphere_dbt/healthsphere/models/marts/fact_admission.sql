{{
    config(
        materialized='incremental',
        unique_key='admission_id',
        incremental_strategy='merge'
    )
}}

select
    admission_id,
    encounter_id,
    patient_id,
    facility_id,
    department_id,
    bed_id,
    admission_type,
    admission_status,
    admission_datetime,
    admission_datetime::date as admission_date,
    expected_discharge_date,
    discharge_id,
    discharge_datetime,
    discharge_disposition,
    medically_ready_datetime,
    length_of_stay_minutes,
    delayed_discharge_minutes,
    is_28_day_readmission,
    record_updated_at
from {{ ref('int_admissions') }}

{% if is_incremental() %}
where record_updated_at > (select max(record_updated_at) from {{ this }})
{% endif %}
