select
    triage_category,
    triage_category_name,
    target_wait_minutes
from (
    values
        (1, 'Resuscitation', 0),
        (2, 'Emergency',     10),
        (3, 'Urgent',        30),
        (4, 'Semi-urgent',   60),
        (5, 'Non-urgent',    120)
) as t(triage_category, triage_category_name, target_wait_minutes)
