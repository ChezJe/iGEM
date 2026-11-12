function source = petaseMetadata(mode, options)
%petaseMetadata - Retrieve PETase metadata or use the bundled cache
%   SOURCE = petaseMetadata(MODE) uses "cached" or "live" data. Live
%   mode makes one request with an eight-second timeout and uses the
%   bundled prediction metadata if that request fails.
%
%   SOURCE = petaseMetadata(...,Fetcher=FCN) supplies the two-input
%   custom retrieval function.
%
%   See also petaseStructure, petaseBundledSource

arguments
    mode (1,1) string {mustBeMember(mode, ["cached", "live"])}
    options.Fetcher (1,1) function_handle = @webread
end

source = petaseBundledSource();
source.RequestedMode = mode;
if mode == "cached"
    return
end
try
    url = "https://alphafold.ebi.ac.uk/api/prediction/A0A0K8P6T7";
    requestOptions = weboptions(Timeout=8, ContentType="json");
    metadata = options.Fetcher(url, requestOptions);
    source.Metadata = selectPetaseMetadata(metadata);
    source.SourceLabel = "Live AlphaFold DB | version " + ...
        string(source.Metadata.latestVersion);
    source.RetrievedUTC = string(datetime("now", TimeZone="UTC", ...
        Format="yyyy-MM-dd'T'HH:mm:ss'Z'"));
    source.PDBFile = "";
catch exception
    source.IsFallback = true;
    source.FallbackReason = "Metadata request: " + string(exception.message);
    source.SourceLabel = "LIVE REQUEST FAILED | bundled cache, version 6";
end
end
