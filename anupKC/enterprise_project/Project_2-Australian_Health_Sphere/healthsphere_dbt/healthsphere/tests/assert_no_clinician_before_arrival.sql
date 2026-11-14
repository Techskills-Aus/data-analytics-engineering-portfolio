select encounter_id, arrival_datetime, first_clinician_datetime
from {{ ref('fact_encounter') }}
where first_clinician_datetime < arrival_datetime
