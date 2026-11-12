function metadata = selectPetaseMetadata(entries)
%selectPetaseMetadata - Select and validate the full PETase prediction
%   METADATA = selectPetaseMetadata(ENTRIES) selects the monomer
%   prediction for accession A0A0K8P6T7 from AlphaFold DB metadata.
%
%   See also petaseMetadata, petaseBundledSource

arguments
    entries struct
end

required = ["uniprotAccession", "entryId", "pdbUrl", ...
    "uniprotStart", "uniprotEnd", "uniprotSequence", "latestVersion"];
if isempty(entries) || ~all(isfield(entries, required))
    error("igem:alphafold:InvalidMetadata", ...
        "AlphaFold DB returned incomplete metadata. Use cached mode.");
end
match = string({entries.uniprotAccession}) == "A0A0K8P6T7" & ...
    string({entries.entryId}) == "AF-A0A0K8P6T7-F1";
if nnz(match) ~= 1
    error("igem:alphafold:InvalidMetadata", ...
        "Expected one full PETase model. Use cached mode.");
end
metadata = entries(match);
url = string(metadata.pdbUrl);
if isempty(regexp(url, ...
        "^https://alphafold\.ebi\.ac\.uk/files/AF-A0A0K8P6T7-F1-model_v[0-9]+\.pdb$", "once"))
    error("igem:alphafold:InvalidMetadata", ...
        "The structure URL is outside the approved AlphaFold endpoint.");
end
if metadata.uniprotStart ~= 1 || ...
        metadata.uniprotEnd ~= strlength(string(metadata.uniprotSequence))
    error("igem:alphafold:InvalidMetadata", ...
        "The returned prediction is not a complete PETase sequence.");
end
end
