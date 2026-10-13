# Decision Record

## Issue investigated

Fama and MacBeth calculate monthly returns for 20 portfolios by equally weighting the individual securities. These returns are used to estimate portfolio risk measures and in the monthly cross-sectional regressions reported in Table 3 (Fama & MacBeth, 1973, pp. 616–619). The paper does not specify how to handle a temporarily missing return for a security that remains a portfolio member. We therefore compare two rules, distinguishing temporary missingness from valid zero returns and changes in listing status.

## Alternative A

Available-case equal weighting: the monthly portfolio return is the arithmetic mean of the valid returns of current members. A security with a temporarily missing return is excluded from that month's average, and the remaining securities receive equal weights. Expected membership and valid-return counts are recorded. A month with no valid constituent returns remains missing.

## Alternative B

Complete portfolio month: the monthly portfolio return is calculated only when every current member has a valid return. If any current member has a temporarily missing return, the portfolio-month return is recorded as missing. The same listing-status rules are applied before either alternative calculates returns.

## Common inputs

Both alternatives use the Decision 1 Alternative B sample, the same portfolio assignments and the same individual risk estimates. Both also use CRSP's published NYSE equal-weighted market index, saved as `data/raw/common/market_index_nyse_ew.rds`.

This index is not reconstructed from our selected securities. The earlier difference in market-index inputs has been removed so that the comparison isolates the treatment of missing constituent returns.

## Expected differences

Alternative A was expected to retain more usable portfolio-months, although effective membership and weights could change when returns were missing. Alternative B was expected to preserve complete coverage of current members within each retained portfolio-month, at the cost of losing observations.

Where all current members have valid returns, both rules should produce the same equal-weighted return. Differences in Table 2 portfolio regressions can arise because the rules retain different estimation months.

## Observed differences

The comparison calculated directly from the shared testing-period panel produced 8,040 usable portfolio-months under the available-case rule and 7,584 under the complete-month rule. Alternative B therefore excluded 456 portfolio-months, or approximately 5.7% of the total, that were retained under Alternative A.

For the portfolio-months retained by both rules, the maximum absolute return difference was zero. This confirms that the difference in this comparison concerns coverage rather than the averaging formula when all current members have valid returns.

These figures describe the testing-period panel. They are not observation counts for the separate 60-month estimation windows used in Table 2 and do not establish that the two alternatives produce identical Table 2 statistics.

## Review findings

The review highlighted a useful trade-off between retaining available information and requiring complete constituent coverage. Alternative A provides greater continuity in portfolio returns, while Alternative B makes the effect of imposing full monthly coverage transparent.

Using the same NYSE index, portfolio assignments and individual risk estimates makes this comparison easier to interpret. Tracking expected and valid member counts also makes Alternative A's changing effective membership visible. The distinction between mean individual beta and the standard error from the portfolio-return regression is clarified through the statistic labels.

## Selected approach

We select Alternative A, available-case equal weighting, for the final Decision 2 implementation and the portfolio returns used in Table 3. Alternative B is retained as the comparison.

## Reason for the decision

Alternative A retains the observed returns of other portfolio members when one member's return is temporarily missing. In the shared-panel comparison, it preserves 456 additional portfolio-months, which helps maintain usable portfolio observations for the monthly cross-sectional regressions.

The trade-off is that effective membership changes when constituent returns are missing. We retain membership and valid-return counts so this limitation is transparent. Alternative B remains useful for showing how a stricter completeness requirement affects coverage.

Because the paper does not explicitly resolve this missing-return case, we treat the selection as a documented replication judgment rather than a claim that Alternative A exactly reproduces the authors' original missing-data procedure.

