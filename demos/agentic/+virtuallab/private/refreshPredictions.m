function state = refreshPredictions(state)
    % Both regressions use only the observed responses. This function must
    % never call the SimBiology experiment engine for candidate predictions.
    inputs = normalizeDesign(state.Observations);
    query = normalizeDesign(state.Candidates);
    fluorescence = log(state.Observations.Fluorescence);
    growth = state.Observations.RelativeGrowth;
    optimizer = statset("fitrgp");
    optimizer.MaxIter = 80;
    fluorescenceGP = fitrgp(inputs, fluorescence, ...
        KernelFunction="ardmatern52", KernelParameters=[0.4;0.4;max(std(fluorescence),0.1)], ...
        BasisFunction="constant", FitMethod="exact", PredictMethod="exact", ...
        Standardize=false, Sigma=state.Noise.LogFluorescenceSD, ConstantSigma=true, ...
        SigmaLowerBound=0.001, OptimizerOptions=optimizer);
    growthGP = fitrgp(inputs, growth, ...
        KernelFunction="ardmatern52", KernelParameters=[0.4;0.4;max(std(growth),0.02)], ...
        BasisFunction="constant", FitMethod="exact", PredictMethod="exact", ...
        Standardize=false, Sigma=state.Noise.GrowthSD, ConstantSigma=true, ...
        SigmaLowerBound=0.001, OptimizerOptions=optimizer);
    [logMean, logSD] = predict(fluorescenceGP, query);
    [growthMean, growthSD] = predict(growthGP, query);
    logSD = max(logSD, eps);
    growthSD = max(growthSD, eps);
    fluorescenceMean = exp(logMean + 0.5*logSD.^2);
    fluorescenceSD = sqrt(expm1(logSD.^2).*exp(2*logMean+logSD.^2));
    feasibility = normcdf((growthMean-state.GrowthThreshold)./growthSD);
    feasibleObserved = state.Observations.RelativeGrowth >= state.GrowthThreshold;
    if any(feasibleObserved)
        best = max(state.Observations.Fluorescence(feasibleObserved));
        z = (logMean-log(best))./logSD;
        expectedImprovement = max(0, fluorescenceMean.*normcdf(z+logSD)-best*normcdf(z));
        score = expectedImprovement.*feasibility;
        state.AcquisitionMode = "Constrained expected improvement";
    else
        expectedImprovement = zeros(size(fluorescenceMean));
        score = feasibility.*(1 + fluorescenceSD/max(fluorescenceSD));
        state.AcquisitionMode = "Feasibility exploration";
    end
    state.Predictions = state.Candidates;
    state.Predictions.FluorescenceMean = fluorescenceMean;
    state.Predictions.FluorescenceSD = fluorescenceSD;
    state.Predictions.GrowthMean = growthMean;
    state.Predictions.GrowthSD = growthSD;
    state.Predictions.FeasibilityProbability = feasibility;
    state.Predictions.ExpectedImprovement = expectedImprovement;
    state.Predictions.Score = score;
    state.PredictionRevision = state.Revision;
end
