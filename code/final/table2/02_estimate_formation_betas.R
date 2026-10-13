# Final workflow adaptation of code/common/06_estimate_formation_betas.R.
# Source commit: 9478f1a9bec6c22c720ebc86ee78a8bad99f236e.
# Original selected calculations retained; final paths and explicit package imports.
# Shared DP2 preparation: formation-period beta estimation.
# Uses the selected DP1 Alternative B sample.

library(dplyr)

# ---- Load inputs ----

eligible_securities <- readRDS(
  "data/processed/final/table1/eligible_securities.rds"
)

periods <- readRDS(
  "data/processed/final/table1/periods.rds"
)

stock_returns <- readRDS(
  "data/raw/common/nyse_common_1926_1968.rds"
)

market_index <- readRDS(
  "data/raw/common/market_index_nyse_ew.rds"
)

# ---- Prepare monthly observations ----

stock_returns <- stock_returns |>
  mutate(
    date = as.Date(date),
    month = format(date, "%Y-%m")
  )

market_index <- market_index |>
  mutate(month = format(as.Date(date), "%Y-%m"))

if (anyDuplicated(stock_returns[c("permno", "month")]) > 0L) {
  stop("Duplicate stock-month observations found.")
}

if (anyDuplicated(market_index$month) > 0L) {
  stop("Duplicate market-month observations found.")
}

returns_with_market <- stock_returns |>
  left_join(
    market_index |> select(month, mkt_ret),
    by = "month"
  )

selected_sample <- eligible_securities |>
  filter(eligible) |>
  distinct(period_id, permno)

# ---- Estimate beta using all valid formation-period pairs ----

formation_results <- vector("list", nrow(periods))

for (i in seq_len(nrow(periods))) {
  
  current <- periods[i, ]
  
  members <- selected_sample |>
    filter(period_id == current$period_id)
  
  formation_data <- returns_with_market |>
    semi_join(members, by = "permno") |>
    filter(
      date >= current$formation_start,
      date <= current$formation_end,
      is.finite(ret),
      is.finite(mkt_ret)
    )
  
  minimum_obs <- if (current$period_id == 1L) 44L else 48L
  
  betas <- formation_data |>
    group_by(permno) |>
    group_modify(function(.x, .y) {
      
      if (nrow(.x) < minimum_obs) {
        stop(
          "Insufficient paired observations for PERMNO ",
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
        beta_formation = unname(coef(fit)["mkt_ret"]),
        n_obs = nobs(fit)
      )
    }) |>
    ungroup() |>
    mutate(period_id = current$period_id, .before = 1)
  
  if (nrow(betas) != nrow(members) ||
      any(!is.finite(betas$beta_formation))) {
    stop(
      "Some eligible securities do not have a valid beta in period ",
      current$period_id
    )
  }
  
  formation_results[[i]] <- betas
}

formation_betas <- bind_rows(formation_results) |>
  arrange(period_id, permno)

# ---- Save shared results ----

output_dir <- "data/processed/final/table2"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  formation_betas,
  file.path(output_dir, "formation_betas.rds")
)

beta_summary <- formation_betas |>
  group_by(period_id) |>
  summarise(
    n_securities = n(),
    min_months = min(n_obs),
    max_months = max(n_obs),
    mean_beta = mean(beta_formation),
    .groups = "drop"
  )

print(beta_summary, n = 9, width = Inf)

cat("\nFormation-period beta estimation completed.\n")
cat("Saved to:", output_dir, "\n")

