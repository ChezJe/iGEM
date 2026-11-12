function summary = petaseVisuals(result)
%petaseVisuals - Show a rotatable PETase model and confidence profile
%   SUMMARY = petaseVisuals(RESULT) displays linked scientific views
%   from the selected pipeline result and returns its summary table.
%   The figure labels cached data and live-request fallback explicitly.
%
%   See also petaseSummary, scatter3, tiledlayout

arguments
    result (1,1) struct
end

oldFigure = findall(groot, Type="figure", Tag="iGEM_PETase_Confidence");
if ~isempty(oldFigure) && isstruct(oldFigure(1).UserData) && ...
        isfield(oldFigure(1).UserData,"Residues") && ...
        isequaln(oldFigure(1).UserData.Residues,result.Residues(:,1:7))
    updateThreshold(oldFigure(1),result);
    summary = result.Summary;
    return
end
if isempty(oldFigure)
    fig = figure(Name="PETase | AlphaFold confidence", ...
        Tag="iGEM_PETase_Confidence", Color="white", Theme="light", ...
        Position=[100 100 1220 720]);
else
    fig = oldFigure(1);
    clf(fig);
    figure(fig);
end
layout = tiledlayout(fig, 2, 2, TileSpacing="compact", Padding="loose");
layout.Title.String = "PETase: where is the predicted structure confident?";
layout.Title.FontSize = 18;
layout.Subtitle.String = result.Source.SourceLabel + ...
    " | A0A0K8P6T7 | existing prediction";
if result.Source.IsFallback
    layout.Subtitle.Color = [0.72 0.22 0.02];
end
r = result.Residues;
structureAxes = nexttile(layout, 1, [2 1]);
plot3(structureAxes, r.X, r.Y, r.Z, Color=[0.74 0.77 0.81], LineWidth=1.3);
hold(structureAxes, "on");
markers = scatter3(structureAxes, r.X, r.Y, r.Z, 30, r.pLDDT, "filled");
selected = ~r.AboveThreshold;
outlines = scatter3(structureAxes, r.X(selected), r.Y(selected), r.Z(selected), ...
    66, [0.15 0.15 0.15], LineWidth=0.8);
hold(structureAxes, "off");
axis(structureAxes, "equal");
axis(structureAxes, "vis3d");
axis(structureAxes, "off");
view(structureAxes, [-30 18]);
% AlphaFold confidence convention: orange, yellow, cyan, then blue.
palette = [repmat([1.00 0.49 0.27],50,1); ...
    repmat([1.00 0.86 0.08],20,1); ...
    repmat([0.40 0.80 0.95],20,1); ...
    repmat([0.05 0.33 0.83],10,1)];
colormap(structureAxes, palette);
clim(structureAxes, [0 100]);
colorScale = colorbar(structureAxes, "southoutside");
colorScale.Label.String = "pLDDT: local prediction confidence (0-100)";
colorScale.Ticks = [0 50 70 90 100];
markers.DataTipTemplate.DataTipRows = [ ...
    dataTipTextRow("Residue", r.Residue), ...
    dataTipTextRow("Amino acid", r.ResidueName), ...
    dataTipTextRow("pLDDT", r.pLDDT)];
structureAxes.Interactions = [rotateInteraction, dataTipInteraction];
profileAxes = nexttile(layout, 2);
plot(profileAxes, r.Residue, r.pLDDT, Color=[0.05 0.33 0.65], LineWidth=1.8);
hold(profileAxes, "on");
lowPoints = scatter(profileAxes, r.Residue(selected), r.pLDDT(selected), ...
    24, [0.90 0.36 0.10], "filled");
thresholdLine = yline(profileAxes, result.Threshold, "--", ...
    "Threshold " + result.Threshold, Color=[0.55 0.20 0.02], LineWidth=1.1);
hold(profileAxes, "off");
ylim(profileAxes, [0 105]);
xlim(profileAxes, [1 height(r)]);
xlabel(profileAxes, "Residue number");
ylabel(profileAxes, "pLDDT");
title(profileAxes, "Confidence varies along the sequence");
grid(profileAxes, "on");
notesAxes = nexttile(layout, 4);
axis(notesAxes, "off");
xlim(notesAxes, [0 1]);
ylim(notesAxes, [0 1]);
s = result.Summary;
summaryText = text(notesAxes, 0, 0.94, sprintf("%d / %d residues at pLDDT >= %g", ...
    s.ResiduesAtOrAbove, s.Residues, s.Threshold), ...
    FontSize=14, FontWeight="bold", Interpreter="none", VerticalAlignment="top");
percentText = text(notesAxes, 0, 0.76, sprintf("%.1f%% above threshold | Mean pLDDT %.2f", ...
    s.PercentAtOrAbove, s.MeanpLDDT), FontSize=12, Interpreter="none");
text(notesAxes, 0, 0.57, ["C-alpha backbone: drag to rotate; outlines mark low confidence."; ...
    "Use confidence to guide where to inspect."; ...
    "A low score does not prove disorder or inactivity."; ...
    "A high score does not establish PET degradation activity."; ...
    "No new folding or mutation prediction is performed."], ...
    FontSize=11, Interpreter="none", VerticalAlignment="top");
sourceText = text(notesAxes, 0, 0.05, "AlphaFold DB | CC BY 4.0 | source retrieved " + ...
    extractBefore(result.Source.RetrievedUTC, "T"), ...
    FontSize=9, Color=[0.35 0.35 0.35], Interpreter="none");
if result.Source.IsFallback
    disp(result.Source.FallbackReason)
end
summary = result.Summary;
fig.UserData = struct("Residues",r(:,1:7),"Outlines",outlines, ...
    "LowPoints",lowPoints,"ThresholdLine",thresholdLine, ...
    "SummaryText",summaryText,"PercentText",percentText, ...
    "SourceText",sourceText,"Layout",layout);
drawnow;
end

function updateThreshold(fig,result)
%updateThreshold - Update existing graphics and preserve the rotated view
state = fig.UserData;
r = result.Residues;
s = result.Summary;
selected = ~r.AboveThreshold;
set(state.Outlines,XData=r.X(selected),YData=r.Y(selected),ZData=r.Z(selected));
set(state.LowPoints,XData=r.Residue(selected),YData=r.pLDDT(selected));
state.ThresholdLine.Value = result.Threshold;
state.ThresholdLine.Label = "Threshold " + result.Threshold;
state.SummaryText.String = sprintf("%d / %d residues at pLDDT >= %g", ...
    s.ResiduesAtOrAbove,s.Residues,s.Threshold);
state.PercentText.String = sprintf("%.1f%% above threshold | Mean pLDDT %.2f", ...
    s.PercentAtOrAbove,s.MeanpLDDT);
state.SourceText.String = "AlphaFold DB | CC BY 4.0 | source retrieved " + ...
    extractBefore(result.Source.RetrievedUTC,"T");
state.Layout.Subtitle.String = result.Source.SourceLabel + ...
    " | A0A0K8P6T7 | existing prediction";
state.Layout.Subtitle.Color = [0.15 0.15 0.15];
if result.Source.IsFallback
    state.Layout.Subtitle.Color = [0.72 0.22 0.02];
    disp(result.Source.FallbackReason)
end
figure(fig);
drawnow;
end
