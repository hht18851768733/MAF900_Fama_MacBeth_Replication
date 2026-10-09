# =========================================================
# 04_compare_decision1.R
# Compare Alternative A and Alternative B eligibility.
# =========================================================

library(dplyr)
library(tidyr)
library(readr)

# ---- 1. Load both eligibility results ----

results_a <- readRDS(
  "data/processed/decision1/alternative_A/eligible_securities.rds"
)

results_b <- readRDS(
  "data/processed/decision1/alternative_B/eligible_securities.rds"
)

first_month_a <- readRDS(
  "data/processed/decision1/alternative_A/first_month_long.rds"
)

first_month_b <- readRDS(
  "data/processed/decision1/alternative_B/first_month_long.rds"
)

# ---- 2. Verify that both alternatives use the same candidates ----

candidates_a <- first_month_a |>
  distinct(period_id, permno)

candidates_b <- first_month_b |>
  distinct(period_id, permno)

candidate_difference <- bind_rows(
  anti_join(
    candidates_a, candidates_b,
    by = c("period_id", "permno")
  ),
  anti_join(
    candidates_b, candidates_a,
    by = c("period_id", "permno")
  )
)

if (nrow(candidate_difference) > 0L) {
  stop("The first-testing-month candidate lists differ between A and B.")
}

# ---- 3. Extract qualified securities ----

qualified_a <- results_a |>
  filter(eligible) |>
  distinct(period_id, permno) |>
  mutate(eligible_A = TRUE)

qualified_b <- results_b |>
  filter(eligible) |>
  distinct(period_id, permno) |>
  mutate(eligible_B = TRUE)

# ---- 4. Compare eligibility for every first-month candidate ----

membership_comparison <- candidates_a |>
  left_join(
    qualified_a,
    by = c("period_id", "permno")
  ) |>
  left_join(
    qualified_b,
    by = c("period_id", "permno")
  ) |>
  mutate(
    eligible_A = replace_na(eligible_A, FALSE),
    eligible_B = replace_na(eligible_B, FALSE),
    
    membership = case_when(
      eligible_A & eligible_B ~ "Both",
      eligible_A & !eligible_B ~ "A only",
      !eligible_A & eligible_B ~ "B only",
      TRUE ~ "Neither"
    )
  ) |>
  arrange(period_id, permno)

# ---- 5. Summarise counts and overlap ----

comparison_summary <- membership_comparison |>
  group_by(period_id) |>
  summarise(
    n_available = n(),
    n_A = sum(eligible_A),
    n_B = sum(eligible_B),
    n_both = sum(eligible_A & eligible_B),
    n_A_only = sum(eligible_A & !eligible_B),
    n_B_only = sum(!eligible_A & eligible_B),
    n_neither = sum(!eligible_A & !eligible_B),
    .groups = "drop"
  ) |>
  mutate(
    B_minus_A = n_B - n_A,
    A_subset_of_B = n_A_only == 0L
  )

# ---- 6. Save comparison outputs ----

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  comparison_summary,
  "output/tables/decision1_comparison_summary.csv"
)

write_csv(
  membership_comparison,
  "output/tables/decision1_membership_comparison.csv"
)

write_csv(
  filter(membership_comparison, membership == "B only"),
  "output/tables/decision1_B_only_securities.csv"
)

# ---- 7. Display summary ----

print(comparison_summary, n = 9, width = Inf)

cat("\nFirst-testing-month candidate lists match.\n")
cat("Comparison files saved to output/tables/.\n")

# ---- 8. Explain why B-only securities fail Alternative A ----

b_only_diagnostics <- membership_comparison |>
  filter(membership == "B only") |>
  left_join(
    results_a |>
      select(
        period_id,
        permno,
        formation_valid_months,
        formation_longest_run,
        estimation_valid_months,
        listed_ok,
        formation_ok,
        estimation_ok
      ),
    by = c("period_id", "permno")
  ) |>
  mutate(
    exclusion_reason = case_when(
      !listed_ok ~ "Listing coverage",
      !formation_ok & !estimation_ok ~ "Both formation and estimation",
      !formation_ok ~ "Formation only",
      !estimation_ok ~ "Estimation only",
      TRUE ~ "Check required"
    )
  )

exclusion_summary <- b_only_diagnostics |>
  count(
    period_id,
    exclusion_reason,
    name = "n_securities"
  ) |>
  pivot_wider(
    names_from = exclusion_reason,
    values_from = n_securities,
    values_fill = 0
  ) |>
  arrange(period_id)

write_csv(
  b_only_diagnostics,
  "output/tables/decision1_B_only_diagnostics.csv"
)

write_csv(
  exclusion_summary,
  "output/tables/decision1_exclusion_summary.csv"
)

print(exclusion_summary, n = 9, width = Inf)