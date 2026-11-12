# Introduction: Analyze Growth with Claude

Start with a smaller example before exploring the [virtual lab](../README.md). The Live Script analyzes synthetic plate-reader measurements using time-matched blank correction and a separate exponential-growth fit for each replicate.

Run `demo.m` from this folder, or use MATLAB `run` with its full path. MATLAB R2026b and Statistics and Machine Learning Toolbox are required. The analysis runs independently of an AI service.

## Files

| File | Purpose |
|---|---|
| `demo.m` | Completed growth-analysis Live Script |
| `data/plateReader.csv` | Three constructs, three replicates, and three blank wells |
| `data/generationTruth.csv` | Known synthetic rates for checking estimates |
| `generateGrowthData.m` | Seeded data generator |
| `loadGrowthData.m` | Read the measurement table |
| `analyzeGrowth.m` | Blank correction, fitting windows, and per-well estimates |
| `showGrowthResults.m` | Curves, selected fitting observations, and intervals |
| `prompts.md` | Prompts for an existing Claude–MATLAB connection |

Time is in hours and OD600 is dimensionless. The example fits observations between corrected OD600 0.05 and 0.30, requiring at least five observations. This window is a demonstration choice; inspect and adapt it for each assay. The data include lag, exponential, and stationary phases and are not experimental observations.
