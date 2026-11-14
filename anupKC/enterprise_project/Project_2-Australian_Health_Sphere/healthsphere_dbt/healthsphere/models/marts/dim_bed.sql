select
    b.bed_id,
    b.ward_name,
    b.room_number,
    b.bed_number,
    b.bed_type,
    b.operational_status,
    b.department_id,
    d.department_name,
    d.facility_id,
    d.facility_name
from {{ ref('stg_bed') }} b
left join {{ ref('dim_department') }} d
    on b.department_id = d.department_id
