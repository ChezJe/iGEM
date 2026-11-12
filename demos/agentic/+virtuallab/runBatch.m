function state = runBatch(state, options)
    %runBatch - Execute and commit a proposed batch one condition at a time
    %   STATE = virtuallab.runBatch(STATE) simulates the pending conditions.
    %   Completed experiments are retained if a later simulation fails;
    %   LastError explains the failure and the remaining proposal can resume.
    %
    %   STATE = virtuallab.runBatch(...,MaxExperiments=N) completes at most
    %   N pending conditions, allowing an app to update or cancel between
    %   conditions. The default is four.
    %
    %   STATE = virtuallab.runBatch(...,Simulator=FUNCTION) uses an alternate
    %   acquisition function with arguments (candidate,seed,modelVersion).
    %   It must return Fluorescence, RelativeGrowth, and ObservationSeed.
    %   The function handle is not stored in the returned state.
    %
    %   See also virtuallab.propose, virtuallab.simulateCondition

    arguments
        state (1,1) struct
        options.MaxExperiments (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, ...
            mustBeInteger, mustBePositive} = 4
        options.Simulator (1,1) function_handle = @virtuallab.simulateCondition
    end
    validateState(state);
    if remainingBudget(state) == 0
        error("iGEM:VirtualLab:BudgetExhausted", "All twelve new experiments have been completed.");
    end
    if isempty(state.Proposal)
        error("iGEM:VirtualLab:NoProposal", "Propose a batch before running experiments.");
    end
    validateProposal(state);
    count = min([options.MaxExperiments, height(state.Proposal), remainingBudget(state)]);
    state.LastError = emptyError();
    for index = 1:count
        candidate = state.Candidates(state.Proposal.CandidateID(1), :);
        try
            measurement = options.Simulator(candidate, state.Seed, state.ModelVersion);
            row = observationRow(candidate, measurement, state.BatchNumber, ...
                height(state.Observations)+1, "batch");
        catch exception
            state.LastError = struct(Identifier=string(exception.identifier), ...
                Message=string(exception.message), CandidateID=candidate.CandidateID);
            state.Status = "error";
            state = appendEvent(state, "experiment-failed", ...
                "Experiment failed; completed observations are retained. " + string(exception.message), ...
                candidate.CandidateID);
            break
        end
        state.Observations = [state.Observations; row];
        state.Proposal(1, :) = [];
        matching = state.ProposalHistory.ProposalID == state.BatchNumber & ...
            state.ProposalHistory.CandidateID == candidate.CandidateID;
        state.ProposalHistory.Outcome(matching) = "completed";
        state.Revision = state.Revision + 1;
        state.ProposalRevision = state.Revision;
        state = appendEvent(state, "experiment-completed", sprintf( ...
            "Measured condition %d: reporter %.2f a.u.; relative growth %.1f%%.", ...
            candidate.CandidateID, measurement.Fluorescence, 100*measurement.RelativeGrowth), ...
            candidate.CandidateID);
    end
    try
        state = refreshPredictions(state);
    catch exception
        if strlength(state.LastError.Message) == 0
            state.LastError = struct(Identifier=string(exception.identifier), ...
                Message="Measurements saved, but surrogate update failed: " + string(exception.message), ...
                CandidateID=0);
        end
        state.Status = "error";
    end
    if strlength(state.LastError.Message) == 0
        if remainingBudget(state) == 0
            state.Status = "exhausted";
        elseif isempty(state.Proposal)
            state.Status = "ready";
        else
            state.Status = "proposed";
        end
    end
end
