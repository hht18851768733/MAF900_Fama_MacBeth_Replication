# Shared DP2 preparation: complete testing-period member-month panel.
# Keep listing status separate from return availability.
# This script does not yet apply a permanent-exit or re-entry rule.

library(dplyr)
library(tidyr)
library(lubridate)

# ---- Load inputs ----

periods <- readRDS(
  "data/processed/decision1/alternative_B/periods.rds"
)

portfolio_formation <- readRDS(
  "data/processed/common/decision2/portfolio_formation.rds"
)

stock_returns <- readRDS(
  "data/raw/decision1/alternative_B/nyse_common_1926_1968.rds"
)

listing_segments <- readRDS(
  "data/raw/decision1/alternative_B/nyse_listing_segments.rds"
)

# ---- Prepare monthly return records ----

monthly_returns <- stock_returns |>
  transmute(
    permno,
    month = floor_date(as.Date(date), "month"),
    ret,
    has_return_record = TRUE
  )

if (anyDuplicated(monthly_returns[c("permno", "month")]) > 0L) {
  stop("Duplicate stock-month return records found.")
}

# ---- Expand listing segments within the testing date range ----

first_month <- floor_date(min(periods$testing_start), "month")
last_month <- floor_date(max(periods$testing_end), "month")

listing_months <- listing_segments |>
  semi_join(
    portfolio_formation |> distinct(permno),
    by = "permno"
  ) |>
  mutate(
    start_month = pmax(
      floor_date(as.Date(namedt), "month"),
      first_month
    ),
    end_month = pmin(
      floor_date(as.Date(nameendt), "month"),
      last_month
    )
  ) |>
  filter(
    !is.na(start_month),
    !is.na(end_month),
    start_month <= end_month
  ) |>
  rowwise() |>
  mutate(month = list(seq(start_month, end_month, by = "month"))) |>
  ungroup() |>
  select(permno, month) |>
  unnest(month) |>
  distinct(permno, month) |>
  mutate(listed_nyse_common = TRUE)

# ---- Include every assigned security in every testing month ----

panels <- vector("list", nrow(periods))

for (i in seq_len(nrow(periods))) {
  
  current <- periods[i, ]
  
  members <- portfolio_formation |>
    filter(period_id == current$period_id) |>
    select(permno, portfolio)
  
  months <- seq(
    floor_date(current$testing_start, "month"),
    floor_date(current$testing_end, "month"),
    by = "month"
  )
  
  panels[[i]] <- expand_grid(
    permno = members$permno,
    month = months
  ) |>
    left_join(members, by = "permno") |>
    left_join(monthly_returns, by = c("permno", "month")) |>
    left_join(listing_months, by = c("permno", "month")) |>
    mutate(
      period_id = current$period_id,
      has_return_record = replace_na(has_return_record, FALSE),
      listed_nyse_common = replace_na(listed_nyse_common, FALSE),
      valid_return = is.finite(ret),
      .before = 1
    )
}

testing_panel <- bind_rows(panels) |>
  arrange(period_id, portfolio, month, permno)

# ---- Diagnose listing status and missing returns separately ----

panel_summary <- testing_panel |>
  group_by(period_id) |>
  summarise(
    n_months = n_distinct(month),
    assigned_stock_months = n(),
    listed_stock_months = sum(listed_nyse_common),
    listed_missing_return = sum(
      listed_nyse_common & !valid_return
    ),
    outside_listing_months = sum(!listed_nyse_common),
    valid_return_outside_listing = sum(
      !listed_nyse_common & valid_return
    ),
    .groups = "drop"
  )

# ---- Save complete panel and diagnostics ----

output_dir <- "data/processed/common/decision2"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  testing_panel,
  file.path(output_dir, "testing_member_month_panel.rds")
)

saveRDS(
  panel_summary,
  file.path(output_dir, "testing_panel_summary.rds")
)

print(panel_summary, n = 9, width = Inf)

cat("\nTesting-period panel completed.\n")
cat("Counts above are stock-month observations, not unique stocks.\n")