# Part 3: Agreed Methodology and Final Implementation

**Group members:** Haitian Hu and Bharat Goel  
**Updated:** 14 October 2026  
**Final choices:** Decision 1 Alternative B and Decision 2 Alternative A

This document records the rules used in our Part 3 replication of Tables 1–3 from Fama and MacBeth (1973). Both alternatives for each decision are retained in the repository, together with comparison outputs, reciprocal reviews and the group decision records. The selected calculations have been incorporated into `code/final/`, and the final Tables 1–3 have been generated.

## 1. Relationship to Part 2

Part 2 proposed two approaches to missing return histories and two approaches to missing constituent returns. The Part 3 clarification explains how the formation requirements apply to the later 84-month windows and records the final implementation.

The first formation window contains 48 months. Later formation windows contain 84 months. Within those later windows, Alternative A requires a run of at least 48 consecutive valid calendar months, while Alternative B requires at least 48 valid months without a continuity requirement. These eligibility rules leave the full calendar windows unchanged.

The 90% tolerance applies to B's first formation window and its initial estimation windows. It is not applied to the later 84-month formation windows. These thresholds and A's consecutive-month condition are group implementation choices. The submitted Part 2 remains unchanged; this document and the decision records explain their application in Part 3.

## 2. Calendar windows

Both alternatives use the same nine periods.

| Period | Formation | Initial estimation | Testing |
| --- | --- | --- | --- |
| 1 | Jan 1926–Dec 1929 | Jan 1930–Dec 1934 | Jan 1935–Dec 1938 |
| 2 | Jan 1927–Dec 1933 | Jan 1934–Dec 1938 | Jan 1939–Dec 1942 |
| 3 | Jan 1931–Dec 1937 | Jan 1938–Dec 1942 | Jan 1943–Dec 1946 |
| 4 | Jan 1935–Dec 1941 | Jan 1942–Dec 1946 | Jan 1947–Dec 1950 |
| 5 | Jan 1939–Dec 1945 | Jan 1946–Dec 1950 | Jan 1951–Dec 1954 |
| 6 | Jan 1943–Dec 1949 | Jan 1950–Dec 1954 | Jan 1955–Dec 1958 |
| 7 | Jan 1947–Dec 1953 | Jan 1954–Dec 1958 | Jan 1959–Dec 1962 |
| 8 | Jan 1951–Dec 1957 | Jan 1958–Dec 1962 | Jan 1963–Dec 1966 |
| 9 | Jan 1955–Dec 1961 | Jan 1962–Dec 1966 | Jan 1967–Jun 1968 |

Every initial estimation window contains 60 months. Stock extraction extends through December 1968, but the testing sample ends in June 1968: 402 months in total.

## 3. Common data and listing definitions

Stock returns come from `crsp.msf`, with exchange and share-code history from `crsp.msenames`. Records are matched using PERMNO and the applicable name-history dates. NYSE common stocks are defined by `exchcd = 1` and `shrcd` equal to 10 or 11.

The DP1 comparison uses the same input snapshot for A and B. A zero return is valid. Missing returns remain missing and are not interpolated or replaced with zero. Sample construction counts nonmissing returns; the final input validation checks invalid numerical return values, and regressions use finite stock/market pairs.

Listing coverage is measured separately from return availability. A qualifying listing segment covers each calendar month touched by that segment. Repeated security-month coverage is counted once. This month-overlap convention also applies to the testing-period membership indicators.

Both DP1 alternatives require at least 48 qualifying listed months within the formation window, all 60 listed months within the initial estimation window, and listing in the first testing month. A missing return in that first testing month does not by itself remove a security from the available roster. The same first-month roster is used for eligibility and Table 1's availability count, and the comparison checks the identities of candidates across A and B.

## 4. Decision 1: sample eligibility

| Return-history requirement | Alternative A — Haitian | Alternative B — Bharat |
| --- | --- | --- |
| First formation window | All 48 months valid | At least 44 valid months out of 48 |
| Later formation windows | A run of at least 48 consecutive valid calendar months within 84 months | At least 48 valid months within 84 months; continuity not required |
| Initial estimation window | All 60 months valid | At least 54 valid months out of 60 |

For B, the first-period threshold is `ceiling(0.90 * 48) = 44`, and the estimation threshold is `ceiling(0.90 * 60) = 54`. The later formation threshold is a fixed 48 observations. For A, an absent calendar month breaks a consecutive run, and the qualifying run can occur anywhere within the 84-month window.

