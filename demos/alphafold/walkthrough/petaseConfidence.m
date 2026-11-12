%[text] # From PETase accession to local prediction confidence
%[text] This companion Live Script exposes the calculations behind the five-block Biopipeline Designer demo. A0A0K8P6T7 is a PETase accession. The bundled AlphaFold DB model contains 290 residues and retains its source metadata and attribution.
demoFolder = fileparts(which("launchPetaseDemo"));
if isempty(demoFolder)
    candidates = [fullfile(pwd,"demos","alphafold"), fullfile(pwd,".."), pwd];
    demoFolder = candidates(find(isfile(fullfile(candidates,"launchPetaseDemo.m")),1));
    assert(~isempty(demoFolder), "Open this script from the repository or its walkthrough folder.");
end
addpath(demoFolder,fullfile(demoFolder,"functions"));
%%
%[text] ## Select a reproducible source
%[text] Use `"cached"` for an offline run. Use `"live"` to query the approved public AlphaFold DB service, with an eight-second timeout per request and no retries. A failed live request returns visibly labeled bundled data.
source = petaseMetadata("cached");
disp(source.Metadata.uniprotDescription)
disp(source.SourceLabel)
%%
%[text] ## Extract one observation per residue
%[text] The PDB file contains many atoms per residue. Select exactly one C-alpha atom per residue before summarizing pLDDT, which AlphaFold stores in the temperature-factor column. Sequence identity, residue coverage, and the range 0 to 100 are checked.
structure = petaseStructure(source);
analysis = petaseResidues(structure);
head(analysis.Residues)
%%
%[text] ## Set a confidence criterion
%[text] A threshold of 70 selects 263 of 290 residues in the bundled model. Lowering it to 50 selects 283. A threshold changes the interpretation of this fixed prediction; it does not modify coordinates or predict a mutation.
threshold = 70;
result = petaseSummary(analysis,threshold);
result.Summary
%%
%[text] ## Inspect the result
%[text] Rotate the backbone and inspect the confidence profile. In this model the first 27 residues fall below 70. These scores alone do not establish activity, experimental disorder, or mutation benefit.
petaseVisuals(result);
%%
%[text] ## Reuse the analysis as a pipeline
%[text] `createPetasePipeline` connects these same functions into five reusable app blocks. Launch the saved pipeline through the demo README. Attribution, version, retrieval date, and file hashes are stored with the bundled data.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
