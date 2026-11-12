function launchIGEMDemo(name)
%launchIGEMDemo - Open one of the five iGEM demonstrations
%   launchIGEMDemo(NAME) opens "simbiology", "alphafold", "microscopy",
%   "biosensor", or "agentic". Demo folders are added to the MATLAB path
%   for this session so app callbacks can locate their shared functions.
%
%   See also openMeSDemo, launchPetaseDemo, MicroscopyExplorer
arguments
    name (1,1) string {mustBeMember(name,["simbiology","alphafold","microscopy","biosensor","agentic"])}
end
folder = fullfile(fileparts(mfilename("fullpath")),"demos",name);
addpath(genpath(folder));
switch name
    case "simbiology"
        openMeSDemo();
    case "alphafold"
        launchPetaseDemo();
    case "microscopy"
        microscopyApp = MicroscopyExplorer; %#ok<NASGU>
    case "biosensor"
        biosensorApp = BiosensorExplorer; %#ok<NASGU>
    case "agentic"
        virtualLabApp = VirtualLabExplorer; %#ok<NASGU>
end
end
