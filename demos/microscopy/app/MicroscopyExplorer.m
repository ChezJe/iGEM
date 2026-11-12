classdef MicroscopyExplorer < matlab.apps.App

    % Used to locate and load the app's XML configuration file
    properties (Access = public, Constant)
        AppConfigFilename = './MicroscopyExplorer.xml'; % File path to the app configuration file containing component layout and settings
    end

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        RootGrid                        matlab.ui.container.GridLayout
        StatusLabel                     matlab.ui.control.Label
        DisplayGrid                     matlab.ui.container.GridLayout
        CellTable                       matlab.ui.control.Table
        DistributionAxes                matlab.ui.control.UIAxes
        ImageAxes                       matlab.ui.control.UIAxes
        SummaryGrid                     matlab.ui.container.GridLayout
        QualityLabel                    matlab.ui.control.Label
        MedianLabel                     matlab.ui.control.Label
        CountLabel                      matlab.ui.control.Label
        ControlPanel                    matlab.ui.container.Panel
        ControlGrid                     matlab.ui.container.GridLayout
        HintLabel                       matlab.ui.control.Label
        ExportButton                    matlab.ui.control.Button
        ResetButton                     matlab.ui.control.Button
        OverlayCheckBox                 matlab.ui.control.CheckBox
        SplitCheckBox                   matlab.ui.control.CheckBox
        ConditionDropDown               matlab.ui.control.DropDown
        ConditionLabel                  matlab.ui.control.Label
        FieldDropDown                   matlab.ui.control.DropDown
        FieldLabel                      matlab.ui.control.Label
        HeadingGrid                     matlab.ui.container.GridLayout
        SubtitleLabel                   matlab.ui.control.Label
        TitleLabel                      matlab.ui.control.Label
    end

    properties (Access = private)
        CurrentField = []
        CurrentResult = []
        Data = []
    end

    methods (Access = public)

        function rows = exportMeasurements(app, filePath)
            %exportMeasurements - Write the displayed cell measurements to CSV
            %   ROWS = exportMeasurements(APP,filePath) writes the current cells
            %   and settings to filePath and also returns the exported table.
            rows = microscopyExportTable(app.CurrentResult, app.CurrentField.Field, ...
                app.CurrentField.Condition);
            writetable(rows, filePath);
        end

        function rows = getMeasurements(app)
            %getMeasurements - Return the current per-cell results and settings
            %   ROWS = getMeasurements(APP) returns the same table used for export.
            rows = microscopyExportTable(app.CurrentResult, app.CurrentField.Field, ...
                app.CurrentField.Condition);
        end

    end

    methods (Access = private)

        function refreshImage(app)
            displayImage = min(1, double(app.CurrentField.ReporterImage)/1500);
            if app.OverlayCheckBox.Value
                displayImage = labeloverlay(displayImage, bwperim(app.CurrentResult.Labels > 0), ...
                    Colormap=[1 0.8 0], Transparency=0);
            end
            imshow(displayImage, Parent=app.ImageAxes);
            title(app.ImageAxes, ["Reporter image"; "Boundaries from reference channel"]);
        end

        function refreshView(app)
            selected = string({app.Data.Fields.Field}) == string(app.FieldDropDown.Value) & ...
                string({app.Data.Fields.Condition}) == string(app.ConditionDropDown.Value);
            app.CurrentField = app.Data.Fields(selected);
            app.CurrentResult = analyzeMicroscopyField(app.CurrentField.ReferenceImage, ...
                app.CurrentField.ReporterImage, SplitTouching=app.SplitCheckBox.Value, ...
                PixelSizeMicrometers=app.Data.PixelSizeMicrometers, ...
                SaturationADU=app.Data.SaturationADU);
            app.refreshImage();
            cells = app.CurrentResult.Cells;
            validValues = cells.ReporterMeanADU(~cells.IsSaturated);
            histogram(app.DistributionAxes, validValues, BinEdges=0:100:1600);
            title(app.DistributionAxes, "Unsaturated reporter per cell");
            xlabel(app.DistributionAxes, "Reporter per cell (ADU)");
            ylabel(app.DistributionAxes, "Cells");
            xlim(app.DistributionAxes, [0 1600]);
            grid(app.DistributionAxes, "on");
            app.CountLabel.Text = sprintf("%d cells\nDetected in reference", height(cells));
            if isempty(validValues)
                app.MedianLabel.Text = sprintf("No valid intensities\nMedian reporter");
            else
                app.MedianLabel.Text = sprintf("%.0f ADU\nMedian reporter", median(validValues));
            end
            app.QualityLabel.Text = sprintf("%d saturated\n%d border objects excluded", ...
                app.CurrentResult.Summary.SaturatedCellCount, app.CurrentResult.Summary.RemovedBorderObjects);
            displayCells = cells(:, ["CellID", "AreaSquareMicrometers", "ReporterMeanADU", "IsSaturated"]);
        displayCells.AreaSquareMicrometers = round(displayCells.AreaSquareMicrometers, 2);
        displayCells.ReporterMeanADU = round(displayCells.ReporterMeanADU, 1);
        app.CellTable.Data = displayCells;
            app.CellTable.ColumnName = {"Cell", "Area (um^2)", "Reporter (ADU)", "Saturated"};
            app.StatusLabel.Text = sprintf("%s | %s | Background %.1f ADU | Pixel size %.2f um | Synthetic data", ...
                app.CurrentField.Field, app.CurrentField.Condition, ...
                app.CurrentResult.Summary.BackgroundADU, app.Data.PixelSizeMicrometers);
        end

    end

    % Callbacks that handle component events
    methods

        % Code that executes after component creation
        function startupFcn(app)
            appFolder = fileparts(which("MicroscopyExplorer"));
            addpath(fullfile(fileparts(appFolder), "functions"));
            app.Data = loadMicroscopyData();
            app.refreshView();
        end

        % Value changed function: ConditionDropDown, FieldDropDown, 
        % ...and 1 other components
        function selectionChanged(app, event)
            app.refreshView();
        end

        % Value changed function: OverlayCheckBox
        function overlayChanged(app, event)
            app.refreshImage();
        end

        % Button pushed function: ResetButton
        function resetPushed(app, event)
            app.FieldDropDown.Value = "Dense";
            app.ConditionDropDown.Value = "Induced";
            app.SplitCheckBox.Value = true;
            app.OverlayCheckBox.Value = true;
            app.refreshView();
        end

        % Button pushed function: ExportButton
        function exportPushed(app, event)
            [fileName, folder] = uiputfile('*.csv', 'Export cell measurements', 'microscopy-measurements.csv');
            if isequal(fileName, 0)
                return
            end
            try
                app.exportMeasurements(fullfile(folder, fileName));
                app.StatusLabel.Text = "Saved " + string(fileName) + " with the displayed analysis settings.";
            catch exception
                uialert(app.UIFigure, exception.message, "Export failed");
            end
        end
    end

    % App creation
    methods (Access = public)

        % Construct app
        function app = MicroscopyExplorer(varargin)
            app = app@matlab.apps.App(varargin{:});

            if nargout == 0
                clear app
            end
        end
    end
end