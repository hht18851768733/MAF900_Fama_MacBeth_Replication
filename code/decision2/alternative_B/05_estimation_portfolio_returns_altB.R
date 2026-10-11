# Decision 2, Alternative B.
# Construct portfolio returns over each 60-month ESTIMATION window.
# These returns are for Table 2, separate from testing-period returns.

library(dplyr)
library(tidyr)
library(lubridate)

periods <- readRDS(
  "data/processed/decision1/alternative_B/periods.rds"
)

portfolio_formation <- readRDS(
  "data/processed/common/decision2/portfolio_formation.rds"
)

stock_returns <- readRDS(
  "data/raw/decision1/alternative_B/nyse_common_1926_1968.rds"
)

monthly_returns <- stock_returns |>
  transmute(
    permno,
    month = floor_date(as.Date(date), "month"),
    ret
  )

if (anyDuplicated(monthly_returns[c("permno", "month")]) > 0L) {
  stop("Duplicate stock-month observations found.")
}

# ---- Complete member-month panel for the estimation windows ----
# DP1-B already requires all 60 listed months in these windows.
# Every assigned security is therefore an expected member throughout.

panels <- vector("list", nrow(periods))

for (i in seq_len(nrow(periods))) {
  
  current <- periods[i, ]
  
  members <- portfolio_formation |>
    filter(period_id == current$period_id) |>
    select(permno, portfolio)
  
  months <- seq(
    floor_date(current$estimation_start, "month"),
    floor_date(current$estimation_end, "month"),
    by = "month"
  )
  
  if (length(months) != 60L) {
    stop("An estimation window does not contain 60 months.")
  }
  
  panels[[i]] <- expand_grid(
    permno = members$permno,
    month = months
  ) |>
    left_join(members, by = "permno") |>
    left_join(monthly_returns, by = c("permno", "month")) |>
    mutate(
      period_id = current$period_id,
      .before = 1
    )
}

estimation_panel <- bind_rows(panels) |>
  arrange(period_id, portfolio, month, permno)

# ---- Apply Alternative B to estimation-period portfolio returns ----

estimation_returns_B <- estimation_panel |>
  group_by(period_id, portfolio, month) |>
  summarise(
    n_expected = n(),
    n_valid = sum(is.finite(ret)),
    n_missing = sum(!is.finite(ret)),
    
    portfolio_return = if (all(is.finite(ret))) {
      mean(ret)
    } else {
      NA_real_
    },
    
    .groups = "drop"
  ) |>
  arrange(period_id, portfolio, month)

# ---- Coverage diagnostics ----

portfolio_coverage <- estimation_returns_B |>
  group_by(period_id, portfolio) |>
  summarise(
    n_calendar_months = n(),
    n_valid_months = sum(is.finite(portfolio_return)),
    .groups = "drop"
  )

coverage_summary <- portfolio_coverage |>
  group_by(period_id) |>
  summarise(
    n_portfolios = n(),
    total_portfolio_months = sum(n_calendar_months),
    valid_portfolio_months = sum(n_valid_months),
    min_valid_months = min(n_valid_months),
    max_valid_months = max(n_valid_months),
    .groups = "drop"
  )

# ---- Save separately from testing-period results ----

common_dir <- "data/processed/common/decision2"
output_dir <- "data/processed/decision2/alternative_B"

dir.create(common_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

saveRDS(
  estimation_panel,
  file.path(common_dir, "estimation_member_month_panel.rds")
)

saveRDS(
  estimation_returns_B,
  file.path(output_dir, "estimation_portfolio_returns_altB.rds")
)

write.csv(
  portfolio_coverage,
  "output/tables/decision2_B_estimation_coverage.csv",
  row.names = FALSE
)

print(coverage_summary, n = 9, width = Inf)

cat("\nEstimation-period portfolio returns completed.\n")