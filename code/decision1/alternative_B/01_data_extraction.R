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

# ---- Save return-level data ----
saveRDS(nyse_common, "data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")

# ---- Preserve NYSE common-stock listing segments ----
# Separate from nyse_common's return rows — this captures WHEN a stock
# was listed as NYSE common stock, independent of whether CRSP has a
# valid return for any given month.
nyse_listing_segments <- crsp_names |>
  filter(exchcd == 1, shrcd %in% c(10, 11)) |>
  select(permno, namedt, nameendt)

saveRDS(nyse_listing_segments, "data/raw/decision1/alternative_B/nyse_listing_segments.rds")


# ---- Apply Alternative B eligibility rule ----
# Listed history: must be listed for the full formation window (>= 48
#            months) and the full estimation window (= 60 months).
# Formation: period 1 requires >= 44 valid months (allowing some
#            tolerance, since its window is exactly 48 months long);
#            periods 2-9 require the full >= 48 months, matching the
#            paper's literal "at least 4 years" minimum.
# Estimation: all periods require >= 54 of 60 months (90% tolerance
#            applied to the paper's "all 5 years" requirement).

eligible_securities <- security_coverage |>
  left_join(listed_coverage, by = c("period_id", "permno")) |>
  mutate(
    formation_threshold = if_else(period_id == 1, 44, 48),
    listed_ok = formation_listed_months >= 48 & estimation_listed_months >= 60,
    eligible = listed_ok &
      formation_valid_months  >= formation_threshold &
      estimation_valid_months >= 54
  )

# ---- Quick look ----
head(eligible_securities)


# ---- Shared first-testing-month list: a security must be listed in
#      the first month of the testing period to be eligible. A
#      missing RETURN alone should not remove it — only not being
#      listed does — so this uses listed_months_table, and script 03
#      reuses this same list for its "securities available" count. ----

first_month_long <- periods |>
  rowwise() |>
  mutate(
    permnos = list(
      listed_months_table |>
        filter(months_listed == floor_date(testing_start, "month")) |>
        pull(permno) |>
        unique()
    )
  ) |>
  select(period_id, permnos) |>
  unnest(permnos) |>
  rename(permno = permnos) |>
  mutate(in_first_month = TRUE) |>
  ungroup()


eligible_securities <- eligible_securities |>
  left_join(first_month_long, by = c("period_id", "permno")) |>
  mutate(
    in_first_month = replace_na(in_first_month, FALSE),
    eligible = eligible & in_first_month
  )

# ---- How many eligible securities per period? ----
eligible_securities |>
  group_by(period_id) |>
  summarise(
    n_eligible = sum(eligible),
    n_total    = n(),
    .groups = "drop"
  )

saveRDS(eligible_securities, "data/processed/decision1/alternative_B/eligible_securities.rds")
saveRDS(periods, "data/processed/decision1/alternative_B/periods.rds")
saveRDS(first_month_long, "data/processed/decision1/alternative_B/first_month_long.rds")
