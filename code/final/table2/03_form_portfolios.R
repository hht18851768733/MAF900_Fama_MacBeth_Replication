# Final workflow adaptation of code/common/07_form_portfolios.R.
# Source commit: 9478f1a9bec6c22c720ebc86ee78a8bad99f236e.
# Original selected calculations retained; final paths and explicit package imports.
# Shared DP2 preparation: assign securities to 20 portfolios.
# Uses formation-period betas from the selected DP1-B sample.

library(dplyr)

formation_betas <- readRDS(
  "data/processed/final/table2/formation_betas.rds"
)

# ---- Assign portfolios within each period ----

assign_portfolios <- function(df) {
  
  # PERMNO provides a reproducible ordering if betas are tied.
  df <- df |>
    arrange(beta_formation, permno)
  
  n_securities <- nrow(df)
  
  if (n_securities < 20L) {
    stop("Fewer than 20 securities available for portfolio formation.")
  }
  
  if (any(!is.finite(df$beta_formation))) {
    stop("Invalid formation beta found.")
  }
  
  base_size <- n_securities %/% 20L
  remainder <- n_securities %% 20L
  
  first_extra <- remainder %/% 2L
  last_extra <- remainder - first_extra
  
  portfolio_sizes <- c(
    base_size + first_extra,
    rep(base_size, 18),
    base_size + last_extra
  )
  
  df$portfolio <- rep(
    seq_len(20),
    times = portfolio_sizes
  )
  
  df
}

portfolio_formation <- formation_betas |>
  group_by(period_id) |>
  group_modify(~ assign_portfolios(.x)) |>
  ungroup() |>
  arrange(period_id, portfolio, beta_formation, permno)

# ---- Summarise membership and beta ranges ----

portfolio_summary <- portfolio_formation |>
  group_by(period_id, portfolio) |>
  summarise(
    n_securities = n(),
    min_beta = min(beta_formation),
    max_beta = max(beta_formation),
    mean_beta = mean(beta_formation),
    .groups = "drop"
  )

period_summary <- portfolio_summary |>
  group_by(period_id) |>
  summarise(
    n_portfolios = n(),
    total_securities = sum(n_securities),
    smallest_portfolio = min(n_securities),
    largest_portfolio = max(n_securities),
    .groups = "drop"
  )

# ---- Save the shared portfolio assignments ----

output_dir <- "data/processed/final/table2"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  portfolio_formation,
  file.path(output_dir, "portfolio_formation.rds")
)

saveRDS(
  portfolio_summary,
  file.path(output_dir, "portfolio_formation_summary.rds")
)

print(period_summary, n = 9, width = Inf)

cat("\nPeriod 1 portfolio details:\n")

print(
  portfolio_summary |> filter(period_id == 1),
  n = 20,
  width = Inf
)

cat("\nPortfolio formation completed.\n")
cat("Saved to:", output_dir, "\n")

