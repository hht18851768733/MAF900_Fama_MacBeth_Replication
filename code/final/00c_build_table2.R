# Final Table 2 and testing-period returns, using selected DP1-B and DP2-A.
# Source from the project root after 00a and 00b. All calculation scripts
# and processed inputs are independent of the alternative-development folders.
local({
  for (pkg in c("dplyr", "tidyr", "lubridate", "purrr")) {
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Install ", pkg, " first.")
  }
  required <- c("data/processed/final/table1/periods.rds",
    "data/processed/final/table1/eligible_securities.rds",
    "data/raw/common/nyse_common_1926_1968.rds", "data/raw/common/nyse_listing_segments.rds")
  if (!all(file.exists(required))) stop("Run final/00a and final/00b first.")
  dir.create("data/processed/final/table2", recursive = TRUE, showWarnings = FALSE)
  dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
  scripts <- c("01_prepare_market_index.R", "02_estimate_formation_betas.R",
    "03_form_portfolios.R", "04_estimate_initial_risk.R", "05_build_testing_panel.R",
    "06_build_estimation_panel.R", "07_portfolio_returns.R", "08_table2_output.R")
  paths <- file.path("code/final/table2", scripts)
  if (!all(file.exists(paths))) stop("Copy the complete final/table2 folder into the project.")
  for (path in paths) {
    cat("\nRunning", path, "\n")
    source(path, local = new.env(parent = globalenv()))
  }
  returns <- readRDS("data/processed/final/table2/portfolio_returns_final.rds")
  estimation <- readRDS("data/processed/final/table2/estimation_portfolio_returns_final.rds")
  table2 <- readRDS("data/processed/final/table2/table2_final.rds")
  periods <- readRDS("data/processed/final/table1/periods.rds")
  expected_grid <- function(start, end) {
    dplyr::bind_rows(lapply(seq_len(nrow(periods)), function(i) {
      dates <- seq(as.Date(format(periods[[start]][i], "%Y-%m-01")),
        as.Date(format(periods[[end]][i], "%Y-%m-01")), by = "month")
      tidyr::expand_grid(period_id = periods$period_id[i], portfolio = 1:20, date = dates)
    }))
  }
  check_returns <- function(x, expected, label) {
    keys <- c("period_id", "portfolio", "date")
    if (anyNA(x[keys]) || anyDuplicated(x[keys]) ||
        nrow(dplyr::anti_join(expected, x, by = keys)) ||
        nrow(dplyr::anti_join(x, expected, by = keys)) ||
        any(!is.finite(x$portfolio_return)) || anyNA(x[c("n_expected", "n_valid")]) ||
        any(x$n_valid <= 0 | x$n_valid > x$n_expected)) {
      stop(label, ": incomplete grid, invalid counts or invalid returns.")
    }
  }
  check_returns(returns, expected_grid("testing_start", "testing_end"), "Testing returns")
  check_returns(estimation, expected_grid("estimation_start", "estimation_end"), "Estimation returns")
  if (nrow(table2) != 180L || anyDuplicated(table2[c("period_id", "portfolio")]) ||
      any(!vapply(table2, function(x) all(is.finite(x)), logical(1)))) stop("Invalid final Table 2 statistics.")
  diagnostic <- returns |>
    dplyr::group_by(period_id) |>
    dplyr::summarise(n_months = dplyr::n_distinct(date), n_portfolios = dplyr::n_distinct(portfolio),
      n_portfolio_months = dplyr::n(), n_valid_returns = sum(is.finite(portfolio_return)),
      n_partial_portfolio_months = sum(n_valid < n_expected), .groups = "drop")
  write.csv(diagnostic, "output/tables/table2_final_testing_coverage.csv", row.names = FALSE)
  writeLines(c("# Final Table 2 notes", "",
    "Selected pipeline: DP1-B and DP2-A available-case equal weighting.",
    "Market input: published CRSP NYSE equal-weighted index 1000001 (mthtotret).", "",
    "The displayed beta is the mean individual beta (beta_portfolio).",
    "The displayed SE belongs to the portfolio-return regression (se_beta_correct),",
    "whose beta is beta_from_portfolio_regression in the detailed output.",
    "The detailed se_beta_portfolio field is sd(individual betas)/sqrt(n);",
    "it is a cross-security dispersion diagnostic, not a regression standard error.",
    "Individual and portfolio residual risk use sample SD of fitted residuals.",
    "The displayed periods 2, 4, 6 and 8 have estimation windows 1934-1938,",
    "1942-1946, 1950-1954 and 1958-1962, respectively.", "",
    "Shared preparation and the selected A calculations are retained from the",
    "group's implementations. Integration changes paths, output names and checks;",
    "it does not introduce a different missing-return rule.",
    "The final testing return file supplies Table 3; it is separate from the",
    "60-month estimation-window returns used to calculate Table 2."),
    "output/tables/table2_final_notes.md")
  cat("\nPASS: 180 finite Table 2 rows; 20 portfolios in every estimation and testing month.\n")
  print(diagnostic, n = Inf, width = Inf)
  cat("Final Table 2 completed.\nProcessed inputs: data/processed/final/table2/\n")
  cat("Saved: output/tables/table2_final_detailed.csv\n")
  cat("Saved: output/tables/table2_final_all_periods_display.csv\n")
  cat("Saved: output/tables/table2_final_display.csv\n")
})
