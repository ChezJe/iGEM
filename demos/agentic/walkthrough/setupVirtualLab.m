function setupVirtualLab()
%setupVirtualLab - Make the virtual-lab functions available
%   setupVirtualLab() adds this demonstration's folder to the MATLAB
%   path for the session without changing the current folder.
demoFolder = fileparts(fileparts(mfilename("fullpath")));
addpath(demoFolder);
end
