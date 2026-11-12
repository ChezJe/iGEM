function state = newSession(options)
    %newSession - Start a budgeted virtual reporter-expression study
    %   STATE = virtuallab.newSession() measures eight initial conditions
    %   with seed 2026 and permits twelve additional virtual experiments.
    %   The returned serializable state contains no live model handles.
    %
    %   STATE = virtuallab.newSession(seed=VALUE) sets the deterministic
    %   observation-noise seed. No candidate batch is proposed initially.
    %
    %   See also virtuallab.propose, virtuallab.runBatch

    arguments
        options.seed (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, ...
            mustBeInteger, mustBeNonnegative, mustBeLessThan(options.seed,4294967296)} = 2026
    end

    candidates = candidateGrid();
    observations = table(Size=[0 9], VariableTypes=[repmat("double",1,7), "string", "double"], ...
        VariableNames=["CandidateID", "PromoterStrength", "InducerMicromolar", ...
        "Fluorescence", "RelativeGrowth", "Batch", "ObservationIndex", "Origin", "ObservationSeed"]);
    events = table(Size=[0 7], VariableTypes=["double", "string", "string", repmat("double",1,4)], ...
        VariableNames=["Sequence", "Type", "Message", "Batch", "CandidateID", "RemainingBudget", "Threshold"]);
    state = struct(SchemaVersion=1, ModelVersion="1.0.0", Seed=double(options.seed), ...
        Candidates=candidates, Observations=observations, InitialCount=8, ...
        TotalBudget=12, GrowthThreshold=0.8, BatchSize=4, BatchNumber=0, Revision=0, ...
        ProposalRevision=-1, ProposalThreshold=NaN, Proposal=table(), ...
        ProposalHistory=table(), Predictions=table(), PredictionRevision=-1, ...
        Events=events, Status="ready", LastError=emptyError(), ...
        AcquisitionMode="", Noise=struct(LogFluorescenceSD=0.03, GrowthSD=0.006));
    initialDesign = [0.25 0; 3 0; 0.25 100; 3 100; 0.75 30; 2.5 20; 1.5 70; 2.25 50];
    [~, initialIds] = ismember(initialDesign, candidates{:,2:3}, "rows");
    for index = 1:numel(initialIds)
        candidate = candidates(initialIds(index), :);
        measurement = virtuallab.simulateCondition(candidate, state.Seed, state.ModelVersion);
        state.Observations = [state.Observations; observationRow(candidate, measurement, 0, index, "initial")];
    end
    state = appendEvent(state, "initialized", ...
        "Eight initial virtual experiments measured; twelve new experiments available.", 0);
    state = refreshPredictions(state);
    state.Proposal = state.Predictions([], :);
    state.ProposalHistory = state.Proposal;
    state.ProposalHistory.ProposalID = zeros(0,1);
    state.ProposalHistory.Threshold = zeros(0,1);
    state.ProposalHistory.Outcome = strings(0,1);
end
