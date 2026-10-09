# Part 3: Unified implementation rules and code revisions

Group members: Haitian Hu and Bharat Goel  
Updated: 9 October 2026  
Part 3 implementation of the alternatives agreed in Part 2. Final selections follow coding, comparison and reciprocal review.

## 1. What this update changes

Our submitted Part 2 compared strict complete history with a 90% valid-observation rule. It described a 48-month formation period without explaining the later 84-month formation windows. This note clarifies that omission and specifies how the alternatives should work with different lengths of listed history.

We retain Alternative B's 44/48 formation threshold in the first block and 54/60 initial-estimation threshold. We apply the formation percentage to each security's expected listed-history months in later blocks. This requires an explicit change from Bharat's current fixed 48-valid-month rule for blocks 2–9.

This version also replaces the 8 October clarification's additional floor of 48 **valid** formation observations. There is a shared minimum of 48 months of **calendar coverage**, but Alternative B need not have 48 valid formation returns.

The two DP1 alternatives and the pre-specified 90% threshold were already established in Part 2. In Part 3, we implement both alternatives, review whether the code follows each rule, and compare their effects on sample retention, beta estimates and portfolio results. This note adds the implementation details for later 84-month formation windows and their denominators while carrying forward the Part 2 comparison. Keep the submitted Part 2 unchanged and record these implementation details in GitHub.

## 2. Shared date configuration

Use one common date configuration for both alternatives. Bharat's current nine-block configuration can be retained.

| Block | Formation | Initial estimation | Testing |
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

The first formation window is 48 months and later windows are 84 months. Every initial estimation window is 60 months. Do not truncate the later formation windows to 48 months. All analysis must respect the final testing cutoff of June 1968, even if the extraction includes later records.

These are initial-estimation dates. They do not replace the separate updating of risk measures during the testing periods; the shared downstream implementation must document that schedule and avoid using current or future test returns to construct a month's explanatory risk measures.

## 3. Shared sample, coverage and missing-data definitions

Retain one common NYSE common-stock mapping for both alternatives. For the legacy CRSP fields used in the current scripts, the working mapping is date-matched exchange/share history with `exchcd == 1` and `shrcd %in% c(10, 11)`. Record this mapping as an implementation choice and apply it consistently.

Create one shared security-month panel before filtering out invalid returns. Preserve the dated listing and exchange/share-status records needed to distinguish calendar coverage from return availability.

For each security and block, define:

- `available_first_month`: the security is available under the shared sample definition in the first testing month. Use dated status/listing information; a missing numerical return alone must not make an otherwise available security unavailable.
- `N_form`: the number of expected months of the security's qualifying listed history within the full formation window, determined from dated listing/status records before dropping missing returns.
- `n_form`: the number of those months with a valid stock return.
- `N_est`: expected qualifying listed-history months within the fixed 60-month initial estimation window.
- `n_est`: the number of those initial-estimation months with a valid stock return.

Both alternatives require `available_first_month == TRUE`, `N_form >= 48`, and coverage of every month of the initial estimation window, represented by `N_est == 60`.

Months before listing are not temporary missing returns. A missing row during an established qualifying listing spell is an expected month with an unavailable return. Do not infer coverage from the first and last nonmissing returns. Use the same dated mapping for exchange changes, listing-spell breaks and boundary months; distinguish documented noncoverage from a temporary return gap.

Confirm that there is only one observation per `permno` and calendar month. Investigate duplicate date-range matches before counting months. Normalise special missing-value codes according to the CRSP product used; `!is.na(ret)` is sufficient only if such codes have already been converted correctly. A valid zero return counts as valid. Do not fill missing returns with zero or interpolate them.

Use one documented common market-return proxy and return-unit convention. Check its monthly coverage in the common preprocessing. Estimate betas from valid stock/market pairs and save the actual regression observation counts; do not assume the stock-return count always equals the paired count.

## 4. Decision Point 1 eligibility rules

| Requirement | Alternative A: Haitian | Alternative B: Bharat |
| --- | --- | --- |
| Available in first testing month | Required | Required |
| Formation calendar coverage | `N_form >= 48` | `N_form >= 48` |
| Formation valid returns | `n_form == N_form` | `n_form >= ceiling(0.90 * N_form)` |
| Initial estimation calendar coverage | `N_est == 60` | `N_est == 60` |
| Initial estimation valid returns | `n_est == 60` | `n_est >= 54` |

Valid observations under B do not need to be consecutive. Formation betas use all valid paired observations in the relevant full formation window.

Examples:

| Expected formation months | A: valid months required | B: valid months required |
| --- | ---: | ---: |
| 48 | 48 | 44 |
| 60 | 60 | 54 |
| 84 | 84 | 76 |

Thus a security with 84 expected formation months and 50 valid returns passes Bharat's current fixed-48 rule but fails this revised 90% rule. A security with only 48 expected months within a later 84-month window needs 44 valid returns under B; it does not automatically need 76.

The eligibility logic, after constructing the shared panel, is:

```r
eligible_A <- available_first_month &
  N_form >= 48 & N_est == 60 &
  n_form == N_form & n_est == 60

formation_threshold_B <- ceiling(0.90 * N_form)

eligible_B <- available_first_month &
  N_form >= 48 & N_est == 60 &
  n_form >= formation_threshold_B & n_est >= 54
```

The snippet describes the rule, not a drop-in replacement for the existing scripts: the shared coverage and availability fields must be constructed first.

Retain both outputs. Compare eligible-security counts, exclusion reasons, sample overlap, paired observation counts, formation-beta estimates and their precision, and the membership of the 20 beta-sorted portfolios. Select the final DP1 implementation after review; do not choose solely by closeness to the original reported counts.

## 5. Required revisions to the uploaded DP1 B scripts

