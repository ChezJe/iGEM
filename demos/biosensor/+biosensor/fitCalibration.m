function model = fitCalibration(calibration, bootstrapCount, seed)
    %fitCalibration - Fit a Hill curve and stratified bootstrap samples
    %   MODEL = fitCalibration(CALIBRATION) fits one sensor's replicated
    %   concentration and fluorescence table using weighted least squares.
    %
    %   MODEL = fitCalibration(CALIBRATION,bootstrapCount,SEED) controls
    %   the number and reproducibility of within-concentration resamples.
    %
    %   See also biosensor.hillResponse, biosensor.generateData
    arguments
        calibration table
        bootstrapCount (1,1) {mustBeNumeric, mustBeReal, mustBeInteger, mustBeNonnegative} = 400
        seed (1,1) {mustBeNumeric, mustBeReal, mustBeInteger, mustBeNonnegative} = 2026
    end
    requiredNames = ["Sensor", "Concentration_uM", "Fluorescence_RFU"];
    if ~all(ismember(requiredNames, string(calibration.Properties.VariableNames)))
        error("biosensor:CalibrationColumns", "The calibration table is missing required columns.");
    end
    if numel(unique(calibration.Sensor)) ~= 1
        error("biosensor:SensorCount", "Fit one sensor at a time.");
    end
    concentration = calibration.Concentration_uM(:);
    fluorescence = calibration.Fluorescence_RFU(:);
    if any(~isfinite(concentration) | concentration < 0 | ~isfinite(fluorescence))
        error("biosensor:CalibrationValues", "Use finite fluorescence and nonnegative concentration values.");
    end
    summary = groupsummary(calibration, "Concentration_uM", ["mean", "std"], "Fluorescence_RFU");
    if height(summary) < 5 || any(summary.GroupCount < 3)
        error("biosensor:CalibrationReplicates", "Provide at least five standards with three replicates each.");
    end
    [~, group] = ismember(concentration, summary.Concentration_uM);
    % A small noise floor prevents nearly identical replicates dominating.
    standardDeviation = max(5, summary.std_Fluorescence_RFU);
    sigma = standardDeviation(group);
    initial = [max(1, min(summary.mean_Fluorescence_RFU)), ...
        max(summary.mean_Fluorescence_RFU) - min(summary.mean_Fluorescence_RFU), ...
        median(concentration(concentration > 0)), 1.2];
    options = optimset("Display", "off", "MaxIter", 800, ...
        "MaxFunEvals", 1600, "TolX", 1e-7, "TolFun", 1e-7);
    [theta, ~, exitFlag] = fminsearch(@(p) weightedLoss(p, concentration, fluorescence, sigma), ...
        log(initial), options);
    if exitFlag <= 0
        error("biosensor:FitConvergence", "The Hill calibration did not converge. Inspect the standards.");
    end
    parameters = exp(theta);
    bootstrapParameters = zeros(bootstrapCount, 4);
    stream = RandStream("mt19937ar", "Seed", seed);
    groupRows = arrayfun(@(n) find(group == n), (1:height(summary))', "UniformOutput", false);
    for sample = 1:bootstrapCount
        selectedRows = zeros(height(calibration), 1);
        for level = 1:numel(groupRows)
            rows = groupRows{level};
            selectedRows(rows) = rows(randi(stream, numel(rows), numel(rows), 1));
        end
        [sampleTheta, ~, sampleExit] = fminsearch( ...
            @(p) weightedLoss(p, concentration, fluorescence(selectedRows), sigma), theta, options);
        if sampleExit <= 0
            error("biosensor:BootstrapConvergence", ...
                "Bootstrap fit %d did not converge; no failed fits were silently removed.", sample);
        end
        bootstrapParameters(sample,:) = exp(sampleTheta);
    end
    model = struct("Sensor", string(calibration.Sensor(1)), "Parameters", parameters, ...
        "BootstrapParameters", bootstrapParameters, "Summary", summary, ...
        "ConcentrationRange", [min(concentration(concentration > 0)), max(concentration)], ...
        "BootstrapSeed", seed, "BootstrapCount", bootstrapCount, "FitExitFlag", exitFlag);
    model.Grid = logspace(log10(model.ConcentrationRange(1)), log10(model.ConcentrationRange(2)), 240);
    model.Response = biosensor.hillResponse(parameters, model.Grid);
    if bootstrapCount > 0
        orderedCurves = sort(biosensor.hillResponse(bootstrapParameters, model.Grid), 1);
        intervalRows = max(1, min(bootstrapCount, ceil([0.025, 0.975]*bootstrapCount)));
        model.LowerBand = orderedCurves(intervalRows(1),:);
        model.UpperBand = orderedCurves(intervalRows(2),:);
    else
        model.LowerBand = model.Response;
        model.UpperBand = model.Response;
    end
end

function loss = weightedLoss(logParameters, concentration, fluorescence, sigma)
    %weightedLoss - Evaluate weighted residuals in positive parameter space
    if any(abs(logParameters) > 20)
        loss = 1e20 + sum(logParameters.^2);
        return
    end
    prediction = biosensor.hillResponse(exp(logParameters), concentration');
    residual = (prediction(:) - fluorescence)./sigma;
    loss = sum(residual.^2);
end
