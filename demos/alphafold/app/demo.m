%[text] # Inspect PETase confidence in Biopipeline Designer
%[text] Where is an AlphaFold prediction confident enough to guide closer inspection? Run this section to open the completed result and the saved five-block pipeline. The bundled prediction makes the opening reproducible.
demoFolder = fileparts(which("launchPetaseDemo"));
if isempty(demoFolder)
    candidates = [fullfile(pwd,"demos","alphafold"), fullfile(pwd,".."), pwd];
    demoFolder = candidates(find(isfile(fullfile(candidates,"launchPetaseDemo.m")),1));
    assert(~isempty(demoFolder), "Open this script from the repository or its app folder.");
    addpath(demoFolder);
end
launchPetaseDemo;
%%
%[text] ## Try one meaningful change
%[text] In the app, click **Run**. Select **ConfidenceThreshold**, change its **Threshold** input from 70 to 50, and run again. The lower threshold includes additional residues near the N terminus. The coordinates do not change: you changed your confidence criterion.
%[text] Select **MetadataAndCache** and change **Mode** from `"cached"` to `"live"` to retrieve the existing PETase prediction from the public AlphaFold database. Failed live retrieval is visibly labeled and uses the same bundled PETase model. No new protein folding is performed.
%[text] High pLDDT describes local structural confidence. It does not establish enzyme activity, mutation benefit, or PET degradation performance.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
