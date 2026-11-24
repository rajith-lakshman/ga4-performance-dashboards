-- Sessions with at least one event of each step; step order within a session is not checked.
select
    event_date as date,
    case event_name
        when 'view_item' then 1
        when 'add_to_cart' then 2
        when 'begin_checkout' then 3
        when 'purchase' then 4
    end as step_order,
    event_name as step,
    count(distinct session_key) as sessions
from {{ ref('stg_ga4_events') }}
where event_name in ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
  and ga_session_id is not null
group by date, step_order, step
order by date, step_order
