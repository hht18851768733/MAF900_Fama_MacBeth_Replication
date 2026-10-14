# MAF900 — Fama and MacBeth (1973) Replication

**Group members:** Haitian Hu and Bharat Goel  
**Assessment:** MAF900 Assessment 3, Part 3

This repository contains our replication of Tables 1–3 from Fama and MacBeth (1973). We compare two sample-eligibility rules and two ways of calculating portfolio returns when constituent returns are temporarily missing. The repository includes the alternative implementations, their outputs, reciprocal reviews, decision records and the selected final workflow.

## Final methodological choices

| Decision | Selected approach | Implementation |
| --- | --- | --- |
| Decision 1: sample eligibility | Alternative B | At least 44 valid returns in the first 48-month formation window, at least 48 valid returns in later 84-month formation windows, and at least 54 valid returns in each 60-month estimation window. |
| Decision 2: missing constituent returns | Alternative A | Calculate each monthly portfolio return as the equal-weighted average of the valid returns of current members. |

DP1-B also checks NYSE common-stock listing history separately: at least 48 listed months in the formation window, all 60 listed months in the estimation window, and listing in the first testing month. The missing-return thresholds are our implementation choices. Both unselected alternatives are retained for comparison.

The reasons and comparison results are recorded in [Decision 1](decisions/decision1.md) and [Decision 2](decisions/decision2.md). The final testing sample covers **January 1935–June 1968**. Table 3 uses 20 portfolios in each of 402 months. Its regression panels A–D refer to four model specifications, not to the decision alternatives.

## Repository structure

| Location | Contents |
| --- | --- |
| `code/common/` | Shared preparation and comparison scripts for the alternatives. |
| `code/decision1/alternative_A/` and `alternative_B/` | The two sample-eligibility implementations. |
| `code/decision2/alternative_A/` and `alternative_B/` | The two missing-return implementations. |
| `code/final/` | Selected workflow and Table 3 calculations. |
| `code/final/table2/` | Final market-index preparation, portfolio construction and Table 2 calculations. |
| `output/tables/` | Final tables, alternative results and diagnostics. |
| `reviews/` | Four reciprocal implementation reviews. |
| `decisions/` | The two group decision records. |
| `data/raw/` and `data/processed/` | Local inputs and intermediate files; excluded from Git. |

## Software setup

Open `MAF900_Fama_MacBeth_Replication.Rproj` in RStudio, or set the working directory to the repository root. Relative paths in the scripts assume that this directory contains `code/` and `output/`.

Use R 4.1 or newer and dplyr 1.1.0 or newer. Install the packages used by the final workflow:

```r
install.packages(c(
  "dplyr", "tidyr", "lubridate", "purrr", "DBI", "RPostgres"
))
```

Some alternative-development scripts also use `tidyverse` and `rstudioapi`. Install these if running those scripts:

```r
install.packages(c("tidyverse", "rstudioapi"))
```

## Data access and preparation

The public repository does not include raw CRSP data or processed security-level data. Recreating the inputs requires a WRDS account with access to the relevant CRSP tables, or compatible local input files obtained through authorised access.

The final workflow uses:

- **Stocks and listing history:** `crsp.msf` and `crsp.msenames`, restricted to NYSE common stocks (`exchcd = 1`, `shrcd` 10 or 11). Stock extraction covers January 1926–December 1968; testing ends in June 1968.
- **Market returns:** the published CRSP NYSE Equal-Weighted Market Index, `indno = 1000001`, using `mthtotret` from `crsp_q_indexes.indmthseriesdata_ind` for January 1926–June 1968. This is not an index reconstructed from the selected sample.
- **Risk-free returns:** the monthly `RF` column from the Kenneth French Data Library's [F-F Research Data Factors ZIP](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip). The script selects January 1935–June 1968 and converts percent to decimal by dividing by 100 once.

### Downloading inputs on a new machine

Set `WRDS_USER` and `WRDS_PASSWORD` in your local environment. One option is a local `.Renviron` file in the project root:

```text
WRDS_USER=your_wrds_username
WRDS_PASSWORD=your_wrds_password
```

Replace these placeholders locally and restart R before running the workflow. `.Renviron` is excluded by `.gitignore`; do not put credentials in committed scripts or documents. Network access to WRDS and the French download site is required when the corresponding inputs are absent.

