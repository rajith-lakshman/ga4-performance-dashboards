# OPTIONAL: check whether missing funnel days exist in the raw public GA4 sample.
# Needs a Google sign-in (bigrquery::bq_auth()) and GCP_PROJECT_ID, because BigQuery
# queries always bill to your own project (about 100 MB scanned; inside the free tier).
# Not needed to run validation or the dashboards.

library(bigrquery)

project <- Sys.getenv("GCP_PROJECT_ID")
if (!nzchar(project)) stop("Set GCP_PROJECT_ID (see .env.example).", call. = FALSE)

sql <- "
select parse_date('%Y%m%d', event_date) as date,
  countif(event_name = 'view_item') as view_item,
  countif(event_name = 'add_to_cart') as add_to_cart,
  countif(event_name = 'begin_checkout') as begin_checkout,
  countif(event_name = 'purchase') as purchase
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where _table_suffix between '20201101' and '20210131'
group by date
order by date"

raw <- bq_table_download(bq_project_query(project, sql), bigint = "integer")
cat("Days with zero add_to_cart events in the raw sample:", sum(raw$add_to_cart == 0), "\n")
print(raw[raw$add_to_cart < 20, ], n = Inf)
