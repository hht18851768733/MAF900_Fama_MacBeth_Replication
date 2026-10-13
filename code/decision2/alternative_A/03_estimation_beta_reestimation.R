# =========================================================
# 03_estimation_beta_reestimation.R
# Decision 2, Alternative A
# Uses the shared, common-pipeline estimation-period betas
# (computed once in code/common/, identical for Alternative A
# and B since beta estimation does not depend on the market-
# index or portfolio-return decision points), and averages
# individual betas within each portfolio to get the
# portfolio-level beta used in Table 2.
# =========================================================

library(tidyverse)

# ---- Load shared individual-security estimation-period betas ----
estimation_betas <- readRDS("data/processed/common/decision2/estimation_betas.rds")

# ---- Quick look ----
head(estimation_betas)
dim(estimation_betas)
summary(estimation_betas$beta_estimation)

# ---- Average individual betas within each portfolio ----
portfolio_betas <- estimation_betas |>
  group_by(period_id, portfolio) |>
  summarise(
    beta_portfolio    = mean(beta_estimation, na.rm = TRUE),
    se_beta_portfolio = sd(beta_estimation, na.rm = TRUE) / sqrt(n()),
    n_securities      = n(),
    .groups = "drop"
  )

# ---- Quick look ----
portfolio_betas |> filter(period_id == 1)

saveRDS(portfolio_betas, "data/processed/decision2/alternative_A/portfolio_betas.rds")