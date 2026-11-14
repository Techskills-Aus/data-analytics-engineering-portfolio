select
    e.encounter_id,
    e.facility_id,
    e.department_id,
    e.arrival_date,
    e.triage_category,
    e.waiting_minutes,
    t.target_wait_minutes,
    iff(e.waiting_minutes <= t.target_wait_minutes, 1, 0) as is_seen_within_target
from {{ ref('fact_encounter') }} as e
inner join {{ ref('dim_triage_category') }} as t
    on e.triage_category = t.triage_category
where e.encounter_type = 'EMERGENCY'
  and e.waiting_minutes is not null
