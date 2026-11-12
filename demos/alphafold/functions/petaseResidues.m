function analysis = petaseResidues(structure)
%petaseResidues - Extract one confidence value per PETase residue
%   ANALYSIS = petaseResidues(STRUCTURE) reads C-alpha coordinates and
%   pLDDT from the AlphaFold PDB temperature-factor field. Duplicate
%   residues, incomplete sequences, and invalid confidence are rejected.
%
%   See also petaseStructure, petaseSummary

arguments
    structure (1,1) struct
end

pdb = structure.PDB;
if numel(pdb.Model) ~= 1 || ~isfield(pdb.Model, "Atom")
    error("igem:alphafold:InvalidStructure", ...
        "Expected one protein model containing atoms.");
end
atoms = pdb.Model.Atom;
ca = atoms(string({atoms.AtomName}) == "CA");
if isempty(ca)
    error("igem:alphafold:InvalidStructure", ...
        "No C-alpha atoms were found in the prediction.");
end
chain = string({ca.chainID})';
residue = [ca.resSeq]';
insertionCode = string({ca.iCode})';
residueName = string({ca.resName})';
plddt = [ca.tempFactor]';
xyz = [[ca.X]' [ca.Y]' [ca.Z]'];
residueKey = chain + ":" + residue + ":" + insertionCode;
if numel(unique(residueKey)) ~= numel(ca) || numel(unique(chain)) ~= 1
    error("igem:alphafold:InvalidStructure", ...
        "Expected exactly one C-alpha atom per residue in one chain.");
end
metadata = structure.Source.Metadata;
expected = (metadata.uniprotStart:metadata.uniprotEnd)';
sequence = string(aminolookup(char(join(residueName, ""))));
if ~isequal(residue, expected) || sequence ~= string(metadata.uniprotSequence)
    error("igem:alphafold:InvalidStructure", ...
        "The structure residues do not match the selected PETase sequence.");
end
if any(~isfinite(plddt) | plddt < 0 | plddt > 100) || ...
        any(~isfinite(xyz), "all")
    error("igem:alphafold:InvalidConfidence", ...
        "Coordinates must be finite and pLDDT must lie between 0 and 100.");
end
residues = table(residue, chain, residueName, plddt, xyz(:,1), xyz(:,2), xyz(:,3), ...
    VariableNames=["Residue", "Chain", "ResidueName", "pLDDT", "X", "Y", "Z"]);
analysis = struct("Residues", residues, "Source", structure.Source);
end
