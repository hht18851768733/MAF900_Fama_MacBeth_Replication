# Decision Record

## Issue investigated

How should intermittent missing monthly return observations be treated when
determining whether a security has sufficient historical data to be included
in the replication sample? Fama and MacBeth (1973, p. 617) require a security
to have data for all 5 years of the preceding estimation period and at least
4 years of the portfolio-formation period, but do not specify how to handle a
security with one or more missing monthly returns inside those windows, nor
how to distinguish a security that was never listed during part of a window
from one that was listed but has gaps in its return data.

## Alternative A

A strict complete-case rule: a security must have a valid, non-missing
return in every month of the required window (48 of 48 formation months,
60 of 60 estimation months) to be included. Any gap disqualifies the
security for that period.

## Alternative B

A threshold rule: a security qualifies if it has a valid return
in at least 90% of the required months, allowing isolated gaps. Specifically:
- Estimation period: at least 54 of 60 months valid (90% of the paper's
  stated "all 5 years" requirement).
- Formation period: at least 44 of 48 months valid for Period 1 (whose
  formation window is exactly 48 months), and at least 48 of the available
  months valid for Periods 2-9 (whose formation windows run 84 months,
  but the paper's "at least 4 years" is read as a fixed 48-month minimum
  rather than a percentage of each period's specific window length).

Following group review, two refinements were incorporated:
1. Listed history (from CRSP exchange/share-code date ranges, `namedt` to
   `nameendt`) is checked separately from valid-return coverage. A security
   must be listed as NYSE common stock for the full formation window
   (≥48 months) and the full estimation window (=60 months), in addition
   to meeting the valid-return thresholds above. This separates "wasn't
   listed yet" from "was listed but has a data gap."
2. A single shared list of securities listed in the first month of each
   testing period is constructed once and used both to determine
   eligibility (a security must appear in this list to be eligible) and
   to compute the "securities available" count for Table 1, rather than
   each script independently deriving its own version of this list. A
   missing return alone does not remove a security from this list; only
   non-listing does.

## Expected differences

Alternative A was expected to produce a more uniform estimation sample but
exclude more securities due to isolated gaps, narrowing the sample and
potentially the range of betas available for portfolio sorting. Alternative
B was expected to retain more securities, at the cost of some securities'
betas being estimated on fewer effective observations than others.

Incorporating the listed-history check was expected to further reduce
Alternative B's eligible-security counts relative to the valid-returns-only
version, since it adds a genuinely separate requirement rather than relaxing
the existing one. The shared first-month list was expected to have a smaller
effect, since most securities with a valid return in a given month are also
listed in that month.

## Observed differences

[To be completed once Alternative A's results are available for comparison.]

Alternative B's eligible-security counts, after incorporating refinements: 390, 562, 588, 687, 733, 787, 839,
845, 821 across the nine periods, against the paper's reported 435, 576, 
607, 704, 751, 802, 856, 858, 845 — consistently 2-10% below the original.
Period 1 showed the largest gap (390 vs. 435, ~10%), likely reflecting the
stricter requirement that a security be listed at both the start of the
1926-29 formation window and the end of the 1930-34 estimation window, a
harder bar to clear in the earliest, smaller NYSE universe.


Securities-available counts, computed from the shared first-month list:
690, 761, 789, 894, 996, 1036, 1041, 1139, 1229, each within 1 unit of the
count derived directly from CRSP return rows prior to the refinement. This
indicates the listed-history distinction mattered substantially more for
the multi-year eligibility requirement than for the single-month
availability count. Both remained 2-3% below the paper's reported figures
(710, 779, 804, 908, 1011, 1053, 1065, 1162, 1261) across all nine periods.

## Review findings

[To be completed after the group reviews both implementations together,
per the Part 2 workflow. Initial review of Alternative B (recorded above)
identified two gaps: listed history was not checked separately from return
validity, and the "securities available" and eligibility calculations used
two independently derived first-month lists rather than one shared list.
Both were addressed in the implementation described above.]

## Selected approach

[To be completed.]

## Reason for the decision

[To be completed.]