# R scripts and dashboard

Run from inside the repo; scripts use `here`, so the working directory does not matter.

| Step | Script | Login needed? |
|---|---|---|
| Validate the committed CSVs against the data contract | `02_validate_data.R` | No |
| Render the Quarto dashboard and copy it to `docs/r-dashboard.html` | `render.R` | No |
| Export PNG chart previews to `docs/images/` (no Quarto needed) | `04_export_previews.R` | No |
| Refresh `data/GA4-demo/` from BigQuery | `01_get_data.R` | Yes (Google account) |
| Check the raw sample for funnel gaps | `03_check_raw_funnel.R` | Yes (Google account) |
| Compare the engaged-session rule with the sample's `session_engaged` flag (about 1.6 GB scanned) | `05_check_engagement_rule.R` | Yes (Google account) |

`helpers.R` holds the data loading, the funnel window rule and the plot functions used by `dashboard.qmd`. The dashboard reads only `data/`.

## Packages

- Validate and render: `readr`, `dplyr`, `ggplot2` (3.5 or later), `scales`, `tidyr`, `here`, `knitr`, `rmarkdown`, plus [Quarto](https://quarto.org) (1.4 or later for dashboards).
- Refresh and raw check: `bigrquery`.

```r
install.packages(c("readr", "dplyr", "ggplot2", "scales", "tidyr", "here", "knitr", "rmarkdown"))
source("r-dashboard/02_validate_data.R")
source("r-dashboard/render.R")
```

## Refresh the data (optional)

Querying BigQuery, even a public dataset, needs a Google account and a project to bill (the free sandbox is enough). No key file is used; sign-in is in the browser and the project id is read from the environment, never stored in the repo.

```r
install.packages("bigrquery")
Sys.setenv(GCP_PROJECT_ID = "your-gcp-project-id")
source("r-dashboard/01_get_data.R")   # build the dbt marts first, see dbt/README.md
source("r-dashboard/02_validate_data.R")
```
