function structure = petaseStructure(source, options)
%petaseStructure - Obtain and parse the selected PETase prediction
%   STRUCTURE = petaseStructure(SOURCE) reads cached PDB data or makes
%   one eight-second request to the approved AlphaFold structure URL.
%   A failed live request or invalid live structure uses the complete
%   bundled metadata and structure pair and records the fallback.
%
%   STRUCTURE = petaseStructure(...,Fetcher=FCN) supplies the two-input
%   custom retrieval function.
%
%   See also petaseMetadata, petaseResidues, pdbread

arguments
    source (1,1) struct
    options.Fetcher (1,1) function_handle = @webread
end

if source.RequestedMode == "live" && ~source.IsFallback
    try
        source.Metadata = selectPetaseMetadata(source.Metadata);
        requestOptions = weboptions(Timeout=8, ContentType="text");
        pdbText = options.Fetcher(string(source.Metadata.pdbUrl), requestOptions);
        structure = parseStructure(pdbText, source);
        return
    catch exception
        source = petaseBundledSource();
        source.RequestedMode = "live";
        source.IsFallback = true;
        source.FallbackReason = "Structure request: " + string(exception.message);
        source.SourceLabel = "LIVE REQUEST FAILED | bundled cache, version 6";
    end
end
structure = parseStructure(fileread(source.PDBFile), source);
end

function structure = parseStructure(pdbText, source)
%parseStructure - Validate an AlphaFold PDB payload before analysis
if ~contains(string(pdbText), "ALPHAFOLD") || ...
        ~contains(string(pdbText), "A0A0K8P6T7")
    error("igem:alphafold:InvalidStructure", ...
        "The PDB payload does not identify the requested AlphaFold model.");
end
pdb = pdbread(char(pdbText));
structure = struct("PDB", pdb, "Source", source);
% Validate immediately so a malformed live payload can use the cache.
petaseResidues(structure);
end
