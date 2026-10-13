# Published CRSP NYSE equal-weighted index; reuse the validated common cache.
# Fresh projects can download independently using local WRDS credentials.
local({
  path <- "data/raw/common/market_index_nyse_ew.rds"
  fetched <- FALSE
  if (file.exists(path)) {
    index <- readRDS(path)
  } else {
    for (pkg in c("DBI", "RPostgres")) {
      if (!requireNamespace(pkg, quietly = TRUE)) stop("Install ", pkg, " first.")
    }
    user <- Sys.getenv("WRDS_USER")
    if (!nzchar(user)) stop("Set WRDS_USER locally before downloading the NYSE index.")
    args <- list(drv = RPostgres::Postgres(), host = "wrds-pgdata.wharton.upenn.edu",
      port = 9737L, dbname = "wrds", sslmode = "require", user = user)
    password <- Sys.getenv("WRDS_PASSWORD")
    if (nzchar(password)) args$password <- password
    fetch <- function() {
      con <- do.call(DBI::dbConnect, args)
      on.exit(DBI::dbDisconnect(con), add = TRUE)
      list(index = DBI::dbGetQuery(con, paste(
        "SELECT indno, yyyymm, mthcaldt AS date, mthtotret AS mkt_ret",
        "FROM crsp_q_indexes.indmthseriesdata_ind",
        "WHERE indno = 1000001 AND yyyymm BETWEEN 192601 AND 196806 ORDER BY yyyymm")),
        metadata = DBI::dbGetQuery(con,
          "SELECT * FROM crsp_q_indexes.indseriesinfohdr_ind WHERE indno = 1000001"))
    }
    downloaded <- fetch(); index <- downloaded$index
    index$date <- as.Date(index$date)
    if (nrow(downloaded$metadata) != 1L) stop("Expected one NYSE index metadata record.")
    fetched <- TRUE
  }
  if (!all(c("indno", "date", "yyyymm", "mkt_ret") %in% names(index))) stop("Missing market index fields.")
  months <- format(as.Date(index$date), "%Y-%m")
  expected <- format(seq(as.Date("1926-01-01"), as.Date("1968-06-01"), by = "month"), "%Y-%m")
  if (anyNA(index[c("indno", "date", "yyyymm")]) || any(index$indno != 1000001) ||
      anyDuplicated(months) || nrow(index) != 510L || !setequal(months, expected) ||
      any(format(as.Date(index$date), "%Y%m") != as.character(index$yyyymm)) ||
      any(!is.finite(index$mkt_ret))) stop("Invalid NYSE index identity, months or returns.")
  if (fetched) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    saveRDS(index, path)
    saveRDS(downloaded$metadata, "data/raw/common/market_index_nyse_ew_metadata.rds")
    write.csv(data.frame(source_table = "crsp_q_indexes.indmthseriesdata_ind",
      index_id = 1000001L, return_variable = "mthtotret", observations = nrow(index),
      requested_start = "1926-01", requested_end = "1968-06",
      downloaded_at_utc = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
      "data/raw/common/market_index_nyse_ew_download_info.csv", row.names = FALSE)
  }
  cat("PASS: published NYSE index 1000001, 510 unique months and finite returns.\n")
})
