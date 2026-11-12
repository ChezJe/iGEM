function bundle = generateData(destination, bootstrapCount)
    %generateData - Generate synthetic biosensor measurements and fits
    %   BUNDLE = generateData creates the bundled dataset in this demo's
    %   data folder using fixed random seeds.
    %
    %   BUNDLE = generateData(DESTINATION,bootstrapCount) also selects the
    %   output folder and number of calibration bootstrap resamples.
    %
    %   See also biosensor.loadData, biosensor.fitCalibration
    arguments
        destination {mustBeTextScalar} = fullfile(fileparts(fileparts(mfilename("fullpath"))), "data")
        bootstrapCount (1,1) {mustBeNumeric, mustBeReal, mustBeInteger, mustBePositive} = 400
    end
    if ~isfolder(destination)
        mkdir(destination);
    end
    stream = RandStream("mt19937ar", "Seed", 20261112);
    sensors = ["A", "B"];
    parameters = [60, 1900, 2.8, 1.4; 40, 1050, 30, 1.2];
    standards = [0, 0.25, 0.5, 1, 2, 4, 8, 16, 32, 64, 128]';
    replicateCount = 6;
    calibration = table;
    unknown = table;
    samples = ["U1", "U2", "U3"];
    trueConcentration = [45, 4, 0.02];
    for sensor = 1:2
        concentration = repelem(standards, replicateCount);
        meanSignal = biosensor.hillResponse(parameters(sensor,:), concentration');
        % Replicated fluorescence has a noise floor and proportional noise.
        fluorescence = meanSignal' + (8 + 0.015*meanSignal').*randn(stream, numel(concentration), 1);
        oneCalibration = table(repmat(sensors(sensor), numel(concentration), 1), concentration, ...
            repmat((1:replicateCount)', numel(standards), 1), fluorescence, ...
            VariableNames=["Sensor", "Concentration_uM", "Replicate", "Fluorescence_RFU"]);
        calibration = [calibration; oneCalibration]; %#ok<AGROW>
        for sample = 1:3
            meanUnknown = biosensor.hillResponse(parameters(sensor,:), trueConcentration(sample));
            % Unknown measurements have additional replicate variability.
            measured = meanUnknown + (10 + 0.03*meanUnknown).*randn(stream, replicateCount, 1);
            oneUnknown = table(repmat(samples(sample), replicateCount, 1), ...
                repmat(sensors(sensor), replicateCount, 1), (1:replicateCount)', measured, ...
                VariableNames=["SampleID", "Sensor", "Replicate", "Fluorescence_RFU"]);
            unknown = [unknown; oneUnknown]; %#ok<AGROW>
        end
    end
    models = cell(1,2);
    for sensor = 1:2
        models{sensor} = biosensor.fitCalibration( ...
            calibration(calibration.Sensor == sensors(sensor),:), bootstrapCount, 1100 + sensor);
    end
    truth = table(samples', trueConcentration', VariableNames=["SampleID", "TrueConcentration_uM"]);
    bundle = struct("SchemaVersion", "1.0", "Calibration", calibration, "Unknown", unknown, ...
        "Truth", truth, "Models", [models{:}], "InferenceSeed", 8675309, ...
        "SampleIDs", samples, "SampleLabels", ["U1: Compare sensor range", "U2: In-range sample", "U3: Weak signal"], ...
        "SensorLabels", ["Sensor A: early response", "Sensor B: broader range"], ...
        "DataSeed", 20261112, "Synthetic", true);
    save(fullfile(destination, "biosensorData.mat"), "bundle");
    writetable(calibration, fullfile(destination, "calibration.csv"));
    writetable(unknown, fullfile(destination, "unknown_samples.csv"));
    writetable(truth, fullfile(destination, "synthetic_truth.csv"));
end
