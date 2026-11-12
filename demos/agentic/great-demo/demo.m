%[text] # Which construct changes growth?
%[text] These synthetic plate-reader measurements illustrate a reproducible analysis that an agent can create and check with MATLAB. The prepared result runs independently of an AI service.
measurements = loadGrowthData();
result = analyzeGrowth(measurements);
showGrowthResults(result)
%%
%[text] ## Inspect measurements and controls
%[text] Each culture and blank well was measured every 7.5 minutes for 12 hours. OD600 is dimensionless; time is recorded in hours. The data generator includes a lag phase, an exponential phase, a stationary phase, and a small drifting background.
head(measurements)
%%
%[text] ## Separate instrument background from growth
%[text] Subtract the mean of the blank wells at each matching time. Negative corrected values are possible measurements; they are not silently replaced before analysis.
tiledlayout(1,1);
plot(result.BlankMeans.Time_h,result.BlankMeans.mean_OD600,LineWidth=2)
xlabel("Time (h)")
ylabel("Mean blank OD600")
title("The background changes during acquisition")
grid on
%%
%[text] ## Make the fitting window explicit
%[text] Fit a straight line to log OD600 between 0.05 and 0.30, independently for each replicate. Require at least five observations and positive growth. Inspect the window before transferring this criterion to a different assay.
result.ReplicateFits
%%
%[text] ## Compare constructs without hiding replicates
%[text] The summary describes variation among the three simulated replicates. Regression confidence intervals are conditional on the chosen window and do not represent all biological uncertainty.
result.Summary
%[text] Open the demo README for the Claude prompt sequence. Re-run the synthetic generator or adapt the measurement table to explore another experiment.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
