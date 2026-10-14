# Implementation Review — Decision 2, Alternative A

**Reviewer:** Haitian Hu  
**Implementation reviewed:** Bharat Goel's Alternative A  
**Updated:** 14 October 2026

This review covers the current repository scripts, exported Table 2 results and shared-panel comparison. It also considers the reported local execution checks for the final workflow. The review does not include a separate download and rerun of the raw CRSP data.

## Methodological implementation

Alternative A calculates each monthly portfolio return as the equal-weighted average of the valid returns of current members. Valid zero returns are retained. A temporarily missing return is left out of that month's average, while the security keeps its portfolio assignment. If there are no valid member returns, the portfolio return remains missing.

The implementation separates the five-year estimation-period returns used in Table 2 from the testing-period returns used in Table 3. During estimation, all assigned securities are expected members because the selected DP1-B sample requires listing coverage throughout the 60-month window. During testing, membership follows the common monthly NYSE common-stock listing indicators.

The current A and B workflows use the same DP1-B sample, portfolio assignments, initial individual risk estimates and published CRSP NYSE equal-weighted market index (`indno = 1000001`). The earlier difference in market inputs has been resolved.

## Code and output checks

The saved Alternative A Table 2 file contains 180 unique portfolio-period records, covering 20 portfolios in each of nine periods. All numeric entries are finite. Comparing these records with the final Table 2 detailed output gives agreement within floating-point precision.

The output distinguishes the mean individual beta from the beta estimated using portfolio returns. The displayed regression standard error is taken from the portfolio-return regression. Individual and portfolio residual risk are calculated using the sample standard deviation of fitted residuals.

Expected and valid member counts are saved alongside portfolio returns. These counts show how many securities contribute to each monthly average and make the available-case calculation straightforward to check.

## Comparison with Alternative B

The testing-period comparison uses the same member-month panel to calculate an available-case benchmark and compare it with the saved Alternative B returns. The available-case rule retains all 8,040 portfolio-months, while the complete-month rule retains 7,584. Alternative A therefore retains 456 additional portfolio-months, approximately 5.7% of the total.

On the months retained by both rules, the maximum absolute return difference is zero. This is consistent with both methods taking the same equal-weighted average when every current member has a valid return.

These counts describe testing-period coverage. Table 2 uses separate estimation windows, where different usable months can produce different portfolio-regression statistics. The comparison therefore documents the effect of the missing-return rule without treating all A and B statistics as identical.

## Overall assessment

I support the group's selection of Alternative A for Decision 2 and the final Table 3 portfolio returns. It retains the observed returns of other members when one member's return is unavailable, while recording the changing number of contributors. Alternative B provides the corresponding complete-month comparison.

The selected approach is documented in the decision record and incorporated into the final workflow. The current code and exported results provide a clear record of how the available-case rule is applied.

## Evidence reviewed

- [Alternative A portfolio-return calculation](../code/decision2/alternative_A/04_portfolio_returns_altA.R)
- [Alternative A Table 2 calculation](../code/decision2/alternative_A/05_table2_output.R)
- [Alternative A detailed results](../output/tables/table2_altA.csv) and [final detailed results](../output/tables/table2_final_detailed.csv)
- [Shared-panel comparison code](../code/common/10_compare_dp2_returns.R) and [comparison results](../output/tables/decision2_return_comparison.csv)
- [Decision 2 record](../decisions/decision2.md)

AI assistance was used to inspect the code and outputs, compare exported results and draft this review. I remain responsible for its content and judgement.
