# =========================================================
# 01_data_extraction.R
# Decision 1 - Alternative A
# Author: Haitian Hu
#
# Download CRSP monthly returns and listing history.
# Keep the same data definition as Alternative B.
# =========================================================

# ---- 1. Install missing packages ----

required_packages <- c(
  "DBI",
  "RPostgres",
  "dplyr",
  "dbplyr",
  "lubridate",
  "rstudioapi"
)

missing_packages <- setdiff(
  required_packages,
  rownames(installed.packages())
)

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

# ---- 2. Load packages ----

library(DBI)
library(RPostgres)
library(dplyr)
library(dbplyr)
library(lubridate)

# ---- 3. Create Alternative A folders ----

raw_dir <- "data/raw/decision1/alternative_A"

dir.create(
  raw_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "data/processed/decision1/alternative_A",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

# ---- 4. Connect to WRDS ----

# Replace the text below with your own WRDS username.
wrds_username <- "hht18851768733"

if (wrds_username == "YOUR_WRDS_USERNAME") {
  stop("Please enter your WRDS username in wrds_username.")
}

# Enter the password in the popup, not in this script.
wrds <- dbConnect(
  RPostgres::Postgres(),
  host = "wrds-pgdata.wharton.upenn.edu",
  port = 9737,
  dbname = "wrds",
  sslmode = "require",
  user = wrds_username,
  password = rstudioapi::askForPassword("Enter your WRDS password")
)

# Close the connection after downloading, including on error.
tryCatch({
  
  # ---- 5. Define the extraction window ----
  
  start_date <- ymd("1926-01-01")
  end_date   <- ymd("1968-12-31")
  
  # ---- 6. Download monthly stock returns ----
  
  crsp_msf <- tbl(wrds, in_schema("crsp", "msf")) |>
    filter(
      date >= start_date,
      date <= end_date
    ) |>
    select(
      permno,
      date,
      ret
    ) |>
    collect()
  
  # ---- 7. Download exchange/share-code history ----
  
  crsp_names <- tbl(wrds, in_schema("crsp", "msenames")) |>
    select(
      permno,
      namedt,
      nameendt,
      exchcd,
      shrcd
    ) |>
    collect() |>
    mutate(
      namedt = as_date(namedt),
      nameendt = as_date(nameendt)
    )
  
  # ---- 8. Match each return to its dated classification ----
  
  crsp_joined <- crsp_msf |>
    inner_join(
      crsp_names,
      by = join_by(
        permno,
        between(date, namedt, nameendt)
      )
    )
  
  # ---- 9. Keep NYSE common stocks ----
  
  # Do not remove missing returns here.
  # Missing-return eligibility is assessed in script 02.
  
  nyse_common <- crsp_joined |>
    filter(
      exchcd == 1,
      shrcd %in% c(10, 11)
    ) |>
    select(
      permno,
      date,
      ret,
      exchcd,
      shrcd
    )
  
  # ---- 10. Preserve listing history separately ----
  
  nyse_listing_segments <- crsp_names |>
    filter(
      exchcd == 1,
      shrcd %in% c(10, 11)
    ) |>
    select(
      permno,
      namedt,
      nameendt
    )
  
  # ---- 11. Save Alternative A input files ----
  
  saveRDS(
    nyse_common,
    file.path(raw_dir, "nyse_common_1926_1968.rds")
  )
  
  saveRDS(
    nyse_listing_segments,
    file.path(raw_dir, "nyse_listing_segments.rds")
  )
  
  # ---- 12. Display a short summary ----
  
  cat("\nDownload completed.\n")
  cat("NYSE common-stock return rows:", nrow(nyse_common), "\n")
  cat("Distinct securities:", n_distinct(nyse_common$permno), "\n")
  cat("Missing return rows:", sum(is.na(nyse_common$ret)), "\n")
  cat("Return date range:\n")
  print(range(nyse_common$date))
  cat("Files saved to:", raw_dir, "\n")
  
}, finally = {
  
  dbDisconnect(wrds)
  
})