select
    admission_id,
    admission_datetime,
    discharge_datetime
from {{ ref('int_admissions') }}
where discharge_datetime < admission_datetime
