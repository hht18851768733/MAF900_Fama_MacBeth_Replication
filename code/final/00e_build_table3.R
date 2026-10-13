# Final Table 3 entry point. Run after final/00c_build_table2.R.
# Preserve existing local results, run steps 01-06, and compare the values.
# Previous results are optional: a fresh project can reproduce without them.
local({
  required <- c("data/processed/final/table1/periods.rds",
    "data/processed/final/table2/portfolio_formation.rds",
    "data/processed/final/table2/estimation_betas.rds",
    "data/processed/final/table2/testing_member_month_panel.rds",
    "data/processed/final/table2/portfolio_returns_final.rds",
    "data/raw/common/nyse_common_1926_1968.rds",
    "data/raw/common/market_index_nyse_ew.rds")
  if (!all(file.exists(required))) stop("Complete final/00a, 00b and 00c before Table 3.")
  scripts <- file.path("code/final", c("01_update_annual_risk.R", "02_build_table3_panel.R",
    "03_run_monthly_regressions.R", "04_prepare_risk_free.R", "05_summarise_table3.R",
    "06_export_table3.R"))
  if (!all(file.exists(scripts))) stop("Missing one or more final Table 3 scripts.")
  files <- c(
    annual_risk = "data/processed/final/annual_individual_risk.rds",
    table3_panel = "data/processed/final/table3_panel_altA.rds",
    monthly_regressions = "data/processed/final/table3_monthly_regressions.rds",
    summary_statistics = "data/processed/final/table3_summary.rds",
    risk_free = "data/raw/common/risk_free_ff_monthly.rds")
  old_files <- files[file.exists(files)]
  # Backups are kept locally, including the previous human-readable outputs.
  backup <- NULL
  if (length(old_files)) {
    parent <- "data/processed/final/integration_backups"
    dir.create(parent, recursive = TRUE, showWarnings = FALSE)
    backup <- tempfile(paste0("table3_", format(Sys.time(), "%Y%m%d_%H%M%S"), "_"), tmpdir = parent)
    dir.create(backup)
    displays <- file.path("output/tables", c("table3_summary_detailed.csv",
      "table3_all_periods_display.csv", "table3_full_sample_display.csv",
      "table3_display.html", "table3_statistics_notes.md"))
    copies <- c(unname(old_files), displays[file.exists(displays)])
    if (!all(file.copy(copies, file.path(backup, basename(copies)), overwrite = FALSE))) {
      stop("Could not preserve all existing Table 3 outputs; no scripts have run.")
    }
    write.csv(data.frame(original_path = copies, backup_file = basename(copies)),
      file.path(backup, "manifest.csv"), row.names = FALSE)
    cat("Existing Table 3 outputs preserved in:", backup, "\n")
  }
  for (path in scripts) {
    cat("\nRunning", path, "\n")
    source(path, local = new.env(parent = globalenv()))
  }
  # Compare data columns explicitly; preparation timestamps/source attributes
  # may change on rerun and are not numerical replication results.
  comparison <- lapply(names(files), function(item) {
    path <- files[[item]]
    if (!file.exists(path)) stop("Missing Table 3 output after running scripts: ", path)
    if (!item %in% names(old_files)) {
      return(data.frame(item = item, status = "SKIP: no previous output", max_absolute_difference = NA_real_))
    }
    old <- readRDS(file.path(backup, basename(path)))
    new <- readRDS(path)
    same <- is.data.frame(old) && is.data.frame(new) && identical(names(old), names(new)) && nrow(old) == nrow(new)
    max_difference <- 0
    if (same) for (column in names(old)) {
      a <- old[[column]]; b <- new[[column]]
      if (is.numeric(a) && is.numeric(b)) {
        if (!identical(is.na(a), is.na(b)) || !identical(is.finite(a), is.finite(b))) {
          same <- FALSE; break
        }
        finite <- is.finite(a) & is.finite(b)
        delta <- if (any(finite)) max(abs(a[finite] - b[finite])) else 0
        max_difference <- max(max_difference, delta)
        if (delta > 1e-10 || !isTRUE(all.equal(a[!finite], b[!finite], check.attributes = FALSE))) {
          same <- FALSE; break
        }
      } else if (!isTRUE(all.equal(a, b, check.attributes = FALSE))) {
        same <- FALSE; break
      }
    }
    data.frame(item = item, status = if (same) "PASS: matches previous output" else "DIFFERENT: inspect backup",
      max_absolute_difference = if (same) max_difference else NA_real_)
  })
  comparison <- do.call(rbind, comparison)
  dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
  write.csv(comparison, "output/tables/table3_final_integration_check.csv", row.names = FALSE, na = "NA")
  print(comparison, row.names = FALSE)
  if (any(grepl("^DIFFERENT", comparison$status))) {
    stop("Table 3 differs from the preserved local results. Inspect ", backup,
      " and table3_final_integration_check.csv before accepting the new results.")
  }
  cat("\nFinal Table 3 workflow completed.\n")
  cat("SKIP means no previous file was available; it is not a verified match.\n")
})
