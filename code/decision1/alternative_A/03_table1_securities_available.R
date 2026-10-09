# =========================================================
# 03_table1_securities_available.R
# Decision 1 - Alternative A
# Author: Haitian Hu
#
# Produce Table 1 using the shared first-testing-month list
# and the Alternative A eligibility results.
# =========================================================

library(dplyr)
library(tidyr)
library(lubridate)
library(readr)

# ---- 1. Load sample-construction outputs ----

processed_dir <- "data/processed/decision1/alternative_A"

periods <- readRDS(
  file.path(processed_dir, "periods.rds")
)

first_month_long <- readRDS(
  file.path(processed_dir, "first_month_long.rds")
)

eligible_securities <- readRDS(
  file.path(processed_dir, "eligible_securities.rds")
)

# ---- 2. Count available and eligible securities ----

securities_available <- first_month_long |>
  group_by(period_id) |>
  summarise(
    n_available = n_distinct(permno),
    .groups = "drop"
  )

securities_eligible <- eligible_securities |>
  group_by(period_id) |>
  summarise(
    n_eligible = sum(eligible),
    .groups = "drop"
  )

# ---- 3. Combine counts with the period dates ----

table1_a_detail <- periods |>
  left_join(securities_available, by = "period_id") |>
  left_join(securities_eligible, by = "period_id")

# ---- 4. Arrange Table 1 in the paper's layout ----

table1_a <- table1_a_detail |>
  transmute(
    period_id,
    
    `Portfolio formation period` = paste0(
      year(formation_start), "-", year(formation_end)
    ),
    
    `Initial estimation period` = paste0(
      year(estimation_start), "-", year(estimation_end)
    ),
    
    `Testing period` = if_else(
      period_id == 9L,
      "1967-Jun 1968",
      paste0(year(testing_start), "-", year(testing_end))
    ),
    
    `No. of securities available` =
      as.character(n_available),
    
    `No. of securities meeting data requirement` =
      as.character(n_eligible)
  ) |>
  pivot_longer(
    cols = -period_id,
    names_to = "Statistic",
    values_to = "value"
  ) |>
  pivot_wider(
    names_from = period_id,
    values_from = value,
    names_prefix = "Period "
  )

# ---- 5. Save the table and detailed counts ----

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  table1_a,
  "output/tables/table1_a.csv"
)

write_csv(
  table1_a_detail,
  "output/tables/table1_a_detail.csv"
)

# ---- 6. Display results ----

print(table1_a, width = Inf)

cat("\nTable 1 Alternative A saved successfully.\n")
cat("Main table: output/tables/table1_a.csv\n")
cat("Detailed counts: output/tables/table1_a_detail.csv\n")