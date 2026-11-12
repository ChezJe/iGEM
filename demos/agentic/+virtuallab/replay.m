function [state, comparison] = replay(folder)
    %replay - Re-simulate the completed conditions in an exported checkpoint
    %   STATE = virtuallab.replay(FOLDER) loads checkpoint.mat and repeats
    %   its observed conditions with the saved seed and model version.
    %   It does not run unobserved candidates or spend additional budget.
    %
    %   [STATE,COMPARISON] = virtuallab.replay(...) also reports absolute
    %   differences from the exported fluorescence and growth observations.
    %   Exact replay is expected for the default simulator and same release;
    %   alternate acquisition functions can produce different results.
    %
    %   See also virtuallab.exportRun, virtuallab.simulateCondition

    arguments
        folder {mustBeTextScalar}
    end
    loaded = load(fullfile(folder,"checkpoint.mat"), "state");
    state = loaded.state;
    validateState(state);
    fluorescenceDifference = zeros(height(state.Observations),1);
    growthDifference = zeros(height(state.Observations),1);
    for index = 1:height(state.Observations)
        candidate = state.Candidates(state.Observations.CandidateID(index),:);
        measurement = virtuallab.simulateCondition(candidate, state.Seed, state.ModelVersion);
        fluorescenceDifference(index) = abs(measurement.Fluorescence-state.Observations.Fluorescence(index));
        growthDifference(index) = abs(measurement.RelativeGrowth-state.Observations.RelativeGrowth(index));
    end
    comparison = table(state.Observations.CandidateID, fluorescenceDifference, growthDifference, ...
        VariableNames=["CandidateID", "AbsoluteFluorescenceDifference", "AbsoluteGrowthDifference"]);
end
