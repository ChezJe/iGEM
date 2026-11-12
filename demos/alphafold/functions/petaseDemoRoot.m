function folder = petaseDemoRoot()
%petaseDemoRoot - Locate the PETase demonstration folder
%   FOLDER = petaseDemoRoot returns the folder containing this demo.
%
%   See also fileparts, mfilename

folder = string(fileparts(fileparts(mfilename("fullpath"))));
end
