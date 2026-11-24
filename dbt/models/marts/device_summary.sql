select
    date_trunc(session_date, month) as month,
    coalesce(device_category, 'unknown') as device_category,
    count(*) as sessions,
    countif(is_engaged) as engaged_sessions
from {{ ref('int_ga4_sessions') }}
group by month, device_category
order by month, device_category
