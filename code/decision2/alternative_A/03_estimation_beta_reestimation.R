# =========================================================
# 03_estimation_beta_reestimation.R
# Decision 2, Alternative A
# Re-estimates beta for each security over the estimation
# window (fresh data, separate from formation), then averages
# within each portfolio to get the portfolio-level beta used
# in Table 2 and Table 3. This separation avoids the
# regression/bunching bias from estimating and ranking on the
# same data.
# =========================================================

library(tidyverse)
library(lubridate)

# ---- Load what we need ----
periods             <- readRDS("data/processed/decision1/alternative_B/periods.rds")
portfolio_formation <- readRDS("data/processed/decision2/alternative_A/portfolio_formation.rds")
market_index        <- readRDS("data/raw/decision2/alternative_A/market_index.rds")
nyse_common         <- readRDS("data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")

returns_with_market <- nyse_common |>
  inner_join(market_index, by = "date")

# ---- Re-estimate individual betas over the estimation window ----
estimation_betas <- list()

for (p in 1:9) {
  
  row <- periods[p, ]
  
  securities_this_period <- portfolio_formation |>
    filter(period_id == row$period_id) |>
    select(permno, portfolio)
  
  period_data <- returns_with_market |>
    filter(
      permno %in% securities_this_period$permno,
      date >= row$estimation_start,
      date <= row$estimation_end,
      !is.na(ret)
    )
  
  betas_this_period <- period_data |>
    group_by(permno) |>
    summarise(
      {
        fit <- lm(ret ~ mkt_ret, data = pick(ret, mkt_ret))
        tibble(
          beta_estimation = coef(fit)[["mkt_ret"]],
          resid_sd         = sd(residuals(fit)),
          n_obs            = n()
        )
      },
      .groups = "drop"
    ) |>
    left_join(securities_this_period, by = "permno") |>
    mutate(period_id = row$period_id)
  
  estimation_betas[[p]] <- betas_this_period
}

estimation_betas <- bind_rows(estimation_betas)

# ---- Quick look at individual-security re-estimated betas ----
head(estimation_betas)
dim(estimation_betas)
summary(estimation_betas$beta_estimation)

# ---- Average individual betas within each portfolio ----
portfolio_betas <- estimation_betas |>
  group_by(period_id, portfolio) |>
  summarise(
    beta_portfolio = mean(beta_estimation, na.rm = TRUE),
    se_beta_portfolio = sd(beta_estimation, na.rm = TRUE) / sqrt(n()),
    n_securities = n(),
    .groups = "drop"
  )

# ---- Quick look ----
portfolio_betas |> filter(period_id == 1)

saveRDS(estimation_betas, "data/processed/decision2/alternative_A/estimation_betas.rds")
saveRDS(portfolio_betas, "data/processed/decision2/alternative_A/portfolio_betas.rds")
