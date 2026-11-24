-- One row per session. Engaged = 10+ s engagement, a purchase, or 2+ page views (GA4 rule rebuilt from events).
-- session_engaged_param is kept only to compare against the sample's own flag.
select
    session_key,
    any_value(user_pseudo_id) as user_pseudo_id,
    min(event_date) as session_date,
    min(ga_session_number) as ga_session_number,
    coalesce(sum(engagement_time_msec), 0) as engagement_time_msec,
    countif(event_name = 'page_view') as page_views,
    countif(event_name = 'purchase') > 0 as has_purchase,
    logical_or(session_engaged_param = '1') as session_engaged_param,
    (
        coalesce(sum(engagement_time_msec), 0) >= 10000
        or countif(event_name = 'purchase') > 0
        or countif(event_name = 'page_view') >= 2
    ) as is_engaged,
    array_agg(device_category order by event_timestamp limit 1)[offset(0)] as device_category,
    array_agg(traffic_medium order by event_timestamp limit 1)[offset(0)] as traffic_medium,
    array_agg(traffic_source order by event_timestamp limit 1)[offset(0)] as traffic_source
from {{ ref('stg_ga4_events') }}
where ga_session_id is not null
group by session_key
