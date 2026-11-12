function pipeline = createPetasePipeline(mode, threshold)
%createPetasePipeline - Build the five-block PETase confidence pipeline
%   PIPELINE = createPetasePipeline uses the bundled AlphaFold model
%   and a confidence threshold of 70.
%
%   PIPELINE = createPetasePipeline(MODE,THRESHOLD) selects "cached"
%   or "live" retrieval and sets a pLDDT threshold between 0 and 100.
%
%   See also biopipelineDesigner, bioinfo.pipeline.Pipeline

arguments
    mode (1,1) string {mustBeMember(mode,["cached", "live"])} = "cached"
    threshold (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeGreaterThanOrEqual(threshold,0), ...
        mustBeLessThanOrEqual(threshold,100)} = 70
end

addpath(fullfile(fileparts(mfilename("fullpath")), "functions"));
metadata = bioinfo.pipeline.block.UserFunction(@petaseMetadata, ...
    RequiredArguments="Mode", OutputArguments="Source");
metadata.Inputs.Mode.Value = mode;
structure = bioinfo.pipeline.block.UserFunction(@petaseStructure, ...
    RequiredArguments="Source", OutputArguments="Structure");
residues = bioinfo.pipeline.block.UserFunction(@petaseResidues, ...
    RequiredArguments="Structure", OutputArguments="Analysis");
summary = bioinfo.pipeline.block.UserFunction(@petaseSummary, ...
    RequiredArguments=["Analysis", "Threshold"], OutputArguments="Result");
summary.Inputs.Threshold.Value = threshold;
visuals = bioinfo.pipeline.block.UserFunction(@petaseVisuals, ...
    RequiredArguments="Result", OutputArguments="SummaryTable");
pipeline = bioinfo.pipeline.Pipeline;
pipeline.addBlock([metadata; structure; residues; summary; visuals], ...
    ["MetadataAndCache", "ReadPrediction", "ResidueConfidence", ...
    "ConfidenceThreshold", "VisualizePETase"]);
pipeline.connect(metadata, structure, ["Source", "Source"]);
pipeline.connect(structure, residues, ["Structure", "Structure"]);
pipeline.connect(residues, summary, ["Analysis", "Analysis"]);
pipeline.connect(summary, visuals, ["Result", "Result"]);
end
