function remaining = remainingBudget(state)
    remaining = state.TotalBudget - nnz(state.Observations.Origin == "batch");
end
