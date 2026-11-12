function result = petaseSummary(analysis, threshold)
%petaseSummary - Summarize PETase local prediction confidence
%   RESULT = petaseSummary(ANALYSIS,THRESHOLD) reports the number and
%   fraction of residues whose pLDDT is at least THRESHOLD. Confidence
%   is not a measurement of enzyme activity or experimental accuracy.
%
%   See also petaseResidues, petaseVisuals

arguments
    analysis (1,1) struct
    threshold (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeGreaterThanOrEqual(threshold,0), ...
        mustBeLessThanOrEqual(threshold,100)}
end

result = analysis;
result.Threshold = threshold;
result.Residues.AboveThreshold = analysis.Residues.pLDDT >= threshold;
count = height(result.Residues);
selected = nnz(result.Residues.AboveThreshold);
result.Summary = table(count, mean(result.Residues.pLDDT), threshold, selected, ...
    100*selected/count, result.Source.SourceLabel, ...
    VariableNames=["Residues", "MeanpLDDT", "Threshold", ...
    "ResiduesAtOrAbove", "PercentAtOrAbove", "DataSource"]);
end
