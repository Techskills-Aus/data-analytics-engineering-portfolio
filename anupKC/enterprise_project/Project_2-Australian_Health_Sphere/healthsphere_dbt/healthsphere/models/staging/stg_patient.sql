with source as (

    select * from {{ source('raw', 'raw_patient') }}

),

deduplicated as (

    select *
    from source
    qualify row_number() over (
        partition by patient_id
        order by updated_at desc nulls last, ingestion_timestamp desc
    ) = 1

)

select
    trim(patient_id)               as patient_id,
    initcap(trim(given_name))      as given_name,
    initcap(trim(family_name))     as family_name,
    date_of_birth,
    upper(trim(sex_at_birth))      as sex_at_birth,
    initcap(trim(suburb))          as suburb,
    upper(trim(state_code))        as state_code,
    trim(postcode)                 as postcode,
    trim(country_of_birth)         as country_of_birth,
    upper(trim(indigenous_status)) as indigenous_status,
    created_at,
    updated_at,
    ingestion_timestamp
from deduplicated
