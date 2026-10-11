# Implementation Review — Decision 1, Alternative B

## Reviewer

Haitian Hu — review of Bharat Goel's Alternative B.

Group decision update — 11 October 2026: the group agreed at its meeting to adopt Bharat Goel's Alternative B for DP1.

## Methodological implementation

The current implementation is consistent with our agreed Alternative B eligibility rules:

- A security must be listed as NYSE common stock in the first month of the testing period. A missing return in that month does not, by itself, exclude it.
- Listed-history coverage is checked separately from return availability: at least 48 listed months within the formation window and all 60 months of the estimation window.
- The first formation period requires at least 44 valid returns out of 48 months.
- Later formation periods require at least 48 valid monthly returns within the full 84-month window. These observations need not be consecutive.
- Every estimation period requires at least 54 valid returns out of 60 months.

The 90% thresholds for the first formation period and the estimation periods are group implementation choices for handling missing returns. They should not be presented as requirements explicitly specified by the paper or the assignment. In particular, 54/60 permits missing returns within a five-year estimation window; it is not equivalent to requiring 60 valid returns.

The calendar windows remain unchanged. Later formation windows are not shortened to 48 months, and the final testing period ends in June 1968.

## Technical or data-handling issues

The code separates listing coverage from valid-return coverage and uses `!is.na(ret)` to identify valid returns, retaining zero returns. Listing months are deduplicated by security and calendar month.

The sample-construction and Table 1 scripts reuse the same saved first-testing-month roster. The comparison script also checks the identities of A's and B's first-month candidates, rather than comparing only their counts. The reported local run passed this check.

Both alternatives were run locally using the same downloaded input files. Based on the inspected scripts, reported execution and saved comparison outputs, no substantive implementation error affecting the current Table 1 results was identified. This conclusion is limited to sample construction and Table 1; it does not establish the accuracy of downstream beta estimates or portfolio results.

## Plausibility of results

B contains every security selected by A in all nine periods. No A-only security-period observations were found. This is consistent with B's weaker valid-return requirements: A requires complete first-period formation returns, a consecutive 48-month valid-return run in later formation windows, and 60 valid estimation returns.

| Period | Available | A eligible | B eligible | Additional under B |
| --- | ---: | ---: | ---: | ---: |
| 1 | 690 | 269 | 390 | 121 |
| 2 | 761 | 465 | 562 | 97 |
| 3 | 789 | 554 | 588 | 34 |
| 4 | 894 | 662 | 687 | 25 |
| 5 | 996 | 727 | 733 | 6 |
| 6 | 1036 | 784 | 787 | 3 |
| 7 | 1041 | 823 | 839 | 16 |
| 8 | 1139 | 820 | 845 | 25 |
| 9 | 1229 | 797 | 821 | 24 |

Across periods, B adds 351 security-period observations: 134 fail only A's formation rule, 183 fail only A's estimation rule, and 34 fail both. These are repeated period-level observations, not necessarily 351 distinct securities. The diagnostics therefore explain the differences through the intended eligibility rules.

A larger sample does not by itself demonstrate better estimates. B's later-period requirement of 48 valid months within 84 months can permit substantial gaps, and its estimation rule permits up to six missing returns. These are methodological trade-offs to acknowledge in the decision record.

## Recommended revisions

No change to B's current eligibility thresholds is requested on the evidence reviewed. In the joint decision record, explain the group-defined missing-return tolerance and include the observed comparison and exclusion diagnostics.

I support adopting B as the main DP1 approach, as agreed at our group meeting, while retaining A as the stricter comparison. B allows incomplete return histories while preserving the agreed listing-history requirements and calendar windows. This recommendation concerns the sample-selection policy; it is not a claim that B produces less biased or more accurate beta estimates.

Record the agreed selection in `decisions/decision1.md` and incorporate B into the `code/final/` workflow as the common starting point for both DP2 alternatives. Both reciprocal review files should remain in the repository. Selecting B for DP1 does not determine the DP2 choice, which still requires its own comparison, reviews and joint decision.

## Evidence reviewed

- [B sample-construction code](../code/decision1/alternative_B/02_sample_construction.R)
- [B Table 1 code](../code/decision1/alternative_B/03_table1_securities_available.R)
- [Comparison and diagnostic code](../code/common/04_compare_decision1.R)
- [Comparison summary](../output/tables/decision1_comparison_summary.csv)
- [Exclusion summary](../output/tables/decision1_exclusion_summary.csv)
- Reported local execution using the same input snapshot for A and B.

AI assistance was used to inspect code, summarise diagnostics and draft this review. The reviewer remains responsible for the review's content and methodological judgement.
