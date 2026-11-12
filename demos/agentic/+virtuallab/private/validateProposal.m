function validateProposal(state)
    ids = state.Proposal.CandidateID;
    if state.ProposalRevision ~= state.Revision || state.ProposalThreshold ~= state.GrowthThreshold
        error("iGEM:VirtualLab:StaleProposal", ...
            "The proposal no longer matches this session. Recompute it for the current requirement.");
    end
    if numel(unique(ids)) ~= numel(ids) || any(ismember(ids, state.Observations.CandidateID)) || ...
            any(~ismember(ids,state.Candidates.CandidateID)) || height(state.Proposal) > remainingBudget(state)
        error("iGEM:VirtualLab:InvalidProposal", ...
            "The proposal repeats a completed condition or exceeds the remaining budget.");
    end
    if ~isequal(state.Proposal{:,2:3}, state.Candidates{ids,2:3})
        error("iGEM:VirtualLab:InvalidProposal", "Proposed factors do not match their candidate identities.");
    end
end
