# Download the NYSE-only equal-weighted monthly market index.
# Source: CRSP quarterly Index Version 2.
# Index: 1000001 — CRSP NYSE Equal-Weighted Market Index.
# Return: mthtotret, including distributions.
# Period: January 1926 to June 1968.
# The previous broad-market index file is preserved.

library(DBI)
library(RPostgres)

download_market_index <- function() {
  
  # ---- WRDS login ----
  
  wrds_user <- trimws(
    readline("Enter your WRDS username: ")
  )
  
  if (!nzchar(wrds_user)) {
    stop("WRDS username was not supplied.")
  }
  
  wrds_password <- rstudioapi::askForPassword(
    "Enter your WRDS password"
  )
  
  if (is.null(wrds_password) || !nzchar(wrds_password)) {
    stop("WRDS password was not supplied.")
  }
  
  wrds <- dbConnect(
    RPostgres::Postgres(),
    host = "wrds-pgdata.wharton.upenn.edu",
    port = 9737,
    dbname = "wrds",
    sslmode = "require",
    user = wrds_user,
    password = wrds_password
  )
  
  on.exit(dbDisconnect(wrds), add = TRUE)
  rm(wrds_password)
  
  # ---- Download index metadata ----
  
  index_metadata <- dbGetQuery(
    wrds,
    "
    SELECT *
    FROM crsp_q_indexes.indseriesinfohdr_ind
    WHERE indno = 1000001
    "
  )
  
  if (nrow(index_metadata) != 1L) {
    stop("Expected one metadata record for index 1000001.")
  }
  
  # ---- Download monthly total returns ----
  
  market_index <- dbGetQuery(
    wrds,
    "
    SELECT indno, yyyymm,
           mthcaldt AS date,
           mthtotret AS mkt_ret
    FROM crsp_q_indexes.indmthseriesdata_ind
    WHERE indno = 1000001
      AND yyyymm BETWEEN 192601 AND 196806
    ORDER BY yyyymm
    "
  )
  
  if (nrow(market_index) == 0L) {
    stop("No market data returned.")
  }
  
  market_index$date <- as.Date(market_index$date)
  
  # ---- Check index identity and monthly coverage ----
  
  if (anyNA(market_index$indno) ||
      any(market_index$indno != 1000001)) {
    stop("Unexpected or missing index identifier.")
  }
  
  if (anyNA(market_index$date) ||
      anyNA(market_index$yyyymm)) {
    stop("Missing dates or month identifiers.")
  }
  
  month_id <- format(market_index$date, "%Y-%m")
  
  if (anyDuplicated(month_id) > 0L) {
    stop("Duplicate market months found.")
  }
  
  if (any(
    format(market_index$date, "%Y%m") !=
    as.character(market_index$yyyymm)
  )) {
    stop("Calendar dates do not match YYYYMM identifiers.")
  }
  
  expected_months <- format(
    seq(
      as.Date("1926-01-01"),
      as.Date("1968-06-01"),
      by = "month"
    ),
    "%Y-%m"
  )
  
  if (nrow(market_index) != length(expected_months) ||
      !setequal(month_id, expected_months)) {
    stop("Expected 510 consecutive months: January 1926–June 1968.")
  }
  
  if (any(!is.finite(market_index$mkt_ret))) {
    stop("Missing or invalid market returns found.")
  }
  
  # ---- Save the new index separately ----
  
  output_dir <- "data/raw/common"
  
  dir.create(
    output_dir,
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  output_file <- file.path(
    output_dir,
    "market_index_nyse_ew.rds"
  )
  
  saveRDS(market_index, output_file)
  
  saveRDS(
    index_metadata,
    file.path(output_dir, "market_index_nyse_ew_metadata.rds")
  )
  
  # ---- Download record for reproducibility ----
  
  download_info <- data.frame(
    source_table = "crsp_q_indexes.indmthseriesdata_ind",
    index_id = 1000001,
    index_name = trimws(as.character(index_metadata$indnm)),
    return_variable = "mthtotret",
    requested_start = "1926-01",
    requested_end = "1968-06",
    observations = nrow(market_index),
    downloaded_at_utc = format(
      Sys.time(),
      "%Y-%m-%d %H:%M:%S",
      tz = "UTC"
    )
  )
  
  write.csv(
    download_info,
    file.path(output_dir, "market_index_nyse_ew_download_info.csv"),
    row.names = FALSE
  )
  
  # ---- Show results ----
  
  cat("\nNYSE-only market data downloaded successfully.\n")
  cat("Index:", download_info$index_name, "\n")
  cat("Monthly observations:", nrow(market_index), "\n")
  cat("Invalid returns:", sum(!is.finite(market_index$mkt_ret)), "\n")
  
  print(range(market_index$date))
  
  cat("Saved to:", output_file, "\n")
}

download_market_index()