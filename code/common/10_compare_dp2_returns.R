# Compare the saved Alternative B returns with an available-case
# benchmark calculated from the same member-month panel.

library(dplyr)

testing_panel <- readRDS(
  "data/processed/common/decision2/testing_member_month_panel.rds"
)

returns_b <- readRDS(
  "data/processed/decision2/alternative_B/portfolio_returns_altB.rds"
)

# ---- Available-case benchmark on identical membership ----

available_case <- testing_panel |>
  group_by(period_id, portfolio, month) |>
  summarise(
    return_available = {
      observed_returns <- ret[
        listed_nyse_common & valid_return
      ]
      
      if (length(observed_returns) > 0L) {
        mean(observed_returns)
      } else {
        NA_real_
      }
    },
    .groups = "drop"
  )

# ---- Match the saved B results ----

keys <- c("period_id", "portfolio", "month")

if (anyDuplicated(returns_b[keys]) > 0L) {
  stop("Duplicate portfolio-months in Alternative B.")
}

if (
  nrow(anti_join(available_case, returns_b, by = keys)) > 0L ||
  nrow(anti_join(returns_b, available_case, by = keys)) > 0L
) {
  stop("The portfolio-month keys do not match.")
}

comparison <- available_case |>
  left_join(
    returns_b |>
      select(
        period_id,
        portfolio,
        month,
        return_B = portfolio_return,
        n_expected,
        n_valid,
        n_missing
      ),
    by = keys
  ) |>
  mutate(
    available_valid = is.finite(return_available),
    B_valid = is.finite(return_B),
    both_valid = available_valid & B_valid,
    absolute_difference = if_else(
      both_valid,
      abs(return_available - return_B),
      NA_real_
    )
  )

# ---- Summarise the effect of the missing-return rule ----

comparison_summary <- comparison |>
  group_by(period_id) |>
  summarise(
    n_portfolio_months = n(),
    n_available_case = sum(available_valid),
    n_B = sum(B_valid),
    n_available_only = sum(available_valid & !B_valid),
    n_B_only = sum(!available_valid & B_valid),
    max_difference_common = if (any(both_valid)) {
      max(absolute_difference[both_valid])
    } else {
      NA_real_
    },
    .groups = "drop"
  )

# ---- Save diagnostics ----

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write.csv(
  comparison_summary,
  "output/tables/decision2_return_comparison.csv",
  row.names = FALSE
)

saveRDS(
  comparison,
  "data/processed/common/decision2/return_comparison.rds"
)

print(comparison_summary, n = 9, width = Inf)

cat("\nComparison completed using the same monthly membership.\n")