The final workflow downloads missing inputs, validates them and creates the necessary local directories. It does not require you to run the alternative-development scripts first.

### Reusing existing inputs

If you already have the validated input files from this project, keep them in `data/raw/common/`:

```text
nyse_common_1926_1968.rds
nyse_listing_segments.rds
market_index_nyse_ew.rds
F-F_Research_Data_Factors_CSV.zip
```

These are inputs with the formats expected by the scripts; renaming unrelated files is not sufficient. The stock and listing files must be present together. If both are absent from the common folder, the stock-preparation script can also reuse the matching pair from `data/raw/decision1/alternative_B/`.

Existing inputs are reused rather than refreshed automatically. Keep the original French ZIP to preserve its download vintage. The script records its checksum. The resulting risk-free series has not been verified against the data vintage used in the 1973 paper.

## Running the final replication

From the repository root, run:

```r
source("code/final/00_run_final.R")
```

The entry point runs these stages in order:

| Stage | Script | Purpose |
| --- | --- | --- |
| 1 | `code/final/00a_prepare_stock_data.R` | Prepare and validate stock and listing inputs. |
| 2 | `code/final/00b_build_table1.R` | Apply DP1-B and produce Table 1. |
| 3 | `code/final/00c_build_table2.R` | Prepare the market index, form portfolios and produce Table 2 using DP2-A. |
| 4 | `code/final/00e_build_table3.R` | Update annual risk estimates, run monthly regressions and export Table 3. |

The final workflow recreates its processed inputs independently of the alternative-development folders. It does not rebuild every alternative or comparison output; those remain separate parts of the assessment.

The Table 3 risk measures use information through the preceding December. The expected final panel has **8,040 portfolio-months**, and the four specifications produce **1,608 monthly regressions**. These checks establish coverage and internal consistency; they do not establish an exact match to the published paper.

## Reading the results

All exported tables are saved under `output/tables/`.

| Result | Main files |
| --- | --- |
| Table 1 | [Final table](output/tables/table1_final.csv), [diagnostics](output/tables/table1_final_diagnostics.csv) |
| Table 2 | [Selected-period display](output/tables/table2_final_display.csv), [all-period display](output/tables/table2_final_all_periods_display.csv), [detailed results](output/tables/table2_final_detailed.csv) |
| Table 2 documentation | [Methods notes](output/tables/table2_final_notes.md), [testing coverage](output/tables/table2_final_testing_coverage.csv) |
| Table 3 | [Full-sample display](output/tables/table3_full_sample_display.csv), [all-period display](output/tables/table3_all_periods_display.csv), [detailed results](output/tables/table3_summary_detailed.csv) |
| Table 3 documentation | [Methods notes](output/tables/table3_statistics_notes.md), [HTML display](output/tables/table3_display.html) |
| Decision comparisons | [DP1 comparison](output/tables/decision1_comparison_summary.csv), [DP2 return comparison](output/tables/decision2_return_comparison.csv) |

Download and open `table3_display.html` in a browser to view the formatted table. Table 3 coefficient means are summarised across months; the primary t-statistics use the time-series standard deviation divided by the square root of the number of months, without a HAC adjustment. Full definitions and data limitations are in the linked methods notes.

## Checks and repeat runs

The scripts check unique keys, required dates, portfolio coverage and finite regression inputs. Table 3 also checks that every monthly regression uses 20 portfolios and has full column rank.

On repeat runs, `00e_build_table3.R` preserves existing Table 3 results under `data/processed/final/integration_backups/` and compares the regenerated values with them. It writes `output/tables/table3_final_integration_check.csv`. A `PASS` indicates agreement with the previous local result; `SKIP` means no previous result was available, as on a first run. A `SKIP` is not a verified match.

The optional `code/final/00d_check_table2_integration.R` compares final Table 2 intermediate results with existing alternative outputs. It is not called by the main entry point and is not required for a fresh run.

## Contributions and review

Haitian Hu implemented DP1-A and DP2-B and reviewed DP1-B and DP2-A. Bharat Goel implemented DP1-B and DP2-A and reviewed DP1-A and DP2-B. The [review records](reviews/) and [decision records](decisions/) document the checks and the reasons for the final choices.

AI assistance was used for coding, debugging, checks and documentation. The group remains responsible for the implementation, methodological decisions and interpretation of the results.

## Reference

Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. *Journal of Political Economy, 81*(3), 607–636. https://doi.org/10.1086/260061
