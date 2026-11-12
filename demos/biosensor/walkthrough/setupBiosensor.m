function demoRoot = setupBiosensor
    %setupBiosensor - Put the biosensor analysis package on the path
    %   demoRoot = setupBiosensor locates the surrounding demo folder.
    %
    %   See also BiosensorExplorer, biosensor.loadData
    demoRoot = fileparts(fileparts(mfilename("fullpath")));
    addpath(demoRoot);
end
