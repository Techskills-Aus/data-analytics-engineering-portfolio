{{ config(
    materialized='incremental',
    unique_key='transfer_id',
    incremental_strategy='merge'
) }}

select
    t.transfer_id,
    t.admission_id,
    t.from_department_id,
    fd.facility_id          as from_facility_id,
    t.to_department_id,
    td.facility_id          as to_facility_id,
    t.from_bed_id,
    t.to_bed_id,
    t.transfer_datetime,
    t.transfer_datetime::date as transfer_date,
    t.transfer_reason,
    t.updated_at
from {{ ref('stg_patient_transfer') }} as t
left join {{ ref('dim_department') }} as fd
    on t.from_department_id = fd.department_id
left join {{ ref('dim_department') }} as td
    on t.to_department_id = td.department_id

{% if is_incremental() %}
where t.updated_at > (select max(updated_at) from {{ this }})
{% endif %}
