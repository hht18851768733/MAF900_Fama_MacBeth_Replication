# Table 3 statistics notes

Selected pipeline: Decision 1 B and Decision 2 A; published CRSP NYSE equal-weighted market index.
Four monthly OLS specifications, each using 20 equally weighted portfolios and an intercept.
Individual risk estimates expand from 5 to 8 years and use data through the preceding December.
Monthly portfolio risks average current listed members. Temporary missing returns do not remove a pre-estimated risk; A portfolio returns average finite returns. Their denominators can therefore differ.
beta2 is the mean of squared individual betas. Non-beta risk is mean individual residual SD, calculated using sd(residuals) in the individual regressions.

## Reporting samples and units

The ten original Table 3 reporting samples overlap. They differ from the nine formation/testing periods; they must not be pooled or added together.
Expected months: 402, 132, 120, 150, 72, 60, 60, 60, 60, 90, in sample_id order.
Returns and RF are monthly decimals. No percentage rescaling or annualization is applied to coefficients.

## Summary definitions

Coefficient means and sample SDs are computed across monthly cross-sectional estimates. Sample SD uses n-1. SE(mean) = SD/sqrt(n), and t = mean/SE(mean). No HAC/Newey-West adjustment is applied to the primary replication.
Monthly cross-sectional coefficient SEs are not used as SEs of time-series means.
For the gamma0-RF test, subtract RF month by month first; use the SD of this difference series in its t-statistic.
The reported R-squared mean and SD use monthly adjusted R-squared, as specified on p. 619. Negative adjusted values are retained.
Serial correlations use lag one. rho_M(gamma1) is centered at the full reporting-sample mean; rho_0(gamma0-RF), rho_0(gamma2), and rho_0(gamma3) are centered at zero.
Implementation convention: rho = sum(z[t]*z[t-1], t=2..n) / sum(z[t]^2, t=1..n), with z=x-center. The paper specifies centering but does not give this finite-sample denominator explicitly.
Omitted gamma2/gamma3 statistics are NA (not zero). No missing observations are silently dropped.

## RF provenance

Provider: Kenneth French Data Library. Series: F-F Research Data Factors: RF (one-month Treasury bill).
Source: https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip
Raw ZIP MD5: cf6a400f83fa4137582d251d9084c1fe
RF was divided by 100 once to convert monthly percent to decimal. Negative RF observations are retained.
Modern downloaded series; not verified against the original 1973 RF vintage.

Reference: Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. Journal of Political Economy, 81(3), 607-636. https://doi.org/10.1086/260061
Table 3 definitions and reporting periods: pp. 619, 622-623.
