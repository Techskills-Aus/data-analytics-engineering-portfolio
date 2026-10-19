{{ config(
    materialized='incremental',
    unique_key='shift_id',
    incremental_strategy='merge'
) }}

select
    shift_id,
    employee_id,
    facility_id,
    department_id,
    shift_date,
    shift_name,
    role_name,
    shift_status,
    planned_hours,
    worked_hours,
    iff(shift_status = 'ABSENT', 1, 0)  as is_absent,
    iff(shift_status = 'AGENCY', 1, 0)  as is_agency,
    ingestion_timestamp
from {{ ref('stg_staff_roster') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
