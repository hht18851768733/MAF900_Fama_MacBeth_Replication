# Table 3, step 3: 20-portfolio cross-sectional OLS each month.
# Run from project root: source("code/final/03_run_monthly_regressions.R")
# Fama & MacBeth (1973), equation (10), Table 3 panels A-D:
# A: return ~ beta; B: return ~ beta + mean(individual beta^2);
# C: return ~ beta + mean(individual residual SD); D: all three risks.
# All models include an intercept and give each portfolio equal weight.
# Returns are raw monthly decimal returns, not excess returns or percentages.
# Risk variables are already aligned to the return month by steps 1-2;
# do not shift them by another month or recompute beta2 as beta_portfolio^2.
# Omitted gamma terms are NA, not zero. se_gamma* are conventional OLS
# standard errors WITHIN each monthly cross-section. They are not the
# time-series standard errors of mean gammas used in the final Table 3.

local({
  library(dplyr)
  path <- "data/processed/final/table3_panel_altA.rds"
  if (!file.exists(path)) stop("Missing input. Run final/02 first: ", path)
  panel <- readRDS(path)
  required <- c("period_id", "portfolio", "date", "portfolio_return",
    "beta_portfolio", "beta2_portfolio", "mean_resid_sd", "information_cutoff")
  if (!all(required %in% names(panel))) stop("Required panel columns are missing.")
  panel <- panel |> mutate(date = as.Date(date), information_cutoff = as.Date(information_cutoff)) |>
    arrange(date, portfolio)
  if (anyNA(panel[c("period_id", "portfolio", "date", "information_cutoff")]) ||
      anyDuplicated(panel[c("date", "portfolio")])) stop("Missing or duplicate panel keys.")
  numeric_columns <- c("portfolio_return", "beta_portfolio", "beta2_portfolio", "mean_resid_sd")
  if (!all(vapply(panel[numeric_columns], function(x) is.numeric(x) && all(is.finite(x)), logical(1)))) {
    stop("Non-finite return or risk variables. Rerun final/02.")
  }
  expected_dates <- seq(as.Date("1935-01-01"), as.Date("1968-06-01"), by = "month")
  if (!setequal(panel$date, expected_dates)) stop("Expected monthly coverage: January 1935 to June 1968.")
  expected_cutoff <- as.Date(sprintf("%d-12-31", as.integer(format(panel$date, "%Y")) - 1L))
  if (any(panel$information_cutoff != expected_cutoff)) stop("Unexpected risk information cutoff.")
  if (any(panel$mean_resid_sd < 0) || any(panel$beta2_portfolio + 1e-12 < panel$beta_portfolio^2)) {
    stop("Invalid risk measures in input panel.")
  }
  expected_period <- pmin(9L, (as.integer(format(panel$date, "%Y")) - 1935L) %/% 4L + 1L)
  if (any(panel$period_id != expected_period)) stop("Period IDs do not match testing dates.")
  months <- split(panel, format(panel$date, "%Y-%m"))
  if (!all(vapply(months, function(x) nrow(x) == 20L && setequal(x$portfolio, 1:20), logical(1)))) {
    stop("Each month must contain portfolios 1-20 exactly once.")
  }
  cat("PASS: 402 months, 20 portfolios per month, finite inputs and prior-year risk estimates.\n")

  models <- list(
    A = portfolio_return ~ beta_portfolio,
    B = portfolio_return ~ beta_portfolio + beta2_portfolio,
    C = portfolio_return ~ beta_portfolio + mean_resid_sd,
    D = portfolio_return ~ beta_portfolio + beta2_portfolio + mean_resid_sd
  )
  term_names <- c("(Intercept)", "beta_portfolio", "beta2_portfolio", "mean_resid_sd")
  output <- vector("list", length(models))
  for (m in seq_along(models)) {
    model_name <- names(models)[m]
    results <- lapply(months, function(x) {
      fit <- lm(models[[m]], data = x, na.action = na.fail)
      model_matrix <- model.matrix(fit)
      if (fit$rank != ncol(model_matrix)) {
        stop("Rank-deficient regression in panel ", model_name, ", month ", x$date[1])
      }
      sm <- summary(fit)
      b <- coef(fit)
      se <- sm$coefficients[, "Std. Error"]
      if (nobs(fit) != 20L || any(!is.finite(b)) || any(!is.finite(se)) ||
          !is.finite(sm$r.squared) || !is.finite(sm$adj.r.squared)) {
        stop("Invalid regression in panel ", model_name, ", month ", x$date[1])
      }
      # Identity and normal-equation checks catch accidental fitting changes.
      errors <- residuals(fit)
      scale <- max(1, max(abs(model_matrix))) * max(1, max(abs(x$portfolio_return)))
      if (max(abs(drop(crossprod(model_matrix, errors)))) > 1e-8 * scale ||
          max(abs(x$portfolio_return - fitted(fit) - errors)) > 1e-10 * scale) {
        stop("OLS verification failed in panel ", model_name, ", month ", x$date[1])
      }
      coef_value <- function(name) if (name %in% names(b)) unname(b[name]) else NA_real_
      se_value <- function(name) if (name %in% names(se)) unname(se[name]) else NA_real_
      tibble(period_id = x$period_id[1], date = x$date[1], model = model_name,
        n_portfolios = nobs(fit), n_parameters = length(b), residual_df = df.residual(fit),
        gamma0 = coef_value(term_names[1]), gamma1 = coef_value(term_names[2]),
        gamma2 = coef_value(term_names[3]), gamma3 = coef_value(term_names[4]),
        se_gamma0 = se_value(term_names[1]), se_gamma1 = se_value(term_names[2]),
        se_gamma2 = se_value(term_names[3]), se_gamma3 = se_value(term_names[4]),
        r_squared = sm$r.squared, adjusted_r_squared = sm$adj.r.squared,
        regression_sigma = sm$sigma)
    })
    output[[m]] <- bind_rows(results)
    cat("Panel", model_name, "completed:", length(results), "monthly regressions.\n")
  }
  monthly_regressions <- bind_rows(output) |> arrange(model, date)
  if (nrow(monthly_regressions) != 1608L ||
      anyDuplicated(monthly_regressions[c("model", "date")])) stop("Unexpected regression output coverage.")
  diagnostics <- monthly_regressions |> group_by(model) |>
    summarise(n_months = n(), min_portfolios = min(n_portfolios), max_portfolios = max(n_portfolios),
      residual_df = first(residual_df), mean_r_squared = mean(r_squared), .groups = "drop")
  cat("PASS: all 1,608 regressions use 20 portfolios and have full column rank.\n")
  print(diagnostics, n = Inf, width = Inf)
  dir.create("data/processed/final", recursive = TRUE, showWarnings = FALSE)
  saveRDS(monthly_regressions, "data/processed/final/table3_monthly_regressions.rds")
  cat("\nMonthly cross-sectional regressions completed.\n")
  cat("Saved to: data/processed/final/table3_monthly_regressions.rds\n")
  cat("Next step: time-series summaries of coefficients for Table 3.\n")
})
