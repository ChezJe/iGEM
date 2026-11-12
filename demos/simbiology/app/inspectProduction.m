%[text] # Compare production and local sensitivity
%[text] This supporting Live Script recomputes the same model independently of the app. Results are simulated hypotheses, not experimentally validated yields.
result = simulateMeS();
tiledlayout(1,2,TileSpacing="compact");
nexttile
plot(result.BaselineProduct.Time,result.BaselineProduct.Data,LineWidth=2)
hold on
plot(result.ModifiedProduct.Time,result.ModifiedProduct.Data,LineWidth=2)
hold off
xlabel("Time (s)")
ylabel("Methyl salicylate (mM)")
legend("Baseline","2x BSMT1 transcription",Location="northwest")
title("How does a parameter change affect the trajectory?")
grid on
nexttile
barh(result.Sensitivity.NormalizedSensitivity)
yticks(1:height(result.Sensitivity))
yticklabels(result.Sensitivity.Input)
xlabel("Normalized local sensitivity at 250 s")
title("Which inputs influence this modeled result?")
grid on
%%
%[text] ## Interpret the model locally
%[text] A fully normalized sensitivity compares fractional changes in output and input. Its sign describes direction near the selected parameter values. It does not establish an optimum or prove behavior in an experiment.
result.Sensitivity

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
