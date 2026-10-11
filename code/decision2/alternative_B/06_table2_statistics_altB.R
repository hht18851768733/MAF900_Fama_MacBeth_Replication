# Decision 2, Alternative B: estimation-period Table 2 statistics.
# Keep the mean individual beta separate from the portfolio-regression
# beta and its standard error. With missing data, they can differ.

library(dplyr)
library(lubridate)

# ---- Load inputs ----

portfolio_returns <- readRDS(
  paste0(
    "data/processed/decision2/alternative_B/",
    "estimation_portfolio_returns_altB.rds"
  )
)

individual_estimates <- readRDS(
  "data/processed/common/decision2/estimation_betas.rds"
)

market_index <- readRDS(
  "data/raw/common/market_index.rds"
)

periods <- readRDS(
  "data/processed/decision1/alternative_B/periods.rds"
)

market_monthly <- market_index |>
  transmute(
    month = floor_date(as.Date(date), "month"),
    mkt_ret
  )

if (anyDuplicated(market_monthly$month) > 0L) {
  stop("Duplicate market months found.")
}

# ---- Average individual risk measures within each portfolio ----
# These retain each stock's own valid estimation-period observations.

individual_summary <- individual_estimates |>
  group_by(period_id, portfolio) |>
  summarise(
    n_securities = n(),
    beta_individual_mean = mean(beta_estimation),
    avg_individual_resid_sd = mean(resid_sd),
    min_individual_months = min(n_obs),
    max_individual_months = max(n_obs),
    .groups = "drop"
  )

# ---- Attach market returns ----

regression_data <- portfolio_returns |>
  left_join(market_monthly, by = "month")

if (any(!is.finite(regression_data$mkt_ret))) {
  stop("Missing or invalid market returns in estimation months.")
}

# ---- Estimate portfolio-level statistics ----

portfolio_statistics <- regression_data |>
  group_by(period_id, portfolio) |>
  group_modify(function(.x, .y) {
    
    usable <- .x |>
      filter(
        is.finite(portfolio_return),
        is.finite(mkt_ret)
      )
    
    if (nrow(usable) < 3L) {
      stop(
        "Insufficient complete portfolio months in period ",
        .y$period_id,
        ", portfolio ",
        .y$portfolio
      )
    }
    
    if (var(usable$mkt_ret) <= 0) {
      stop("Market return variance is zero.")
    }
    
    fit <- lm(
      portfolio_return ~ mkt_ret,
      data = usable
    )
    
    fit_summary <- summary(fit)
    
    tibble(
      n_calendar_months = nrow(.x),
      n_portfolio_months_used = nobs(fit),
      
      beta_portfolio_regression =
        unname(coef(fit)["mkt_ret"]),
      
      se_beta_portfolio_regression =
        fit_summary$coefficients["mkt_ret", "Std. Error"],
      
      r_squared = fit_summary$r.squared,
      
      sd_portfolio_return =
        sd(usable$portfolio_return),
      
      resid_sd_portfolio =
        sd(residuals(fit))
    )
  }) |>
  ungroup()

# ---- Combine results with explicit definitions ----

table2_altB <- portfolio_statistics |>
  left_join(
    individual_summary,
    by = c("period_id", "portfolio")
  ) |>
  left_join(
    periods |>
      select(period_id, estimation_start, estimation_end),
    by = "period_id"
  ) |>
  mutate(
    resid_sd_ratio =
      resid_sd_portfolio / avg_individual_resid_sd,
    
    beta_difference =
      beta_portfolio_regression - beta_individual_mean
  ) |>
  arrange(period_id, portfolio)

# ---- Save unrounded detailed results ----

output_dir <- "data/processed/decision2/alternative_B"

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)

saveRDS(
  table2_altB,
  file.path(output_dir, "table2_altB_detailed.rds")
)

write.csv(
  table2_altB,
  "output/tables/table2_altB_detailed.csv",
  row.names = FALSE
)

# ---- Display a compact summary ----

table2_summary <- table2_altB |>
  group_by(period_id) |>
  summarise(
    n_portfolios = n(),
    min_months_used = min(n_portfolio_months_used),
    max_months_used = max(n_portfolio_months_used),
    mean_r_squared = mean(r_squared),
    max_abs_beta_difference = max(abs(beta_difference)),
    .groups = "drop"
  )

print(table2_summary, n = 9, width = Inf)

cat("\nDetailed estimation-period statistics saved.\n")
cat("Output: output/tables/table2_altB_detailed.csv\n")
cat(
  "Portfolio-regression SE belongs to beta_portfolio_regression,",
  "not beta_individual_mean.\n"
)