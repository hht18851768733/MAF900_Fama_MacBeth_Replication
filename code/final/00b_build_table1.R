# Final workflow: selected DP1-B sample and final Table 1.
# Adapted from Bharat Goel's selected DP1-B scripts 02 and 03.
# Source snapshot: 9478f1a9bec6c22c720ebc86ee78a8bad99f236e.
# Eligibility logic is preserved; paths, explicit diagnostics and the final
# testing-period label are updated for the independent final workflow.
# Run after 00a_prepare_stock_data.R from the project root.

local({
  dir.create("data/processed/final/table1", recursive = TRUE, showWarnings = FALSE)
  dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
  inputs <- file.path("data/raw/common", c("nyse_common_1926_1968.rds", "nyse_listing_segments.rds"))
  if (!all(file.exists(inputs))) stop("Run code/final/00a_prepare_stock_data.R first.")
# =========================================================
# 02_sample_construction.R
# Decision 1, Alternative B
# Applies the formation/estimation/testing period structure
# from Table 1. Checks listed history (from exchange/share
# code date ranges) separately from valid-return coverage,
# then combines both into the eligibility rule.
# =========================================================

library(dplyr)
library(tidyr)
library(lubridate)

# ---- Load the NYSE common-stock data from script 01 ----
nyse_common <- readRDS("data/raw/common/nyse_common_1926_1968.rds")
nyse_listing_segments <- readRDS("data/raw/common/nyse_listing_segments.rds")


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

# ---- Apply Alternative B eligibility rule ----
# Listed history: at least 48 formation months within the full window,
#            and all 60 initial-estimation months.
# Formation: period 1 requires >= 44 valid months (allowing some
#            tolerance, since its window is exactly 48 months long);
#            periods 2-9 require >= 48 valid months within 84 calendar
#            months. This retains the implemented selected rule; it is
#            NOT a 90% rule across all later formation months.
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

saveRDS(eligible_securities, "data/processed/final/table1/eligible_securities.rds")
saveRDS(periods, "data/processed/final/table1/periods.rds")
saveRDS(first_month_long, "data/processed/final/table1/first_month_long.rds")


# =========================================================
# 03_table1_securities_available.R
# Decision 1, Alternative B
# Computes "securities available" — stocks listed as NYSE
# common stock in the first month of each testing period,
# with no data-sufficiency filter applied — and combines
# with eligible-security counts into the final Table 1 output
# =========================================================

library(dplyr)
library(tidyr)
library(lubridate)

# ---- Load everything this script needs, so it can run independently ----
eligible_securities  <- readRDS("data/processed/final/table1/eligible_securities.rds")
periods              <- readRDS("data/processed/final/table1/periods.rds")
first_month_long     <- readRDS("data/processed/final/table1/first_month_long.rds")

# ---- Count securities available in first month of each testing period ----
# Uses the same first_month_long list built in script 02, so both scripts
# agree on who counts as "available" — based on listing status, not on
# whether CRSP happens to have a valid return that month.
securities_available <- first_month_long |>
  group_by(period_id) |>
  summarise(n_available = n_distinct(permno), .groups = "drop")

securities_available

# ---- Build Table 1, Alternative B, in the paper's own layout ----
table1_b <- periods |>
  left_join(securities_available, by = "period_id") |>
  left_join(
    eligible_securities |>
      group_by(period_id) |>
      summarise(n_eligible = sum(eligible), .groups = "drop"),
    by = "period_id"
  ) |>
  transmute(
    period_id,
    `Portfolio formation period` = paste0(year(formation_start), "-", year(formation_end)),
    `Initial estimation period`  = paste0(year(estimation_start), "-", year(estimation_end)),
    `Testing period`             = if_else(period_id == 9L, "1967-Jun 1968",
      paste0(year(testing_start), "-", year(testing_end))),
    `No. of securities available`                = as.character(n_available),
    `No. of securities meeting data requirement` = as.character(n_eligible)
  ) |>
  pivot_longer(cols = -period_id, names_to = "Statistic", values_to = "value") |>
  pivot_wider(names_from = period_id, values_from = value, names_prefix = "Period ")

table1_b

# ---- Save ----
write.csv(table1_b, "output/tables/table1_final.csv", row.names = FALSE, na = "")
# Explicit diagnostics for the final workflow.
if (anyNA(eligible_securities$eligible) ||
    anyDuplicated(eligible_securities[c("period_id", "permno")]) ||
    anyDuplicated(first_month_long[c("period_id", "permno")])) {
  stop("Missing eligibility indicators or duplicate sample keys.")
}
selected <- eligible_securities |> filter(eligible)
if (nrow(anti_join(selected, first_month_long, by = c("period_id", "permno")))) {
  stop("Eligible securities must be available in the first testing month.")
}
diagnostic <- periods |> select(period_id) |>
  left_join(securities_available, by = "period_id") |>
  left_join(selected |> count(period_id, name = "n_eligible"), by = "period_id")
if (anyNA(diagnostic) || any(diagnostic$n_eligible > diagnostic$n_available)) {
  stop("Invalid final Table 1 sample counts.")
}
write.csv(diagnostic, "output/tables/table1_final_diagnostics.csv", row.names = FALSE, na = "")
cat("PASS: nine periods, unique sample keys and eligible securities within first-month availability.\n")
print(diagnostic, n = Inf, width = Inf)
cat("Final Table 1 completed.\n")
cat("Saved: output/tables/table1_final.csv\n")
cat("Saved: output/tables/table1_final_diagnostics.csv\n")
cat("Sample inputs: data/processed/final/table1/\n")
})