The recorded eligible counts for periods 1–9 are:

- **A:** 269, 465, 554, 662, 727, 784, 823, 820 and 797.
- **B:** 390, 562, 588, 687, 733, 787, 839, 845 and 821.

A is a subset of B in all nine periods. B adds 351 security-period observations: 134 fail only A's formation rule, 183 fail only its estimation rule, and 34 fail both. These are period-level observations, so a security can appear more than once in the total.

The group selected **Alternative B** to allow incomplete return histories while retaining the listing-history requirements and calendar windows. Alternative A remains the stricter comparison. The counts, reasons and supporting evidence are recorded in [decision1.md](decisions/decision1.md) and the [comparison summary](output/tables/decision1_comparison_summary.csv).

## 5. Market index, portfolio formation and initial risk

Both DP2 alternatives and the final workflow use the published CRSP NYSE Equal-Weighted Market Index, `indno = 1000001`. Monthly total returns are downloaded as `mthtotret` from `crsp_q_indexes.indmthseriesdata_ind` for January 1926–June 1968 and saved as `data/raw/common/market_index_nyse_ew.rds`. The file contains 510 monthly observations. This market index is not reconstructed from the selected stocks.

For each selected DP1-B security, formation beta is estimated from `ret ~ mkt_ret`, including an intercept, using all valid paired observations in the full formation window. Securities are sorted by beta, with PERMNO breaking ties, and assigned to 20 portfolios. The base size is `N %/% 20`; the remainder is split between portfolios 1 and 20, with any odd extra security assigned to portfolio 20.

Initial individual betas and residual standard deviations are re-estimated over each five-year estimation window. Residual standard deviation is calculated with `sd(residuals(fit))`. The shared DP2 preparation keeps sample selection, portfolio assignments, market inputs and individual risk estimates the same for the two return rules.

## 6. Decision 2: monthly portfolio returns

**Alternative A**, implemented by Bharat, averages valid returns of current members with equal weights. If some returns are temporarily missing, the remaining observed returns determine that month's average. If none are valid, the return remains missing.

**Alternative B**, implemented by Haitian, calculates the equal-weighted return only when every current member has a valid return. Otherwise, the portfolio-month is missing.

Expected and valid member counts are retained. Missing returns do not permanently remove an assigned security. Valid zero returns contribute to the average under both rules.

In the estimation windows, all assigned securities are expected members because DP1-B requires all 60 months of listing coverage. During testing, original portfolio assignments are retained and monthly membership follows the NYSE common-stock listing indicators. A security outside qualifying listing coverage is excluded for that month; if it returns within the same testing period, it resumes its original assignment. The implementation uses CRSP `ret` without a separate delisting-return adjustment.

The [testing-period comparison](output/tables/decision2_return_comparison.csv) recomputes an available-case benchmark from the shared member-month panel and compares it with saved B returns. It records 8,040 usable portfolio-months under A's rule and 7,584 under B's rule. The additional 456 months under A represent about 5.7% of the total. Returns match exactly on all months retained by both rules.

The group selected **Alternative A** for the final portfolio returns. It retains observed information from other members when a return is unavailable, with the changing contributor counts recorded in the output. The selection and its rationale are documented in [decision2.md](decisions/decision2.md).

## 7. Table 2 statistics

Table 2 uses portfolio returns from the separate 60-month estimation windows. Each alternative produces 180 portfolio-period records. The displayed subset uses periods 2, 4, 6 and 8; all nine periods are also exported.

The reported mean individual beta and the beta from the portfolio-return regression are separate quantities. The displayed OLS standard error belongs to the portfolio-return regression. The detailed A output also retains `se_beta_portfolio`, calculated as the cross-security standard deviation of individual betas divided by the square root of the number of securities; this is a dispersion diagnostic.

The table also reports portfolio-regression R-squared, portfolio return SD, portfolio residual SD, mean individual residual SD and the ratio of the latter two risk measures. The portfolio regression uses the valid portfolio/market pairs retained by the relevant return rule. B can therefore use fewer estimation months than A. The 54-month threshold is an individual DP1 eligibility rule, not a minimum portfolio-regression sample size.

