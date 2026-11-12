function app = demo
    %DEMO - Open the fluorescent biosensor Explorer
    %   APP = DEMO adds this demo to the path and opens the prepared app.
    %
    %   See also BiosensorExplorer, biosensor.loadData
    demoRoot = fileparts(fileparts(mfilename("fullpath")));
    addpath(demoRoot);
    app = BiosensorExplorer;
end
