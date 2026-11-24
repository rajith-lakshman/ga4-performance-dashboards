# Render the Quarto dashboard and copy the self-contained HTML to docs/ for GitHub Pages.
# Requires: Quarto (https://quarto.org), and R packages knitr, rmarkdown, plus those in helpers.R.
# No login needed.

input <- here::here("r-dashboard", "dashboard.qmd")
status <- system2("quarto", c("render", shQuote(input)))
if (status != 0) stop("quarto render failed", call. = FALSE)

dir.create(here::here("docs"), showWarnings = FALSE)
file.copy(
  here::here("r-dashboard", "dashboard.html"),
  here::here("docs", "r-dashboard.html"),
  overwrite = TRUE
)
message("Wrote docs/r-dashboard.html")
