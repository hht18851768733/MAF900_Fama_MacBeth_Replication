# Final workflow adaptation of code/decision2/alternative_A/04_portfolio_returns_altA.R.
# Source commit: 9478f1a9bec6c22c720ebc86ee78a8bad99f236e.
# Original selected calculations retained; final paths and explicit package imports.
# =========================================================
# 04_portfolio_returns_altA.R
# Decision 2, Alternative A — Available-case equal weighting
# Computes equally-weighted portfolio returns using available-
# case weighting, for BOTH the estimation window (used in
# Table 2) and the testing window (used in Table 3).
# =========================================================

library(dplyr)
library(tidyr)
library(purrr)

estimation_panel <- readRDS("data/processed/final/table2/estimation_member_month_panel.rds")
testing_panel    <- readRDS("data/processed/final/table2/testing_member_month_panel.rds")

# ---- Estimation-period returns: all assigned securities are expected members ----
estimation_portfolio_returns <- estimation_panel |>
  group_by(period_id, portfolio, month) |>
  summarise(
    n_expected = n(),
    n_valid    = sum(!is.na(ret)),
    portfolio_return = if (n_valid > 0) mean(ret, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  ) |>
  rename(date = month)

# ---- Testing-period returns: current members identified via listed_nyse_common ----
testing_portfolio_returns <- testing_panel |>
  filter(listed_nyse_common) |>
  group_by(period_id, portfolio, month) |>
  summarise(
    n_expected = n(),
    n_valid    = sum(valid_return, na.rm = TRUE),
    portfolio_return = if (n_valid > 0) mean(ret[valid_return], na.rm = TRUE) else NA_real_,
    .groups = "drop"
  ) |>
  rename(date = month)

# ---- Quick look ----
estimation_portfolio_returns |> filter(period_id == 2, portfolio == 1) |> head(12)
testing_portfolio_returns    |> filter(period_id == 1, portfolio == 1) |> head(12)
dir.create("data/processed/final/table2", recursive = TRUE, showWarnings = FALSE)

saveRDS(testing_portfolio_returns, "data/processed/final/table2/portfolio_returns_final.rds")
saveRDS(estimation_portfolio_returns, "data/processed/final/table2/estimation_portfolio_returns_final.rds")