The uploaded ZIP contains `01_data_extraction.R`, `02_sample_construction.R` and `03_table1_securities_available.R`. This review checks code logic only: the ZIP does not include the data or empirical outputs needed to validate numerical results.

| Item | Current implementation | Required action |
| --- | --- | --- |
| Date windows in script 02 | First formation window 48 months; later windows 84 months; final test ends June 1968 | Retain the dates and move/reuse the configuration in shared code. |
| Formation threshold in script 02 | `if_else(period_id == 1, 44, 48)` | Replace with `ceiling(0.90 * N_form)` after building coverage. The first block still requires 44; later requirements depend on listed coverage. |
| Formation coverage | Counts nonmissing returns but does not construct expected listed months | Preserve dated status history from script 01; construct `N_form` independently of `n_form`; require `N_form >= 48`. |
| Initial estimation coverage | Requires at least 54 nonmissing returns only | Keep the 54-return rule, and additionally require complete 60-month calendar coverage using `N_est == 60`. |
| First-testing-month availability | Script 03 calculates an available-security count; script 02 does not use the underlying list when assigning eligibility | Build a shared `period_id, permno` availability list and incorporate it into eligibility. Securities that exited before the first test month must not enter the eligible sample. |
| Table 1 sample relationship | Available and eligible totals are calculated separately | Derive both from the same availability list. Eligible securities must be a subset of available securities; check `n_eligible <= n_available` and the actual identities. |
| Missing-code and duplicate handling | Validity is based on `!is.na(ret)`; no uniqueness check is shown | Verify the imported missing-code representation and security-month uniqueness. These are checks to perform, not confirmed data errors. |
| Diagnostic output | Saves eligibility and Table 1 counts | Also save coverage counts, valid counts, threshold, availability flag and exclusion reasons for each security/block. Save paired counts and beta diagnostics when regressions are added. |
| Final test-period label in script 03 | Shows only `1967-1968` although the coded endpoint is June | Make the June 1968 cutoff explicit in the final table or a table note. |

Before writing RDS/CSV outputs, create the required directories. The ZIP alone does not establish whether those directories already exist in the repository.

The current ZIP does not yet implement formation-beta estimation, assignment to 20 portfolios, initial risk-measure estimation, or DP2. Treat these as remaining stages, rather than errors in code that has not yet been supplied.

## 6. Decision Point 2: retain the submitted alternatives

Run both DP2 alternatives from the **same selected DP1 sample and portfolio assignments**, with the same market data, dated constituent roster and entry/exit/delisting rules.

- Alternative A — Bharat: take the arithmetic mean of valid current-constituent returns. Reweight equally among those valid constituents. If none is valid, record `NA`.
- Alternative B — Haitian: calculate the equal-weighted return only when every current constituent has a valid return. If at least one temporary return is missing, record `NA`. An empty portfolio also has return `NA`.

A temporary missing return does not permanently remove a security from its portfolio. Apply documented exits and the shared treatment of observed delisting returns before classifying a gap as temporary. Keep valid zeros and retain the full monthly calendar. Do not replace unavailable returns with zero.

Save expected membership, valid membership and the portfolio return for every portfolio-month. Compare coverage and effective portfolio size, returns on common valid dates, downstream risk statistics and availability of the 20-portfolio cross section.

This update also proposes a shared downstream rule for the main Table 3 comparison: use months with all 20 required portfolio returns and valid explanatory risk measures under the relevant DP2 alternative. Keep and report incomplete months and reasons for exclusion. Use the same rule in both alternatives. Any regression using fewer portfolios should be separately labelled and documented rather than silently changing the main sample. Record this downstream clarification in GitHub; it was not fully specified in the submitted Part 2. If usable months are insufficient for an estimate, report that limitation rather than filling missing values or silently relaxing the rule.

## 7. Execution, review and records

1. Prepare shared date configuration, monthly data, validity definitions, listed-history coverage, first-test-month availability and the market proxy.
2. Haitian implements DP1-A; Bharat revises and implements DP1-B. Produce candidate Table 1 outputs, beta estimates, portfolio assignments and comparison diagnostics.
3. Each member reviews the other's DP1 implementation. Record the final selection and reasons in `decisions/decision1.md`.
4. Use the selected DP1 output as the common input. Bharat implements DP2-A; Haitian implements DP2-B.
5. Each member reviews the other's DP2 implementation. Compare portfolio-month coverage and downstream effects; record the selection and reasons in `decisions/decision2.md`.
6. Use the selected pipeline for final Tables 1–3. Retain alternative code and outputs so the differences can be inspected.
7. Update the README with run order, dependencies, data-access instructions, output locations and AI disclosure. Make progressive commits and keep credentials and licensed raw data outside the public repository.

Keep shared code under `code/common/`, alternative implementations under `code/decision1/alternative_A/`, `code/decision1/alternative_B/`, `code/decision2/alternative_A/` and `code/decision2/alternative_B/`, and the selected pipeline under `code/final/`. Keep the four reciprocal-review records under `reviews/` and table outputs under `output/tables/`.

The decision records should link the 90% threshold and the 44/48 and 54/60 rules to the agreed Part 2 alternatives. Separately document the omitted 84-month windows, the coverage denominator, the replacement of Bharat's later fixed-48 threshold, the removal of the 8 October extra valid-month floor, and the added Table 3 cross-section rule. Distinguish confirmed implementation omissions from data checks and unfinished stages.

## Reference

Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. *Journal of Political Economy, 81*(3), 607–636. https://doi.org/10.1086/260061

Source document: the group's submitted *Fama and MacBeth 1973 Group Replication Strategy* (Assessment 3 Part 2). Code reviewed: the three R scripts in Bharat's uploaded `alternative_B.zip`.
