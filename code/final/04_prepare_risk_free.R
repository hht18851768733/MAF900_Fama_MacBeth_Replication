# Table 3, step 4: prepare the monthly risk-free-rate input.
# Run from project root: source("code/final/04_prepare_risk_free.R")
# Table 3 includes mean(gamma0 - RF), its t-statistic and serial correlation.
# Proxy source: Kenneth French Data Library, F-F Research Data Factors, RF.
# For 1935-1968 this is the one-month Treasury bill series from Ibbotson
# Associates, as described by the provider. This modern downloadable vintage
# is not asserted to be identical to the original 1973 data vintage.
# Read ONLY RF; the other factor columns are not used in this replication.
# Provider monthly RF values are in percent: divide by 100 exactly once.
# Never divide by 12, compound an annual yield, or replace missing RF with zero.
# Keep the raw ZIP and its checksum for reproducibility; an existing ZIP is reused.
# Source: https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_factors.html

local({
  panel_file <- "data/processed/final/table3_panel_altA.rds"
  if (!file.exists(panel_file)) stop("Run final/02 before this script.")
  panel <- readRDS(panel_file)
  if (!"date" %in% names(panel)) stop("Missing date column in Table 3 panel.")
  required_dates <- seq(as.Date("1935-01-01"), as.Date("1968-06-01"), by = "month")
  observed_dates <- sort(unique(as.Date(panel$date)))
  if (!identical(observed_dates, required_dates)) stop("Unexpected Table 3 dates.")

  source_url <- paste0("https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/",
    "F-F_Research_Data_Factors_CSV.zip")
  raw_dir <- "data/raw/common"
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  zip_path <- file.path(raw_dir, "F-F_Research_Data_Factors_CSV.zip")
  if (!file.exists(zip_path)) {
    cat("Downloading the French monthly factor file to obtain RF...\n")
    download_zip <- function() {
      old_timeout <- getOption("timeout")
      options(timeout = max(120, old_timeout))
      on.exit(options(timeout = old_timeout), add = TRUE)
      tmp <- tempfile("ff_factors_", tmpdir = raw_dir, fileext = ".zip")
      on.exit(unlink(tmp), add = TRUE)
      status <- tryCatch(download.file(source_url, tmp, mode = "wb", quiet = FALSE),
        error = function(e) NA_integer_)
      if (is.na(status) || status != 0L || !file.exists(tmp) || file.info(tmp)$size == 0) {
        stop("Download failed. Download the ZIP manually from:\n", source_url,
          "\nSave it as: ", zip_path, "\nThen rerun this script.")
      }
      if (!file.rename(tmp, zip_path)) stop("Could not save downloaded ZIP: ", zip_path)
    }
    download_zip()
  } else {
    cat("Using the existing raw ZIP:", zip_path, "\n")
  }

  # Inspect the archive and select only the named monthly/annual factor CSV.
  entries <- tryCatch(unzip(zip_path, list = TRUE), error = function(e) NULL)
  if (is.null(entries) || !nrow(entries)) stop("Invalid ZIP. Check or replace: ", zip_path)
  csv_entry <- entries$Name[tolower(entries$Name) == "f-f_research_data_factors.csv"]
  if (length(csv_entry) != 1L) stop("Expected factor CSV not found uniquely in ZIP.")
  read_lines <- function() {
    folder <- tempfile("ff_extract_")
    dir.create(folder)
    on.exit(unlink(folder, recursive = TRUE), add = TRUE)
    unzip(zip_path, files = csv_entry, exdir = folder)
    readLines(file.path(folder, csv_entry), warn = FALSE)
  }
  lines <- read_lines()
  fields <- strsplit(lines, ",", fixed = TRUE)
  header_rows <- which(vapply(fields, function(x) {
    identical(trimws(x), c("", "Mkt-RF", "SMB", "HML", "RF"))
  }, logical(1)))
  if (!length(header_rows)) stop("Unrecognized factor CSV header; inspect the provider format.")
  # Six-digit YYYYMM identifies monthly observations; four-digit annual rows
  # are deliberately excluded. Do not parse annual figures as monthly rates.
  monthly_rows <- which(grepl("^[[:space:]]*[0-9]{6}[[:space:]]*,", lines))
  if (!length(monthly_rows) || min(monthly_rows) <= min(header_rows)) stop("Monthly RF block not found.")
  raw <- read.csv(text = paste(lines[monthly_rows], collapse = "\n"), header = FALSE,
    col.names = c("yyyymm", "mkt_rf_unused", "smb_unused", "hml_unused", "rf_percent"),
    stringsAsFactors = FALSE, strip.white = TRUE)
  if (anyNA(raw$yyyymm) || anyDuplicated(raw$yyyymm)) stop("Missing or duplicate monthly dates.")
  raw <- raw[raw$yyyymm >= 193501L & raw$yyyymm <= 196806L, ]
  if (!is.numeric(raw$rf_percent) || any(!is.finite(raw$rf_percent)) ||
      any(raw$rf_percent %in% c(-99.99, -999))) stop("Missing or invalid RF observations.")
  risk_free <- data.frame(date = as.Date(paste0(raw$yyyymm, "01"), format = "%Y%m%d"),
    rf = raw$rf_percent / 100)
  risk_free <- risk_free[order(risk_free$date), ]
  rownames(risk_free) <- NULL
  if (!identical(risk_free$date, required_dates) || nrow(risk_free) != 402L ||
      anyDuplicated(risk_free$date)) stop("RF must cover exactly 402 consecutive testing months.")
  if (any(abs(risk_free$rf) > .05)) stop("Unexpected monthly RF magnitude; inspect units and source.")
  source_info <- list(
    provider = "Kenneth French Data Library",
    series = "F-F Research Data Factors: RF (one-month Treasury bill)",
    historical_underlying_source = "Ibbotson Associates (provider documentation)",
    source_url = source_url,
    description_url = "https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/f-f_factors.html",
    source_zip = zip_path,
    source_zip_md5 = unname(tools::md5sum(zip_path)),
    prepared_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    raw_zip_mtime_utc = format(file.info(zip_path)$mtime, tz = "UTC", usetz = TRUE),
    source_units = "monthly percent", output_units = "monthly decimal",
    conversion = "rf = RF / 100",
    vintage_note = "Modern downloaded series; not verified against the original 1973 RF vintage."
  )
  attr(risk_free, "source_info") <- source_info
  output_file <- file.path(raw_dir, "risk_free_ff_monthly.rds")
  saveRDS(risk_free, output_file)
  cat("PASS: 402 unique monthly RF observations, January 1935 to June 1968.\n")
  cat("PASS: RF dates match the Table 3 panel; percent converted to decimal.\n")
  print(data.frame(n_months = nrow(risk_free), start = min(risk_free$date),
    end = max(risk_free$date), min_rf = min(risk_free$rf),
    max_rf = max(risk_free$rf), mean_rf = mean(risk_free$rf)), row.names = FALSE)
  cat("\nFirst six observations (monthly decimal rates):\n")
  print(head(risk_free), row.names = FALSE)
  cat("\nRisk-free input completed.\nSaved to:", output_file, "\n")
  cat("Raw source ZIP MD5:", source_info$source_zip_md5, "\n")
})
