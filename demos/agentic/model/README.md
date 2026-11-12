# Reporter expression with growth burden

This **illustrative, uncalibrated SimBiology model** is the experiment engine for the virtual laboratory. It links transcription, translation, reporter maturation, degradation, and growth dilution. Its parameters and observation noise explain the workflow; they are not fitted to experimental measurements.

Both responses come from **one eight-hour `sbiosimulate` run for the selected condition**:

- **Fluorescence (a.u.)** is mature-reporter concentration divided by 1 nM. It represents a linear reporter readout, not a calibrated instrument measurement.
- **Relative growth** is the terminal specific growth rate divided by the unburdened reference rate, 0.8 h⁻¹. It is not a ratio of biomass, OD600, or cell counts. A requirement of 90% means an observed normalized specific growth rate of at least 0.90.

## Open or recreate the model

From the repository root:

```matlab
addpath("demos/agentic")
model = virtuallab.createModel();
simBiologyModelBuilder(model)
```

`reporter-growth-model.mat` stores the same SimBiology model and its version metadata. The source of its parameters and equations is `../+virtuallab/createModel.m`. The simulator keeps its own model instance; opening a fresh model for inspection does not modify a running virtual-lab session.

## Equations and units

Let $m$, $u$, and $r$ denote mRNA, immature reporter, and mature reporter concentrations in nM. Time is in hours. Promoter strength $p$ is dimensionless; inducer $i$ is in µM.

$$a(i)=0.025+0.975\frac{i^2}{25^2+i^2}$$

$$\mu=\frac{0.8}{1+m/45+(u+r)/500+0.10(i/100)^2}$$

$$\frac{dm}{dt}=7pa(i)-(1.6+\mu)m$$

$$\frac{du}{dt}=\frac{9m}{1+m/20}-(1.8+0.12+\mu)u$$

$$\frac{dr}{dt}=1.8u-(0.12+\mu)r$$

The concentration scales 20, 45, and 500 are in nM; inducer scales are in µM. Transcription has units nM/h; the other rate constants have units h⁻¹. All species start at zero. SimBiology uses a 1 L reference compartment and explicit volume factors in reaction rates so these concentration equations pass dimensional analysis and unit conversion.

The burden law is phenomenological. More transcript and protein reduce growth, while growth also dilutes them. The inducer term represents an illustrative direct burden. This omits many real biological effects, including resource dynamics, population heterogeneity, growth phases, and experimental calibration.

## Observations and recommendations

The finite design space contains 132 conditions: promoter strength 0.25–3.00 in steps of 0.25 and inducer 0–100 µM in steps of 10. Eight initial conditions are measured. Only completed new experiments consume the additional budget of twelve, with up to four conditions in a proposed batch.

Observation noise is reproducible from the session seed and candidate identity. Fluorescence receives independent, mean-preserving lognormal noise with log standard deviation 0.03; relative growth receives additive Gaussian noise with standard deviation 0.006. Noise can place measured relative growth slightly above 1. The data are not clipped to hide that measurement variability.

Recommendations fit separate Gaussian processes to **observed log fluorescence and observed relative growth only**, using ARD Matérn 5/2 kernels and the specified noise levels. Predicted fluorescence moments account for the log transform. Reported uncertainty includes observation noise. Feasibility probability means the model's predictive chance that a new noisy growth observation meets the requirement; it is not a guarantee or an observed result.

When a feasible observation exists, constrained expected improvement multiplies expected fluorescence improvement over the best feasible observation by the predicted growth-feasibility probability. A distance-based diversity penalty spreads the four batch choices. When no observed condition is feasible, recommendations seek predicted feasibility with an uncertainty bonus. These are sequential-design heuristics; no unseen simulated outcome is consulted by the selector, and no global optimum is claimed.

Changing the growth requirement invalidates pending recommendations. Completed data and the remaining experiment budget are preserved. A failed experiment leaves completed observations intact and the remaining proposal available to resume.

## Reproduce a run

`virtuallab.exportRun(state,folder)` saves observed measurements, proposal outcomes, event history, model version, noise specification, seed, and a serializable checkpoint. It rejects destinations containing any of its export files; choose a new or empty folder to preserve earlier evidence. `virtuallab.replay(folder)` re-simulates only completed conditions and reports differences from the saved responses without spending additional budget. Exact replay is expected with the default simulator and the same MATLAB release; exported checkpoints preserve the original observations regardless.

Requires MATLAB R2026b, SimBiology, and Statistics and Machine Learning Toolbox. No external service is called by the model or optimizer.
