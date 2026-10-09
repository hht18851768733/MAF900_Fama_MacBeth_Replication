# =========================================================
# 03_table1_securities_available.R
# Decision 1, Alternative B
# Computes "securities available" — stocks listed as NYSE
# common stock in the first month of each testing period,
# with no data-sufficiency filter applied — and combines
# with eligible-security counts into the final Table 1 output
# =========================================================

library(tidyverse)
library(lubridate)

# ---- Load everything this script needs, so it can run independently ----
eligible_securities  <- readRDS("data/processed/decision1/alternative_B/eligible_securities.rds")
periods              <- readRDS("data/processed/decision1/alternative_B/periods.rds")
first_month_long     <- readRDS("data/processed/decision1/alternative_B/first_month_long.rds")

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
    `Testing period`             = paste0(year(testing_start), "-", year(testing_end)),
    `No. of securities available`                = as.character(n_available),
    `No. of securities meeting data requirement` = as.character(n_eligible)
  ) |>
  pivot_longer(cols = -period_id, names_to = "Statistic", values_to = "value") |>
  pivot_wider(names_from = period_id, values_from = value, names_prefix = "Period ")

table1_b

# ---- Save ----
write_csv(table1_b, "output/tables/table1_b.csv")