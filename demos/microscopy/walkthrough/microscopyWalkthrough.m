%[text] # Measure reporter expression one cell at a time
%[text] A brighter image can mean more cells, more reporter in each cell, or both. This walkthrough finds cells in a reference channel and then measures a separate reporter channel. The same analysis powers Microscopy Explorer.
%[text] **All images are synthetic.** The examples include touching cells, border objects, camera noise, and saturation. MATLAB R2026b and Image Processing Toolbox are required.
candidateFolders = [fullfile(pwd, "..", "functions"), fullfile(pwd, "functions"), fullfile(pwd, "demos", "microscopy", "functions")];
helperFolders = candidateFolders(isfile(fullfile(candidateFolders, "loadMicroscopyData.m")));
assert(~isempty(helperFolders), "Set the current folder to this walkthrough folder or the repository root.");
addpath(helperFolders(1));
data = loadMicroscopyData();
denseBasal = data.Fields(3);
denseInduced = data.Fields(4);
%%
%[text] ## Separate detection from measurement
%[text] The reference image has similar contrast for every cell. The reporter image contains heterogeneous expression. Segmenting the reporter directly could favor bright cells and bias the comparison.
tiledlayout(1,2, TileSpacing="compact");
nexttile;
imshow(denseInduced.ReferenceImage, [0 1000]);
title("Reference: define cell boundaries");
nexttile;
imshow(denseInduced.ReporterImage, [0 1500]);
title("Reporter: measure expression");
%%
%[text] ## Touching cells change the count
%[text] Thresholding, small-object removal, and border exclusion leave connected objects. Distance-transform watershed can divide touching objects into individual cells. Toggle this same option in the app.
merged = analyzeMicroscopyField(denseInduced.ReferenceImage, denseInduced.ReporterImage, SplitTouching=false);
separated = analyzeMicroscopyField(denseInduced.ReferenceImage, denseInduced.ReporterImage, SplitTouching=true);
tiledlayout(1,2, TileSpacing="compact");
nexttile;
imshow(labeloverlay(rescale(denseInduced.ReferenceImage), merged.Labels));
title(merged.Summary.CellCount + " connected objects");
nexttile;
imshow(labeloverlay(rescale(denseInduced.ReferenceImage), separated.Labels));
title(separated.Summary.CellCount + " separated cells");
%%
%[text] ## Compare expression without changing detection
%[text] Basal and induced fields use the identical reference image. Background is estimated outside a dilated foreground mask and subtracted from reporter means. Pixels at the 12-bit camera limit identify saturated cells; those cells are excluded from the histogram and median but retained in the result table.
basal = analyzeMicroscopyField(denseBasal.ReferenceImage, denseBasal.ReporterImage);
basalSignal = basal.Cells.ReporterMeanADU(~basal.Cells.IsSaturated);
inducedSignal = separated.Cells.ReporterMeanADU(~separated.Cells.IsSaturated);
histogram(basalSignal, BinEdges=0:100:1600);
hold on;
histogram(inducedSignal, BinEdges=0:100:1600);
hold off;
legend("Basal", "Induced", Location="northeast");
xlabel("Background-corrected reporter (ADU)");
ylabel("Unsaturated cells");
title("Expression shifts while detected cell count stays fixed");
grid on;
comparison = table([basal.Summary.CellCount; separated.Summary.CellCount], [median(basalSignal); median(inducedSignal)], [basal.Summary.SaturatedCellCount; separated.Summary.SaturatedCellCount], RowNames=["Basal", "Induced"], VariableNames=["DetectedCells", "MedianReporterADU", "SaturatedCells"])
%%
%[text] ## Keep results and settings together
%[text] Export includes each cell's centroid, area, reporter intensity, saturation flag, selected field and condition, and segmentation settings. The app's **Export measurements** button writes this table to CSV.
measurements = microscopyExportTable(separated, "Dense", "Induced");
measurements(1:6, ["CellID", "AreaSquareMicrometers", "ReporterMeanADU", "IsSaturated"])
%[text] **Takeaway:** analyze cell abundance and per-cell expression separately. These generated images make it possible to check detection against known masks; they do not establish performance on real microscopy images. Real experiments need representative annotations, acquisition calibration, and independent biological replicates.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
