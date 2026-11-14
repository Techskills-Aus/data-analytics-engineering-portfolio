{{ config(
    materialized='incremental',
    unique_key='diagnosis_id',
    incremental_strategy='merge'
) }}

select
    d.diagnosis_id,
    d.encounter_id,
    e.patient_id,
    e.facility_id,
    e.department_id,
    e.arrival_date          as encounter_date,
    d.diagnosis_code,
    d.diagnosis_description,
    d.diagnosis_group,
    d.diagnosis_type,
    d.recorded_datetime,
    d.updated_at
from {{ ref('stg_diagnosis') }} as d
left join {{ ref('fact_encounter') }} as e
    on d.encounter_id = e.encounter_id

{% if is_incremental() %}
where d.updated_at > (select max(updated_at) from {{ this }})
{% endif %}
