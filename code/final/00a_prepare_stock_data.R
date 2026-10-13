# Final workflow: common CRSP stock inputs for the selected DP1-B rule.
# Run from the repository root. Reuses complete local raw caches; otherwise
# downloads the same CRSP fields as the selected extraction implementation.
# No alternative-development script is sourced.

local({
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Install dplyr first.")
  raw_dir <- "data/raw/common"
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  filenames <- c("nyse_common_1926_1968.rds", "nyse_listing_segments.rds")
  paths <- file.path(raw_dir, filenames)
  legacy_paths <- file.path("data/raw/decision1/alternative_B", filenames)

  validate_inputs <- function(stocks, segments) {
    if (!all(c("permno", "date", "ret", "exchcd", "shrcd") %in% names(stocks)) ||
        !all(c("permno", "namedt", "nameendt") %in% names(segments))) {
      stop("Raw input columns do not match the selected extraction.")
    }
    if (!nrow(stocks) || !nrow(segments) || !is.numeric(stocks$ret)) stop("Invalid raw input.")
    if (anyNA(stocks[c("permno", "date", "exchcd", "shrcd")]) ||
        anyNA(segments[c("permno", "namedt", "nameendt")])) stop("Missing identifiers or dates.")
    months <- format(as.Date(stocks$date), "%Y-%m")
    if (anyDuplicated(data.frame(permno = stocks$permno, month = months))) {
      stop("Duplicate security-months in raw stock data.")
    }
    if (any(stocks$exchcd != 1) || any(!stocks$shrcd %in% c(10, 11))) {
      stop("Raw stock data are not exclusively NYSE common stocks.")
    }
    if (any(!is.na(stocks$ret) & (!is.finite(stocks$ret) | stocks$ret < -1))) {
      stop("Invalid numerical returns or unconverted missing-value codes.")
    }
    if (any(as.Date(segments$namedt) > as.Date(segments$nameendt))) stop("Invalid listing segments.")
  }

  if (all(file.exists(paths))) {
    stocks <- readRDS(paths[1]); segments <- readRDS(paths[2])
    origin <- "Existing common raw cache"
  } else if (!any(file.exists(paths)) && all(file.exists(legacy_paths))) {
    # Optional migration of existing RAW inputs, not a dependency on the
    # alternative implementation. A fresh project uses the WRDS branch below.
    stocks <- readRDS(legacy_paths[1]); segments <- readRDS(legacy_paths[2])
    origin <- "Existing DP1-B raw cache copied to common inputs"
  } else if (any(file.exists(paths))) {
    stop("Incomplete common raw cache: provide both stock and listing files before continuing.")
  } else {
    for (pkg in c("DBI", "RPostgres")) {
      if (!requireNamespace(pkg, quietly = TRUE)) stop("Install ", pkg, " first.")
    }
    username <- Sys.getenv("WRDS_USER")
    if (!nzchar(username)) stop("Set WRDS_USER in your local environment before downloading.")
    args <- list(drv = RPostgres::Postgres(), host = "wrds-pgdata.wharton.upenn.edu",
      port = 9737L, dbname = "wrds", sslmode = "require", user = username)
    password <- Sys.getenv("WRDS_PASSWORD")
    if (nzchar(password)) args$password <- password
    download <- function() {
      con <- do.call(DBI::dbConnect, args)
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      msf <- DBI::dbGetQuery(con, paste(
        "SELECT permno, date, ret FROM crsp.msf",
        "WHERE date BETWEEN '1926-01-01' AND '1968-12-31'"))
      names_history <- DBI::dbGetQuery(con,
        "SELECT permno, namedt, nameendt, exchcd, shrcd FROM crsp.msenames")
      msf$date <- as.Date(msf$date)
      names_history$namedt <- as.Date(names_history$namedt)
      names_history$nameendt <- as.Date(names_history$nameendt)
      joined <- dplyr::inner_join(msf, names_history,
        by = dplyr::join_by(permno, between(date, namedt, nameendt)))
      list(stocks = joined |>
        dplyr::filter(exchcd == 1, shrcd %in% c(10, 11)) |>
        dplyr::select(permno, date, ret, exchcd, shrcd),
        segments = names_history |>
          dplyr::filter(exchcd == 1, shrcd %in% c(10, 11)) |>
          dplyr::select(permno, namedt, nameendt))
    }
    cat("Downloading CRSP stock inputs from WRDS...\n")
    downloaded <- download()
    stocks <- downloaded$stocks; segments <- downloaded$segments
    origin <- "WRDS crsp.msf and crsp.msenames download"
  }

  validate_inputs(stocks, segments)
  if (!all(file.exists(paths))) {
    saveRDS(stocks, paths[1]); saveRDS(segments, paths[2])
  }
  cat("PASS: raw fields, NYSE common-stock filters, unique months and valid return codes.\n")
  cat("Source:", origin, "\n")
  cat("Stock-month rows:", nrow(stocks), "; securities:", length(unique(stocks$permno)), "\n")
  cat("Raw inputs ready in:", raw_dir, "\n")
})
