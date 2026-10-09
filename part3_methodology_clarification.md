# Part 3: Current implementation rules

Group members: Haitian Hu and Bharat Goel  
Updated: 9 October 2026  
Status: DP1 eligibility and Table 1 count comparisons completed; final approach selection and downstream analysis remain pending.

## 1. Purpose and relationship to Part 2

This document records the rules used by our current Part 3 implementations. Part 2 proposed a strict-history alternative and an alternative allowing missing monthly returns. It specified 48/48 versus 44/48 formation observations and 60/60 versus 54/60 estimation observations, but did not fully explain how the formation rules would apply to the later 84-month windows.

Our current clarification keeps those first-period and estimation thresholds. For later formation windows, A requires a run of at least 48 consecutive valid calendar months, while B requires at least 48 valid months without a continuity requirement. The full 84-month formation windows remain unchanged.

These are group implementation choices for comparing the treatment of incomplete monthly histories. The 90% tolerance, its denominators, and A's consecutive-month criterion must not be presented as explicit instructions from the paper or the assignment. In particular, B's allowance of 54 valid estimation months is our missing-data alternative, rather than a literal requirement for 60 valid monthly observations.

**This version supersedes the earlier rule in this file that applied `ceiling(0.90 * N_form)` to later formation histories.** We do not require B to have 76 valid months out of 84, or A to have valid returns throughout every listed month of the 84-month window. Bharat's current 44/48 formation thresholds are retained.

Keep the submitted Part 2 unchanged. Record this clarification, the comparison evidence and the eventual choices in GitHub. The alternatives are defined for implementation; neither has yet been selected as the final pipeline.

## 2. Common time windows

Both alternatives use the following dates.

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

Period 1 has a 48-month formation window; Periods 2–9 have 84-month formation windows. Every initial estimation window contains 60 months. A 48-month eligibility requirement does not shorten an 84-month window.

The extraction includes records through December 1968, but the final testing period ends in June 1968. The year-only label `1967-1968` in B's current table does not extend its coded testing endpoint.

## 3. Shared data and sample definitions

### Data source and monthly validity

Use the same input snapshot for both alternatives:

- Legacy CRSP monthly stock returns from `crsp.msf`.
- Exchange/share-code history from `crsp.msenames`, matched to each return date using `namedt` and `nameendt`.
- NYSE common stocks defined by `exchcd == 1` and `shrcd %in% c(10, 11)`.
- A valid return in the current implementation means `!is.na(ret)`. A zero return is valid. Keep missing returns in the downloaded input; do not replace them with zero or interpolate them.

The comparison run used the same two input RDS files in separate A and B directories. This keeps the implementations separate while holding the input data fixed.

### Listed-history coverage

Listed coverage and valid-return counts are separate concepts. Construct coverage from the qualifying exchange/share-code date segments rather than from the first and last nonmissing returns.

The implemented monthly convention includes each calendar month touched by a qualifying segment: both segment endpoints are rounded down to the start of their month, the intervening months are expanded, and repeated security-month coverage is counted once. This is a month-overlap convention, not a claim that the security was listed on every day of a boundary month.

Both alternatives require:

- At least 48 qualifying listed calendar months within the formation window.
- Coverage of all 60 calendar months within the initial estimation window.

The formation coverage requirement is **at least 48 months within the window**, not coverage of the entire later 84-month window. This common coverage check does not itself impose a consecutive formation-history requirement.

### First testing month and Table 1

A security must appear in the qualifying listing-based roster for the first testing month. A missing return in that month alone does not remove it from the available roster.

Within each alternative, the same saved `first_month_long.rds` is used for eligibility and Table 1's available-security count. Across alternatives, the comparison script checks equality of the actual `period_id, permno` rosters, not only the totals.

Table 1's eligible securities must be a subset of the available roster. A and B use the same candidate roster but may retain different eligible samples.

## 4. Decision Point 1: implemented rules

| Requirement | Alternative A — Haitian | Alternative B — Bharat |
| --- | --- | --- |
| Available in first testing month | Required | Required |
| Formation listed coverage | At least 48 calendar months | At least 48 calendar months |
| Period 1 formation returns | All 48 months valid | At least 44 of 48 months valid |
| Periods 2–9 formation returns | At least one run of 48 consecutive valid calendar months within the 84-month window | At least 48 valid months anywhere within the 84-month window; continuity not required |
| Initial estimation listed coverage | All 60 calendar months | All 60 calendar months |
| Initial estimation returns | All 60 months valid | At least 54 of 60 months valid |

