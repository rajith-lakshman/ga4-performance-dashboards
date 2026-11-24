# Dashboard specification

Scope: the GA4 sample ecommerce dashboards only (Power BI, R, Python). The separate CMRD web analytics project is in `cmrd-analytics/`. Figures are never stated here; all numbers come from the CSVs at render time.

## Purpose and audience

The same KPI views are built three ways (Power BI, R/Quarto, Python/Plotly) to show one measurement logic in different tools. Intended audience: performance analysts and service owners in public-sector digital services, and portfolio reviewers.

## Data sources

| Source | Content | Notes |
|---|---|---|
| GA4 sample ecommerce (BigQuery public dataset `ga4_obfuscated_sample_ecommerce`, Google Merchandise Store, Nov 2020 to Jan 2021) | Aggregated marts in `data/GA4-demo/` | **Sample data.** Obfuscated. Not CMRD traffic. Every page labels it. |

## Data contract

Dashboards read only these files. Rates are computed in the dashboard as sum(numerator) / sum(denominator); stored values are never averaged.

| File | Grain | Columns |
|---|---|---|
| `data/GA4-demo/daily_kpis.csv` | day | `date, sessions, engaged_sessions, users, new_users, returning_users` |
| `data/GA4-demo/channel_summary.csv` | month x channel | `month, channel, sessions, engaged_sessions` |
| `data/GA4-demo/device_summary.csv` | month x device | `month, device_category, sessions, engaged_sessions` |
| `data/GA4-demo/funnel_daily.csv` | day x step | `date, step_order, step, sessions` |

`step` values: `view_item` (1), `add_to_cart` (2), `begin_checkout` (3), `purchase` (4). `date` is ISO `YYYY-MM-DD`; `month` is the first day of the month.

## Views, questions and KPIs

| Page (title = question) | KPIs |
|---|---|
| Overview: How many sessions did the site get, and how engaged were they? | Sessions, engaged sessions, engagement rate |
| Audience: Who visited: new or returning users, which channels and devices? | New vs returning users, channel mix, device split |
| Funnel: Where do sessions drop out between viewing an item and purchasing? | Funnel sessions per step, step drop-off |

## KPI definitions

| KPI | Definition |
|---|---|
| Sessions | Distinct session key: `user_pseudo_id` + `ga_session_id`. |
| Engaged sessions | Sessions meeting GA4's engaged-session rule (10+ seconds of engagement, a conversion event, or 2+ page views). The rule is rebuilt from events (dbt `int_ga4_sessions`), not taken from the sample's `session_engaged` flag; see limitations. |
| Engagement rate | Engaged sessions / sessions. |
| Users | Distinct `user_pseudo_id` active in the period. Not additive across days. |
| New users | Users with a session where `ga_session_number = 1` on that day (daily distinct; not additive across days). |
| Returning users | Users active that day who are not new that day. |
| New / returning share | New (or returning) users divided by daily active users, summed over the period: a share of user-days, not of distinct users. |
| Channel mix | Share of sessions by channel, grouped from the traffic source medium/source. Grouping: medium `(none)` is Direct, `organic` is Organic Search, `cpc` is Paid Search, `referral` is Referral, anything else is Other. |
| Device split | Share of sessions by device category. |
| Funnel sessions | Sessions with at least one of the step's event. Step order inside a session is not checked. Shown only for the funnel window: from 2020-11-25 (the day after the last day with a missing step; the raw sample has no add_to_cart events on most days from 2020-11-01 to 2020-11-24 and only partial counts on 2020-11-16 to 2020-11-20) to 2021-01-31. |
| Step drop-off | 1 - (sessions at step / sessions at previous step). |

## Accessibility and content rules (every page)

- Title states the question; short footnote defining each KPI; limitations footnote.
- Colour-blind-safe palette (Okabe-Ito); no meaning conveyed by colour alone (direct labels or patterns); alt text on charts.
- Sample-data label on all GA4 views.
- No personal data. Only aggregates are exported; `user_pseudo_id` never leaves BigQuery.

## Refresh method

1. `dbt build` against the public dataset (BigQuery sandbox, US location, views/tables only).
2. Export each mart to CSV in `data/GA4-demo/` (see README).
3. Re-render the R dashboard to `docs/`; rebuild the Python dashboard; refresh Power BI.

The sample data is static, so refresh is manual and only needed when logic changes.

## Limitations

- GA4 sample is a different organisation's ecommerce site, obfuscated, covering about three months. Patterns here do not describe CMRD users.
- Channel comes from `traffic_source`, which is the user's first-touch source in this dataset rather than the session's source. About a fifth of sessions fall in "Other" (any medium that is not none, organic, cpc or referral).
- The daily engagement rate steps from about 40% to about 90% on 28 to 29 December 2020 (55% on the 28th, 87% on the 29th). A weekly comparison on the raw events (`r-dashboard/05_check_engagement_rule.R`) shows the cause is the page-view component: the share of sessions with 2 or more page views rises from about a third (week of 21 Dec: 33%) to about 83% (week of 28 Dec) and 89% after, while the share with 10 or more seconds of engagement stays flat or falls (about 37% to 34%). GA4's own `session_engaged` flag jumps at the same time (47% to 85%), so the step is in the sample data itself, not an artefact of the rebuilt rule. Why page views per session jumped is unknown (possibly a tracking change); do not read it as a change in user behaviour.
- The rebuilt rule (as built, on the events kept by the staging model) runs about 4 to 5 percentage points below the sample's flag before the jump and about 1 point below it after. Using engagement time from all events brings it within about 1 point of the flag (week of 2 Nov: 55.5% against 56.6%). This was left as built.
- Funnel steps are not sequence-checked; drop-off is indicative. The funnel excludes 2020-11-01 to 2020-11-24 because add_to_cart is missing or partial in the raw sample (found by comparing raw event counts with the marts; `r-dashboard/03_check_raw_funnel.R`).
- New/returning and users counts are daily distinct and not additive.
- Obfuscation and null values in some fields may affect counts.
