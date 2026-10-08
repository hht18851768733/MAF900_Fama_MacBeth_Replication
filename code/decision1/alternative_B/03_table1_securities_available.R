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
nyse_common          <- readRDS("data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")
eligible_securities  <- readRDS("data/processed/decision1/alternative_B/eligible_securities.rds")
periods              <- readRDS("data/processed/decision1/alternative_B/periods.rds")

# ---- Count securities available in first month of each testing period ----
securities_available <- periods |>
  rowwise() |>
  mutate(
    n_available = nyse_common |>
      filter(date >= testing_start, date < testing_start %m+% months(1)) |>
      pull(permno) |>
      n_distinct()
  ) |>
  select(period_id, n_available) |>
  ungroup()

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