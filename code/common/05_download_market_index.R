# Download the market return series shared by both DP2 alternatives.
# Source: CRSP monthly index file (msi), equal-weighted return (ewretd).

library(DBI)
library(RPostgres)

download_market_index <- function() {
  
  wrds_user <- trimws(readline("Enter your WRDS username: "))
  wrds_password <- rstudioapi::askForPassword("Enter your WRDS password")
  
  if (!nzchar(wrds_user) ||
      is.null(wrds_password) ||
      !nzchar(wrds_password)) {
    stop("WRDS username or password was not supplied.")
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
  
  market_index <- dbGetQuery(
    wrds,
    "
    SELECT date, ewretd AS mkt_ret
    FROM crsp.msi
    WHERE date >= '1926-01-01'
      AND date <= '1968-12-31'
    ORDER BY date
    "
  )
  
  market_index$date <- as.Date(market_index$date)
  
  if (nrow(market_index) == 0L) {
    stop("No market data returned.")
  }
  
  month_id <- format(market_index$date, "%Y-%m")
  
  if (anyDuplicated(month_id) > 0L) {
    stop("Duplicate market months found.")
  }
  
  expected_months <- format(
    seq(as.Date("1926-01-01"),
        as.Date("1968-12-01"),
        by = "month"),
    "%Y-%m"
  )
  
  if (!setequal(month_id, expected_months) ||
      any(!is.finite(market_index$mkt_ret))) {
    stop("Market data contain missing months or invalid returns.")
  }
  
  dir.create(
    "data/raw/common",
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  saveRDS(
    market_index,
    "data/raw/common/market_index.rds"
  )
  
  cat("Market data downloaded successfully.\n")
  cat("Monthly observations:", nrow(market_index), "\n")
  print(range(market_index$date))
  cat("Saved to: data/raw/common/market_index.rds\n")
}

download_market_index()