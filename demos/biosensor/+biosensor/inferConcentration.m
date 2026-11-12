function results = inferConcentration(bundle, sampleID)
    %inferConcentration - Estimate a sample concentration with uncertainty
    %   RESULTS = inferConcentration(BUNDLE,sampleID) independently inverts
    %   each sensor's calibration using its own replicate measurements.
    %   Intervals retain zero and infinite bounds from censored inversions.
    %
    %   See also biosensor.hillResponse, biosensor.makeState
    arguments
        bundle (1,1) struct
        sampleID {mustBeTextScalar}
    end
    sampleID = string(sampleID);
    sampleIndex = find(bundle.SampleIDs == sampleID, 1);
    if isempty(sampleIndex)
        error("biosensor:UnknownSample", "Select one of the bundled sample identifiers.");
    end
    rows = cell(2,1);
    for sensor = 1:2
        model = bundle.Models(sensor);
        measured = bundle.Unknown.Fluorescence_RFU( ...
            bundle.Unknown.SampleID == sampleID & bundle.Unknown.Sensor == model.Sensor);
        meanSignal = mean(measured);
        bootstrap = model.BootstrapParameters;
        bootstrapCount = size(bootstrap,1);
        if bootstrapCount < 100
            error("biosensor:BootstrapCount", "At least 100 prepared bootstrap fits are required for inference.");
        end
        stream = RandStream("mt19937ar", "Seed", bundle.InferenceSeed + 100*sampleIndex + sensor);
        index = randi(stream, numel(measured), numel(measured), bootstrapCount);
        signalDraws = mean(measured(index), 1)';
        fractions = (signalDraws - bootstrap(:,1))./bootstrap(:,2);
        concentrationDraws = zeros(bootstrapCount,1);
        valid = fractions > 0 & fractions < 1;
        concentrationDraws(valid) = bootstrap(valid,3).* ...
            (fractions(valid)./(1 - fractions(valid))).^(1./bootstrap(valid,4));
        % Above-asymptote inversions remain infinite rather than being dropped.
        concentrationDraws(fractions >= 1) = Inf;
        ordered = sort(concentrationDraws);
        interval = ordered(ceil([0.025, 0.975]*bootstrapCount));
        parameters = model.Parameters;
        fraction = (meanSignal - parameters(1))/parameters(2);
        estimate = NaN;
        if fraction > 0 && fraction < 1
            estimate = parameters(3)*(fraction/(1 - fraction))^(1/parameters(4));
        end
        endpointResponse = biosensor.hillResponse(parameters, model.ConcentrationRange);
        if meanSignal < endpointResponse(1)
            statusCode = "below_range";
            status = "Below calibration range";
        elseif fraction >= 1 || ~isfinite(interval(2))
            statusCode = "unbounded";
            status = "Unbounded near saturation";
        elseif meanSignal > endpointResponse(2)
            statusCode = "above_range";
            status = "Above calibration range";
        elseif fraction >= 0.95
            statusCode = "near_saturation";
            status = "Near saturation";
        elseif interval(1) < model.ConcentrationRange(1) || interval(2) > model.ConcentrationRange(2)
            statusCode = "interval_outside";
            status = "Interval crosses calibration range";
        else
            statusCode = "within_range";
            status = "Within calibration range";
        end
        quantifiable = statusCode == "within_range";
        rows{sensor} = table(sampleID, model.Sensor, meanSignal, std(measured), estimate, interval(1), ...
            interval(2), quantifiable, statusCode, status, model.ConcentrationRange(1), ...
            model.ConcentrationRange(2), parameters(3), fraction, ...
            VariableNames=["SampleID", "Sensor", "MeanFluorescence_RFU", "SDFluorescence_RFU", ...
            "Estimate_uM", "Lower95_uM", "Upper95_uM", "Quantifiable", "StatusCode", "Status", ...
            "CalibrationMin_uM", "CalibrationMax_uM", "EC50_uM", "ResponseFraction"]);
    end
    results = vertcat(rows{:});
end
