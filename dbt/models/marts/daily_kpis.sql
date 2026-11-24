-- users, new_users and returning_users are daily distinct counts (not additive across days).
select
    session_date as date,
    count(*) as sessions,
    countif(is_engaged) as engaged_sessions,
    count(distinct user_pseudo_id) as users,
    count(distinct if(ga_session_number = 1, user_pseudo_id, null)) as new_users,
    count(distinct user_pseudo_id)
        - count(distinct if(ga_session_number = 1, user_pseudo_id, null)) as returning_users
from {{ ref('int_ga4_sessions') }}
group by date
order by date
