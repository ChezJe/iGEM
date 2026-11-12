function measurement = simulateCondition(candidate, seed, modelVersion)
    %simulateCondition - Measure one virtual reporter-growth experiment
    %   MEASUREMENT = virtuallab.simulateCondition(CANDIDATE,SEED,VERSION)
    %   runs a single SimBiology condition and returns paired fluorescence
    %   and relative growth. CANDIDATE is one row of the candidate table.
    %   Measurement noise is reproducible for a given seed and candidate.
    %
    %   See also virtuallab.createModel, virtuallab.runBatch

    arguments
        candidate (1,:) table
        seed (1,1) {mustBeNumeric, mustBeReal, mustBeFinite, mustBeInteger, mustBeNonnegative}
        modelVersion {mustBeTextScalar}
    end

    if height(candidate) ~= 1 || string(modelVersion) ~= "1.0.0"
        error("iGEM:VirtualLab:SimulationInput", ...
            "Supply one candidate and supported model version 1.0.0.");
    end
    grid = candidateGrid();
    if ~all(ismember(grid.Properties.VariableNames,candidate.Properties.VariableNames)) || ...
            ~ismember(candidate(:,grid.Properties.VariableNames),grid,"rows")
        error("iGEM:VirtualLab:SimulationInput", "Candidate identity and factors must match the finite design grid.");
    end
    persistent model
    if isempty(model) || ~isvalid(model)
        model = virtuallab.createModel();
    end
    promoter = sbioselect(model, Type="parameter", Name="PromoterStrength");
    inducer = sbioselect(model, Type="parameter", Name="Inducer");
    promoter.Value = candidate.PromoterStrength;
    inducer.Value = candidate.InducerMicromolar;
    simulation = sbiosimulate(model);
    reporter = selectbyname(simulation, "Cell.MatureReporter");
    growth = selectbyname(simulation, "GrowthRate");
    referenceGrowth = sbioselect(model, Type="parameter", Name="UnburdenedGrowthRate");
    scale = sbioselect(model, Type="parameter", Name="FluorescenceScale");
    fluorescence = reporter.Data(end)/scale.Value;
    relativeGrowth = growth.Data(end)/referenceGrowth.Value;
    observationSeed = mod(double(seed) + 7919*double(candidate.CandidateID), 2^32-1);
    stream = RandStream("mt19937ar", Seed=observationSeed);
    measurement = struct( ...
        Fluorescence=fluorescence*exp(0.03*randn(stream)-0.5*0.03^2), ...
        RelativeGrowth=relativeGrowth + 0.006*randn(stream), ...
        ObservationSeed=observationSeed);
end
