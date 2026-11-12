function result = analyzeMicroscopyField(reference, reporter, options)
    %analyzeMicroscopyField - Segment cells and quantify reporter intensity
    %   RESULT = analyzeMicroscopyField(REFERENCE,REPORTER) finds cells in
    %   a reference image and measures a separate reporter channel. Both
    %   inputs are nonnegative, finite, real 2-D camera-count arrays.
    %
    %   RESULT = analyzeMicroscopyField(...,SplitTouching=TF) controls
    %   distance-transform watershed separation, enabled by default.
    %
    %   RESULT = analyzeMicroscopyField(...,PixelSizeMicrometers=VALUE)
    %   specifies the pixel scale, 0.35 micrometers by default.
    %
    %   RESULT = analyzeMicroscopyField(...,SaturationADU=VALUE) specifies
    %   the camera saturation level, 4095 by default. Saturated objects
    %   remain in the table but are excluded from the intensity summary.
    %
    %   See also bwconncomp, watershed, regionprops

    arguments
        reference {mustBeNumeric, mustBeReal, mustBeFinite, ...
            mustBeNonnegative, mustBeMatrix, mustBeNonempty}
        reporter {mustBeNumeric, mustBeReal, mustBeFinite, ...
            mustBeNonnegative, mustBeMatrix, mustBeNonempty}
        options.SplitTouching (1,1) {mustBeA(options.SplitTouching,"logical")} = true
        options.PixelSizeMicrometers (1,1) {mustBeNumeric, mustBeReal, ...
            mustBeFinite, mustBePositive} = 0.35
        options.SaturationADU (1,1) {mustBeNumeric, mustBeReal, ...
            mustBeFinite, mustBePositive} = 4095
    end

    if ~isequal(size(reference), size(reporter))
        error("iGEM:Microscopy:ChannelSize", ...
            "The reference and reporter channels must have identical image dimensions.");
    end
    settings = struct(MinimumAreaPixels=80, GaussianSigmaPixels=1, ...
        WatershedDepthPixels=1.5, SplitTouching=options.SplitTouching, ...
        PixelSizeMicrometers=options.PixelSizeMicrometers, ...
        SaturationADU=options.SaturationADU);
    smoothReference = imgaussfilt(double(reference), settings.GaussianSigmaPixels);
    if max(smoothReference, [], "all") == min(smoothReference, [], "all")
        foreground = false(size(reference));
    else
        normalizedReference = rescale(smoothReference);
        foreground = normalizedReference > graythresh(normalizedReference);
    end
    foreground = imfill(foreground, "holes");
    cleaned = bwareaopen(foreground, settings.MinimumAreaPixels);
    interior = imclearborder(cleaned);
    removedBorder = bwconncomp(cleaned & ~interior);
    if options.SplitTouching && any(interior, "all")
        distance = -bwdist(~interior);
        distance(~interior) = -Inf;
        basins = watershed(imhmin(distance, settings.WatershedDepthPixels));
        interior(basins == 0) = false;
        interior = bwareaopen(interior, settings.MinimumAreaPixels);
    end
    components = bwconncomp(interior);
    labels = labelmatrix(components);
    backgroundPixels = ~imdilate(foreground, strel("disk", 4));
    if any(backgroundPixels, "all")
        backgroundADU = median(double(reporter(backgroundPixels)));
    else
        backgroundADU = NaN;
    end
    correctedReporter = double(reporter) - backgroundADU;
    measurements = regionprops("table", components, correctedReporter, ...
        "Area", "Centroid", "MeanIntensity");
    centroids = reshape(measurements.Centroid, [], 2);
    saturatedFraction = zeros(components.NumObjects, 1);
    for index = 1:components.NumObjects
        values = reporter(components.PixelIdxList{index});
        saturatedFraction(index) = nnz(values >= options.SaturationADU)/numel(values);
    end
    cells = table((1:components.NumObjects)', measurements.Area, ...
        measurements.Area*options.PixelSizeMicrometers^2, ...
        centroids(:,1), centroids(:,2), ...
        measurements.MeanIntensity, saturatedFraction, saturatedFraction > 0, ...
        VariableNames=["CellID", "AreaPixels", "AreaSquareMicrometers", ...
        "CentroidXPixel", "CentroidYPixel", "ReporterMeanADU", ...
        "SaturatedPixelFraction", "IsSaturated"]);
    validIntensity = cells.ReporterMeanADU(~cells.IsSaturated);
    summary = struct(CellCount=height(cells), ...
        MedianReporterADU=median(validIntensity, "omitmissing"), ...
        SaturatedCellCount=nnz(cells.IsSaturated), ...
        RemovedBorderObjects=removedBorder.NumObjects, BackgroundADU=backgroundADU);
    result = struct(Labels=labels, Cells=cells, Summary=summary, Settings=settings);
end
