with capacity as (

    select * from {{ ref('stg_ward_capacity') }}

)

select
    snapshot_date,
    facility_id,
    department_id,
    planned_beds,
    available_beds,
    occupied_beds,
    unavailable_beds,
    div0null(occupied_beds, available_beds) as occupancy_rate,
    ingestion_timestamp
from capacity
