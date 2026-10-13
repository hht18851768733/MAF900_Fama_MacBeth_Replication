# Implementation Review

## Reviewer

Haitian Hu  
Date: 13 October 2026

This review is based on the uploaded Alternative A code and Table 2 outputs, rather than an independent rerun of the raw data.

## Methodological implementation

I found Bharat's Alternative A clearly organised, with separate scripts for portfolio formation, risk estimation and portfolio returns. The available-case calculation takes the equal-weighted average of observed member returns and retains valid zero returns. The detailed and display tables also make the results easy to follow.

## Differences between the alternatives

Alternative A uses the available member returns in each month, while Alternative B requires every expected member to have a valid return. With the same inputs and membership, both methods give the same portfolio return when all member returns are observed.

Their main difference appears in incomplete months. A can retain these months by averaging the remaining observed returns, which helps preserve time-series coverage. B retains only complete portfolio-months, keeping all expected members represented in each reported monthly return.

These approaches highlight a useful trade-off between observation coverage and completeness of member returns. Different usable months and effective weights can lead to differences in estimated beta, R-squared and residual risk. The current workflows also use different market inputs, so differences in their existing tables cannot be attributed solely to missing-return treatment.

## Overall assessment

A provides a clear and practical implementation of available-case equal weighting. Its uploaded detailed table contains 180 unique portfolio-period records with no missing numeric values, and the basic ranges of R-squared and standard deviations are plausible. Together, the two approaches help explain how missing-return choices affect the information retained for portfolio analysis.

AI assistance was used to inspect the uploaded code and outputs and draft this review. I remain responsible for its content and judgement.
