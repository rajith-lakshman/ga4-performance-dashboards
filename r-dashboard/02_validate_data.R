# Validate the data contract (docs/dashboard-spec.md) on the committed CSVs.
# No login needed: reads only data/GA4-demo/.
# Requires: readr, dplyr, here.
# Hard failures stop the script. Known data issues are reported as warnings.

library(readr)
library(dplyr)

read <- function(...) read_csv(here::here(...), show_col_types = FALSE)

daily   <- read("data", "GA4-demo", "daily_kpis.csv")
channel <- read("data", "GA4-demo", "channel_summary.csv")
device  <- read("data", "GA4-demo", "device_summary.csv")
funnel  <- read("data", "GA4-demo", "funnel_daily.csv")

failures <- character()
check <- function(ok, msg) {
  cat(if (isTRUE(ok)) "PASS " else "FAIL ", msg, "\n", sep = "")
  if (!isTRUE(ok)) failures <<- c(failures, msg)
}

# Columns match the data contract
check(identical(names(daily), c("date", "sessions", "engaged_sessions", "users", "new_users", "returning_users")), "daily_kpis columns")
check(identical(names(channel), c("month", "channel", "sessions", "engaged_sessions")), "channel_summary columns")
check(identical(names(device), c("month", "device_category", "sessions", "engaged_sessions")), "device_summary columns")
check(identical(names(funnel), c("date", "step_order", "step", "sessions")), "funnel_daily columns")

# Completeness and keys
check(sum(is.na(daily)) + sum(is.na(channel)) + sum(is.na(device)) + sum(is.na(funnel)) == 0, "no missing values in sample marts")
check(!anyDuplicated(daily$date), "daily_kpis: one row per date")
check(!anyDuplicated(funnel[c("date", "step")]), "funnel_daily: one row per date and step")
check(identical(funnel$step[match(1:4, funnel$step_order)], c("view_item", "add_to_cart", "begin_checkout", "purchase")), "funnel step_order matches step names")

# Internal consistency
check(all(daily$engaged_sessions <= daily$sessions), "engaged sessions <= sessions")
check(all(daily$users <= daily$sessions), "users <= sessions")
check(all(daily$new_users + daily$returning_users == daily$users), "new + returning = users")
check(sum(daily$sessions) == sum(channel$sessions) && sum(daily$sessions) == sum(device$sessions), "sessions total agrees across daily, channel and device")
check(sum(daily$engaged_sessions) == sum(channel$engaged_sessions) && sum(daily$engaged_sessions) == sum(device$engaged_sessions), "engaged total agrees across daily, channel and device")
check(all(funnel$sessions <= daily$sessions[match(funnel$date, daily$date)]), "funnel sessions <= daily sessions")

# Known issues: reported, not failed
missing_steps <- funnel |>
  count(date) |>
  right_join(tibble(date = daily$date), by = "date") |>
  mutate(n = coalesce(n, 0L)) |>
  filter(n < 4)
if (nrow(missing_steps) > 0) {
  warning(
    nrow(missing_steps), " days lack at least one funnel step (", min(missing_steps$date), " to ",
    max(missing_steps$date), "). Funnel views must handle this; see docs/dashboard-spec.md.",
    call. = FALSE
  )
}

if (length(failures) > 0) stop(length(failures), " check(s) failed.", call. = FALSE)
cat("\nAll checks passed.\n")
