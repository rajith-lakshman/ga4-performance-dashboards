-- One row per event, only the columns the marts need, filtered by shard date.
select
    parse_date('%Y%m%d', event_date) as event_date,
    event_timestamp,
    event_name,
    user_pseudo_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id') as ga_session_id,
    (select value.int_value from unnest(event_params) where key = 'ga_session_number') as ga_session_number,
    (select value.int_value from unnest(event_params) where key = 'engagement_time_msec') as engagement_time_msec,
    (select value.string_value from unnest(event_params) where key = 'session_engaged') as session_engaged_param,
    (select value.string_value from unnest(event_params) where key = 'page_location') as page_location,
    device.category as device_category,
    traffic_source.medium as traffic_medium,
    traffic_source.source as traffic_source,
    concat(
        user_pseudo_id, '-',
        cast((select value.int_value from unnest(event_params) where key = 'ga_session_id') as string)
    ) as session_key
from {{ source('ga4_sample', 'events') }}
where _table_suffix between '{{ var("start_date") }}' and '{{ var("end_date") }}'
  and event_name in (
      'page_view', 'user_engagement', 'first_visit', 'session_start',
      'view_item', 'add_to_cart', 'begin_checkout', 'purchase'
  )
  and user_pseudo_id is not null
