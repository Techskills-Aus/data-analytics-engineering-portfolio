with
    dates
    as
    (

        select
            dateadd(day, seq4(), '2020-01-01'
    ::date) as date_day
    from table
(generator
(rowcount => 2922))   -- 2020-01-01 to 2027-12-31

)

select
    date_day,
    year(date_day)                          as year_number,
    quarter(date_day)                       as quarter_number,
    month(date_day)                         as month_number,
    monthname(date_day)                     as month_name,
    date_trunc('month', date_day)
::date     as month_start_date,
    to_char
(date_day, 'YYYY-MM')            as year_month,
    dayofweekiso
(date_day)                  as day_of_week_number,
    dayname
(date_day)                       as day_name,
    dayname
(date_day) in
('Sat', 'Sun')     as is_weekend
from dates