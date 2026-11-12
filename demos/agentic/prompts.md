# Operate the Virtual Lab with Claude

Use an existing Claude client with a MATLAB connection. Open this demo folder in the client's workspace. The app methods and the `virtuallab` package run scientific calculations locally in MATLAB; no new API or external software is needed for virtual experiments.

## 1. Inspect the state and explain the objective

> Use MATLAB to open `VirtualLabExplorer` in a variable named `lab`, or reuse that variable if the app is already running. Call `lab.getState()` and inspect the observations, growth requirement, candidate factors, and remaining budget. Explain what is known from completed experiments and what is only predicted. The objective is high reporter signal while preserving at least 80% of reference growth. Use the app's public methods for experiment selection and execution.

## 2. Propose and run a batch

> Call `lab.proposeBatch()`. Summarize the proposed conditions, predicted signal and growth, and uncertainty. Explain why the proposal is worth evaluating. Call `lab.runBatch()` to execute those virtual experiments through SimBiology. Inspect `lab.getState()` afterward and report which outcomes meet the growth requirement and how many experiments remain. Do not count a proposal as an executed experiment.

## 3. Change the requirement and adapt

> Raise the minimum growth requirement to 90% with `lab.setGrowthThreshold(0.9)`. Confirm that completed observations and the remaining budget are preserved and that the previous proposal is no longer current. Request a new proposal. Explain how the tighter requirement changes the recommendation, then run the next batch if budget remains.

## 4. Inspect the model and export the evidence

> Use `lab.openModel()` to open the underlying SimBiology model. Describe the reporter-expression and growth-burden coupling, its units, and its limitations. Inspect the final experiment record and call `lab.exportRun()` to save it. Summarize the best observed feasible design, any constraint violations, and the uncertainty that remains. Clearly distinguish simulated outcomes from laboratory evidence.

## Recovery

If the connected session is unavailable, run `claude-session/recovery.m`. It executes the prepared MATLAB workflow using the same model and selection functions. Identify it as a scripted demonstration rather than a live Claude session.

For a smaller introductory coding task, use [the growth-analysis example](introduction/README.md) and its prompts.
