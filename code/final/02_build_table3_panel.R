# Table 3, step 2: monthly portfolio risks and selected A returns.
# Run from the repository root: source("code/final/02_build_table3_panel.R")
# Reference: Fama & MacBeth (1973), pp. 615-618, equation (10).
# beta_portfolio = mean(individual beta); beta2_portfolio = mean(beta^2);
# mean_resid_sd = mean(individual residual SD), not portfolio residual SD.
# All individual estimates use information through the preceding December.
#
# Project convention for the paper's unspecified temporary-missing case:
# Risk averages use all currently listed members under final/table2/05's NYSE
# membership rule. A temporary missing return does not remove membership or
# a pre-estimated risk measure. A returns average finite returns only.
# These denominators can differ; n_members, n_valid_returns and the difference
# are retained. Listing exits/re-entries follow final/table2/05, with fixed original
# portfolio assignments. No new permanent-exit or delisting-return rule here.
# This step prepares data only; it does not run Table 3 regressions.

local({
  library(dplyr)
  month_date <- function(x) as.Date(paste0(format(as.Date(x), "%Y-%m"), "-01"))
  read_input <- function(path, columns) {
    if (!file.exists(path)) stop("Missing input: ", path)
    x <- readRDS(path)
    if (!all(columns %in% names(x))) stop("Required columns missing in: ", path)
    x
  }
  unique_keys <- function(x, keys, label) {
    if (anyNA(x[keys]) || anyDuplicated(x[keys])) stop(label, ": missing or duplicate keys.")
  }
  same_keys <- function(x, y, keys, label) {
    if (nrow(anti_join(x, y, by = keys)) || nrow(anti_join(y, x, by = keys))) {
      stop(label, ": keys do not match.")
    }
  }
  periods <- read_input("data/processed/final/table1/periods.rds",
    c("period_id", "testing_start", "testing_end"))
  members <- read_input("data/processed/final/table2/portfolio_formation.rds",
    c("period_id", "permno", "portfolio")) |>
    select(period_id, permno, portfolio)
  panel <- read_input("data/processed/final/table2/testing_member_month_panel.rds",
    c("period_id", "portfolio", "permno", "month", "ret", "listed_nyse_common", "valid_return")) |>
    select(period_id, portfolio, permno, month, ret, listed_nyse_common, valid_return) |>
    mutate(month = month_date(month))
  annual <- read_input("data/processed/final/annual_individual_risk.rds",
    c("period_id", "portfolio", "permno", "testing_year", "beta_individual",
      "resid_sd_individual", "information_cutoff", "last_observation_month"))
  returns_A <- read_input("data/processed/final/table2/portfolio_returns_final.rds",
    c("period_id", "portfolio", "date", "portfolio_return", "n_expected", "n_valid")) |>
    transmute(period_id, portfolio, month = month_date(date), portfolio_return,
      saved_n_expected = n_expected, saved_n_valid = n_valid)

  member_keys <- c("period_id", "permno", "portfolio")
  monthly_keys <- c("period_id", "portfolio", "month")
  unique_keys(periods, "period_id", "Periods")
  unique_keys(members, c("period_id", "permno"), "Portfolio assignments")
  unique_keys(panel, c("period_id", "permno", "month"), "Testing member panel")
  unique_keys(annual, c("period_id", "testing_year", "permno"), "Annual risks")
  unique_keys(returns_A, monthly_keys, "A returns")
  same_keys(panel, members, member_keys, "Testing membership")
  same_keys(annual, members, member_keys, "Annual risk membership")
  same_keys(periods, members, "period_id", "Periods and membership")
  if (!is.logical(panel$listed_nyse_common) || !is.logical(panel$valid_return) ||
      anyNA(panel[c("listed_nyse_common", "valid_return")]) ||
      any(panel$valid_return != is.finite(panel$ret))) stop("Invalid listing/return flags in common panel.")

  # Validate the full assigned-member grid before filtering listing status.
  expected_months <- bind_rows(lapply(seq_len(nrow(periods)), function(i) {
    p <- periods[i, ]
    months <- seq(month_date(p$testing_start), month_date(p$testing_end), by = "month")
    observed <- panel |> filter(period_id == p$period_id)
    counts <- observed |> count(permno)
    if (any(!observed$month %in% months) || any(counts$n != length(months))) {
      stop("Incomplete member-month grid in period ", p$period_id)
    }
    if (!setequal(observed$portfolio, 1:20)) stop("Expected 20 portfolios in each period.")
    expand.grid(period_id = p$period_id, portfolio = 1:20, month = months)
  }))
  same_keys(expected_months, returns_A, monthly_keys, "Expected portfolio months and A returns")
  cat("PASS: membership, monthly coverage and unique keys checked.\n")

  current <- panel |>
    filter(listed_nyse_common) |>
    mutate(testing_year = as.integer(format(month, "%Y"))) |>
    left_join(annual |> select(all_of(member_keys), testing_year, beta_individual,
        resid_sd_individual, information_cutoff, last_observation_month),
      by = c(member_keys, "testing_year"))
  if (any(!is.finite(current$beta_individual)) ||
      any(!is.finite(current$resid_sd_individual)) ||
      any(current$resid_sd_individual < 0)) stop("Missing or invalid risk for a current member.")
  expected_cutoff <- as.Date(sprintf("%d-12-31", current$testing_year - 1L))
  if (anyNA(current[c("information_cutoff", "last_observation_month")]) ||
      any(as.Date(current$information_cutoff) != expected_cutoff) ||
      any(as.Date(current$information_cutoff) >= current$month) ||
      any(as.Date(current$last_observation_month) > as.Date(current$information_cutoff))) {
    stop("Invalid risk information cutoff. Rerun step 1.")
  }

  monthly_risk <- current |>
    group_by(period_id, portfolio, month) |>
    summarise(
      n_members = n(),
      n_valid_returns = sum(valid_return),
      n_missing_returns = sum(!valid_return),
      beta_portfolio = mean(beta_individual),
      beta2_portfolio = mean(beta_individual^2),
      mean_resid_sd = mean(resid_sd_individual),
      information_cutoff = first(as.Date(information_cutoff)),
      return_recomputed = if (any(valid_return)) mean(ret[valid_return]) else NA_real_,
      .groups = "drop"
    )
  same_keys(expected_months, monthly_risk, monthly_keys, "Current portfolio membership coverage")
  combined <- returns_A |> left_join(monthly_risk, by = monthly_keys)
  if (anyNA(combined[c("saved_n_expected", "saved_n_valid")]) ||
      any(combined$saved_n_expected != combined$n_members) ||
      any(combined$saved_n_valid != combined$n_valid_returns)) {
    stop("A return counts differ from the common panel. Rerun final/00c and this step.")
  }
  if (any(!is.finite(combined$portfolio_return)) ||
      any(!is.finite(combined$return_recomputed)) ||
      any(abs(combined$portfolio_return - combined$return_recomputed) > 1e-12)) {
    stop("Saved A returns do not match available-case returns from the common panel.")
  }
  cat("PASS: saved A returns and member counts match independent recomputation.\n")
  if (any(!is.finite(combined$beta2_portfolio)) ||
      any(combined$beta2_portfolio + 1e-12 < combined$beta_portfolio^2)) {
    stop("Invalid mean of squared individual betas.")
  }
  table3_panel <- combined |>
    transmute(period_id, portfolio, date = month,
      testing_year = as.integer(format(month, "%Y")), portfolio_return,
      beta_portfolio, beta2_portfolio, mean_resid_sd,
      n_members, n_valid_returns, n_missing_returns, information_cutoff) |>
    arrange(date, portfolio)
  unique_keys(table3_panel, c("date", "portfolio"), "Final Table 3 panel")
  month_check <- table3_panel |> count(date)
  if (any(month_check$n != 20L)) stop("A month does not contain 20 portfolios.")
  cat("PASS: three finite risk variables; prior-year estimates; 20 portfolios in every month.\n")
  summary <- table3_panel |> group_by(period_id) |>
    summarise(n_months = n_distinct(date), n_portfolio_months = n(),
      n_valid_returns = sum(is.finite(portfolio_return)),
      n_complete_risk_rows = sum(is.finite(beta_portfolio) & is.finite(beta2_portfolio) & is.finite(mean_resid_sd)),
      n_partial_portfolio_months = sum(n_missing_returns > 0), .groups = "drop")
  print(summary, n = Inf, width = Inf)
  dir.create("data/processed/final", recursive = TRUE, showWarnings = FALSE)
  saveRDS(table3_panel, "data/processed/final/table3_panel_altA.rds")
  cat("\nTable 3 panel completed:", nrow(table3_panel), "portfolio-months in",
    nrow(month_check), "months.\nSaved to: data/processed/final/table3_panel_altA.rds\n")
  cat("The final diagnostic column counts portfolio-months with temporary missing member returns.\n")
})
