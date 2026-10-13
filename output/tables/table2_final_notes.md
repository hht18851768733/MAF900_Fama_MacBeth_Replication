# Final Table 2 notes

Selected pipeline: DP1-B and DP2-A available-case equal weighting.
Market input: published CRSP NYSE equal-weighted index 1000001 (mthtotret).

The displayed beta is the mean individual beta (beta_portfolio).
The displayed SE belongs to the portfolio-return regression (se_beta_correct),
whose beta is beta_from_portfolio_regression in the detailed output.
The detailed se_beta_portfolio field is sd(individual betas)/sqrt(n);
it is a cross-security dispersion diagnostic, not a regression standard error.
Individual and portfolio residual risk use sample SD of fitted residuals.
The displayed periods 2, 4, 6 and 8 have estimation windows 1934-1938,
1942-1946, 1950-1954 and 1958-1962, respectively.

Shared preparation and the selected A calculations are retained from the
group's implementations. Integration changes paths, output names and checks;
it does not introduce a different missing-return rule.
The final testing return file supplies Table 3; it is separate from the
60-month estimation-window returns used to calculate Table 2.
