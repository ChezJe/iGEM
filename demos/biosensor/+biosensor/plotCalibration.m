function chart = plotCalibration(bundle, sampleID)
    %plotCalibration - Plot calibration curves and inferred concentrations
    %   CHART = plotCalibration(BUNDLE,sampleID) plots the same curves,
    %   intervals, and independent measurements used in the app.
    %
    %   See also biosensor.inferConcentration, biosensor.makeState
    arguments
        bundle (1,1) struct
        sampleID {mustBeTextScalar} = "U1"
    end
    results = biosensor.inferConcentration(bundle, sampleID);
    chart = figure("Name", "Fluorescent biosensor calibration", "Color", "white");
    layout = tiledlayout(chart, 1, 2, "TileSpacing", "compact", "Padding", "compact");
    colors = [0, 0.447, 0.741; 0.850, 0.325, 0.098];
    for sensor = 1:2
        axesHandle = nexttile(layout);
        model = bundle.Models(sensor);
        hold(axesHandle, "on");
        fill(axesHandle, [model.Grid, fliplr(model.Grid)], [model.LowerBand, fliplr(model.UpperBand)], ...
            colors(sensor,:), "FaceAlpha", 0.16, "EdgeColor", "none", "DisplayName", "95% fit band");
        selected = bundle.Calibration.Sensor == model.Sensor & bundle.Calibration.Concentration_uM > 0;
        scatter(axesHandle, bundle.Calibration.Concentration_uM(selected), ...
            bundle.Calibration.Fluorescence_RFU(selected), 16, colors(sensor,:), ...
            "MarkerEdgeAlpha", 0.55, "DisplayName", "Standards");
        plot(axesHandle, model.Grid, model.Response, "Color", colors(sensor,:), "LineWidth", 2, ...
            "DisplayName", "Hill calibration");
        yline(axesHandle, results.MeanFluorescence_RFU(sensor), "--", "Color", colors(sensor,:), ...
            "LineWidth", 1.3, "DisplayName", "Unknown mean");
        if isfinite(results.Estimate_uM(sensor)) && results.Estimate_uM(sensor) > 0
            scatter(axesHandle, results.Estimate_uM(sensor), results.MeanFluorescence_RFU(sensor), ...
                65, colors(sensor,:), "filled", "DisplayName", "Inverse estimate");
        end
        set(axesHandle, "XScale", "log", "FontSize", 11);
        xlim(axesHandle, model.ConcentrationRange);
        xlabel(axesHandle, "Concentration (µM)");
        ylabel(axesHandle, "Fluorescence (RFU)");
        title(axesHandle, bundle.SensorLabels(sensor));
        subtitle(axesHandle, results.Status(sensor));
        grid(axesHandle, "on");
        legend(axesHandle, "Location", "southeast");
        hold(axesHandle, "off");
    end
    title(layout, string(sampleID) + ": two independent sensor measurements", "FontWeight", "bold");
end
