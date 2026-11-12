# Growth Analysis with Claude and MATLAB

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=ChezJe/iGEM&file=demos/agentic/great-demo/demo.m)

Turn synthetic plate-reader measurements into a checked growth analysis. This seven-minute demonstration combines an existing Claude–MATLAB connection with a Live Script that also runs independently.

The badge opens the prepared Live Script; select **Run**. A live Claude session is a separate workflow and is not launched by the badge.

## File Manifest

| File / Directory | Description |
|---|---|
| `great-demo/demo.m` | Completed analysis in plain-text Live Script format |
| `great-demo/generateGrowthData.m` | Reproducible synthetic data generator |
| `great-demo/loadGrowthData.m` | CSV loading and schema checks |
| `great-demo/analyzeGrowth.m` | Shared blank correction and per-well fitting |
| `great-demo/showGrowthResults.m` | Growth and diagnostic visualizations |
| `great-demo/data/` | Plate-reader measurements and generation truth |
| `live-build-start/` | Starting instructions and prepared recovery |
| `prompts.md` | Three prompts for the live Claude workflow |

## Presentation Flow

1. **0:00–0:30:** Ask which construct changes growth.
2. **0:30–1:30:** Open and run `great-demo/demo.m`; show curves, fit windows, and replicate estimates.
3. **1:30–5:00:** Use the three prompts to inspect, implement, and check the analysis with Claude.
4. **5:00–6:00:** Inspect a selected fitting window or demonstrate the insufficient-data check.
5. **6:00–7:00:** Explain the reusable pattern: inspect assumptions, execute code, and verify observable behavior.

## Setup Instructions

1. Use MATLAB R2026b with Statistics and Machine Learning Toolbox.
2. Open the `great-demo` folder and run `demo.m`, or run it by full path with MATLAB `run`.
3. For the live segment, use an already configured Claude client with access to MATLAB and this demo folder. Rehearse that connection before presenting.
4. To regenerate bundled data, run `generateGrowthData` from `great-demo`. The prompt sequence includes checks against the known synthetic growth rates.

## Presentation Notes

- Data are synthetic: three constructs, three culture replicates each, three blank wells, and 12 hours sampled every 7.5 minutes. Time is hours; OD600 is dimensionless.
- Rates are fit per replicate after time-matched blank subtraction. The OD600 range 0.05–0.30 is a demonstration assumption, not a universal exponential-phase criterion.
- Confidence intervals describe the fitted slope conditional on its window. They do not account for every source of biological uncertainty.
- The data contain lag, exponential, and stationary phases. Inspecting the selected observations matters more than trusting a returned number.
- `live-build-start/recovery.m` uses the prepared result. Identify it clearly if needed.

[Back to the demo portfolio](../../README.md)
