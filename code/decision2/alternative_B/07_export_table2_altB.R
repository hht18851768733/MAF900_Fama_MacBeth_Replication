# Export Alternative B Table 2 results.
# Extended presentation: distinguish the mean individual beta
# from the portfolio-regression beta and its own standard error.

library(dplyr)
library(tidyr)
library(readr)

table2_data <- readRDS(
  "data/processed/decision2/alternative_B/table2_altB_detailed.rds"
)

# ---- Define the display rows ----

statistic_labels <- c(
  beta_individual_mean =
    "Mean individual beta",
  beta_portfolio_regression =
    "Portfolio-regression beta",
  se_beta_portfolio_regression =
    "SE of portfolio-regression beta",
  r_squared =
    "R-squared",
  sd_portfolio_return =
    "SD of portfolio return",
  resid_sd_portfolio =
    "SD of portfolio residuals",
  avg_individual_resid_sd =
    "Mean individual residual SD",
  resid_sd_ratio =
    "Portfolio / mean individual residual SD"
)

# ---- Build a journal-style display for all nine periods ----

display_all <- table2_data |>
  mutate(
    estimation_period = paste0(
      format(as.Date(estimation_start), "%Y"),
      "-",
      format(as.Date(estimation_end), "%Y")
    )
  ) |>
  select(
    period_id,
    estimation_period,
    portfolio,
    all_of(names(statistic_labels))
  ) |>
  pivot_longer(
    cols = all_of(names(statistic_labels)),
    names_to = "statistic_code",
    values_to = "value"
  ) |>
  mutate(
    row_order = match(
      statistic_code,
      names(statistic_labels)
    ),
    Statistic = unname(
      statistic_labels[statistic_code]
    ),
    value = sprintf("%.3f", value)
  ) |>
  select(
    period_id,
    estimation_period,
    row_order,
    Statistic,
    portfolio,
    value
  ) |>
  pivot_wider(
    names_from = portfolio,
    values_from = value,
    names_prefix = "Portfolio "
  ) |>
  arrange(period_id, row_order) |>
  select(-row_order)

# ---- Select the four estimation periods shown in the paper ----

display_paper_periods <- display_all |>
  filter(period_id %in% c(2, 4, 6, 8))

# ---- Save display tables ----

dir.create(
  "output/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

write_csv(
  display_paper_periods,
  "output/tables/table2_altB_display.csv"
)

write_csv(
  display_all,
  "output/tables/table2_altB_all_periods_display.csv"
)

# ---- Save definitions alongside the tables ----

notes <- c(
  "# Table 2 — Alternative B: output notes",
  "",
  "## Scope",
  "",
  "These tables use five-year estimation-period data.",
  "They do not use testing-period portfolio returns.",
  "",
  "The main display includes periods 2, 4, 6 and 8:",
  "1934–1938, 1942–1946, 1950–1954 and 1958–1962.",
  "A separate display includes all nine periods.",
  "",
  "## Missing-return treatment",
  "",
  "The selected DP1-B sample and formation assignments are fixed.",
  "A portfolio-month return is calculated only when every assigned",
  "member has a valid monthly return. Otherwise it is missing.",
  "Valid zero returns are retained; missing returns are not filled.",
  "",
  "## Beta and standard-error definitions",
  "",
  "Mean individual beta averages the initial individual estimates,",
  "using each stock's own valid estimation-period observations.",
  "",
  "Portfolio-regression beta is estimated from complete portfolio",
  "months paired with market returns. Its reported standard error",
  "comes from that same OLS regression.",
  "",
  "With missing data, these two beta estimates need not coincide.",
  "The portfolio-regression SE is not reported as the SE of the",
  "mean individual beta.",
  "",
  "This is an extended presentation with an additional beta row,",
  "rather than an exact seven-row reproduction of the paper.",
  "Both alternatives need the same definitions for a fair comparison.",
  "",
  "## Other statistics",
  "",
  "R-squared, portfolio return SD and portfolio residual SD use",
  "the valid portfolio-market pairs in the estimation window.",
  "Residual SD is calculated with R's sd() function.",
  "",
  "Mean individual residual SD averages the individual estimates",
  "from each stock's own valid estimation-period observations.",
  "The residual-SD ratio therefore compares measures that may",
  "use different effective sets of months when data are missing.",
  "",
  "Returns and return SDs are in decimal units, not percentages.",
  "Display values are rounded to three decimals.",
  "Unrounded values and observation counts are retained in",
  "table2_altB_detailed.csv.",
  "",
  "The separate testing-period return comparison is a diagnostic;",
  "it is not the estimation-period Table 2 comparison."
)

writeLines(
  enc2utf8(notes),
  "output/tables/table2_altB_notes.md",
  useBytes = TRUE
)

# ---- Show the first displayed period ----

print(
  display_paper_periods |>
    filter(period_id == 2) |>
    select(
      period_id,
      estimation_period,
      Statistic,
      `Portfolio 1`,
      `Portfolio 2`,
      `Portfolio 3`
    ),
  n = 8,
  width = Inf
)

cat("\nAlternative B display tables and notes saved.\n")