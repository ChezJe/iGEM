function state = setConstraint(state, threshold)
    %setConstraint - Change the growth requirement without losing experiments
    %   STATE = virtuallab.setConstraint(STATE,THRESHOLD) sets the minimum
    %   relative growth fraction in (0,1]. A changed requirement invalidates
    %   the pending proposal and preserves all observations and spent budget.
    %
    %   See also virtuallab.propose, virtuallab.viewState

    arguments
        state (1,1) struct
        threshold (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, ...
            mustBePositive, mustBeLessThanOrEqual(threshold,1)}
    end
    validateState(state);
    if threshold == state.GrowthThreshold
        return
    end
    if ~isempty(state.Proposal)
        matching = state.ProposalHistory.ProposalID == state.BatchNumber & ...
            state.ProposalHistory.Outcome == "proposed";
        state.ProposalHistory.Outcome(matching) = "invalidated";
    end
    state.GrowthThreshold = double(threshold);
    state.Proposal = state.Proposal([], :);
    state.ProposalRevision = -1;
    state.ProposalThreshold = NaN;
    state.Revision = state.Revision + 1;
    state.LastError = emptyError();
    state.Status = "ready";
    if remainingBudget(state) == 0
        state.Status = "exhausted";
    end
    state = appendEvent(state, "constraint-changed", sprintf( ...
        "Growth requirement changed to %.0f%%; observations and budget preserved.", 100*threshold), 0);
    state = refreshPredictions(state);
end
