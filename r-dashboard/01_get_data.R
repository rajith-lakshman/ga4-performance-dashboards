# Download the four dbt marts from BigQuery into data/GA4-demo/ (sample data only).
# Requires: bigrquery, readr, here. Authenticate once with bigrquery::bq_auth()
# (browser OAuth; no key file). Set GCP_PROJECT_ID in your environment (see .env.example);
# the project id is never stored in the repo.

library(bigrquery)
library(readr)

project <- Sys.getenv("GCP_PROJECT_ID")
dataset <- Sys.getenv("BQ_DATASET", unset = "ga4_dashboards_dev")
sample_dir <- here::here("data", "GA4-demo")

if (!nzchar(project)) {
  stop("Set GCP_PROJECT_ID to your Google Cloud project id (see .env.example).", call. = FALSE)
}

marts <- c("daily_kpis", "channel_summary", "device_summary", "funnel_daily")

dir.create(sample_dir, recursive = TRUE, showWarnings = FALSE)

for (mart in marts) {
  df <- bq_table_download(
    bq_table(project, dataset, mart),
    bigint = "integer",
    page_size = 500
  )
  write_csv(df, file.path(sample_dir, paste0(mart, ".csv")))
  message(mart, ": ", nrow(df), " rows")
}
