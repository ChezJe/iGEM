function result = simulateMeS(projectFile)
%simulateMeS - Compare production and normalized parameter sensitivities
%   RESULT = simulateMeS(FILE) loads a copy of the supplied project,
%   simulates 250 seconds, doubles BSMT1 transcription, and computes
%   local sensitivities. It does not overwrite the project or its diagram.
%
%   See also sbioloadproject, sbiosimulate, getsensmatrix
arguments
    projectFile (1,1) string = fullfile(fileparts(mfilename("fullpath")),"MeS_Production.sbproj")
end
loaded = sbioloadproject(projectFile);
names = fieldnames(loaded);
model = [];
for index = 1:numel(names)
    if isa(loaded.(names{index}),"SimBiology.Model")
        model = loaded.(names{index});
        break
    end
end
assert(~isempty(model),"igem:MissingModel","The project does not contain a SimBiology model.");
cleanup = onCleanup(@() delete(model));
config = getconfigset(model,"active");
config.StopTime = 250;
config.TimeUnits = "second";
config.MaximumWallClock = 60;
config.CompileOptions.UnitConversion = true;
config.CompileOptions.DimensionalAnalysis = true;
config.SolverOptions.SensitivityAnalysis = false;
config.SensitivityAnalysisOptions.Inputs = [];
config.SensitivityAnalysisOptions.Outputs = [];
config.RuntimeOptions.StatesToLog = model.Species;
baseline = sbiosimulate(model);
parameter = sbioselect(model,Type="parameter",Name="k3_transcription");
assert(isscalar(parameter),"igem:MissingParameter","Expected one k3_transcription parameter.");
originalValue = parameter.Value;
parameter.Value = 2*originalValue;
modified = sbiosimulate(model);
parameter.Value = originalValue;
inputNames = ["k1_transcription","k3_transcription","k3_degradation", ...
    "k2_transcription","cell.chorismate"];
inputObjects = [sbioselect(model,Type="parameter",Name=inputNames(1)); ...
    sbioselect(model,Type="parameter",Name=inputNames(2)); ...
    sbioselect(model,Type="parameter",Name=inputNames(3)); ...
    sbioselect(model,Type="parameter",Name=inputNames(4)); ...
    sbioselect(model,Type="species",Name="chorismate")];
config.SensitivityAnalysisOptions.Inputs = inputObjects;
config.SensitivityAnalysisOptions.Outputs = sbioselect(model,Type="species",Name="MeS_1");
config.SensitivityAnalysisOptions.Normalization = "Full";
config.SolverOptions.SensitivityAnalysis = true;
sensitivityData = sbiosimulate(model);
[sensitivityTime,sensitivity,~,inputs] = getsensmatrix(sensitivityData);
config.SolverOptions.SensitivityAnalysis = false;
config.SensitivityAnalysisOptions.Inputs = [];
config.SensitivityAnalysisOptions.Outputs = [];
baselineProduct = selectbyname(baseline,"MeS_1");
modifiedProduct = selectbyname(modified,"MeS_1");
finalSensitivity = reshape(sensitivity(end,1,:),[],1);
sensitivityTable = table(string(inputs(:)),finalSensitivity, ...
    VariableNames=["Input","NormalizedSensitivity"]);
result = struct;
result.Baseline = baseline;
result.Modified = modified;
result.SensitivityData = sensitivityData;
result.BaselineProduct = baselineProduct;
result.ModifiedProduct = modifiedProduct;
result.SensitivityTime = sensitivityTime;
result.Sensitivity = sensitivityTable;
result.Parameter = "k3_transcription";
result.BaselineValue = originalValue;
result.ModifiedValue = 2*originalValue;
end
