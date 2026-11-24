# Shared data loading and plotting helpers for the Quarto dashboard.
# Reads only data/GA4-demo/. No login needed.
# Requires: dplyr, ggplot2, readr, scales, here (plus knitr and rmarkdown to render).

library(dplyr)
library(ggplot2)
library(readr)
library(scales)

# Okabe-Ito colour-blind-safe palette
okabe_ito <- c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#56B4E9", "#D55E00", "#F0E442", "#999999")

read_data <- function(...) read_csv(here::here("data", ...), show_col_types = FALSE)

daily   <- read_data("GA4-demo", "daily_kpis.csv")
channel <- read_data("GA4-demo", "channel_summary.csv")
device  <- read_data("GA4-demo", "device_summary.csv")
funnel  <- read_data("GA4-demo", "funnel_daily.csv")

funnel_steps <- c("view_item", "add_to_cart", "begin_checkout", "purchase")

# Funnel window starts the day after the last day with a missing funnel step
# (the raw GA4 sample has no add_to_cart events on some days in Nov 2020).
incomplete_days <- funnel |>
  count(date) |>
  right_join(tibble(date = daily$date), by = "date") |>
  mutate(n = coalesce(n, 0L)) |>
  filter(n < 4)
funnel_start <- max(incomplete_days$date) + 1
funnel_window <- funnel |> filter(date >= funnel_start)

theme_dash <- function() {
  theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(), plot.title = element_blank())
}

month_levels <- function(x) format(sort(unique(x)), "%b %Y")

line_plot <- function(df, y_lab) {
  ggplot(df, aes(date, value, colour = series, linetype = series)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = okabe_ito[c(1, 2)]) +
    scale_y_continuous(labels = comma, limits = c(0, NA)) +
    labs(x = NULL, y = y_lab, colour = NULL, linetype = NULL) +
    theme_dash()
}

# Stacked 100% bars by month; labels and patterned legend order avoid relying on colour alone
share_plot <- function(df, category, share_of) {
  d <- df |>
    mutate(month_lbl = factor(format(month, "%b %Y"), levels = rev(month_levels(month)))) |>
    group_by(month_lbl) |>
    mutate(share = .data[[share_of]] / sum(.data[[share_of]])) |>
    ungroup()
  stack <- position_stack(vjust = 0.5, reverse = TRUE)
  ggplot(d, aes(share, month_lbl, fill = .data[[category]])) +
    geom_col(width = 0.7, colour = "white", position = position_stack(reverse = TRUE)) +
    geom_label(
      aes(label = ifelse(share >= 0.04, percent(share, accuracy = 1), "")),
      position = stack, size = 3, fill = "white", linewidth = 0, show.legend = FALSE
    ) +
    scale_fill_manual(values = okabe_ito) +
    scale_x_continuous(labels = percent) +
    guides(fill = guide_legend(nrow = 2)) +
    labs(x = "Share", y = NULL, fill = NULL) +
    theme_dash()
}

funnel_table <- function() {
  funnel_window |>
    group_by(step_order, step) |>
    summarise(sessions = sum(sessions), .groups = "drop") |>
    arrange(step_order) |>
    mutate(drop_off = 1 - sessions / lag(sessions))
}

# Chart builders shared by dashboard.qmd and 04_export_previews.R
chart_sessions <- function() {
  daily |>
    transmute(date, `Sessions` = sessions, `Engaged sessions` = engaged_sessions) |>
    tidyr::pivot_longer(-date, names_to = "series", values_to = "value") |>
    line_plot("Sessions per day")
}

chart_engagement <- function() {
  daily |>
    mutate(rate = engaged_sessions / sessions) |>
    ggplot(aes(date, rate)) +
    geom_line(linewidth = 0.8, colour = okabe_ito[1]) +
    scale_y_continuous(labels = percent, limits = c(0, 1)) +
    labs(x = NULL, y = "Engagement rate") +
    theme_dash()
}

chart_users <- function() {
  daily |>
    mutate(month = as.Date(format(date, "%Y-%m-01"))) |>
    group_by(month) |>
    summarise(`New users` = sum(new_users), `Returning users` = sum(returning_users), .groups = "drop") |>
    tidyr::pivot_longer(-month, names_to = "type", values_to = "n") |>
    share_plot("type", "n")
}

chart_funnel <- function() {
  funnel_table() |>
    ggplot(aes(sessions, reorder(step, -step_order))) +
    geom_col(fill = okabe_ito[1], width = 0.7) +
    geom_text(aes(label = comma(sessions)), hjust = -0.1, size = 3.5) +
    scale_x_continuous(labels = comma, expand = expansion(mult = c(0, 0.15))) +
    labs(x = "Sessions", y = NULL) +
    theme_dash()
}
