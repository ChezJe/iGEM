function [state, proposal] = propose(state)
    %propose - Recommend an unmeasured batch from observed responses
    %   [STATE,PROPOSAL] = virtuallab.propose(STATE) selects up to four new
    %   conditions using constrained expected improvement and diversity.
    %   It uses observed measurements only and spends no experiment budget.
    %   An existing valid proposal is returned without being replaced.
    %
    %   See also virtuallab.runBatch, virtuallab.setConstraint

    arguments
        state (1,1) struct
    end
    validateState(state);
    remaining = remainingBudget(state);
    if remaining == 0
        error("iGEM:VirtualLab:BudgetExhausted", "All twelve new experiments have been completed.");
    end
    if ~isempty(state.Proposal)
        validateProposal(state);
        proposal = state.Proposal;
        return
    end
    if state.PredictionRevision ~= state.Revision
        state = refreshPredictions(state);
    end
    available = ~ismember(state.Candidates.CandidateID, state.Observations.CandidateID);
    scores = state.Predictions.Score;
    scores(~available) = -Inf;
    normalized = normalizeDesign(state.Candidates);
    selected = zeros(min([state.BatchSize, remaining, nnz(available)]), 1);
    selectedScores = zeros(size(selected));
    diversity = ones(height(state.Candidates), 1);
    for index = 1:numel(selected)
        acquisition = max(scores, realmin).*diversity;
        acquisition(~available) = -Inf;
        [selectedScores(index), selected(index)] = max(acquisition);
        available(selected(index)) = false;
        distanceSquared = sum((normalized-normalized(selected(index),:)).^2, 2);
        diversity = diversity.*(1-exp(-distanceSquared/(2*0.15^2)));
    end
    state.BatchNumber = state.BatchNumber + 1;
    state.Revision = state.Revision + 1;
    state.PredictionRevision = state.Revision;
    state.Proposal = state.Predictions(selected, :);
    state.Proposal.Score = selectedScores;
    state.ProposalRevision = state.Revision;
    state.ProposalThreshold = state.GrowthThreshold;
    history = state.Proposal;
    history.ProposalID = repmat(state.BatchNumber, height(history), 1);
    history.Threshold = repmat(state.GrowthThreshold, height(history), 1);
    history.Outcome = repmat("proposed", height(history), 1);
    state.ProposalHistory = [state.ProposalHistory; history];
    state.Status = "proposed";
    state.LastError = emptyError();
    state = appendEvent(state, "proposed", sprintf( ...
        "Proposed %d conditions using %s; no experiments spent.", ...
        height(state.Proposal), lower(state.AcquisitionMode)), 0);
    proposal = state.Proposal;
end
