# OPTIONAL: compare the rebuilt engaged-session rule with the sample's own session_engaged flag,
# by week, on the raw public GA4 sample. Needs a Google sign-in (bigrquery::bq_auth()) and
# GCP_PROJECT_ID. Scans about 1.6 GB of BigQuery (inside the free monthly allowance).
# Not needed to validate data or render the dashboards.
#
# Columns (shares of sessions):
#   rule_as_built        the rule on the events the dbt staging model keeps
#   rule_all_events      the same rule using engagement time from all events
#   flag_session_engaged sessions with session_engaged = '1' on any event
#   t10_*, pv2, purchase the three components of the rule

library(bigrquery)
library(dplyr)

project <- Sys.getenv("GCP_PROJECT_ID")
if (!nzchar(project)) stop("Set GCP_PROJECT_ID (see .env.example).", call. = FALSE)

sql <- "
with ev as (
  select
    parse_date('%Y%m%d', event_date) as d,
    concat(user_pseudo_id, '-', cast((select value.int_value from unnest(event_params) where key = 'ga_session_id') as string)) as session_key,
    (select value.int_value from unnest(event_params) where key = 'ga_session_id') as sid,
    event_name,
    (select value.int_value from unnest(event_params) where key = 'engagement_time_msec') as ms,
    (select value.string_value from unnest(event_params) where key = 'session_engaged') as se
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  where _table_suffix between '20201101' and '20210131' and user_pseudo_id is not null
),
sess as (
  select session_key, min(d) as d,
    sum(coalesce(ms, 0)) as ms_all,
    sum(if(event_name in ('page_view','user_engagement','first_visit','session_start','view_item','add_to_cart','begin_checkout','purchase'), coalesce(ms, 0), 0)) as ms_kept,
    countif(event_name = 'page_view') as pv,
    countif(event_name = 'purchase') > 0 as purch,
    logical_or(se = '1') as flag
  from ev where sid is not null group by session_key
)
select date_trunc(d, week(monday)) as week, count(*) as sessions,
  countif(ms_kept >= 10000 or purch or pv >= 2) as rule_as_built,
  countif(ms_all >= 10000 or purch or pv >= 2) as rule_all_events,
  countif(flag) as flag_session_engaged,
  countif(ms_kept >= 10000) as t10_kept,
  countif(ms_all >= 10000) as t10_all,
  countif(pv >= 2) as pv2,
  countif(purch) as purchase
from sess group by week order by week"

weekly <- bq_table_download(bq_project_query(project, sql), bigint = "integer")
weekly |>
  mutate(across(-c(week, sessions), \(x) round(x / sessions, 3))) |>
  print(n = Inf, width = Inf)
