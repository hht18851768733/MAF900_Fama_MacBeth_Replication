# Comparison with Fama and MacBeth (1973)

This note compares our final Tables 1–3 with the published results in Fama and MacBeth (1973). Our final specification uses **DP1-B** for sample eligibility and **DP2-A** for portfolio returns. The Table 3 testing sample covers January 1935 to June 1968, with 20 portfolios in each of 402 months.

The comparison uses the final exports in this repository at commit `2419516`. Published values are taken from Tables 1–3 on pages 618–623 of the original paper. Numerical agreement is closest for the simple linear model; the nonlinear specifications show more noticeable differences.

## Table 1: Sample construction

The formation, initial estimation and testing windows follow the paper's nine-period structure. The numbers of available and eligible securities are lower in our sample in every period.

| Testing period | Published available | Our available | Published eligible | Our eligible |
| --- | ---: | ---: | ---: | ---: |
| 1935–1938 | 710 | 690 | 435 | 390 |
| 1939–1942 | 779 | 761 | 576 | 562 |
| 1943–1946 | 804 | 789 | 607 | 588 |
| 1947–1950 | 908 | 894 | 704 | 687 |
| 1951–1954 | 1011 | 996 | 751 | 733 |
| 1955–1958 | 1053 | 1036 | 802 | 787 |
| 1959–1962 | 1065 | 1041 | 856 | 839 |
| 1963–1966 | 1162 | 1139 | 858 | 845 |
| 1967–June 1968 | 1261 | 1229 | 845 | 821 |

The eligible-sample shortfall ranges from 13 to 45 securities. Both samples show a substantial increase in eligible securities over time, followed by a small decline in the final period.

Our counts reflect the current CRSP extract, the NYSE common-stock filters, listing-history checks and the selected DP1-B return-availability rules. These do not reproduce the historical sample exactly. Since the available-security counts already differ before the final eligibility screen, the difference cannot be attributed solely to the missing-return threshold.

Source: [Final Table 1](output/tables/table1_final.csv).

## Table 2: Portfolio risk characteristics

The following comparison uses portfolios 1 and 20 in the four estimation periods displayed in the original Table 2. Each pair reports **portfolio 1 / portfolio 20**. Beta is the average of the constituent securities' estimated betas; return SD is the standard deviation of monthly portfolio returns, in decimal units.

| Estimation period | Published beta | Our beta | Published return SD | Our return SD |
| --- | ---: | ---: | ---: | ---: |
| 1934–1938 | 0.322 / 1.458 | 0.328 / 1.512 | 0.040 / 0.160 | 0.041 / 0.166 |
| 1942–1946 | 0.467 / 1.661 | 0.451 / 1.600 | 0.035 / 0.106 | 0.034 / 0.103 |
| 1950–1954 | 0.418 / 1.527 | 0.428 / 1.525 | 0.019 / 0.060 | 0.019 / 0.061 |
| 1958–1962 | 0.626 / 1.388 | 0.643 / 1.445 | 0.030 / 0.063 | 0.031 / 0.066 |

The selected portfolios reproduce the broad risk ordering in the paper: portfolio 20 has a higher beta and more variable returns than portfolio 1 in each period. The magnitudes are also reasonably close. For example, the 1950–1954 portfolio-20 beta is 1.525 in our results and 1.527 in the paper.

The diversification pattern is similar as well. For portfolio 20 in 1950–1954, the ratio of portfolio residual SD to average individual residual SD is 0.279 in our results, compared with 0.273 in the paper. Both indicate that portfolio formation substantially reduces residual variation.

This is a comparison of selected endpoints, rather than a claim that every Table 2 entry matches.

Sources: [Final Table 2 display](output/tables/table2_final_display.csv) and [detailed statistics](output/tables/table2_final_detailed.csv).

## Table 3: Risk–return regressions

For the full sample, Panel A includes beta; Panel B adds the mean of individual squared betas; Panel C adds average individual residual SD; and Panel D includes all three risk variables.

In the table below, each entry reports the **mean monthly coefficient (t-statistic)**. Gamma 1 is the coefficient on beta, gamma 2 on squared beta, and gamma 3 on residual risk. A dash denotes an omitted regressor.

| Panel | Statistic | Published result | Our result |
| --- | --- | ---: | ---: |
| A | Gamma 1 | 0.0085 (2.57) | 0.0084 (2.56) |
| B | Gamma 1 | 0.0105 (1.79) | 0.0198 (3.08) |
| B | Gamma 2 | −0.0008 (−0.29) | −0.0055 (−2.07) |
| C | Gamma 1 | 0.0072 (2.20) | 0.0114 (3.11) |
| C | Gamma 3 | 0.0198 (0.46) | −0.0668 (−1.60) |
| D | Gamma 1 | 0.0114 (1.85) | 0.0212 (3.18) |
| D | Gamma 2 | −0.0026 (−0.86) | −0.0063 (−2.06) |
| D | Gamma 3 | 0.0516 (1.11) | −0.0047 (−0.11) |

**The simple linear result is very close.** In Panel A, the estimated monthly beta premium is approximately 0.84% per unit of beta, compared with 0.85% in the paper. The t-statistics are almost identical. The mean intercept also rounds to 0.0061 in both sets of results.

**The squared-beta result differs.** The original full-sample squared-beta coefficients are not statistically significant. Our coefficients are more negative, with t-statistics of −2.07 and −2.06. Under the conventional two-sided 5% t-test, these provide modest evidence of curvature. Our results therefore do not reproduce the paper's full-sample finding of no detectable nonlinearity.

**Residual risk remains statistically insignificant.** The residual-risk coefficients change sign relative to the paper, but neither is significant at the conventional two-sided 5% level in our results. This is consistent with the paper's lack of evidence that residual risk commands a separate premium.

Average adjusted R-squared is similar: the published values for Panels A–D are 0.29, 0.32, 0.32 and 0.34, compared with 0.30, 0.32, 0.32 and 0.33 in our results. These comparisons concern the full sample; they do not establish agreement in every subperiod.

Sources: [Full-sample Table 3](output/tables/table3_full_sample_display.csv), [all reporting periods](output/tables/table3_all_periods_display.csv) and [statistical definitions](output/tables/table3_statistics_notes.md).

## Interpretation of the differences

The replication preserves the main portfolio-risk pattern, closely matches the simple linear risk premium, and finds no statistically significant residual-risk premium. The main substantive difference is the stronger negative squared-beta coefficient.

Differences in sample membership, missing-return treatment and the historical data available in the current CRSP extract are possible contributors. DP2-A calculates each monthly return from currently eligible portfolio members with valid returns, while DP1-B determines the securities entering the portfolios. These choices affect portfolio composition and estimated risk characteristics. Their individual contributions to the gap from the published results have not been isolated.

The comparison therefore supports substantial agreement on several central results, while documenting a specific difference in the nonlinear regressions. Further details of our implementation are recorded in [the methodology note](part3_methodology_clarification.md).

## Reference

Fama, E. F., & MacBeth, J. D. (1973). Risk, return, and equilibrium: Empirical tests. *Journal of Political Economy, 81*(3), 607–636. Numerical comparisons above use Tables 1–3, pp. 618–623.

