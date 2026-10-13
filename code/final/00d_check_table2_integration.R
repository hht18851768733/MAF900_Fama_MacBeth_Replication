# Optional migration check against previously generated alternative outputs.
# This is a validation tool, NOT a dependency of the final replication.
local({
  pairs <- data.frame(
    item = c("formation_betas", "portfolio_formation", "estimation_betas",
      "testing_panel", "estimation_panel", "testing_returns", "estimation_returns", "table2_statistics"),
    old = c(paste0("data/processed/common/decision2/", c("formation_betas.rds",
      "portfolio_formation.rds", "estimation_betas.rds", "testing_member_month_panel.rds",
      "estimation_member_month_panel.rds")),
      paste0("data/processed/decision2/alternative_A/", c("portfolio_returns_altA.rds",
        "estimation_portfolio_returns_altA.rds", "table2_altA.rds"))),
    new = paste0("data/processed/final/table2/", c("formation_betas.rds",
      "portfolio_formation.rds", "estimation_betas.rds", "testing_member_month_panel.rds",
      "estimation_member_month_panel.rds", "portfolio_returns_final.rds",
      "estimation_portfolio_returns_final.rds", "table2_final.rds")))
  report <- lapply(seq_len(nrow(pairs)), function(i) {
    p <- pairs[i, ]
    if (!file.exists(p$new)) stop("Missing final input: ", p$new)
    if (!file.exists(p$old)) return(data.frame(item = p$item, status = "SKIP: no previous output"))
    old <- readRDS(p$old); new <- readRDS(p$new)
    result <- all.equal(old, new, tolerance = 1e-10, check.attributes = FALSE)
    if (!isTRUE(result)) stop("Integration differs for ", p$item, ": ", paste(result, collapse = "; "))
    data.frame(item = p$item, status = "PASS: matches previous output")
  })
  report <- do.call(rbind, report)
  print(report, row.names = FALSE)
  cat("\nIntegration comparison completed. SKIP is not a verified match.\n")
})
