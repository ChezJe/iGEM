function app = demo
    %DEMO - Open the SimBiology Virtual Lab
    %   APP = DEMO opens a repeatable experiment-planning session.
    %
    %   See also VirtualLabExplorer, virtuallab.newSession
    demoRoot = fileparts(fileparts(mfilename("fullpath")));
    addpath(demoRoot);
    app = VirtualLabExplorer;
end
