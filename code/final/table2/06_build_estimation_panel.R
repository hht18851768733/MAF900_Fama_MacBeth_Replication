# Final estimation member-month panel; no missing-return alternative is applied here.
# Extracted from Haitian Hu's DP2-B script 05 (shared panel construction only).
# Source commit: 9478f1a9bec6c22c720ebc86ee78a8bad99f236e.
library(dplyr)
library(tidyr)
library(lubridate)

periods <- readRDS(
  "data/processed/final/table1/periods.rds"
)

portfolio_formation <- readRDS(
  "data/processed/final/table2/portfolio_formation.rds"
)

stock_returns <- readRDS(
  "data/raw/common/nyse_common_1926_1968.rds"
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

saveRDS(estimation_panel,
  "data/processed/final/table2/estimation_member_month_panel.rds")
cat("Estimation member-month panel completed.\n")
