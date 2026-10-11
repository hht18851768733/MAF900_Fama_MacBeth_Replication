# Decision 2, Alternative B: complete portfolio-month returns.
#
# Membership convention for this implementation:
# - Keep the original portfolio assignment.
# - Count members currently listed as NYSE common stock.
# - A returning security resumes its original portfolio assignment.
# - Do not remove a current member merely because its return is missing.
#
# Return input: existing CRSP ret, without a separate delisting adjustment.

library(dplyr)

testing_panel <- readRDS(
  "data/processed/common/decision2/testing_member_month_panel.rds"
)

# ---- Calculate complete-case portfolio-month returns ----
# Keep the full panel so empty portfolio-months remain in the output.

portfolio_returns <- testing_panel |>
  group_by(period_id, portfolio, month) |>
  summarise(
    nominal_n = n_distinct(permno),
    
    n_expected = sum(listed_nyse_common),
    
    n_valid = sum(
      listed_nyse_common & valid_return
    ),
    
    n_missing = sum(
      listed_nyse_common & !valid_return
    ),
    
    portfolio_return = {
      current_returns <- ret[listed_nyse_common]
      
      if (
        length(current_returns) > 0L &&
        all(is.finite(current_returns))
      ) {
        mean(current_returns)
      } else {
        NA_real_
      }
    },
    
    .groups = "drop"
  ) |>
  arrange(period_id, portfolio, month)

# ---- Summarise usable and missing portfolio-months ----

return_summary <- portfolio_returns |>
  group_by(period_id) |>
  summarise(
    n_portfolio_months = n(),
    
    n_complete = sum(
      is.finite(portfolio_return)
    ),
    
    n_incomplete = sum(
      n_expected > 0L & n_missing > 0L
    ),
    
    n_empty = sum(
      n_expected == 0L
    ),
    
    complete_pct = round(
      100 * mean(is.finite(portfolio_return)),
      2
    ),
    
    .groups = "drop"
  )

# ---- Save outputs ----

output_dir <- "data/processed/decision2/alternative_B"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

saveRDS(
  portfolio_returns,
  file.path(output_dir, "portfolio_returns_altB.rds")
)

write.csv(
  return_summary,
  "output/tables/decision2_B_return_coverage.csv",
  row.names = FALSE
)

print(return_summary, n = 9, width = Inf)

cat("\nAlternative B portfolio returns completed.\n")
cat(
  "Total portfolio-months:",
  nrow(portfolio_returns),
  "\n"
)