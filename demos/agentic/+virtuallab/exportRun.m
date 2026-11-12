function manifest = exportRun(state, folder)
    %exportRun - Save virtual-lab observations, history, and checkpoint
    %   virtuallab.exportRun(STATE,FOLDER) writes CSV measurements and
    %   proposal/event histories, JSON metadata, and a MAT-file checkpoint.
    %   Existing export files are never overwritten. Choose a new folder
    %   or a destination without any of the five export filenames.
    %
    %   MANIFEST = virtuallab.exportRun(...) also returns the saved paths.
    %
    %   See also virtuallab.replay, virtuallab.viewState

    arguments
        state (1,1) struct
        folder {mustBeTextScalar}
    end
    validateState(state);
    folder = string(folder);
    manifest = struct(observations=fullfile(folder,"observations.csv"), ...
        proposals=fullfile(folder,"proposal-history.csv"), ...
        events=fullfile(folder,"events.csv"), metadata=fullfile(folder,"metadata.json"), ...
        checkpoint=fullfile(folder,"checkpoint.mat"));
    targets = string(struct2cell(manifest));
    if any(isfile(targets) | isfolder(targets))
        error("iGEM:VirtualLab:ExportExists", ...
            "The destination already contains export files. Choose a new or empty folder to preserve the earlier run.");
    end
    if ~isfolder(folder)
        mkdir(folder);
    end
    writetable(state.Observations, manifest.observations);
    writetable(state.ProposalHistory, manifest.proposals);
    writetable(state.Events, manifest.events);
    metadata = struct(schemaVersion=state.SchemaVersion, modelVersion=state.ModelVersion, ...
        seed=state.Seed, endpointHours=8, growthThreshold=state.GrowthThreshold, ...
        initialCount=state.InitialCount, totalNewExperimentBudget=state.TotalBudget, ...
        usedNewExperiments=state.TotalBudget-remainingBudget(state), ...
        noise=state.Noise, fluorescenceUnits="a.u. (mature reporter / 1 nanomolar)", ...
        growthDefinition="Terminal specific growth rate / unburdened specific growth rate", ...
        modelStatus="Illustrative and uncalibrated; all observations simulated", ...
        surrogate="Separate ARD Matern 5/2 GPs for log fluorescence and relative growth", ...
        probabilityDefinition="Predictive probability a new noisy growth measurement meets the threshold");
    writeJson(manifest.metadata, metadata);
    save(manifest.checkpoint, "state");
end

function writeJson(path, value)
    file = fopen(path, "w", "n", "UTF-8");
    if file < 0
        error("iGEM:VirtualLab:Export", "Cannot write the selected export folder.");
    end
    cleanup = onCleanup(@() fclose(file));
    fprintf(file, "%s", jsonencode(value, PrettyPrint=true));
end
