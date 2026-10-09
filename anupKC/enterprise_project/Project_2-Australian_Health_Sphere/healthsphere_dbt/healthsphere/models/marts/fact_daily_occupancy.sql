{{
    config(
        materialized='incremental',
        unique_key=['snapshot_date', 'facility_id', 'department_id'],
        incremental_strategy='merge'
    )
}}

select
    snapshot_date,
    facility_id,
    department_id,
    planned_beds,
    available_beds,
    occupied_beds,
    unavailable_beds,
    occupancy_rate,
    ingestion_timestamp
from {{ ref('int_daily_occupancy') }}

{% if is_incremental() %}
where ingestion_timestamp > (select max(ingestion_timestamp) from {{ this }})
{% endif %}
