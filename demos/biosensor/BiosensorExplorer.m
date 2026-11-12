classdef (Sealed) BiosensorExplorer < handle
    %BiosensorExplorer - Explore fluorescent biosensor calibration
    %   APP = BiosensorExplorer opens a local HTML interface backed by
    %   MATLAB analysis of bundled synthetic measurements.
    %
    %   APP = BiosensorExplorer(Visible="off") creates a hidden window.
    %
    %   BiosensorExplorer functions:
    %       selectSample  - Select a sample and emphasize a sensor
    %       exportResults - Save the currently displayed numeric results
    %
    %   BiosensorExplorer properties:
    %       UIFigure      - App window
    %       HTML          - HTML component
    %       CurrentResults - Current two-sensor result table
    %       IsReady       - HTML initialization completed
    %       LastRenderedRequestID - Latest confirmed HTML rendering
    %
    %   See also biosensor.loadData, biosensor.inferConcentration
    properties (SetAccess = private)
        UIFigure matlab.ui.Figure % App window
        HTML matlab.ui.control.HTML % Local HTML component
        CurrentResults table % Results currently displayed and exported
        IsReady (1,1) logical = false % HTML initialization completed
        LastRenderedRequestID (1,1) double = -1 % Latest confirmed rendering
    end
    properties (Access = private)
        Bundle (1,1) struct
        State (1,1) struct
        LastRequestID (1,1) double = 0
    end
    methods
        function app = BiosensorExplorer(options)
            arguments
                options.Visible (1,1) string {mustBeMember(options.Visible,["on","off"])} = "on"
            end
            app.Bundle = biosensor.loadData;
            [app.State, app.CurrentResults] = biosensor.makeState(app.Bundle, "U1", "A");
            app.UIFigure = uifigure("Name", "Fluorescent biosensor calibration", ...
                "Position", [80, 80, 1180, 760], "Visible", options.Visible);
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);
            app.UIFigure.UserData = app;
            layout = uigridlayout(app.UIFigure, [1,1], "Padding", [0,0,0,0]);
            app.HTML = uihtml(layout);
            app.HTML.HTMLEventReceivedFcn = @(~,event) app.handleEvent(event);
            app.HTML.HTMLSource = fullfile(fileparts(mfilename("fullpath")), "web", "biosensor.html");
        end

        function selectSample(app, sampleID, sensorID)
            %selectSample - Select a sample and emphasize a sensor
            %   selectSample(APP,sampleID,sensorID) updates the result table
            %   and the app's visual state using the shared analysis.
            arguments
                app
                sampleID {mustBeTextScalar}
                sensorID {mustBeTextScalar} = "A"
            end
            [nextState, nextResults] = biosensor.makeState(app.Bundle, sampleID, sensorID);
            app.State = nextState;
            app.CurrentResults = nextResults;
            app.LastRequestID = app.LastRequestID + 1;
            if app.IsReady
                app.sendState;
            end
        end

        function saved = exportResults(app, fileName)
            %exportResults - Export the displayed two-sensor result table
            %   SAVED = exportResults(APP) prompts for a CSV destination.
            %   Cancelling the dialog returns false.
            %
            %   SAVED = exportResults(APP,fileName) writes directly to the
            %   specified CSV file.
            arguments
                app
                fileName {mustBeTextScalar} = ""
            end
            saved = false;
            if strlength(string(fileName)) == 0
                suggestedName = "biosensor_" + app.State.sampleID + ".csv";
                [selectedName, selectedFolder] = uiputfile("*.csv", "Export biosensor results", suggestedName);
                if isequal(selectedName, 0)
                    return
                end
                fileName = fullfile(selectedFolder, selectedName);
            end
            [~,~,extension] = fileparts(fileName);
            if ~strcmpi(extension, ".csv")
                error("biosensor:ExportExtension", "Choose a filename ending in .csv.");
            end
            exported = app.CurrentResults;
            exported.EmphasizedSensor = repmat(app.State.activeSensor, height(exported), 1);
            exported.BundleVersion = repmat(app.Bundle.SchemaVersion, height(exported), 1);
            exported.BootstrapCount = repmat(app.Bundle.Models(1).BootstrapCount, height(exported), 1);
            writetable(exported, fileName);
            saved = true;
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isgraphics(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
    methods (Access = private)
        function handleEvent(app, event)
            %handleEvent - Validate and handle an HTML request
            requestID = 0;
            try
                payload = event.HTMLEventData;
                if ~isstruct(payload) || ~isscalar(payload) || ~isfield(payload, "requestId")
                    error("biosensor:BridgePayload", "The app received an incomplete request. Reset the app.");
                end
                requestID = payload.requestId;
                if ~isnumeric(requestID) || ~isscalar(requestID) || ~isreal(requestID) || ...
                        ~isfinite(requestID) || requestID < 0 || requestID ~= fix(requestID)
                    error("biosensor:RequestID", "The app received an invalid request identifier.");
                end
                if requestID < app.LastRequestID
                    return
                end
                app.LastRequestID = requestID;
                switch string(event.HTMLEventName)
                    case "Initialize"
                        app.IsReady = true;
                        app.sendState;
                    case "Analyze"
                        if ~all(isfield(payload, ["sampleID", "sensorID"]))
                            error("biosensor:Selection", "Select a prepared sample and sensor.");
                        end
                        [nextState, nextResults] = biosensor.makeState( ...
                            app.Bundle, payload.sampleID, payload.sensorID);
                        app.State = nextState;
                        app.CurrentResults = nextResults;
                        app.sendState;
                    case "ExportResults"
                        saved = app.exportResults;
                        result = struct("requestId", requestID, "saved", saved);
                        sendEventToHTMLSource(app.HTML, "ExportComplete", result);
                    case "Rendered"
                        app.LastRenderedRequestID = requestID;
                    otherwise
                        error("biosensor:UnknownEvent", "The app received an unsupported action.");
                end
            catch exception
                response = struct("requestId", requestID, "identifier", string(exception.identifier), ...
                    "message", string(exception.message));
                sendEventToHTMLSource(app.HTML, "Error", response);
            end
        end

        function sendState(app)
            %sendState - Send the confirmed MATLAB state to the HTML view
            response = app.State;
            response.requestId = app.LastRequestID;
            sendEventToHTMLSource(app.HTML, "State", response);
        end
    end
end
