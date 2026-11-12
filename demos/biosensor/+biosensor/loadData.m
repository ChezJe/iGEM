function bundle = loadData
    %loadData - Load the prepared synthetic biosensor data and fits
    %   BUNDLE = loadData reads and validates the bundled calibration data.
    %
    %   See also biosensor.generateData, biosensor.inferConcentration
    demoRoot = fileparts(fileparts(mfilename("fullpath")));
    fileName = fullfile(demoRoot, "data", "biosensorData.mat");
    if ~isfile(fileName)
        error("biosensor:MissingData", ...
            "Bundled data is missing. Run biosensor.generateData once before opening the demo.");
    end
    saved = load(fileName, "bundle");
    bundle = saved.bundle;
    if bundle.SchemaVersion ~= "1.0" || numel(bundle.Models) ~= 2 || ~bundle.Synthetic
        error("biosensor:DataVersion", "This app requires version 1.0 of the synthetic biosensor bundle.");
    end
    assert(height(bundle.Calibration) == 132 && height(bundle.Unknown) == 36, ...
        "biosensor:DataDimensions", "The bundled measurement counts are unexpected.");
    assert(all(isfinite(bundle.Calibration.Fluorescence_RFU)) && ...
        all(isfinite(bundle.Unknown.Fluorescence_RFU)), ...
        "biosensor:DataValues", "The bundled fluorescence values must be finite.");
end
