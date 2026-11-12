# Explore Methyl Salicylate Production with SimBiology

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=ChezJe/iGEM&file=demos/simbiology/great-demo/demo.m)

Explore how pathway parameters affect simulated methyl salicylate production. This seven-minute demonstration uses a SimBiology model, its diagram, a parameter-slider program, and normalized local sensitivity analysis.

The badge opens the launcher; run its first section to open Model Analyzer. Sign in to MATLAB Online with access to SimBiology.

## File Manifest

| File / Directory | Description |
|---|---|
| `great-demo/demo.m` | Live Script launcher and Model Builder entry |
| `great-demo/openMeSDemo.m` | Relocatable Model Analyzer launcher |
| `great-demo/openMeSModel.m` | Relocatable Model Builder launcher |
| `great-demo/MeS_Production.sbproj` | Pathway model, diagram, analysis tasks, and saved results |
| `great-demo/baselineResults.mat` | Recomputed numerical checkpoint |
| `great-demo/simulateMeS.m` | Reproducible baseline, parameter change, and sensitivity computation |
| `great-demo/inspectProduction.m` | Supporting quantitative Live Script |

## Presentation Flow

1. **0:00–0:30:** Ask which modeled processes most influence product formation.
2. **0:30–1:30:** Open Model Analyzer and show the saved production result.
3. **1:30–3:00:** Open the Model Builder diagram and trace the pathway and gene-expression modules.
4. **3:00–5:00:** Return to the Sliders program. Run it and compare a change in `k3_transcription` from 0.0644 to 0.1288.
5. **5:00–6:00:** Run Sensitivity Analysis, focusing on `cell.MeS_1` at 250 seconds.
6. **6:00–7:00:** Explain how a mechanistic model helps prioritize experimental questions.

## Setup Instructions

1. Use MATLAB R2026b with SimBiology.
2. Open `great-demo/demo.m` and run its first section, or run the file by full path.
3. Call `openMeSModel` to open the saved diagram in Model Builder. Keep the displayed project changes unsaved during rehearsal unless you intend to retain them.
4. Run `inspectProduction.m` for the supporting numerical comparison. It recomputes baseline production, a parameter change, and local sensitivity.

## Presentation Notes

- This model is illustrative and was not calibrated against an experimental dataset for this demonstration. Review its biological assumptions and parameter values before applying it to an experiment.
- The pathway includes chorismate, isochorismate, salicylate, methyl salicylate, pchA, pchB, and BSMT1 expression modules.
- Keep time in seconds. The model intentionally mixes molecule counts and concentrations with unit conversion and dimensional analysis enabled. Methyl salicylate is reported in millimolarity.
- The sensitivity task uses `cell.MeS_1` as its output and a 250-second simulation horizon.
- Normalized sensitivity is local to the baseline. It neither establishes an optimum nor predicts an experimentally validated yield improvement.

[Back to the demo portfolio](../../README.md)
