# Claude presenter prompts

Use your existing Claude client connected to MATLAB. Start a fresh working copy in `live-build-start/`; keep the prepared reference in `great-demo/` available for recovery. No installation or API key is part of this demo.

## 1. Inspect and propose

> Inspect `../great-demo/data/plateReader.csv` in MATLAB. It contains synthetic OD600 measurements. Explain the schema, identify blank and culture wells, and propose how to compare growth between constructs. Do not edit the supplied data. Make the time units, blank correction, replicate handling, and fitting assumptions explicit.

## 2. Implement and execute

> Create a plain-text MATLAB Live Script named `claudeGrowthAnalysis.m` in this folder. Subtract the mean blank at each matching time. Fit log corrected OD600 separately for every well using observations between 0.05 and 0.30 and at least five points. Report rate in inverse hours, doubling time in hours, fit intervals, and insufficient windows. Preserve nonpositive measurements in the inspected data and exclude them from logarithms. Show the selected observations and compare all replicates. Run the script with MATLAB and inspect the results.

## 3. Check the result

> Check the script with MATLAB Code Analyzer. Verify the results are unchanged when CSV rows are reordered. Confirm that removing blank wells raises a clear error and that an acquisition too short to contain an exponential window is flagged. Compare estimated rates against `../great-demo/data/generationTruth.csv` only now, as a verification step. Explain what these checks establish and what they do not establish.

## Recovery

If the connection or generation fails, state that you are switching to the prepared result, then run `recovery.m`. Do not present the prepared script as a transcript of a live Claude run. The repository does not contain a fabricated agent-session recording.
