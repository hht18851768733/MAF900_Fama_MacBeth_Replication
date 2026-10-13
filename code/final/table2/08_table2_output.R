# Final workflow adaptation of code/decision2/alternative_A/05_table2_output.R.
# Source commit: 9478f1a9bec6c22c720ebc86ee78a8bad99f236e.
# Original selected calculations retained; final paths and explicit package imports.
# =========================================================
# 05_table2_output.R
# Decision 2, Alternative A
# Assembles Table 2's reported statistics per portfolio:
# beta, its SE, R-squared against the market, portfolio
# return SD, portfolio residual SD, average individual
# residual SD, and their ratio.
# =========================================================

library(dplyr)
library(tidyr)
library(purrr)
library(lubridate)

# ---- Load what we need ----
periods          <- readRDS("data/processed/final/table1/periods.rds")
estimation_betas <- readRDS("data/processed/final/table2/estimation_betas.rds")
market_index     <- readRDS("data/raw/common/market_index_nyse_ew.rds")
portfolio_returns <- readRDS("data/processed/final/table2/estimation_portfolio_returns_final.rds")

# ---- Mean individual beta and cross-security dispersion diagnostic ----
# se_beta_portfolio is sd(individual betas)/sqrt(n), not a regression SE.
# The displayed SE is se_beta_correct from the portfolio-return regression.
portfolio_betas <- estimation_betas |>
  group_by(period_id, portfolio) |>
  summarise(
    beta_portfolio    = mean(beta_estimation, na.rm = TRUE),
    se_beta_portfolio = sd(beta_estimation, na.rm = TRUE) / sqrt(n()),
    n_securities      = n(),
    .groups = "drop"
  )

# ---- Average individual residual SD within each portfolio: s_bar_p(e_i) ----
avg_resid_sd <- estimation_betas |>
  group_by(period_id, portfolio) |>
  summarise(avg_resid_sd = mean(resid_sd, na.rm = TRUE), .groups = "drop")

# ---- Portfolio-level statistics from estimation-period returns ----
portfolio_return_stats <- list()

for (p in 1:9) {
  
  row <- periods[p, ]
  
  period_returns <- portfolio_returns |>
    filter(period_id == row$period_id) |>
    mutate(month = floor_date(date, "month")) |>
    inner_join(
      market_index |> mutate(month = floor_date(date, "month")) |> select(month, mkt_ret),
      by = "month"
    )
  
  stats_this_period <- period_returns |>
    group_by(portfolio) |>
    summarise(
      {
        fit <- lm(portfolio_return ~ mkt_ret, data = pick(portfolio_return, mkt_ret))
        tibble(
          beta_from_portfolio_regression = coef(fit)[["mkt_ret"]],
          se_beta_correct      = summary(fit)$coefficients["mkt_ret", "Std. Error"],
          r_squared            = summary(fit)$r.squared,
          sd_portfolio_return  = sd(portfolio_return),
          resid_sd_portfolio   = sd(residuals(fit))
        )
      },
      .groups = "drop"
    ) |>
    mutate(period_id = row$period_id)
  
  portfolio_return_stats[[p]] <- stats_this_period
}

portfolio_return_stats <- bind_rows(portfolio_return_stats)

# ---- Combine everything into the final Table 2 layout ----
table2_altA <- portfolio_betas |>
  left_join(portfolio_return_stats, by = c("period_id", "portfolio")) |>
  left_join(avg_resid_sd, by = c("period_id", "portfolio")) |>
  mutate(
    resid_sd_ratio = resid_sd_portfolio / avg_resid_sd
  ) |>
  arrange(period_id, portfolio)

# ---- Quick look ----
table2_altA |> filter(period_id == 1)

saveRDS(table2_altA, "data/processed/final/table2/table2_final.rds")
write.csv(table2_altA, "output/tables/table2_final_detailed.csv", row.names = FALSE, na = "")

# ---- Reshape ALL periods into journal layout, one block per period ----

build_journal_table <- function(data, period) {
  data |>
    filter(period_id == period) |>
    arrange(portfolio) |>
    transmute(
      portfolio,
      `beta_p,t-1`                       = sprintf("%.3f", beta_portfolio),
      `SE of portfolio-regression beta`  = sprintf("%.3f", se_beta_correct),
      `r(Rp,Rm)^2`                       = sprintf("%.3f", r_squared),
      `s(Rp)`                            = sprintf("%.3f", sd_portfolio_return),
      `s(e_p)`                           = sprintf("%.3f", resid_sd_portfolio),
      `sbar_p,t-1(e_i)`                  = sprintf("%.3f", avg_resid_sd),
      `s(e_p)/sbar_p,t-1(e_i)`           = sprintf("%.3f", resid_sd_ratio)
    ) |>
    pivot_longer(cols = -portfolio, names_to = "Statistic", values_to = "value") |>
    pivot_wider(names_from = portfolio, values_from = value, names_prefix = "Portfolio ") |>
    mutate(period_id = period, .before = 1)
}

table2_journal_all <- map_dfr(1:9, ~ build_journal_table(table2_altA, .x))

table2_journal_all |> filter(period_id %in% c(2, 4))

write.csv(table2_journal_all, "output/tables/table2_final_all_periods_display.csv", row.names = FALSE, na = "")

# ---- Filter the journal-style table to just the four comparable periods ----

table2_journal_comparable <- table2_journal_all |>
  filter(period_id %in% c(2, 4, 6, 8))

table2_journal_comparable

write.csv(table2_journal_comparable, "output/tables/table2_final_display.csv", row.names = FALSE, na = "")
