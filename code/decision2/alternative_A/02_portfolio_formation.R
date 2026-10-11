# =========================================================
# 02_portfolio_formation.R
# Decision 2, Alternative A
# Ranks eligible securities by formation-period beta and
# sorts into 20 portfolios per period, following the paper's
# exact sizing rule: middle 18 portfolios get floor(N/20)
# securities each; portfolios 1 and 20 absorb the remainder,
# split as evenly as possible, with portfolio 20 taking any
# extra odd security.
# =========================================================

library(tidyverse)

formation_betas <- readRDS("data/processed/decision2/alternative_A/formation_betas.rds")

assign_portfolios <- function(df) {
  
  df <- df |> arrange(beta_formation)
  N <- nrow(df)
  
  base_size <- floor(N / 20)
  leftover  <- N - 20 * base_size
  
  first_extra <- floor(leftover / 2)
  last_extra  <- leftover - first_extra
  
  sizes <- c(
    base_size + first_extra,
    rep(base_size, 18),
    base_size + last_extra
  )
  
  df$portfolio <- rep(1:20, times = sizes)
  
  df
}

portfolio_formation <- formation_betas |>
  group_by(period_id) |>
  group_modify(~ assign_portfolios(.x)) |>
  ungroup()

# ---- Quick look ----
head(portfolio_formation)
portfolio_formation |>
  group_by(period_id, portfolio) |>
  summarise(n_securities = n(), .groups = "drop") |>
  filter(period_id == 1)

saveRDS(portfolio_formation, "data/processed/decision2/alternative_A/portfolio_formation.rds")