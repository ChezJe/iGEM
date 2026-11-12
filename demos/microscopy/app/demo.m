%DEMO - Launch the microscopy reporter-expression app
%   Run this file to open Microscopy Explorer with prepared synthetic data.
%   Requires MATLAB R2026b and Image Processing Toolbox.

if verLessThan("matlab", "26.2")
    error("iGEM:Microscopy:Release", "This plain-text App Designer demo requires MATLAB R2026b or later.");
end
if isempty(which("bwconncomp"))
    error("iGEM:Microscopy:Toolbox", "This demo requires Image Processing Toolbox.");
end
demoFolder = fileparts(mfilename("fullpath"));
addpath(demoFolder, fullfile(fileparts(demoFolder), "functions"));
microscopyApp = MicroscopyExplorer;
