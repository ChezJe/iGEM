function data = loadMicroscopyData()
    %loadMicroscopyData - Read the bundled synthetic microscopy fields
    %   DATA = loadMicroscopyData() loads the four prepared fields and
    %   acquisition metadata. The path is resolved relative to this file.
    %
    %   See also generateMicroscopyData, analyzeMicroscopyField

    dataFile = fullfile(fileparts(fileparts(mfilename("fullpath"))), ...
        "data", "microscopyFields.mat");
    if ~isfile(dataFile)
        error("iGEM:Microscopy:MissingData", ...
            "Bundled images are missing. Run generateMicroscopyData with the data-file path.");
    end
    loaded = load(dataFile, "data");
    data = loaded.data;
end
