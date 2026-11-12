# Five MATLAB Demos for iGEM 2026

Explore five ways to use MATLAB in synthetic biology: model a pathway, inspect a protein prediction, quantify microscopy images, calibrate a biosensor, and create a reproducible analysis with an AI agent. Each demonstration takes about seven minutes and is designed for student teams with mixed programming experience.

## Demo Portfolio

| Demo | Scientific question | Great Demo interface | Required products beyond MATLAB |
|---|---|---|---|
| [Methyl salicylate production](demos/simbiology/README.md) | Which modeled processes influence product formation? | SimBiology Model Builder and Model Analyzer | SimBiology |
| [PETase structure with AlphaFold](demos/alphafold/README.md) | Which regions of a predicted structure have high local confidence? | Biopipeline Designer | Bioinformatics Toolbox |
| [Reporter expression from microscopy](demos/microscopy/README.md) | How does reporter expression vary from cell to cell? | Custom uifigure app, saved as App Designer `.m` and `.xml` | Image Processing Toolbox |
| [Fluorescent biosensor calibration](demos/biosensor/README.md) | Which sensor can quantify this sample reliably? | Custom uihtml app with MATLAB analysis | None |
| [Growth analysis with Claude](demos/agentic/README.md) | Can an agent turn raw measurements into a checked growth analysis? | Live Claude integration and an independent Live Script | Statistics and Machine Learning Toolbox; existing Claude connection for the live segment |

Every demo README contains its own **Open in MATLAB Online** badge. The badge imports the repository and opens that demo's entry file; select **Run** to start. Sign in with a MathWorks Account that has access to the required products.

## File Manifest

| File / Directory | Description |
|---|---|
| `demos/` | Five independently documented demo packages |
| `launchIGEMDemo.m` | Common desktop launcher |
| `demos/*/great-demo/` | Completed apps, saved analyses, and Live Script entry points |
| `demos/*/walkthrough/` | Explanatory Live Scripts for inspecting and adapting the analyses |
| `demos/agentic/prompts.md` | Prompts for the Claude–MATLAB workflow |
| `demos/*/data/` and demo-specific data folders | Bundled datasets, generation truth, and source information |

## Presentation Flow

1. Choose a demonstration from the table and read its presenter notes.
2. Open the completed app or Live Script and show the result first.
3. Explain the workflow in three focused steps. Microscopy and biosensor walkthroughs use the same MATLAB analysis functions as their apps.
4. Change one meaningful input and inspect the result.
5. Finish with the scientific takeaway and the demo's Online link.

Each demo allocates 30 seconds to the question, 1 minute to the completed result, 3.5 minutes to the walkthrough, 1 minute to an interaction, and 1 minute to the takeaway. Presenting all five takes approximately 35 minutes. No slide deck is required.

## Setup Instructions

1. Use MATLAB R2026b. The microscopy app's plain-text App Designer format requires this release or newer.
2. Ensure the products listed for the chosen demo are installed and licensed.
3. From this repository folder, launch a demo:

   ```matlab
   launchIGEMDemo("microscopy")
   ```

   Other names are `"simbiology"`, `"alphafold"`, `"biosensor"`, and `"agentic"`.

4. Follow the selected demo README to explore its controls, open its walkthrough, or regenerate the synthetic data.
5. For the live agentic demonstration, use an existing Claude client connected to MATLAB and follow `demos/agentic/prompts.md`.

## Presentation Notes

- The three experimental datasets are explicitly synthetic and include reproducible generators. They illustrate workflows, not results from an actual iGEM team.
- The SimBiology model illustrates pathway hypotheses. It was not calibrated against experimental measurements for this demonstration.
- The PETase data are an attributed AlphaFold DB prediction under CC BY 4.0. Cached data support the offline opening; live mode uses the public EMBL-EBI service without a key.
- AlphaFold confidence does not establish protein activity. Biosensor EC50 does not establish a detection limit. Inspect growth windows and segmentation overlays before interpreting results.
- The custom apps open with prepared results and focused controls. Use the accompanying Live Scripts to inspect or adapt the calculations.
- Claude uses an existing presenter connection. The finished growth analysis runs independently; clearly identify the prepared recovery if used.
- The demos require no third-party executable or downloaded JavaScript library.

## Data and Attribution

See each demo README for its dataset, units, assumptions, and source attribution.
