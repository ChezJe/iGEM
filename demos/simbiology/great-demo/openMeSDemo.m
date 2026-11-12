function openMeSDemo()
%openMeSDemo - Open the packaged model in SimBiology Model Analyzer
%   openMeSDemo() opens the saved analysis tasks and their refreshed
%   results. The model diagram is also available in Model Builder.
%
%   See also simBiologyModelAnalyzer, simBiologyModelBuilder
projectFile = fullfile(fileparts(mfilename("fullpath")),"MeS_Production.sbproj");
assert(isfile(projectFile),"igem:MissingProject","The packaged SimBiology project is missing.");
assert(exist("simBiologyModelAnalyzer","file") ~= 0, ...
    "igem:MissingSimBiology","This demo requires SimBiology in the current MATLAB environment.");
simBiologyModelAnalyzer(projectFile);
end
