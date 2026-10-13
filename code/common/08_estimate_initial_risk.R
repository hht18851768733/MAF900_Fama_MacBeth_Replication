# Shared DP2 preparation: initial estimation-period risk measures.
# Portfolio assignments remain fixed from the formation stage.

library(dplyr)

# ---- Load inputs ----

periods <- readRDS(
  "data/processed/decision1/alternative_B/periods.rds"
)

portfolio_formation <- readRDS(
  "data/processed/common/decision2/portfolio_formation.rds"
)

stock_returns <- readRDS(
  "data/raw/decision1/alternative_B/nyse_common_1926_1968.rds"
)

market_index <- readRDS(
  "data/raw/common/market_index_nyse_ew.rds"
)

stock_returns <- stock_returns |>
  mutate(
    date = as.Date(date),
    month = format(date, "%Y-%m")
  )

market_index <- market_index |>
  mutate(month = format(as.Date(date), "%Y-%m"))

if (anyDuplicated(stock_returns[c("permno", "month")]) > 0L ||
    anyDuplicated(market_index$month) > 0L) {
  stop("Duplicate monthly observations found.")
}

returns_with_market <- stock_returns |>
  left_join(
    market_index |> select(month, mkt_ret),
    by = "month"
  )

# ---- Re-estimate individual risk measures ----

estimation_results <- vector("list", nrow(periods))

for (i in seq_len(nrow(periods))) {
  
  current <- periods[i, ]
  
  members <- portfolio_formation |>
    filter(period_id == current$period_id) |>
    select(permno, portfolio)
  
  estimation_data <- returns_with_market |>
    semi_join(members, by = "permno") |>
    filter(
      date >= current$estimation_start,
      date <= current$estimation_end,
      is.finite(ret),
      is.finite(mkt_ret)
    )
  
  estimates <- estimation_data |>
    group_by(permno) |>
    group_modify(function(.x, .y) {
      
      if (nrow(.x) < 54L) {
        stop(
          "Fewer than 54 valid paired months for PERMNO ",
          .y$permno,
          " in period ",
          current$period_id
        )
      }
      
      if (var(.x$mkt_ret) <= 0) {
        stop("Market return variance is zero.")
      }
      
      fit <- lm(ret ~ mkt_ret, data = .x)
      
      tibble(
        beta_estimation = unname(coef(fit)["mkt_ret"]),
        se_beta_individual =
          summary(fit)$coefficients["mkt_ret", "Std. Error"],
        
        # Sample SD of fitted residuals, matching Bharat's
        # current individual-residual calculation.
        resid_sd = sd(residuals(fit)),
        
        n_obs = nobs(fit)
      )
    }) |>
    ungroup() |>
    left_join(members, by = "permno") |>
    mutate(period_id = current$period_id, .before = 1)
  
  if (nrow(estimates) != nrow(members) ||
      any(!is.finite(estimates$beta_estimation)) ||
      any(!is.finite(estimates$resid_sd))) {
    stop(
      "Incomplete or invalid estimation results in period ",
      current$period_id
    )
  }
  
  estimation_results[[i]] <- estimates
}

estimation_betas <- bind_rows(estimation_results) |>
  arrange(period_id, portfolio, permno)

# ---- Save individual estimates ----

output_dir <- "data/processed/common/decision2"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  estimation_betas,
  file.path(output_dir, "estimation_betas.rds")
)

# ---- Diagnostic summary ----

estimation_summary <- estimation_betas |>
  group_by(period_id) |>
  summarise(
    n_securities = n(),
    min_months = min(n_obs),
    max_months = max(n_obs),
    mean_beta = mean(beta_estimation),
    mean_resid_sd = mean(resid_sd),
    .groups = "drop"
  )

print(estimation_summary, n = 9, width = Inf)

cat("\nInitial estimation-period risk measures completed.\n")
cat("Saved to:", output_dir, "\n")
