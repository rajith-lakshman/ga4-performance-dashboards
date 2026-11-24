-- Channel is derived from traffic_source (user first-touch in this dataset), not session source.
select
    date_trunc(session_date, month) as month,
    case
        when traffic_medium = '(none)' then 'Direct'
        when traffic_medium = 'organic' then 'Organic Search'
        when traffic_medium = 'cpc' then 'Paid Search'
        when traffic_medium = 'referral' then 'Referral'
        else 'Other'
    end as channel,
    count(*) as sessions,
    countif(is_engaged) as engaged_sessions
from {{ ref('int_ga4_sessions') }}
group by month, channel
order by month, channel
