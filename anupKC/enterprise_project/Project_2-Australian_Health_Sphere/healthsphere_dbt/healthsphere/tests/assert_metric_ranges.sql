select 'occupancy_rate_out_of_range' as failed_rule, snapshot_date::varchar as record_key
from {{ ref('fact_daily_occupancy') }}
where occupancy_rate < 0 or occupancy_rate > 1

union all

select 'negative_length_of_stay' as failed_rule, admission_id::varchar as record_key
from {{ ref('fact_admission') }}
where length_of_stay_minutes < 0
