function source = petaseBundledSource()
%petaseBundledSource - Read attributed PETase prediction metadata
%   SOURCE = petaseBundledSource reads the bundled AlphaFold database
%   metadata and provenance without making a network request.
%
%   See also petaseMetadata, petaseStructure

cacheFolder = fullfile(petaseDemoRoot(), "data", "cache");
metadata = jsondecode(fileread(fullfile(cacheFolder, "metadata.json")));
metadata = selectPetaseMetadata(metadata);
provenance = jsondecode(fileread(fullfile(cacheFolder, "provenance.json")));
source = struct("Metadata", metadata, "RequestedMode", "cached", ...
    "SourceLabel", "Bundled cache | AlphaFold DB version 6", ...
    "IsFallback", false, "FallbackReason", "", ...
    "RetrievedUTC", string(provenance.retrievedUTC), ...
    "PDBFile", fullfile(cacheFolder, "AF-A0A0K8P6T7-F1-model_v6.pdb"));
end
