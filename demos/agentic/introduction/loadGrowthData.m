function measurements = loadGrowthData()
%loadGrowthData - Read the bundled synthetic plate-reader measurements
%   T = loadGrowthData() loads the bundled CSV independently of the
%   current working folder. Missing data can be rebuilt by the generator.
%
%   See also generateGrowthData, analyzeGrowth
dataFile = fullfile(fileparts(mfilename("fullpath")),"data","plateReader.csv");
assert(isfile(dataFile),"igem:MissingGrowthData", ...
    "Bundled data is missing. Run generateGrowthData to rebuild it.");
measurements = readtable(dataFile,TextType="string");
assert(height(measurements) > 0,"igem:EmptyGrowthData","The measurements table is empty.");
assert(all(ismember(["Time_h","Well","Construct","Replicate","OD600","IsBlank"], ...
    string(measurements.Properties.VariableNames))), ...
    "igem:GrowthSchema","The CSV does not have the documented plate-reader columns.");
assert(any(measurements.IsBlank),"igem:MissingBlanks","The plate must contain blank wells.");
end
