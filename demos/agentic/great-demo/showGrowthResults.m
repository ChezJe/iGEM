function showGrowthResults(result)
%showGrowthResults - Display growth curves and replicate estimates
%   showGrowthResults(RESULT) plots corrected curves, the selected fitting
%   observations, and the growth rates returned by analyzeGrowth.
%
%   See also analyzeGrowth, tiledlayout
layout = tiledlayout(1,3,TileSpacing="compact",Padding="compact");
layout.Parent.Position(3:4) = [1320,440];
title(layout,"From plate-reader measurements to checked growth estimates");
palette = [0.00 0.45 0.70; 0.85 0.33 0.10; 0.00 0.60 0.50];
constructs = unique(result.Measurements.Construct,"stable");
ax = nexttile(layout);
hold(ax,"on");
for index = 1:numel(constructs)
    rows = result.Measurements.Construct == constructs(index);
    average = groupsummary(result.Measurements(rows,:),"Time_h","mean","CorrectedOD600");
    plot(ax,average.Time_h,average.mean_CorrectedOD600,LineWidth=2, ...
        Color=palette(index,:),DisplayName=constructs(index));
end
xlabel(ax,"Time (h)"); ylabel(ax,"Blank-corrected OD600");
title(ax,"Growth differs between constructs"); legend(ax,Location="northwest"); grid(ax,"on");
ax = nexttile(layout);
hold(ax,"on");
for index = 1:numel(constructs)
    selected = result.Measurements.Construct == constructs(index) & result.Measurements.InFit;
    scatter(ax,result.Measurements.Time_h(selected),result.Measurements.CorrectedOD600(selected), ...
        16,palette(index,:),"filled",DisplayName=constructs(index));
end
ax.YScale = "log";
xlabel(ax,"Time (h)"); ylabel(ax,"OD600 in fitting window");
title(ax,"Inspect the exponential-phase window"); grid(ax,"on");
ax = nexttile(layout);
hold(ax,"on");
for index = 1:numel(constructs)
    selected = result.ReplicateFits.Construct == constructs(index);
    values = result.ReplicateFits.GrowthRate_per_h(selected);
    lower = result.ReplicateFits.Lower95_per_h(selected);
    upper = result.ReplicateFits.Upper95_per_h(selected);
    positions = index + linspace(-0.16,0.16,nnz(selected))';
    errorbar(ax,positions,values,values-lower,upper-values,"o", ...
        Color=palette(index,:),MarkerFaceColor=palette(index,:),LineWidth=1.4);
end
xticks(ax,1:numel(constructs)); xticklabels(ax,constructs);
ylabel(ax,"Growth rate (h^{-1})"); xlim(ax,[0.5,numel(constructs)+0.5]);
title(ax,"Each replicate has its own 95% interval"); grid(ax,"on");
set(findall(layout,Type="axes"),FontSize=12);
end
