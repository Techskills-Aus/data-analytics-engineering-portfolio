with source as (

    select * from {{ source('raw', 'raw_department_target') }}

),

parsed as (

    select
        trim(payload:department_id::string)          as department_id,
        lower(trim(payload:metric_code::string))     as metric_code,
        try_to_date(payload:effective_from::string)  as effective_from,
        try_to_date(payload:effective_to::string)    as effective_to,
        payload:target_value::number(10, 2)          as target_value,
        source_file_name,
        ingestion_timestamp
    from source

),

deduplicated as (

    select *
    from parsed
    qualify row_number() over (
        partition by department_id, metric_code, effective_from
        order by ingestion_timestamp desc
    ) = 1

)

select * from deduplicated
