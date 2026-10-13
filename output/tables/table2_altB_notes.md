# Table 2 — Alternative B: output notes

## Scope

These tables use five-year estimation-period data.
They do not use testing-period portfolio returns.

The main display includes periods 2, 4, 6 and 8:
1934–1938, 1942–1946, 1950–1954 and 1958–1962.
A separate display includes all nine periods.

## Missing-return treatment

The selected DP1-B sample and formation assignments are fixed.
A portfolio-month return is calculated only when every assigned
member has a valid monthly return. Otherwise it is missing.
Valid zero returns are retained; missing returns are not filled.

## Beta and standard-error definitions

Mean individual beta averages the initial individual estimates,
using each stock's own valid estimation-period observations.

Portfolio-regression beta is estimated from complete portfolio
months paired with market returns. Its reported standard error
comes from that same OLS regression.

With missing data, these two beta estimates need not coincide.
The portfolio-regression SE is not reported as the SE of the
mean individual beta.

This is an extended presentation with an additional beta row,
rather than an exact seven-row reproduction of the paper.
Both alternatives need the same definitions for a fair comparison.

## Other statistics

R-squared, portfolio return SD and portfolio residual SD use
the valid portfolio-market pairs in the estimation window.
Residual SD is calculated with R's sd() function.

Mean individual residual SD averages the individual estimates
from each stock's own valid estimation-period observations.
The residual-SD ratio therefore compares measures that may
use different effective sets of months when data are missing.

Returns and return SDs are in decimal units, not percentages.
Display values are rounded to three decimals.
Unrounded values and observation counts are retained in
table2_altB_detailed.csv.

The separate testing-period return comparison is a diagnostic;
it is not the estimation-period Table 2 comparison.