The saved A detailed results and final Table 2 detailed results agree within floating-point precision. Final output definitions are recorded in [table2_final_notes.md](output/tables/table2_final_notes.md).

## 8. Annual risk updates and Table 3

Individual risk estimates are updated once for each testing year using observations through the preceding December. The window begins at the original estimation start and expands from 60 to 72, 84 and 96 calendar months across a four-year testing period. Period 9 uses 60 and 72 months. The minimum remains 54 valid paired observations; the workflow does not impose a new 90% threshold on each expanded window.

For each testing month, the explanatory variables are calculated over current listed members using their annual estimates:

- Mean individual beta.
- Mean squared individual beta, calculated as `mean(beta_individual^2)`.
- Mean individual residual standard deviation.

A member's temporarily missing current return does not remove its previously estimated risk measure. The risk averages can therefore have a different denominator from the available-case return average. Portfolio membership is not re-sorted by the updated beta within a testing period.

Each monthly cross-sectional regression includes an intercept and uses raw portfolio returns:

| Panel | Explanatory variables |
| --- | --- |
| A | Mean beta |
| B | Mean beta and mean squared beta |
| C | Mean beta and mean residual SD |
| D | Mean beta, mean squared beta and mean residual SD |

The panel letters describe regression specifications; all four use the selected DP2-A returns. The completed panel contains 8,040 portfolio-months across 402 months, with 20 portfolios per month. The four models produce 1,608 monthly regressions. The reported run passed the coverage, finite-input and full-column-rank checks. First-year individual risk estimates and observation counts also match the final Table 2 initial estimates.

## 9. Table 3 summaries and risk-free returns

Monthly coefficient estimates are summarised using their time-series means and sample standard deviations. The standard error of a mean is `SD / sqrt(n)`, and its t-statistic is the mean divided by that standard error. The primary results do not apply a HAC/Newey–West adjustment. Omitted model terms remain missing and are displayed as dashes.

For the intercept-minus-RF test, RF is subtracted month by month before calculating the mean, SD and t-statistic. RF comes from the monthly F-F Research Data Factors file supplied by the Kenneth French Data Library, divided by 100 once to convert percent to decimal. The 402 RF dates match the testing sample. Negative observations are retained, and the source ZIP checksum is recorded. This modern downloaded series has not been verified against the original 1973 RF vintage.

The reported R-squared summaries use monthly adjusted R-squared, including negative values. Lag-one serial correlations use mean-centering for gamma1 and zero-centering for gamma0 minus RF, gamma2 and gamma3. The implemented ratio is `sum(z[t] * z[t-1], t = 2,...,n) / sum(z[t]^2, t = 1,...,n)`.

The ten reporting samples consist of the full sample, three longer subperiods and six shorter subperiods. They overlap and differ from the nine formation/testing periods. Their month counts are 402, 132, 120, 150, 72, 60, 60, 60, 60 and 90; these counts are not added together. The four models generate 40 model/sample summary rows. Details are in [table3_statistics_notes.md](output/tables/table3_statistics_notes.md).

## 10. Final workflow and evidence

From the repository root, the final entry point is:

```r
source("code/final/00_run_final.R")
```

It runs stock preparation, Table 1, Table 2 and Table 3 in sequence. The final calculation scripts recreate their processed inputs without requiring intermediate outputs from the alternative-development folders. Compatible raw caches are reused; otherwise, authorised WRDS access and the French RF download supply the inputs. Setup instructions are in [README.md](README.md).

Final results are saved under `output/tables/`. Raw data, processed data and integration backups remain local. The alternative implementations, their comparison outputs and four reciprocal review records remain available separately.

The reported repeat run matched the previous annual risk, Table 3 panel, monthly regressions, summary statistics and RF outputs, with a maximum absolute difference of zero for each comparison. The saved [integration check](output/tables/table3_final_integration_check.csv) records these results. These checks document consistency of the implemented workflow and saved outputs; they do not imply an exact numerical match to the original paper.

Haitian implemented DP1-A and DP2-B and reviewed DP1-B and DP2-A. Bharat implemented DP1-B and DP2-A and reviewed DP1-A and DP2-B. The agreed final selections are DP1-B and DP2-A.

AI assistance was used for code inspection, debugging, output checks and documentation. The group remains responsible for the methodological choices, implementation and interpretation.

## Reference

Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. *Journal of Political Economy, 81*(3), 607–636. https://doi.org/10.1086/260061
