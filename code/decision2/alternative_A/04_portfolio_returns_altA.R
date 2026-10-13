# =========================================================
# 04_portfolio_returns_altA.R
# Decision 2, Alternative A — Available-case equal weighting
# Computes equally-weighted portfolio returns using available-
# case weighting, for BOTH the estimation window (used in
# Table 2) and the testing window (used in Table 3).
# =========================================================

library(tidyverse)
library(lubridate)

periods             <- readRDS("data/processed/decision1/alternative_B/periods.rds")
portfolio_formation <- readRDS("data/processed/common/decision2/portfolio_formation.rds")
nyse_common         <- readRDS("data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")

nominal_size <- portfolio_formation |>
  group_by(period_id, portfolio) |>
  summarise(nominal_n = n(), .groups = "drop")

compute_portfolio_returns <- function(date_start_col, date_end_col) {
  
  results <- list()
  
  for (p in 1:9) {
    
    row <- periods[p, ]
    
    members_this_period <- portfolio_formation |>
      filter(period_id == row$period_id) |>
      select(permno, portfolio)
    
    window_returns <- nyse_common |>
      filter(
        permno %in% members_this_period$permno,
        date >= row[[date_start_col]],
        date <= row[[date_end_col]]
      ) |>
      left_join(members_this_period, by = "permno")
    
    returns_this_period <- window_returns |>
      filter(!is.na(ret)) |>
      group_by(portfolio, date) |>
      summarise(
        portfolio_return = mean(ret),
        n_valid = n(),
        .groups = "drop"
      ) |>
      mutate(period_id = row$period_id)
    
    results[[p]] <- returns_this_period
  }
  
  bind_rows(results) |>
    left_join(nominal_size, by = c("period_id", "portfolio"))
}

# ---- Testing-period returns (for Table 3) ----
portfolio_returns_testing <- compute_portfolio_returns("testing_start", "testing_end")
saveRDS(portfolio_returns_testing, "data/processed/decision2/alternative_A/portfolio_returns_altA.rds")

# ---- Estimation-period returns (for Table 2) ----
portfolio_returns_estimation <- compute_portfolio_returns("estimation_start", "estimation_end")
saveRDS(portfolio_returns_estimation, "data/processed/decision2/alternative_A/estimation_portfolio_returns_altA.rds")

# ---- Quick look ----
portfolio_returns_estimation |> filter(period_id == 2, portfolio == 1) |> head(12)