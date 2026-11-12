function plotVirtualLabState(state)
%plotVirtualLabState - Display predictions and observed experiment outcomes
%   plotVirtualLabState(STATE) shows the predicted design space and the
%   fluorescence-growth tradeoff using recorded data only. The candidate
%   map is a surrogate prediction, not a map of unseen simulation truth.
%
%   See also virtuallab.propose, virtuallab.viewState
arguments
    state (1,1) struct
end
layout = tiledlayout(1,2,TileSpacing="compact",Padding="compact");
layout.Parent.Position(3:4) = [1200 470];
remaining = state.TotalBudget - (height(state.Observations) - state.InitialCount);
title(layout,sprintf("Minimum relative growth: %.0f%% | %d new experiments remaining", ...
    100*state.GrowthThreshold,remaining));
prediction = state.Predictions;
observed = state.Observations;
ax = nexttile(layout);
palette = colororder(ax);
scatter(ax,prediction.InducerMicromolar,prediction.PromoterStrength, ...
    105,prediction.FluorescenceMean,"s","filled",HandleVisibility="off");
hold(ax,"on");
scatter(ax,observed.InducerMicromolar,observed.PromoterStrength, ...
    45,"o",MarkerEdgeColor=ax.XColor,LineWidth=1.5,DisplayName="Measured");
if ~isempty(state.Proposal)
    scatter(ax,state.Proposal.InducerMicromolar,state.Proposal.PromoterStrength, ...
        180,"s",MarkerEdgeColor=palette(2,:),LineWidth=2,DisplayName="Proposed");
end
hold(ax,"off");
signalScale = colorbar(ax);
signalScale.Label.String = "Predicted fluorescence (a.u.)";
xlabel(ax,"Inducer (µM)"); ylabel(ax,"Promoter strength (relative)");
title(ax,"A prediction from the observations");
legend(ax,Location="southoutside",Orientation="horizontal");
grid(ax,"on");
ax = nexttile(layout);
feasible = observed.RelativeGrowth >= state.GrowthThreshold;
hold(ax,"on");
scatter(ax,100*observed.RelativeGrowth(feasible),observed.Fluorescence(feasible), ...
    65,palette(1,:),"filled",DisplayName="Observed: meets target");
scatter(ax,100*observed.RelativeGrowth(~feasible),observed.Fluorescence(~feasible), ...
    65,palette(3,:),"x",LineWidth=1.5,DisplayName="Observed: below target");
if ~isempty(state.Proposal)
    scatter(ax,100*state.Proposal.GrowthMean,state.Proposal.FluorescenceMean, ...
        100,palette(2,:),"d",LineWidth=1.5,DisplayName="Proposed: predicted");
end
xline(ax,100*state.GrowthThreshold,"--",HandleVisibility="off",LineWidth=1.5);
hold(ax,"off");
xlabel(ax,"Endpoint growth rate (% of unburdened reference)");
ylabel(ax,"Fluorescence (a.u.)");
title(ax,"Observed and predicted feasibility differ");
legend(ax,Location="southoutside");
grid(ax,"on");
set(findall(layout,Type="axes"),FontSize=11);
end
