# Table 3, step 1: annual individual-security risk estimates.
# Run from the repository root: source("code/final/01_update_annual_risk.R")
# Selected inputs: Decision 1 B, shared NYSE index, Decision 2 A returns.
# Fama & MacBeth (1973), pp. 615-617: expand the initial five-year window
# through December of the preceding year; update individual risks annually.
# Project conventions: finite paired observations, minimum 54 observations
# retained from DP1 B (not a new 90% threshold), sd(residuals), raw returns.
# This script estimates individual risks only; monthly portfolio aggregation
# and the cross-sectional regressions are subsequent steps.

local({
  library(dplyr)

  read_input <- function(path, columns) {
    if (!file.exists(path)) stop("Missing input: ", path)
    x <- readRDS(path)
    missing <- setdiff(columns, names(x))
    if (length(missing)) stop(path, ": missing columns ", paste(missing, collapse = ", "))
    x
  }
  check_unique <- function(x, keys, label) {
    if (anyNA(x[keys]) || anyDuplicated(x[keys])) {
      stop(label, ": missing or duplicate keys.")
    }
  }
  month_date <- function(x) as.Date(paste0(format(as.Date(x), "%Y-%m"), "-01"))
  year_number <- function(x) as.integer(format(as.Date(x), "%Y"))

  periods <- read_input("data/processed/final/table1/periods.rds",
    c("period_id", "estimation_start", "estimation_end", "testing_start", "testing_end"))
  members <- read_input("data/processed/final/table2/portfolio_formation.rds",
    c("period_id", "permno", "portfolio")) |>
    select(period_id, permno, portfolio)
  initial <- read_input("data/processed/final/table2/estimation_betas.rds",
    c("period_id", "permno", "portfolio", "beta_estimation", "resid_sd", "n_obs"))
  stocks <- read_input("data/raw/common/nyse_common_1926_1968.rds",
    c("permno", "date", "ret")) |>
    transmute(permno, month = month_date(date), ret)
  market <- read_input("data/raw/common/market_index_nyse_ew.rds",
    c("indno", "date", "mkt_ret")) |>
    transmute(indno, month = month_date(date), mkt_ret)
  returns_A <- read_input("data/processed/final/table2/portfolio_returns_final.rds",
    c("period_id", "portfolio", "date", "portfolio_return")) |>
    mutate(month = month_date(date))

  check_unique(periods, "period_id", "Periods")
  check_unique(members, c("period_id", "permno"), "Portfolio assignments")
  check_unique(initial, c("period_id", "permno"), "Initial risks")
  check_unique(stocks, c("permno", "month"), "Stock returns")
  check_unique(market, "month", "Market index")
  check_unique(returns_A, c("period_id", "portfolio", "month"), "A portfolio returns")
  if (anyNA(market$indno) || any(market$indno != 1000001L) ||
      any(!is.finite(market$mkt_ret))) stop("Invalid NYSE index observations.")
  if (!setequal(members$period_id, periods$period_id) ||
      !setequal(returns_A$period_id, periods$period_id)) stop("Period IDs do not match.")

  # Exact expected portfolio-month coverage, including the final partial year.
  expected <- bind_rows(lapply(seq_len(nrow(periods)), function(i) {
    p <- periods[i, ]
    expand.grid(period_id = p$period_id, portfolio = 1:20,
      month = seq(month_date(p$testing_start), month_date(p$testing_end), by = "month"))
  }))
  keys <- c("period_id", "portfolio", "month")
  if (nrow(anti_join(expected, returns_A, by = keys)) ||
      nrow(anti_join(returns_A, expected, by = keys)) ||
      any(!is.finite(returns_A$portfolio_return))) {
    stop("A returns do not have the expected complete, finite testing coverage.")
  }
  cat("PASS: A returns have unique keys and complete testing coverage.\n")

  paired <- stocks |>
    left_join(market |> select(month, mkt_ret), by = "month") |>
    filter(is.finite(ret), is.finite(mkt_ret))
  results <- list()
  for (i in seq_len(nrow(periods))) {
    p <- periods[i, ]
    current_members <- members |> filter(period_id == p$period_id)
    if (!setequal(current_members$portfolio, 1:20)) stop("Expected 20 portfolios per period.")
    first_year <- year_number(p$testing_start)
    years <- seq(first_year, year_number(p$testing_end))
    start <- month_date(p$estimation_start)
    if (as.Date(p$estimation_end) != as.Date(sprintf("%d-12-31", first_year - 1L))) {
      stop("Initial estimation window must end in December before testing.")
    }
    for (yr in years) {
      cutoff <- as.Date(sprintf("%d-12-31", yr - 1L))
      window_months <- seq(start, month_date(cutoff), by = "month")
      if (length(window_months) != 60L + 12L * (yr - first_year) ||
          !all(window_months %in% market$month)) stop("Invalid estimation window or incomplete index.")
      sample <- paired |>
        semi_join(current_members, by = "permno") |>
        filter(month >= start, month <= cutoff) |>
        arrange(permno, month)
      estimates <- sample |>
        group_by(permno) |>
        group_modify(function(.x, .y) {
          if (nrow(.x) < 54L || var(.x$mkt_ret) <= 0) {
            stop("Cannot estimate risk: period ", p$period_id,
              ", year ", yr, ", PERMNO ", .y$permno)
          }
          fit <- lm(ret ~ mkt_ret, data = .x)
          tibble(beta_individual = unname(coef(fit)["mkt_ret"]),
            resid_sd_individual = sd(residuals(fit)), n_obs = nobs(fit),
            last_observation_month = max(.x$month))
        }) |>
        ungroup()
      if (!setequal(estimates$permno, current_members$permno) ||
          any(!is.finite(estimates$beta_individual)) ||
          any(!is.finite(estimates$resid_sd_individual))) stop("Incomplete annual risk estimates.")
      results[[length(results) + 1L]] <- current_members |>
        left_join(estimates, by = "permno") |>
        mutate(testing_year = yr, estimation_start = start,
          information_cutoff = cutoff, n_calendar_months = length(window_months))
    }
    cat("Estimated period", p$period_id, "for", paste(range(years), collapse = "-"), "\n")
  }
  annual_risk <- bind_rows(results) |> arrange(period_id, testing_year, portfolio, permno)
  check_unique(annual_risk, c("period_id", "testing_year", "permno"), "Annual risks")
  if (any(annual_risk$last_observation_month > annual_risk$information_cutoff)) {
    stop("Risk estimation used observations after the information cutoff.")
  }

  # Recompute rather than copy the first year, so stale input/index choices fail.
  first <- annual_risk |> group_by(period_id) |>
    filter(testing_year == min(testing_year)) |> ungroup()
  match_keys <- c("period_id", "permno", "portfolio")
  if (nrow(anti_join(first, initial, by = match_keys)) ||
      nrow(anti_join(initial, first, by = match_keys))) stop("Initial risk membership mismatch.")
  comparison <- first |>
    left_join(initial |> select(all_of(match_keys), beta_estimation,
      initial_resid_sd = resid_sd, initial_n_obs = n_obs), by = match_keys) |>
    mutate(beta_difference = abs(beta_individual - beta_estimation),
      resid_sd_difference = abs(resid_sd_individual - initial_resid_sd))
  if (anyNA(comparison[c("beta_difference", "resid_sd_difference", "initial_n_obs")]) ||
      any(comparison$beta_difference > 1e-10) ||
      any(comparison$resid_sd_difference > 1e-10) ||
      any(comparison$n_obs != comparison$initial_n_obs)) {
    stop("First-year estimates differ from final/table2/04. Check inputs and rerun shared preparation.")
  }
  cat("PASS: first-year beta, residual SD and observation counts match final/table2/04.\n")
  diagnostic <- annual_risk |> group_by(period_id) |>
    summarise(n_years = n_distinct(testing_year), n_securities = n_distinct(permno),
      min_window_months = min(n_calendar_months), max_window_months = max(n_calendar_months),
      min_valid_months = min(n_obs), max_valid_months = max(n_obs), .groups = "drop")
  print(diagnostic, n = Inf, width = Inf)
  output_dir <- "data/processed/final"
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  saveRDS(annual_risk, file.path(output_dir, "annual_individual_risk.rds"))
  cat("\nAnnual risk updates completed.\nSaved to:",
    file.path(output_dir, "annual_individual_risk.rds"), "\n")
})
