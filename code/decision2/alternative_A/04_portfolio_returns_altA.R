# =========================================================
# 04_portfolio_returns_altA.R
# Decision 2, Alternative A — Available-case equal weighting
# For each portfolio, each month of the testing period,
# computes the equally weighted average of valid (non-missing)
# member returns. A security with a temporary missing return
# is left out for that month only; remaining securities are
# equally weighted. Effective membership size is tracked
# alongside nominal portfolio size.
# =========================================================

library(tidyverse)
library(lubridate)

# ---- Load what we need ----
periods             <- readRDS("data/processed/decision1/alternative_B/periods.rds")
portfolio_formation <- readRDS("data/processed/decision2/alternative_A/portfolio_formation.rds")
nyse_common         <- readRDS("data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")

# ---- Nominal portfolio size per period (fixed membership count) ----
nominal_size <- portfolio_formation |>
  group_by(period_id, portfolio) |>
  summarise(nominal_n = n(), .groups = "drop")

# ---- Compute available-case equal-weighted portfolio returns ----
portfolio_returns <- list()

for (p in 1:9) {
  
  row <- periods[p, ]
  
  members_this_period <- portfolio_formation |>
    filter(period_id == row$period_id) |>
    select(permno, portfolio)
  
  testing_returns <- nyse_common |>
    filter(
      permno %in% members_this_period$permno,
      date >= row$testing_start,
      date <= row$testing_end
    ) |>
    left_join(members_this_period, by = "permno")
  
  returns_this_period <- testing_returns |>
    filter(!is.na(ret)) |>
    group_by(portfolio, date) |>
    summarise(
      portfolio_return = mean(ret),
      n_valid = n(),
      .groups = "drop"
    ) |>
    mutate(period_id = row$period_id)
  
  portfolio_returns[[p]] <- returns_this_period
}

portfolio_returns <- bind_rows(portfolio_returns)

# ---- Attach nominal size, so effective vs nominal membership can be checked ----
portfolio_returns <- portfolio_returns |>
  left_join(nominal_size, by = c("period_id", "portfolio"))

# ---- Quick look ----
head(portfolio_returns)
dim(portfolio_returns)
portfolio_returns |> filter(period_id == 1, portfolio == 1) |> head(12)

saveRDS(portfolio_returns, "data/processed/decision2/alternative_A/portfolio_returns_altA.rds")
