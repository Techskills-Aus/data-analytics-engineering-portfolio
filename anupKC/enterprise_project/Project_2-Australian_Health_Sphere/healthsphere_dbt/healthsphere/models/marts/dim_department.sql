select
    d.department_id,
    d.department_code,
    d.department_name,
    d.department_class,
    d.planned_capacity,
    d.is_active,
    d.facility_id,
    f.facility_name,
    f.state_code
from {{ ref('stg_department') }} d
left join {{ ref('stg_facility') }} f
    on d.facility_id = f.facility_id
