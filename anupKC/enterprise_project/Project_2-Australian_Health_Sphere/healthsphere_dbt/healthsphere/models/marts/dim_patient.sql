select
    patient_id,
    year(date_of_birth) as birth_year,
    sex_at_birth,
    suburb,
    state_code,
    postcode,
    country_of_birth,
    indigenous_status
from {{ ref('stg_patient') }}
