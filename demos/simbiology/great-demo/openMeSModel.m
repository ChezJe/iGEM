function openMeSModel()
%openMeSModel - Open the saved pathway diagram in Model Builder
%   openMeSModel() opens the same packaged project as openMeSDemo.
%
%   See also openMeSDemo, simBiologyModelBuilder
projectFile = fullfile(fileparts(mfilename("fullpath")),"MeS_Production.sbproj");
simBiologyModelBuilder(projectFile);
end
