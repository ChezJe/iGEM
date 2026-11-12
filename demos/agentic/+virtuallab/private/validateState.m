function validateState(state)
    if state.SchemaVersion ~= 1 || state.ModelVersion ~= "1.0.0"
        error("iGEM:VirtualLab:StateVersion", "This state requires a different virtual-lab model version.");
    end
    if ~isequal(state.Candidates, candidateGrid()) || state.TotalBudget ~= 12 || state.InitialCount ~= 8
        error("iGEM:VirtualLab:InvalidState", "The checkpoint candidate grid or experiment budget has been changed.");
    end
    ids = state.Observations.CandidateID;
    if numel(unique(ids)) ~= numel(ids) || ...
            any(~ismember(ids,state.Candidates.CandidateID)) || remainingBudget(state) < 0
        error("iGEM:VirtualLab:InvalidState", "The checkpoint has repeated conditions or an invalid experiment budget.");
    end
    if ~isequal(state.Observations{:,2:3}, state.Candidates{ids,2:3})
        error("iGEM:VirtualLab:InvalidState", "Observed factors do not match their candidate identities.");
    end
end
