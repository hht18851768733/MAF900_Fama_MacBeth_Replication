# Decision 1 — Table 1 Sample Eligibility

**Group:** Haitian Hu and Bharat Goel  
**Decision date:** 11 October 2026  
**Selected approach:** Alternative B, implemented by Bharat Goel and agreed at the group meeting.

## Issue investigated

We compared two ways of handling missing monthly stock returns when determining eligibility for Table 1. The purpose was to distinguish insufficient listed history from missing returns within an otherwise eligible history, while keeping the formation, estimation and testing calendar windows unchanged.

The 90% tolerance and the consecutive-month condition described below are our implementation choices. They are not thresholds or continuity requirements explicitly imposed by the paper or the assignment.

## The two alternatives

Haitian implemented Alternative A; Bharat implemented Alternative B.

| Requirement | Alternative A | Alternative B |
| --- | --- | --- |
| First formation period: 48 calendar months | All 48 monthly returns valid | At least 44 valid monthly returns |
| Later formation periods: 84 calendar months | At least one run of 48 consecutive valid calendar months within the window | At least 48 valid monthly returns within the window; continuity not required |
| Estimation period: 60 calendar months | All 60 monthly returns valid | At least 54 valid monthly returns |

Both alternatives also require:

- NYSE common-stock classification and the same downloaded input data for the comparison.
- At least 48 listed months within the formation window and all 60 listed months within the estimation window, checked separately from valid returns.
- Listing in the first testing month. A missing return in that month alone does not remove a security from the candidate roster.
- The same first-testing-month roster for eligibility and the Table 1 availability count.

B's 90% threshold applies to the first formation period (`ceiling(0.90 * 48) = 44`) and every estimation period (`0.90 * 60 = 54`). For later formation periods, the threshold is a fixed 48 valid months, not 90% of 84 months or of each security's listed history.

The later formation windows remain 84 months long. A does not require 84 valid months, and B does not require 76. The last testing period ends in June 1968.

## Expected differences

We expected B to retain all securities selected by A and admit additional securities with incomplete or interrupted return histories. A provides complete estimation returns and a continuous qualifying formation history. B permits fewer valid observations and different effective observation counts across securities.

These are sample-selection trade-offs. Neither greater sample size nor stricter completeness alone establishes better beta estimates.

## Observed differences

The local comparison used the same input snapshot. The first-testing-month candidate lists matched, and A was a subset of B in every period.

| Period | Available | A eligible | B eligible | B minus A |
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

B adds 351 security-period observations across the nine periods. Of these, 134 fail only A's formation rule, 183 fail only A's estimation rule, and 34 fail both. These are security-period counts, not counts of unique securities across the whole study. No A-only observations were found.

The observed differences are therefore consistent with the intended missing-return rules. Their implications for beta estimates and portfolio results have not yet been established by these diagnostics.

## Key review findings

The inspected B implementation applies the agreed thresholds, separates listed history from valid-return coverage, and reuses its saved first-month roster in the Table 1 script. The comparison code checks candidate identities as well as sample counts. Based on the inspected code, reported local execution and saved diagnostics, no substantive error affecting the current Table 1 results was identified.

The main clarification is methodological: allowing 54 valid returns within the 60-month estimation window is a group-defined tolerance, not the same as requiring 60 valid returns. Similarly, B's later formation rule can allow substantial gaps because it requires 48 valid months within 84 months.

Individual review records are maintained separately in [the review of A](../reviews/decision1_A_review.md) and [the review of B](../reviews/decision1_B_review.md). This joint decision record does not replace either student's reciprocal review.

## Selected approach and reason

We agreed at our meeting on 11 October 2026 to use **Bharat's Alternative B** for the final Table 1 sample and as the common starting point for Table 2.

We prefer B because it allows incomplete return histories while retaining explicit listed-history requirements and the original calendar windows. A's consecutive formation requirement and complete estimation requirement exclude additional securities; our comparison makes those exclusions visible. We accept B's tolerance as a practical implementation choice for this replication and retain A as the stricter comparison.

The decision is not based solely on retaining more securities or obtaining counts closer to the published table. We do not claim that B eliminates selection bias or produces more accurate beta estimates.

## Implementation and next steps

1. Incorporate B's sample-construction and Table 1 logic into `code/final/`, using shared code where appropriate. The final workflow must recreate its inputs without depending on scripts or intermediate results produced only by the alternative-development folders.
2. Preserve both DP1 implementations, their outputs and reciprocal reviews in the repository.
3. Use the selected DP1 sample as the common basis for both DP2 alternatives. Hold the market data, portfolio formation and membership rules constant when comparing their missing-return treatments.
4. Record the DP2 choice separately in `decisions/decision2.md`. Selecting B for DP1 does not select a DP2 alternative.

## Supporting evidence

- [Comparison summary](../output/tables/decision1_comparison_summary.csv)
- [Exclusion diagnostics](../output/tables/decision1_exclusion_summary.csv)
- [Comparison code](../code/common/04_compare_decision1.R)
- [Alternative B sample construction](../code/decision1/alternative_B/02_sample_construction.R)
- [Methodology clarification](../part3_methodology_clarification.md)

AI assisted with code inspection, diagnostic summaries and drafting. The group remains responsible for the methodological choice and the accuracy of this record.
