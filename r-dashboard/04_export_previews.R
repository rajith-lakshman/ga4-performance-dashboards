# Export PNG previews of the R dashboard charts to docs/images/ (no Quarto needed).
# Requires: dplyr, ggplot2, readr, scales, tidyr, here. No login needed.

source(here::here("r-dashboard", "helpers.R"))

sample_note <- "SAMPLE DATA: Google Merchandise Store GA4 sample ecommerce dataset (obfuscated), 1 Nov 2020 to 31 Jan 2021. Not CMRD traffic."

previews <- list(
  "r-01-sessions"        = list(chart_sessions(), "How many sessions did the site get?", sample_note),
  "r-02-engagement-rate" = list(chart_engagement(), "How engaged were sessions? Engagement rate per day", sample_note),
  "r-03-new-returning"   = list(chart_users(), "New and returning users, share of daily active users by month", sample_note),
  "r-04-channel"         = list(share_plot(channel, "channel", "sessions"), "Channel mix, share of sessions by month", sample_note),
  "r-05-device"          = list(share_plot(device, "device_category", "sessions"), "Device split, share of sessions by month", sample_note),
  "r-06-funnel"          = list(chart_funnel(), paste("Sessions reaching each funnel step from", format(funnel_start, "%d %b %Y")), sample_note)
)

out_dir <- here::here("docs", "images")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

for (name in names(previews)) {
  p <- previews[[name]]
  plot <- p[[1]] +
    labs(title = p[[2]], caption = p[[3]]) +
    theme(plot.title = element_text(face = "bold"), plot.caption = element_text(size = 8, hjust = 0))
  ggsave(file.path(out_dir, paste0(name, ".png")), plot, width = 9, height = 5, dpi = 150, bg = "white")
  message("Wrote docs/images/", name, ".png")
}