For B, `ceiling(0.90 * 48) = 44` applies to the first formation period, and `ceiling(0.90 * 60) = 54` applies to initial estimation. The later formation threshold is a fixed count of 48 valid months; it is not a 90% threshold on 84 months or on security-specific listed coverage.

For A, continuity is assessed using calendar-month identifiers. A missing calendar month breaks a run even if it has no return row. The qualifying 48-month run may occur anywhere within the formation window. Missing months outside that run do not automatically disqualify the security. A is therefore stricter on formation continuity and estimation completeness, but is not a complete-case rule over all 84 formation months.

The following pseudocode summarises eligibility after coverage, validity and the first-month roster have been constructed:

```r
common_ok <- in_first_month &
  formation_listed_months >= 48 &
  estimation_listed_months == 60

eligible_A <- common_ok &
  formation_longest_run >= 48 &
  estimation_valid_months == 60

formation_threshold_B <- if_else(period_id == 1, 44, 48)

eligible_B <- common_ok &
  formation_valid_months >= formation_threshold_B &
  estimation_valid_months >= 54
```

Both implementations evaluate estimation within a fixed 60-month window. B's current `estimation_listed_months >= 60` condition is equivalent to 60 when counting distinct months in that window.

This comparison tests two missing-history policies. It changes both formation eligibility and estimation completeness, so the overall difference must not be attributed to formation continuity alone. The consecutive-run rule also favours uninterrupted histories; our later discussion should consider the resulting sample selection.

### Formation beta estimation: next-stage rule

After eligibility is determined, estimate formation betas using all valid stock/market paired observations in the full formation window. Do not restrict A's regression to its qualifying 48-month run. Record the paired observation count separately from the stock-return count.

The market series and regression details must be documented consistently before this stage is run. Current Table 1 count outputs do not establish effects on beta estimates, portfolio assignments or Tables 2–3.

## 5. Recorded DP1 comparison

The following results are taken from the uploaded [comparison summary](output/tables/decision1_comparison_summary.csv). The local comparison completed its first-month roster identity check. A is a subset of B in every period.

| Period | Available | Eligible A | Eligible B | Both | A only | B only |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 690 | 269 | 390 | 269 | 0 | 121 |
| 2 | 761 | 465 | 562 | 465 | 0 | 97 |
| 3 | 789 | 554 | 588 | 554 | 0 | 34 |
| 4 | 894 | 662 | 687 | 662 | 0 | 25 |
| 5 | 996 | 727 | 733 | 727 | 0 | 6 |
| 6 | 1036 | 784 | 787 | 784 | 0 | 3 |
| 7 | 1041 | 823 | 839 | 823 | 0 | 16 |
| 8 | 1139 | 820 | 845 | 820 | 0 | 25 |
| 9 | 1229 | 797 | 821 | 797 | 0 | 24 |

The [exclusion summary](output/tables/decision1_exclusion_summary.csv) classifies securities retained by B but rejected by A:

| Period | Formation only | Estimation only | Both requirements |
| --- | ---: | ---: | ---: |
| 1 | 50 | 49 | 22 |
| 2 | 48 | 40 | 9 |
| 3 | 21 | 11 | 2 |
| 4 | 8 | 16 | 1 |
| 5 | 3 | 3 | 0 |
| 6 | 1 | 2 | 0 |
| 7 | 0 | 16 | 0 |
| 8 | 1 | 24 | 0 |
| 9 | 2 | 22 | 0 |

These categories are mutually exclusive. “Formation only” means failure of A's formation rule but satisfaction of its estimation rule; “Estimation only” means the reverse. “Both requirements” means failure of both. None of these B-only observations was classified as a listed-coverage failure or an unexplained case.

The largest count differences occur in Periods 1 and 2. In Periods 7–9, estimation completeness accounts for most of the difference. These are descriptions of this run, not evidence that one alternative produces better beta estimates.

The comparison counts security-period observations. A security can appear in more than one period; totals across periods must not be described as distinct stocks.

Supporting outputs:

