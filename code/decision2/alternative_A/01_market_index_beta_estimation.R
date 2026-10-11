# =========================================================
# 01_market_index_beta_estimation.R
# Decision 2, Alternative A
# Pulls CRSP's equal-weighted market index (ewretd), and
# estimates formation-period betas for each eligible security
# in each of the nine periods, via the market-model regression.
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
                  user = 's223014195')

start_date <- ymd("1926-01-01")
end_date   <- ymd("1968-12-31")

# ---- Pull the equal-weighted market index ----
market_index <- tbl(wrds, in_schema("crsp", "msi")) |>
  filter(date >= start_date, date <= end_date) |>
  select(date, ewretd) |>
  collect() |>
  rename(mkt_ret = ewretd)

range(market_index$date)
dim(market_index)

saveRDS(market_index, "data/raw/decision2/alternative_A/market_index.rds")

# ---- Load Decision 1's eligible securities and period definitions ----
eligible_securities <- readRDS("data/processed/decision1/alternative_B/eligible_securities.rds")
periods              <- readRDS("data/processed/decision1/alternative_B/periods.rds")

# ---- Load stock-level returns ----
nyse_common <- readRDS("data/raw/decision1/alternative_B/nyse_common_1926_1968.rds")

# ---- Attach the market return to each stock-month ----
returns_with_market <- nyse_common |>
  inner_join(market_index, by = "date")

# ---- Formation-period beta estimation, per eligible security, per period ----
formation_betas <- list()

for (p in 1:9) {
  
  row <- periods[p, ]
  
  eligible_this_period <- eligible_securities |>
    filter(period_id == row$period_id, eligible == TRUE) |>
    pull(permno)
  
  period_data <- returns_with_market |>
    filter(
      permno %in% eligible_this_period,
      date >= row$formation_start,
      date <= row$formation_end,
      !is.na(ret)
    )
  
  betas_this_period <- period_data |>
    group_by(permno) |>
    summarise(
      beta_formation = {
        fit <- lm(ret ~ mkt_ret, data = pick(ret, mkt_ret))
        coef(fit)[["mkt_ret"]]
      },
      n_obs = n(),
      .groups = "drop"
    ) |>
    mutate(period_id = row$period_id)
  
  formation_betas[[p]] <- betas_this_period
}

formation_betas <- bind_rows(formation_betas)

# ---- Quick look ----
head(formation_betas)
dim(formation_betas)
summary(formation_betas$beta_formation)

saveRDS(formation_betas, "data/processed/decision2/alternative_A/formation_betas.rds")