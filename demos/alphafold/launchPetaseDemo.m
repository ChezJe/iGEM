function launchPetaseDemo()
%launchPetaseDemo - Open the saved PETase pipeline and completed result
%   launchPetaseDemo displays the cached PETase analysis and opens its
%   saved pipeline in Biopipeline Designer. Run the pipeline in the app
%   and change the ConfidenceThreshold block to explore the result.
%
%   See also biopipelineDesigner, createPetasePipeline

folder = string(fileparts(mfilename("fullpath")));
addpath(folder, fullfile(folder, "functions"));
source = petaseMetadata("cached");
structure = petaseStructure(source);
analysis = petaseResidues(structure);
petaseVisuals(petaseSummary(analysis, 70));
biopipelineDesigner(fullfile(folder, "petaseConfidence.plprj"));
disp("Run the five-block pipeline in Biopipeline Designer.")
disp("Select ConfidenceThreshold and change Threshold from 70 to 50.")
disp("Select MetadataAndCache and change Mode from cached to live to query AlphaFold DB.")
end