- [Table 1 A](output/tables/table1_a.csv) and [dated A counts](output/tables/table1_a_detail.csv).
- [Table 1 B](output/tables/table1_b.csv).
- [Membership comparison](output/tables/decision1_membership_comparison.csv).
- [B-only securities](output/tables/decision1_B_only_securities.csv) and [their diagnostic fields](output/tables/decision1_B_only_diagnostics.csv).

These files support eligibility and sample-overlap findings. They do not replace reciprocal review or the final decision record.

## 6. Decision Point 2: retain the two alternatives

Use the **same selected DP1 sample and portfolio assignments** as the input to both DP2 alternatives. Hold the market data, constituent roster and entry/exit/delisting treatment fixed so the comparison isolates portfolio-month missing-return handling.

| Rule | Alternative A — Bharat | Alternative B — Haitian |
| --- | --- | --- |
| Portfolio return | Arithmetic mean of valid current-member returns, with equal weights among those members | Arithmetic mean only when every current member has a valid return |
| Some current-member returns missing | Calculate using the valid members | Record the portfolio-month as missing |
| No valid member returns, or an empty portfolio | Record missing | Record missing |

Apply the common membership and exit rules before determining which current members have missing returns. A temporary missing return does not permanently remove a stock from the portfolio. Keep valid zero returns and do not fill unavailable returns with zero.

Save expected membership, valid membership and returns for each portfolio-month. Compare usable portfolio-month counts, effective portfolio size, returns on common valid dates and downstream results.

These alternatives remain the agreed DP2 design. They have not yet been implemented in the current repository.

## 7. Run order and file locations

Run scripts from the project root.

1. Create the relevant `data/raw/decision1/alternative_A/`, `data/raw/decision1/alternative_B/`, `data/processed/decision1/alternative_A/`, `data/processed/decision1/alternative_B/` and `output/tables/` directories.
2. Prepare the two common input files, `nyse_common_1926_1968.rds` and `nyse_listing_segments.rds`, using the same CRSP snapshot and extraction definitions. Store identical copies in the A and B raw-data directories for the comparison. A separate extraction is unnecessary if the shared files are already available.
3. Run each alternative's `02_sample_construction.R`, followed by its `03_table1_securities_available.R`.
4. Run [04_compare_decision1.R](code/common/04_compare_decision1.R) after both sets of processed outputs exist.

Implementation sources:

- [A sample construction](code/decision1/alternative_A/02_sample_construction.R).
- [B sample construction](code/decision1/alternative_B/02_sample_construction.R).

Keep the two alternatives in their separate code and data directories. GitHub stores the scripts, documentation and comparison outputs; WRDS credentials and licensed raw data remain local.

## 8. Review, decisions and remaining work

Completed at this stage:

- Both DP1 eligibility implementations and Table 1 count outputs.
- A local rerun of B using the same inputs as A, reproducing Bharat's reported eligible counts.
- First-month roster comparison, eligible-set overlap and B-only exclusion diagnostics.

Next steps:

1. Update [decision1.md](decisions/decision1.md) to describe the implemented later-period A rule and the comparison results. Its existing broad description of B as a 90% rule must be read with the stage-specific thresholds above.
2. Complete reciprocal DP1 reviews: Haitian reviews B and Bharat reviews A. Execution checks alone do not establish that both reviews are complete.
3. Document and implement the common market-return series, formation-beta regression, sorting and tie handling for 20 portfolios, initial risk estimates, and risk-measure updates during testing.
4. Review the resulting sample, beta and portfolio differences, and record the final DP1 selection with reasons. A larger sample or a closer match to the original counts is not sufficient on its own.
5. Implement and compare both DP2 alternatives using the same selected DP1 inputs. Record the choice in [decision2.md](decisions/decision2.md).
6. Complete the selected pipeline for Tables 1–3 and update the README with run order, dependencies, data access and AI assistance.

The exact market proxy, risk-update schedule, entry/exit and delisting treatment, and Table 3 regression specification and usable-month rule remain to be documented before downstream execution. The earlier suggestion to require a complete 20-portfolio cross section in every Table 3 regression is not treated here as an already implemented or selected rule. Apply and document a common comparison convention, report missing cross sections, and avoid using current or future testing returns to construct a month's explanatory risk measures.

This document records current implementation rules and evidence. Formal alternative selection and any new downstream choices belong in the decision records, with supporting results and group review.

## Reference

Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. *Journal of Political Economy, 81*(3), 607–636. https://doi.org/10.1086/260061




