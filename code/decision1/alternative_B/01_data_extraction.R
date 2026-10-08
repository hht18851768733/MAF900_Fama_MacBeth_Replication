# =========================================================
# 01_data_extraction.R
# Decision 1, Alternative B
# Pulls CRSP monthly returns, filters to NYSE common stocks
# for the Fama-MacBeth (1973) replication, 1926-1968 sample
# =========================================================

library(DBI)
library(RPostgres)
library(tidyverse)
library(lubridate)
library(dbplyr)

# ---- Connect to WRDS ----
wrds <- dbConnect(Postgres(),
                  host = 'wrds-pgdata.wharton.upenn.edu',
                  port = 9737,
                  dbname = 'wrds',
                  sslmode = 'require',
                  user = 'YOUR_WRDS_USERNAME')  # replace with your actual username

# ---- Define sample window ----
start_date <- ymd("1926-01-01")
end_date   <- ymd("1968-12-31")

# ---- Pull monthly returns ----
crsp_msf <- tbl(wrds, in_schema("crsp", "msf")) |>
  filter(date >= start_date, date <= end_date) |>
  select(permno, date, ret) |>
  collect()

# ---- Pull exchange code / share code history ----
crsp_names <- tbl(wrds, in_schema("crsp", "msenames")) |>
  select(permno, namedt, nameendt, exchcd, shrcd) |>
  collect() |>
  mutate(namedt = as_date(namedt), nameendt = as_date(nameendt))


# ---- Join returns to exchange/share code, matched by date range ----


crsp_joined <- crsp_msf |>
  inner_join(
    crsp_names,
    by = join_by(permno, between(date, namedt, nameendt))
  )

# ---- Filter to NYSE (exchcd == 1), common stock (shrcd 10 or 11) ----
nyse_common <- crsp_joined |>
  filter(exchcd == 1, shrcd %in% c(10, 11)) |>
  select(permno, date, ret, exchcd, shrcd)

# ---- Sanity checks ----
dim(crsp_msf)       # before filtering
dim(nyse_common)     # after filtering - should be noticeably smaller
range(nyse_common$date)
length(unique(nyse_common$permno))  # how many distinct NYSE common stocks

# ---- Save ----
saveRDS(nyse_common, "data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")
