# Implementation Review

## Reviewer

Bharat Goel

## Methodological implementation

Haitian's Alternative A applies a strict complete rule: a security must
have a valid, non-missing return in every month of the required window (all
48 months of formation, all 60 months of estimation). This is a more
conservative approach than Alternative B's threshold approach, and is internally
consistent with the definition set out in the group's Part 2 submission.

## Technical or data-handling issues

The securities available counts (690, 761, 789, 894, 996, 1036, 1041,
1139, 1229) match Alternative B's figures closely, which is expected since
availability depends only on listing status in the first testing month, not
on the eligibility rule being tested.

No specific code-level issues were identified on review.

## Plausibility of results

Alternative A's eligible-security counts are consistently and substantially
lower than both Alternative B's and the paper's published figures — e.g.,
Period 1: 269 vs. Alternative B's 390 vs. the paper's 435. This direction
is expected, since Alternative A's rule is strictly more
restricted than Alternative B's threshold rule.

## Recommended revisions

None. Great Job