# =========================================================
# 02_sample_construction.R
# Decision 1, Alternative B
# Applies the formation/estimation/testing period structure
# from Table 1. Checks listed history (from exchange/share
# code date ranges) separately from valid-return coverage,
# then combines both into the eligibility rule.
# =========================================================

library(tidyverse)
library(lubridate)

# ---- Load the NYSE common-stock data from script 01 ----
nyse_common <- readRDS("data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")
nyse_listing_segments <- readRDS("data/raw/decision1/alternative_B/nyse_listing_segments.rds")


# ---- Encode Table 1's nine periods ----
periods <- tibble(
  period_id        = 1:9,
  formation_start  = ymd(c("1926-01-01","1927-01-01","1931-01-01","1935-01-01",
                           "1939-01-01","1943-01-01","1947-01-01","1951-01-01","1955-01-01")),
  formation_end    = ymd(c("1929-12-31","1933-12-31","1937-12-31","1941-12-31",
                           "1945-12-31","1949-12-31","1953-12-31","1957-12-31","1961-12-31")),
  estimation_start = ymd(c("1930-01-01","1934-01-01","1938-01-01","1942-01-01",
                           "1946-01-01","1950-01-01","1954-01-01","1958-01-01","1962-01-01")),
  estimation_end   = ymd(c("1934-12-31","1938-12-31","1942-12-31","1946-12-31",
                           "1950-12-31","1954-12-31","1958-12-31","1962-12-31","1966-12-31")),
  testing_start    = ymd(c("1935-01-01","1939-01-01","1943-01-01","1947-01-01",
                           "1951-01-01","1955-01-01","1959-01-01","1963-01-01","1967-01-01")),
  testing_end      = ymd(c("1938-12-31","1942-12-31","1946-12-31","1950-12-31",
                           "1954-12-31","1958-12-31","1962-12-31","1966-12-31","1968-06-30"))
)

periods

# ---- For each period, count each security's valid months in the
#      formation and estimation windows ----

security_coverage <- periods |>
  rowwise() |>
  mutate(
    coverage = list(
      nyse_common |>
        mutate(
          in_formation  = date >= formation_start  & date <= formation_end,
          in_estimation = date >= estimation_start & date <= estimation_end
        ) |>
        group_by(permno) |>
        summarise(
          formation_valid_months  = sum(in_formation  & !is.na(ret)),
          estimation_valid_months = sum(in_estimation & !is.na(ret)),
          .groups = "drop"
        )
    )
  ) |>
  select(period_id, coverage) |>
  unnest(coverage) |>
  ungroup()

# ---- Quick look ----
head(security_coverage)
dim(security_coverage)
summary(security_coverage$formation_valid_months)
summary(security_coverage$estimation_valid_months)

# ---- Listed-history coverage, checked separately from return
#      validity: was the security actually listed as NYSE common
#      stock for enough months, regardless of whether CRSP has a
#      valid return for each of those months ----

listed_months_table <- nyse_listing_segments |>
  mutate(
    seg_start = floor_date(namedt, "month"),
    seg_end   = floor_date(nameendt, "month")
  ) |>
  rowwise() |>
  mutate(months_listed = list(seq(seg_start, seg_end, by = "month"))) |>
  ungroup() |>
  select(permno, months_listed) |>
  unnest(months_listed) |>
  distinct(permno, months_listed)

listed_coverage <- periods |>
  rowwise() |>
  mutate(
    coverage = list(
      listed_months_table |>
        mutate(
          in_formation  = months_listed >= floor_date(formation_start, "month")  & months_listed <= floor_date(formation_end, "month"),
          in_estimation = months_listed >= floor_date(estimation_start, "month") & months_listed <= floor_date(estimation_end, "month")
        ) |>
        group_by(permno) |>
        summarise(
          formation_listed_months  = sum(in_formation),
          estimation_listed_months = sum(in_estimation),
          .groups = "drop"
        )
    )
  ) |>
  select(period_id, coverage) |>
  unnest(coverage) |>
  ungroup()
