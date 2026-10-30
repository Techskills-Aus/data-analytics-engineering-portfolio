with admissions as (

    select * from {{ ref('stg_admission') }}

),

discharges as (

    select * from {{ ref('stg_discharge') }}

),

joined as (

    select
        a.admission_id,
        a.encounter_id,
        a.patient_id,
        a.facility_id,
        a.department_id,
        a.bed_id,
        a.admission_type,
        a.admission_datetime,
        a.expected_discharge_date,
        a.admission_status,
        d.discharge_id,
        d.discharge_datetime,
        d.medically_ready_datetime,
        d.discharge_disposition,
        greatest(a.updated_at, coalesce(d.updated_at, a.updated_at))
            as record_updated_at
    from admissions a
    left join discharges d
        on a.admission_id = d.admission_id

),

ordered_admissions as (

    select
        *,
        lag(discharge_datetime) over (
            partition by patient_id
            order by admission_datetime
        ) as prior_discharge
    from joined

)

select
    *,
    datediff('minute', admission_datetime, discharge_datetime)
        as length_of_stay_minutes,
    greatest(datediff('minute', medically_ready_datetime, discharge_datetime), 0)
        as delayed_discharge_minutes,
    iff(prior_discharge is not null
        and admission_datetime <= dateadd(day, 28, prior_discharge), 1, 0)
        as is_28_day_readmission
from ordered_admissions
