# =========================================================
# 02_sample_construction.R
# Decision 1 - Alternative A
# Author: Haitian Hu
#
# Group implementation:
# Period 1: all 48 formation months must be valid.
# Periods 2-9: at least 48 consecutive valid calendar months
#              within the full 84-month formation window.
# Estimation: all 60 months must be valid.
#
# The consecutive-month rule is a group implementation choice.
# =========================================================

library(dplyr)
library(tidyr)
library(lubridate)

# ---- 1. Set paths and load data ----

raw_dir <- "data/raw/decision1/alternative_A"
processed_dir <- "data/processed/decision1/alternative_A"

dir.create(
  processed_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

nyse_common <- readRDS(
  file.path(raw_dir, "nyse_common_1926_1968.rds")
)

nyse_listing_segments <- readRDS(
  file.path(raw_dir, "nyse_listing_segments.rds")
)

# ---- 2. Define the nine periods ----

periods <- tibble(
  period_id = 1:9,
  
  formation_start = ymd(c(
    "1926-01-01", "1927-01-01", "1931-01-01",
    "1935-01-01", "1939-01-01", "1943-01-01",
    "1947-01-01", "1951-01-01", "1955-01-01"
  )),
  
  formation_end = ymd(c(
    "1929-12-31", "1933-12-31", "1937-12-31",
    "1941-12-31", "1945-12-31", "1949-12-31",
    "1953-12-31", "1957-12-31", "1961-12-31"
  )),
  
  estimation_start = ymd(c(
    "1930-01-01", "1934-01-01", "1938-01-01",
    "1942-01-01", "1946-01-01", "1950-01-01",
    "1954-01-01", "1958-01-01", "1962-01-01"
  )),
  
  estimation_end = ymd(c(
    "1934-12-31", "1938-12-31", "1942-12-31",
    "1946-12-31", "1950-12-31", "1954-12-31",
    "1958-12-31", "1962-12-31", "1966-12-31"
  )),
  
  testing_start = ymd(c(
    "1935-01-01", "1939-01-01", "1943-01-01",
    "1947-01-01", "1951-01-01", "1955-01-01",
    "1959-01-01", "1963-01-01", "1967-01-01"
  )),
  
  testing_end = ymd(c(
    "1938-12-31", "1942-12-31", "1946-12-31",
    "1950-12-31", "1954-12-31", "1958-12-31",
    "1962-12-31", "1966-12-31", "1968-06-30"
  ))
)

# ---- 3. Identify valid stock-return months ----

# Use the same non-missing-return definition as Alternative B.
# Each security-month is counted only once.

valid_months <- nyse_common |>
  filter(!is.na(ret)) |>
  transmute(
    permno,
    month = floor_date(date, "month")
  ) |>
  distinct(permno, month)

# ---- 4. Build monthly listing coverage ----

# Use the same month-overlap convention as Alternative B.
# Clip listing segments to the study dates before expansion.

listed_months_table <- nyse_listing_segments |>
  mutate(
    seg_start = pmax(
      floor_date(namedt, "month"),
      ymd("1926-01-01")
    ),
    seg_end = pmin(
      floor_date(nameendt, "month"),
      ymd("1968-12-01")
    )
  ) |>
  filter(
    !is.na(seg_start),
    !is.na(seg_end),
    seg_start <= seg_end
  ) |>
  rowwise() |>
  mutate(
    months_listed = list(
      seq.Date(seg_start, seg_end, by = "month")
    )
  ) |>
  ungroup() |>
  select(permno, months_listed) |>
  unnest(months_listed) |>
  distinct(permno, months_listed)

# ---- 5. Function for consecutive valid calendar months ----

longest_valid_run <- function(month_dates) {
  
  if (length(month_dates) == 0L) {
    return(0L)
  }
  
  # Consecutive calendar months have consecutive integer IDs.
  month_id <- sort(unique(
    year(month_dates) * 12L + month(month_dates)
  ))
  
  # A missing calendar month starts a new run.
  run_id <- cumsum(c(TRUE, diff(month_id) != 1L))
  
  as.integer(max(tabulate(run_id)))
}

# ---- 6. Apply Alternative A separately to each period ----

eligibility_results <- vector("list", nrow(periods))
first_month_results <- vector("list", nrow(periods))

for (i in seq_len(nrow(periods))) {
  
  p <- periods[i, ]
  
  formation_start_month <- floor_date(
    p$formation_start, "month"
  )
  
  formation_end_month <- floor_date(
    p$formation_end, "month"
  )
  
  estimation_start_month <- floor_date(
    p$estimation_start, "month"
  )
  
  estimation_end_month <- floor_date(
    p$estimation_end, "month"
  )
  
  testing_start_month <- floor_date(
    p$testing_start, "month"
  )
  
  # First-testing-month availability does not require a valid return.
  first_month_list <- listed_months_table |>
    filter(months_listed == testing_start_month) |>
    distinct(permno) |>
    mutate(
      period_id = p$period_id,
      in_first_month = TRUE
    ) |>
    select(period_id, permno, in_first_month)
  
  # Count valid months and the longest formation-period run.
  formation_coverage <- valid_months |>
    filter(
      month >= formation_start_month,
      month <= formation_end_month
    ) |>
    group_by(permno) |>
    summarise(
      formation_valid_months = n(),
      formation_longest_run = longest_valid_run(month),
      .groups = "drop"
    )
  
  # Count valid estimation months.
  estimation_coverage <- valid_months |>
    filter(
      month >= estimation_start_month,
      month <= estimation_end_month
    ) |>
    count(
      permno,
      name = "estimation_valid_months"
    )
  
  # Check listing coverage separately from valid returns.
  listed_coverage <- listed_months_table |>
    filter(
      months_listed >= formation_start_month,
      months_listed <= estimation_end_month
    ) |>
    group_by(permno) |>
    summarise(
      formation_listed_months = sum(
        months_listed >= formation_start_month &
          months_listed <= formation_end_month
      ),
      estimation_listed_months = sum(
        months_listed >= estimation_start_month &
          months_listed <= estimation_end_month
      ),
      .groups = "drop"
    )
  
  period_eligibility <- first_month_list |>
    left_join(formation_coverage, by = "permno") |>
    left_join(estimation_coverage, by = "permno") |>
    left_join(listed_coverage, by = "permno") |>
    mutate(
      across(
        c(
          formation_valid_months,
          formation_longest_run,
          estimation_valid_months,
          formation_listed_months,
          estimation_listed_months
        ),
        ~ replace_na(.x, 0L)
      ),
      
      listed_ok =
        formation_listed_months >= 48L &
        estimation_listed_months == 60L,
      
      # In Period 1, a 48-month run covers the entire window.
      # In later periods, the run can occur anywhere within 84 months.
      formation_ok = formation_longest_run >= 48L,
      
      estimation_ok = estimation_valid_months == 60L,
      
      eligible =
        in_first_month &
        listed_ok &
        formation_ok &
        estimation_ok
    )
  
  first_month_results[[i]] <- first_month_list
  eligibility_results[[i]] <- period_eligibility
}

# ---- 7. Combine the nine periods ----

first_month_long <- bind_rows(first_month_results)

# This table contains all first-month candidates and their flags.
eligible_securities <- bind_rows(eligibility_results)

# This table contains only securities that qualify under A.
qualified_securities <- eligible_securities |>
  filter(eligible)

# ---- 8. Summarise the results ----

eligibility_summary <- eligible_securities |>
  group_by(period_id) |>
  summarise(
    n_available = n(),
    n_eligible = sum(eligible),
    n_excluded = sum(!eligible),
    .groups = "drop"
  )

print(eligibility_summary, n = 9)

# ---- 9. Save Alternative A outputs ----

saveRDS(
  periods,
  file.path(processed_dir, "periods.rds")
)

saveRDS(
  first_month_long,
  file.path(processed_dir, "first_month_long.rds")
)

saveRDS(
  eligible_securities,
  file.path(processed_dir, "eligible_securities.rds")
)

saveRDS(
  qualified_securities,
  file.path(processed_dir, "qualified_securities.rds")
)

saveRDS(
  eligibility_summary,
  file.path(processed_dir, "eligibility_summary.rds")
)

cat("\nAlternative A sample construction completed.\n")
cat("Outputs saved to:", processed_dir, "\n")