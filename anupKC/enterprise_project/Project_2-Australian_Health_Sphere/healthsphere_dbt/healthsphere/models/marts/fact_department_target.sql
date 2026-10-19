select
    t.department_id,
    d.facility_id,
    t.metric_code,
    t.target_value,
    t.effective_from,
    t.effective_to
from {{ ref('stg_department_target') }} as t
left join {{ ref('dim_department') }} as d
    on t.department_id = d.department_id
