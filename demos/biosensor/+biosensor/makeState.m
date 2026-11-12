function [state, results] = makeState(bundle, sampleID, activeSensor)
    %makeState - Prepare display data from the shared MATLAB analysis
    %   STATE = makeState(BUNDLE,sampleID,activeSensor) returns bridge-safe
    %   display values and curve coordinates for the selected sample.
    %
    %   [STATE,RESULTS] = makeState(...) also returns the numeric table used
    %   for display and CSV export.
    %
    %   See also biosensor.inferConcentration, biosensor.plotCalibration
    arguments
        bundle (1,1) struct
        sampleID {mustBeTextScalar}
        activeSensor {mustBeTextScalar}
    end
    activeSensor = string(activeSensor);
    if ~ismember(activeSensor, ["A", "B"])
        error("biosensor:UnknownSensor", "Select Sensor A or Sensor B.");
    end
    results = biosensor.inferConcentration(bundle, sampleID);
    curves = cell(1,2);
    displayResults = cell(1,2);
    for sensor = 1:2
        model = bundle.Models(sensor);
        calibration = bundle.Calibration(bundle.Calibration.Sensor == model.Sensor,:);
        positive = calibration.Concentration_uM > 0;
        curves{sensor} = struct("id", model.Sensor, "label", bundle.SensorLabels(sensor), ...
            "x", model.Grid, "y", model.Response, "lower", model.LowerBand, "upper", model.UpperBand, ...
            "pointX", calibration.Concentration_uM(positive)', ...
            "pointY", calibration.Fluorescence_RFU(positive)', "ec50", model.Parameters(3));
        row = results(sensor,:);
        hasEstimate = isfinite(row.Estimate_uM) && row.Estimate_uM >= model.ConcentrationRange(1) && ...
            row.Estimate_uM <= model.ConcentrationRange(2);
        estimate = 0;
        if hasEstimate
            estimate = row.Estimate_uM;
        end
        if row.Quantifiable
            concentrationText = compose("%.2f µM", row.Estimate_uM);
            explanation = "The response and its interval are inside the calibration range.";
        elseif row.StatusCode == "below_range"
            concentrationText = "Below range";
            explanation = "The signal is below the lowest nonzero calibration standard.";
        elseif row.StatusCode == "unbounded"
            concentrationText = "No finite upper bound";
            explanation = "Some bootstrap signals reach the fitted plateau; their inversions remain unbounded.";
        elseif row.StatusCode == "above_range"
            concentrationText = "Above range";
            explanation = "The signal exceeds the highest calibration standard. Dilute or use another sensor.";
        elseif row.StatusCode == "near_saturation"
            concentrationText = "Use with caution";
            explanation = "The response exceeds 95% of the fitted amplitude, where inversion magnifies noise.";
        else
            concentrationText = "Range-limited estimate";
            explanation = "The uncertainty interval extends beyond the calibrated concentrations.";
        end
        if isfinite(row.Upper95_uM)
            intervalText = compose("95%% bootstrap interval: %.2f–%.2f µM", row.Lower95_uM, row.Upper95_uM);
        else
            intervalText = compose("95%% bootstrap interval: %.2f µM to unbounded", row.Lower95_uM);
        end
        displayResults{sensor} = struct("id", model.Sensor, "label", bundle.SensorLabels(sensor), ...
            "meanSignal", row.MeanFluorescence_RFU, "standardDeviation", row.SDFluorescence_RFU, ...
            "hasEstimate", hasEstimate, "estimate", estimate, "concentrationText", concentrationText, ...
            "intervalText", intervalText, "status", row.Status, "statusCode", row.StatusCode, ...
            "quantifiable", row.Quantifiable, "explanation", explanation);
    end
    state = struct("sampleID", string(sampleID), "activeSensor", activeSensor, ...
        "sampleIDs", bundle.SampleIDs, "sampleLabels", bundle.SampleLabels, ...
        "curves", [curves{:}], "results", [displayResults{:}], ...
        "xRange", bundle.Models(1).ConcentrationRange, "bootstrapCount", bundle.Models(1).BootstrapCount, ...
        "dataVersion", bundle.SchemaVersion);
end
