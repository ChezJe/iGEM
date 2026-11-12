function candidates = candidateGrid()
    [promoter, inducer] = ndgrid(0.25:0.25:3, 0:10:100);
    candidates = table((1:numel(promoter))', promoter(:), inducer(:), ...
        VariableNames=["CandidateID", "PromoterStrength", "InducerMicromolar"]);
end
