{{ config(
    materialized='incremental',
    unique_key='procedure_id',
    incremental_strategy='merge'
) }}

select
    p.procedure_id,
    p.encounter_id,
    e.patient_id,
    e.facility_id,
    e.department_id,
    e.arrival_date          as encounter_date,
    p.procedure_code,
    p.procedure_description,
    p.procedure_type,
    p.procedure_datetime,
    p.procedure_status,
    p.updated_at
from {{ ref('stg_procedure') }} as p
left join {{ ref('fact_encounter') }} as e
    on p.encounter_id = e.encounter_id

{% if is_incremental() %}
where p.updated_at > (select max(updated_at) from {{ this }})
{% endif %}
