# Table 3, step 5: time-series summaries for four models and ten samples.
# Run from project root: source("code/final/05_summarise_table3.R")
# Reference: Fama & MacBeth (1973), pp. 619, 622-623 (Table 3).
# mean = mean(monthly coefficients); SD = sample SD with denominator n-1;
# SE(mean) = SD/sqrt(n); t = mean/SE(mean), without a HAC correction.
# Do not average monthly cross-sectional standard errors or t-statistics.
# R-squared columns in the original Table 3 are adjusted for degrees of freedom.
# Autocorrelation conventions are explicitly documented below and in notes.

local({
  library(dplyr)
  regression_file <- "data/processed/final/table3_monthly_regressions.rds"
  rf_file <- "data/raw/common/risk_free_ff_monthly.rds"
  if (!file.exists(regression_file) || !file.exists(rf_file)) stop("Run final/03 and final/04 first.")
  regressions <- readRDS(regression_file)
  risk_free <- readRDS(rf_file)
  rf_source <- attr(risk_free, "source_info")
  required <- c("model", "date", "n_portfolios", "n_parameters", "residual_df",
    "gamma0", "gamma1", "gamma2", "gamma3", "r_squared", "adjusted_r_squared")
  if (!all(required %in% names(regressions)) || !all(c("date", "rf") %in% names(risk_free))) {
    stop("Required input columns are missing.")
  }
  if (is.null(rf_source) || !identical(rf_source$output_units, "monthly decimal")) {
    stop("RF units/provenance unavailable. Rerun final/04.")
  }
  regressions <- regressions |> mutate(date = as.Date(date)) |> arrange(model, date)
  risk_free <- risk_free |> mutate(date = as.Date(date)) |> arrange(date)
  expected_dates <- seq(as.Date("1935-01-01"), as.Date("1968-06-01"), by = "month")
  active_terms <- list(A = c("gamma0", "gamma1"), B = c("gamma0", "gamma1", "gamma2"),
    C = c("gamma0", "gamma1", "gamma3"), D = paste0("gamma", 0:3))
  all_terms <- paste0("gamma", 0:3)
  if (anyNA(regressions[c("model", "date")]) ||
      anyDuplicated(regressions[c("model", "date")]) ||
      !setequal(regressions$model, names(active_terms))) stop("Invalid model/date keys.")
  if (anyNA(risk_free$date) || anyDuplicated(risk_free$date) ||
      !identical(risk_free$date, expected_dates) || any(!is.finite(risk_free$rf))) stop("Invalid RF coverage.")
  for (model_name in names(active_terms)) {
    x <- regressions |> filter(model == model_name)
    k <- length(active_terms[[model_name]])
    if (!identical(x$date, expected_dates)) stop("Missing months for model ", model_name)
    if (anyNA(x[c("n_portfolios", "n_parameters", "residual_df")]) ||
        any(x$n_portfolios != 20L) || any(x$n_parameters != k) || any(x$residual_df != 20L-k)) {
      stop("Unexpected regression dimensions for model ", model_name)
    }
    needed <- c(active_terms[[model_name]], "r_squared", "adjusted_r_squared")
    if (!all(vapply(x[needed], function(z) is.numeric(z) && all(is.finite(z)), logical(1)))) {
      stop("Non-finite regression statistics for model ", model_name)
    }
    omitted <- setdiff(all_terms, active_terms[[model_name]])
    if (length(omitted) && !all(is.na(as.matrix(x[omitted])))) stop("Omitted coefficients must be NA.")
    adj_expected <- 1 - (1-x$r_squared) * 19/(20-k)
    if (any(abs(x$adjusted_r_squared-adj_expected) > 1e-10)) stop("Adjusted R-squared check failed.")
  }
  joined <- regressions |>
    left_join(risk_free |> select(date, rf), by = "date") |>
    mutate(gamma0_minus_rf = gamma0-rf)
  cat("PASS: 402 months per model; RF joins exactly; adjusted R-squared verified.\n")

  # These are reporting samples, not the nine formation/testing period IDs.
  samples <- tibble(
    sample_id = 1:10,
    sample_period = c("1935-06/1968", "1935-1945", "1946-1955", "1956-06/1968",
      "1935-1940", "1941-1945", "1946-1950", "1951-1955", "1956-1960", "1961-06/1968"),
    sample_start = as.Date(c("1935-01-01", "1935-01-01", "1946-01-01", "1956-01-01",
      "1935-01-01", "1941-01-01", "1946-01-01", "1951-01-01", "1956-01-01", "1961-01-01")),
    sample_end = as.Date(c("1968-06-01", "1945-12-01", "1955-12-01", "1968-06-01",
      "1940-12-01", "1945-12-01", "1950-12-01", "1955-12-01", "1960-12-01", "1968-06-01")),
    expected_months = c(402L,132L,120L,150L,72L,60L,60L,60L,60L,90L)
  )
  moments <- function(x, label) {
    if (any(!is.finite(x))) stop("Invalid observations in ", label)
    s <- sd(x)
    if (!is.finite(s) || s <= 0) stop("Zero/invalid coefficient variation in ", label)
    c(mean = mean(x), sd = s, se_mean = s/sqrt(length(x)), t = mean(x)/(s/sqrt(length(x))))
  }
  # Lag-one autocorrelation with a full-series denominator. For rho_M subtract
  # the full sample mean; for rho_0 use zero centering. Paper specifies the
  # centering; we state this finite-sample normalization as our implementation.
  # Using cor(x[-1], x[-n]) would recenter both truncated samples, even for rho_0.
  rho1 <- function(x, center = 0) {
    z <- x-center
    denominator <- sum(z^2)
    if (!is.finite(denominator) || denominator <= 0) stop("Undefined serial correlation.")
    sum(z[-1L]*z[-length(z)])/denominator
  }
  result <- list()
  for (model_name in names(active_terms)) {
    for (i in seq_len(nrow(samples))) {
      s <- samples[i, ]
      x <- joined |> filter(model == model_name, date >= s$sample_start, date <= s$sample_end) |>
        arrange(date)
      wanted_dates <- seq(s$sample_start, s$sample_end, by = "month")
      if (nrow(x) != s$expected_months || !identical(x$date, wanted_dates)) stop("Incomplete reporting sample.")
      row <- tibble(model = model_name, sample_id = s$sample_id,
        sample_period = s$sample_period, sample_start = s$sample_start,
        sample_end = s$sample_end, n_months = nrow(x))
      for (term in c(all_terms, "gamma0_minus_rf")) {
        active <- term %in% c(active_terms[[model_name]], "gamma0_minus_rf")
        v <- if (active) moments(x[[term]], paste(model_name,s$sample_period,term)) else
          c(mean = NA_real_, sd = NA_real_, se_mean = NA_real_, t = NA_real_)
        for (stat in names(v)) row[[paste0(stat,"_",term)]] <- unname(v[stat])
      }
      row$rho0_gamma0_minus_rf <- rho1(x$gamma0_minus_rf)
      row$rhoM_gamma1 <- rho1(x$gamma1, mean(x$gamma1))
      row$rho0_gamma2 <- if ("gamma2" %in% active_terms[[model_name]]) rho1(x$gamma2) else NA_real_
      row$rho0_gamma3 <- if ("gamma3" %in% active_terms[[model_name]]) rho1(x$gamma3) else NA_real_
      row$mean_adjusted_r_squared <- mean(x$adjusted_r_squared)
      row$sd_adjusted_r_squared <- sd(x$adjusted_r_squared)
      result[[length(result)+1L]] <- row
    }
  }
  table3_summary <- bind_rows(result) |> arrange(model, sample_id)
  if (nrow(table3_summary) != 40L || anyDuplicated(table3_summary[c("model", "sample_id")])) {
    stop("Expected 40 unique model/sample rows.")
  }
  cat("PASS: four models x ten reporting samples = 40 summary rows.\n")
  cat("PASS: t-statistics use time-series SD/sqrt(n); omitted terms remain NA.\n")
  cat("\nFull-sample results:\n")
  print(table3_summary |> filter(sample_id == 1L) |>
    select(model,n_months,mean_gamma0,mean_gamma1,mean_gamma2,mean_gamma3,
      t_gamma1,t_gamma2,t_gamma3,t_gamma0_minus_rf,mean_adjusted_r_squared), n = Inf, width = Inf)

  method_notes <- c(
    "# Table 3 statistics notes", "",
    "Selected pipeline: Decision 1 B and Decision 2 A; published CRSP NYSE equal-weighted market index.",
    "Four monthly OLS specifications, each using 20 equally weighted portfolios and an intercept.",
    "Individual risk estimates expand from 5 to 8 years and use data through the preceding December.",
    "Monthly portfolio risks average current listed members. Temporary missing returns do not remove a pre-estimated risk; A portfolio returns average finite returns. Their denominators can therefore differ.",
    "beta2 is the mean of squared individual betas. Non-beta risk is mean individual residual SD, calculated using sd(residuals) in the individual regressions.", "",
    "## Reporting samples and units", "",
    "The ten original Table 3 reporting samples overlap. They differ from the nine formation/testing periods; they must not be pooled or added together.",
    "Expected months: 402, 132, 120, 150, 72, 60, 60, 60, 60, 90, in sample_id order.",
    "Returns and RF are monthly decimals. No percentage rescaling or annualization is applied to coefficients.", "",
    "## Summary definitions", "",
    "Coefficient means and sample SDs are computed across monthly cross-sectional estimates. Sample SD uses n-1. SE(mean) = SD/sqrt(n), and t = mean/SE(mean). No HAC/Newey-West adjustment is applied to the primary replication.",
    "Monthly cross-sectional coefficient SEs are not used as SEs of time-series means.",
    "For the gamma0-RF test, subtract RF month by month first; use the SD of this difference series in its t-statistic.",
    "The reported R-squared mean and SD use monthly adjusted R-squared, as specified on p. 619. Negative adjusted values are retained.",
    "Serial correlations use lag one. rho_M(gamma1) is centered at the full reporting-sample mean; rho_0(gamma0-RF), rho_0(gamma2), and rho_0(gamma3) are centered at zero.",
    "Implementation convention: rho = sum(z[t]*z[t-1], t=2..n) / sum(z[t]^2, t=1..n), with z=x-center. The paper specifies centering but does not give this finite-sample denominator explicitly.",
    "Omitted gamma2/gamma3 statistics are NA (not zero). No missing observations are silently dropped.", "",
    "## RF provenance", "",
    paste0("Provider: ",rf_source$provider,". Series: ",rf_source$series,"."),
    paste0("Source: ",rf_source$source_url),
    paste0("Raw ZIP MD5: ",rf_source$source_zip_md5),
    "RF was divided by 100 once to convert monthly percent to decimal. Negative RF observations are retained.",
    rf_source$vintage_note, "",
    "Reference: Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. Journal of Political Economy, 81(3), 607-636. https://doi.org/10.1086/260061",
    "Table 3 definitions and reporting periods: pp. 619, 622-623."
  )
  attr(table3_summary,"rf_source") <- rf_source
  attr(table3_summary,"method_notes") <- method_notes
  dir.create("data/processed/final",recursive=TRUE,showWarnings=FALSE)
  dir.create("output/tables",recursive=TRUE,showWarnings=FALSE)
  saveRDS(table3_summary,"data/processed/final/table3_summary.rds")
  write.csv(table3_summary,"output/tables/table3_summary_detailed.csv",row.names=FALSE,na="NA")
  writeLines(method_notes,"output/tables/table3_statistics_notes.md",useBytes=TRUE)
  cat("\nTable 3 summary statistics completed.\n")
  cat("Saved: data/processed/final/table3_summary.rds\n")
  cat("Saved: output/tables/table3_summary_detailed.csv\n")
  cat("Saved: output/tables/table3_statistics_notes.md\n")
})
