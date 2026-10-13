# Table 3, step 6: export display tables from the step-5 numerical results.
# Run from project root: source("code/final/06_export_table3.R")
# No regressions or summary estimates are recomputed in this script.
# Full-precision values remain in table3_summary.rds and table3_summary_detailed.csv.
# Display: means 4 decimals; coefficient SDs 3; t, rho and adjusted R2 statistics 2.
# Omitted coefficients are displayed as --, not zero. No significance stars.

local({
  input <- "data/processed/final/table3_summary.rds"
  if (!file.exists(input)) stop("Run final/05 first: ", input)
  results <- readRDS(input)
  notes <- attr(results, "method_notes")
  if (is.null(notes) || !length(notes)) stop("Method notes unavailable. Rerun final/05.")
  keys <- c("model", "sample_id", "sample_period", "n_months")
  # Statistics are kept in the order of the original Table 3.
  fields <- c(
    "mean_gamma0", "mean_gamma1", "mean_gamma2", "mean_gamma3", "mean_gamma0_minus_rf",
    "sd_gamma0", "sd_gamma1", "sd_gamma2", "sd_gamma3",
    "rho0_gamma0_minus_rf", "rhoM_gamma1", "rho0_gamma2", "rho0_gamma3",
    "t_gamma0", "t_gamma1", "t_gamma2", "t_gamma3", "t_gamma0_minus_rf",
    "mean_adjusted_r_squared", "sd_adjusted_r_squared")
  labels <- c(
    "Mean gamma0", "Mean gamma1", "Mean gamma2", "Mean gamma3", "Mean (gamma0 - RF)",
    "SD gamma0", "SD gamma1", "SD gamma2", "SD gamma3",
    "rho0 (gamma0 - RF)", "rhoM gamma1", "rho0 gamma2", "rho0 gamma3",
    "t gamma0", "t gamma1", "t gamma2", "t gamma3", "t (gamma0 - RF)",
    "Mean adjusted R-squared", "SD adjusted R-squared")
  digits <- c(rep(4L,5), rep(3L,4), rep(2L,11))
  if (!all(c(keys,fields) %in% names(results))) stop("Required summary columns are missing.")
  if (nrow(results) != 40L || anyNA(results[keys]) ||
      anyDuplicated(results[c("model","sample_id")]) ||
      !setequal(results$model,c("A","B","C","D"))) stop("Invalid summary coverage.")
  results <- as.data.frame(results[order(results$model,results$sample_id), ], stringsAsFactors=FALSE)
  expected_n <- c(402L,132L,120L,150L,72L,60L,60L,60L,60L,90L)
  for (model_name in c("A","B","C","D")) {
    x <- results[results$model == model_name, ]
    if (!identical(as.integer(x$sample_id),1:10) || !identical(as.integer(x$n_months),expected_n)) {
      stop("Unexpected reporting samples for panel ",model_name)
    }
    omitted_terms <- switch(model_name,A=c("gamma2","gamma3"),B="gamma3",C="gamma2",D=character())
    omitted_fields <- unlist(lapply(omitted_terms,function(z) paste0(c("mean_","sd_","rho0_","t_"),z)))
    for (f in fields) {
      if (f %in% omitted_fields) {
        if (!all(is.na(x[[f]]))) stop("Omitted statistic should be NA: ",f)
      } else if (!is.numeric(x[[f]]) || any(!is.finite(x[[f]]))) stop("Invalid summary statistic: ",f)
    }
  }
  display_number <- function(x,d) {
    y <- rep("--",length(x))
    good <- is.finite(x)
    values <- sprintf(paste0("%.",d,"f"),x[good])
    # Avoid a displayed negative zero while preserving underlying estimates.
    values[as.numeric(values) == 0] <- sprintf(paste0("%.",d,"f"),0)
    y[good] <- values
    y
  }
  display <- data.frame(Model=results$model, Period=results$sample_period,
    Months=as.character(results$n_months), stringsAsFactors=FALSE, check.names=FALSE)
  for (i in seq_along(fields)) display[[labels[i]]] <- display_number(results[[fields[i]]],digits[i])
  full_sample <- display[results$sample_id == 1L, , drop=FALSE]
  rownames(display) <- NULL; rownames(full_sample) <- NULL
  cat("PASS: all 40 model/sample rows and omitted-statistic positions verified.\n")

  escape_html <- function(x) {
    x <- gsub("&","&amp;",x,fixed=TRUE)
    x <- gsub("<","&lt;",x,fixed=TRUE)
    x <- gsub(">","&gt;",x,fixed=TRUE)
    gsub('"',"&quot;",x,fixed=TRUE)
  }
  make_table <- function(x,caption) {
    rows <- vapply(seq_len(nrow(x)),function(i) {
      cells <- paste0("<td>",escape_html(as.character(unlist(x[i, ],use.names=FALSE))),"</td>")
      paste0('<tr',if (x$Period[i] == "1935-06/1968") ' class="overall"' else '',
        '>',paste(cells,collapse=""),"</tr>")
    },character(1))
    paste0('<div class="table-wrap"><table><caption>',escape_html(caption),
      '</caption><thead><tr>',paste0('<th scope="col">',escape_html(names(x)),
        '</th>',collapse=""),'</tr></thead><tbody>',paste(rows,collapse="\n"),
      '</tbody></table></div>')
  }
  html <- c('<!doctype html><html lang="en"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    '<title>Table 3 - Fama and MacBeth replication</title>',
    '<style>body{font-family:Arial,sans-serif;color:#20252b;background:#fff;margin:32px auto;padding:0 24px;max-width:1450px;line-height:1.5}h1{font-size:26px}h2{font-size:21px;margin-top:40px;border-top:2px solid #333;padding-top:16px}p{max-width:1100px}nav a{margin-right:24px;color:#234b6d}.table-wrap{overflow-x:auto;margin:20px 0 28px}table{border-collapse:collapse;width:100%;font-size:13px;font-variant-numeric:tabular-nums}caption{text-align:left;font-weight:bold;margin-bottom:8px}th,td{padding:9px 10px;border-bottom:1px solid #d5dae0;text-align:right;white-space:nowrap}th{background:#eef1f4;font-weight:600}th:first-child,td:first-child{text-align:left}.overall{font-weight:700;background:#f5f7f9}details{margin-top:32px}summary{cursor:pointer;font-weight:bold}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:13px/1.6 Arial,sans-serif}footer{margin-top:30px;color:#555;font-size:13px}@media print{body{margin:0;padding:0;max-width:none}nav{display:none}.table-wrap{overflow:visible}table{font-size:9px}th,td{padding:5px 3px;white-space:normal}thead{display:table-header-group}tr{break-inside:avoid}h2,caption{break-after:avoid}details{display:block}@page{size:A4 landscape;margin:12mm}}</style></head><body>',
    '<h1>Table 3. Monthly risk-return regressions</h1>',
    '<p>Fama and MacBeth (1973) replication, January 1935-June 1968. Each monthly regression uses 20 equally weighted portfolios. Selected methods: Decision 1 B and Decision 2 A. Panels A-D below are regression specifications, all using the selected A portfolio returns.</p>',
    '<p>Coefficient means and standard deviations are in monthly decimal units. t-statistics use the time-series standard error of the mean. The R-squared statistics are adjusted for degrees of freedom. A dash (--) means the coefficient is omitted from that model.</p>',
    '<nav><a href="#panel-A">Panel A</a><a href="#panel-B">Panel B</a><a href="#panel-C">Panel C</a><a href="#panel-D">Panel D</a><a href="#notes">Methods</a></nav>')
  specifications <- c(A="Return = gamma0 + gamma1 beta + error",
    B="Return = gamma0 + gamma1 beta + gamma2 beta2 + error",
    C="Return = gamma0 + gamma1 beta + gamma3 mean residual SD + error",
    D="Return = gamma0 + gamma1 beta + gamma2 beta2 + gamma3 mean residual SD + error")
  for (m in c("A","B","C","D")) {
    x <- display[display$Model == m, , drop=FALSE]
    html <- c(html,paste0('<section id="panel-',m,'"><h2>Panel ',m,'</h2><p>',
      escape_html(specifications[m]),'</p>'),
      make_table(x[c("Period","Months",labels[1:9])],"Coefficient means and monthly standard deviations"),
      make_table(x[c("Period",labels[14:18])],"t-statistics for time-series means"),
      make_table(x[c("Period",labels[10:13],labels[19:20])],"Lag-one serial correlations and adjusted R-squared"),
      '</section>')
  }
  html <- c(html,
    '<p>beta2 is the mean of squared individual betas. Mean residual SD is averaged across individual securities. The ten reporting samples overlap; their month counts must not be added together.</p>',
    '<p>rhoM is centered at the sample mean; rho0 is centered at zero. Serial correlations use the full-series denominator documented in the methods below.</p>',
    '<details id="notes"><summary>Method definitions and data provenance</summary><pre>',
    escape_html(paste(notes,collapse="\n")),'</pre></details>',
    '<footer>Reference: Fama, E. F., and MacBeth, J. D. (1973). Risk, Return, and Equilibrium: Empirical Tests. Journal of Political Economy, 81(3), 607-636. Table 3, pp. 622-623.</footer>',
    '</body></html>')
  output_dir <- "output/tables"
  dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
  all_file <- file.path(output_dir,"table3_all_periods_display.csv")
  full_file <- file.path(output_dir,"table3_full_sample_display.csv")
  html_file <- file.path(output_dir,"table3_display.html")
  write.csv(display,all_file,row.names=FALSE,fileEncoding="UTF-8",na="--")
  write.csv(full_sample,full_file,row.names=FALSE,fileEncoding="UTF-8",na="--")
  writeLines(enc2utf8(html),html_file,useBytes=TRUE)
  # Check the exported strings, including every sign, rounded value and dash.
  saved <- read.csv(all_file,colClasses="character",check.names=FALSE,stringsAsFactors=FALSE)
  if (!identical(saved,display)) stop("CSV round-trip verification failed.")
  saved_full <- read.csv(full_file,colClasses="character",check.names=FALSE,stringsAsFactors=FALSE)
  if (!identical(saved_full,full_sample)) stop("Full-sample CSV verification failed.")
  cat("PASS: 40-row display and 4-row full-sample CSVs match all formatted values.\n")
  cat("PASS: HTML includes panels A-D and all 20 original Table 3 statistic columns.\n")
  print(full_sample[c("Model","Months","Mean gamma0","Mean gamma1","Mean gamma2","Mean gamma3",
    "t gamma1","t gamma2","t gamma3","Mean adjusted R-squared")],row.names=FALSE)
  cat("\nTable 3 display exports completed.\nSaved:\n",all_file,"\n",full_file,"\n",html_file,"\n",sep="")
})
