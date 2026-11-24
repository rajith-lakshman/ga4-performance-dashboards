# dbt project: GA4 sample marts

Reads the public GA4 sample ecommerce dataset (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`, location US) and builds the tables in the data contract (`docs/dashboard-spec.md`). All outputs are **sample data**.

Layers: `staging/stg_ga4_events` (view) -> `intermediate/int_ga4_sessions` (view, one row per session; `session_key` tested `not_null` and `unique`) -> `marts/` (`daily_kpis`, `channel_summary`, `device_summary`, `funnel_daily`, tables). No incremental models, so it works in the BigQuery sandbox.

## One-time setup (no keys, nothing stored in the repo)

1. Use a Google Cloud project with BigQuery sandbox or billing (free tier). Note its project id; do not commit it.
2. Install the Google Cloud SDK, then sign in with browser OAuth:
   ```
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project YOUR_GCP_PROJECT_ID
   ```
3. Copy the block from `dbt/profiles.example.yml` into `~/.dbt/profiles.yml` (Windows: `%USERPROFILE%\.dbt\profiles.yml`), replacing `YOUR_GCP_PROJECT_ID`. Keep `location: US`.
4. Check: `cd dbt && dbt debug`.

## Build, test, docs

```
cd dbt
dbt build            # builds models and runs tests
dbt docs generate    # writes target/ (git-ignored)
```

## Export marts to CSV in data/GA4-demo/

Run the export script from the repo root. It needs R with `bigrquery`, `readr` and `here`, and uses browser sign-in (`bigrquery::bq_auth()`, no key file). Set your project id in the environment first (not stored in the repo; see `.env.example`):

```r
Sys.setenv(GCP_PROJECT_ID = "your-gcp-project-id")
source("r-dashboard/01_get_data.R")
```

This writes `daily_kpis.csv`, `channel_summary.csv`, `device_summary.csv` and `funnel_daily.csv` to `data/GA4-demo/`.

Check each file's header against the data contract and that no status text was written into the CSV.

## Fallback

If dbt cannot be run in the time available, the same logic will be provided as plain SQL in `sql/` (not created unless needed).
