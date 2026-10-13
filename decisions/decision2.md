# Decision Record

## Issue investigated

Fama and MacBeth calculate monthly returns for 20 portfolios by equally
weighting the individual securities. These portfolio returns are then used
to estimate portfolio risk measures and to run the monthly cross-sectional
regressions reported in Table 3 (Fama & MacBeth, 1973, pp. 616-619). The
paper does not explain what to do when a security is still part of the
portfolio, but its return is temporarily missing for one month. This is
different from a valid zero return or a documented delisting, so these
cases are identified separately before portfolio returns are calculated.

## Alternative A

Available-case equal weighting: the portfolio return for a month is the
arithmetic mean of the valid stock returns. A security with a temporary
missing return is left out for that month, and the remaining securities
are equally weighted. Expected portfolio size and the number of valid
returns are both tracked, so the change in effective membership can be
checked.

## Alternative B

Complete portfolio month: a portfolio return is calculated only when every
security on the current portfolio list has a valid return for that month.
If at least one current security has a temporary missing return, the
portfolio-month return is recorded as missing. Portfolio entry, exit and
delisting rules are applied first, so a genuine exit is not incorrectly
treated as temporary missingness.

A related, separate decision within Decision 2 concerns the market index
itself: Alternative A uses CRSP's published equal-weighted index (ewretd)
as the market return proxy, while Alternative B reconstructs the index
directly from NYSE-only security-level data, matching the paper's stated
"equally weighted average of all NYSE stocks" more literally.

## Expected differences

Alternative A was expected to keep more usable portfolio-month
observations, but the actual portfolio represented by the return could
change from month to month. Alternative B was expected to keep the
intended full-portfolio comparison, at the cost of removing some
portfolio-months entirely, potentially leaving some Table 3 months without
a complete 20-portfolio cross-section.

For the market-index question, Alternative B's NYSE-only reconstruction was
expected to track the paper's published Table 2 figures more closely than
Alternative A's ewretd-based approach, if ewretd's universe extends beyond
NYSE in parts of the sample period (e.g., AMEX securities from the
early-to-mid 1960s).

## Observed differences

To be completed after implementation.

## Review findings

To be completed.

## Selected approach

To be completed.

## Reason for the decision

To be completed.
