classdef (Sealed) VirtualLabExplorer < handle
    %VirtualLabExplorer - Plan and run SimBiology virtual experiments
    %   APP = VirtualLabExplorer opens an experiment-planning interface.
    %   MATLAB and SimBiology own the session, predictions, and experiments.
    %
    %   APP = VirtualLabExplorer(Seed=SEED,Visible="off") selects a
    %   repeatable session seed and optionally creates a hidden window.
    %
    %   VirtualLabExplorer functions:
    %       getState           - Return the scientific session state
    %       proposeBatch       - Suggest experiments without spending budget
    %       runBatch           - Run the proposed SimBiology experiments
    %       setGrowthThreshold - Set the minimum relative-growth requirement
    %       resetSession       - Start again with the same seed
    %       exportRun          - Save observations and a reproducible run
    %       openModel          - Open the independent SimBiology model
    %
    %   VirtualLabExplorer properties:
    %       UIFigure              - App window
    %       HTML                  - Local HTML component
    %       CurrentView           - Display data from the shared backend
    %       IsReady               - HTML initialization completed
    %       IsBusy                - A session action is in progress
    %       LastRenderedRequestID - Latest confirmed HTML rendering
    %
    %   See also virtuallab.newSession, virtuallab.viewState
    properties (SetAccess = private)
        UIFigure matlab.ui.Figure % App window
        HTML matlab.ui.control.HTML % Local HTML component
        CurrentView (1,1) struct = struct % Backend display data
        IsReady (1,1) logical = false % HTML initialization completed
        IsBusy (1,1) logical = false % A session action is in progress
        LastRenderedRequestID (1,1) double = -1 % Latest rendered update
    end
    properties (Access = private)
        Session (1,1) struct = struct
        Seed (1,1) double = 2026
        LastRequestID (1,1) double = 0
        UpdateID (1,1) double = 0
        CancelRequested (1,1) logical = false
        CloseRequested (1,1) logical = false
        ProgressDialog = []
        BusyMessage (1,1) string = ""
    end
    methods
        function app = VirtualLabExplorer(options)
            arguments
                options.Seed (1,1) {mustBeNumeric,mustBeReal,mustBeInteger,mustBeNonnegative} = 2026
                options.Visible (1,1) string {mustBeMember(options.Visible,["on","off"])} = "on"
            end
            app.Seed = double(options.Seed);
            app.UIFigure = uifigure("Name", "Virtual Lab: choose the next experiment", ...
                "Position", [70,70,1280,800], "Visible", options.Visible);
            app.UIFigure.CloseRequestFcn = @(~,~) app.requestClose;
            app.UIFigure.UserData = app;
            layout = uigridlayout(app.UIFigure,[1,1],"Padding",[0,0,0,0]);
            app.HTML = uihtml(layout);
            app.HTML.HTMLEventReceivedFcn = @(~,event) app.handleEvent(event);
            app.HTML.HTMLSource = fullfile(fileparts(mfilename("fullpath")),"web","virtual-lab.html");
            try
                app.resetSession;
            catch exception
                app.BusyMessage = "Initialization failed: " + string(exception.message);
                app.sendError(exception,app.LastRequestID);
                if isgraphics(app.UIFigure)
                    uialert(app.UIFigure,exception.message,"Virtual Lab could not start");
                end
            end
        end

        function state = getState(app)
            %getState - Return the shared scientific session state
            %   STATE = getState(APP) returns a value copy suitable for
            %   inspecting or replaying the session with virtuallab.
            state = app.Session;
        end

        function proposal = proposeBatch(app)
            %proposeBatch - Suggest a batch without running experiments
            %   PROPOSAL = proposeBatch(APP) uses only observed data to
            %   recommend the next conditions. It spends no experiment budget.
            app.requireIdle;
            app.requireSession;
            cleanup = app.beginAction("Suggesting experiments from the observed data…",false); %#ok<NASGU>
            [nextState,proposal] = virtuallab.propose(app.Session);
            app.Session = nextState;
            app.refreshView;
        end

        function state = runBatch(app)
            %runBatch - Run the currently proposed SimBiology experiments
            %   STATE = runBatch(APP) commits each completed experiment
            %   before starting the next. Cancellation stops between runs.
            app.requireIdle;
            app.requireSession;
            view = virtuallab.viewState(app.Session);
            if ~view.canRun
                error("virtuallab:NoRunnableProposal", ...
                    "Suggest a current batch before running experiments.");
            end
            cleanup = app.beginAction("Preparing the proposed SimBiology experiments…",true); %#ok<NASGU>
            plannedCount = numel(view.proposal);
            initialCompleted = view.completedCount;
            while true
                drawnow;
                if app.shouldStop
                    app.BusyMessage = "Stopped after the last completed experiment. The remaining proposal can resume.";
                    break
                end
                before = virtuallab.viewState(app.Session);
                if ~before.canRun || isempty(before.proposal)
                    break
                end
                finished = before.completedCount - initialCompleted;
                app.updateProgress(finished/max(1,plannedCount), ...
                    "Simulating experiment " + (finished + 1) + " of " + plannedCount + ...
                    ". Cancel stops after the current experiment.");
                app.Session = virtuallab.runBatch(app.Session,MaxExperiments=1);
                app.refreshView;
                after = app.CurrentView;
                if after.completedCount <= before.completedCount || string(after.status) == "error"
                    break
                end
            end
            state = app.Session;
        end

        function state = setGrowthThreshold(app,threshold)
            %setGrowthThreshold - Change the minimum relative-growth target
            %   STATE = setGrowthThreshold(APP,THRESHOLD) selects 0.8 or 0.9.
            %   Observations and budget remain; an old proposal is invalidated.
            arguments
                app
                threshold (1,1) {mustBeNumeric,mustBeReal,mustBeFinite,mustBeMember(threshold,[0.8,0.9])}
            end
            app.requireIdle;
            app.requireSession;
            cleanup = app.beginAction("Updating the growth requirement…",false); %#ok<NASGU>
            app.Session = virtuallab.setConstraint(app.Session,double(threshold));
            app.refreshView;
            state = app.Session;
        end

        function state = resetSession(app)
            %resetSession - Start again with the original session seed
            %   STATE = resetSession(APP) restores eight initial virtual
            %   measurements, twelve available experiments, and no proposal.
            app.requireIdle;
            cleanup = app.beginAction("Preparing the initial SimBiology observations…",false); %#ok<NASGU>
            app.Session = virtuallab.newSession(seed=app.Seed);
            app.refreshView;
            state = app.Session;
        end

        function exported = exportRun(app,folder)
            %exportRun - Save the observed data and reproducible run state
            %   EXPORTED = exportRun(APP) prompts for a destination folder.
            %   Cancelling the dialog returns false.
            %
            %   EXPORTED = exportRun(APP,FOLDER) exports directly into FOLDER.
            arguments
                app
                folder {mustBeTextScalar} = ""
            end
            app.requireIdle;
            app.requireSession;
            exported = false;
            if strlength(string(folder)) == 0
                selected = uigetdir(pwd,"Choose a folder for the Virtual Lab run");
                if isequal(selected,0)
                    return
                end
                folder = string(selected);
            end
            cleanup = app.beginAction("Exporting observations and the reproducible run…",false); %#ok<NASGU>
            virtuallab.exportRun(app.Session,folder);
            exported = true;
        end

        function model = openModel(app)
            %openModel - Open the independent SimBiology experiment model
            %   MODEL = openModel(APP) opens a separate model in SimBiology
            %   Model Builder. It does not alter the current experiment run.
            app.requireIdle;
            cleanup = app.beginAction("Opening the SimBiology experiment model…",false); %#ok<NASGU>
            model = virtuallab.createModel;
            try
                simBiologyModelBuilder(model);
            catch exception
                delete(model);
                rethrow(exception);
            end
        end

        function delete(app)
            app.CancelRequested = true;
            app.closeProgress;
            if ~isempty(app.UIFigure) && isgraphics(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
    methods (Access = private)
        function cleanup = beginAction(app,message,cancellable)
            %beginAction - Make a bounded session action explicit in the UI
            app.IsBusy = true;
            app.CancelRequested = false;
            app.BusyMessage = message;
            cancelValue = "off";
            if cancellable
                cancelValue = "on";
            end
            app.ProgressDialog = uiprogressdlg(app.UIFigure,"Title","Virtual Lab", ...
                "Message",message,"Indeterminate","on","Cancelable",cancelValue);
            app.sendStatus;
            drawnow;
            cleanup = onCleanup(@() app.finishAction);
        end

        function finishAction(app)
            %finishAction - Restore controls after success, stop, or error
            if ~isvalid(app)
                return
            end
            app.closeProgress;
            app.IsBusy = false;
            if app.CloseRequested
                delete(app);
                return
            end
            app.sendState;
        end

        function updateProgress(app,value,message)
            %updateProgress - Update between bounded SimBiology calls
            app.BusyMessage = message;
            if ~isempty(app.ProgressDialog) && isvalid(app.ProgressDialog)
                app.ProgressDialog.Indeterminate = "off";
                app.ProgressDialog.Value = min(1,max(0,value));
                app.ProgressDialog.Message = message;
            end
            app.sendStatus;
            drawnow;
        end

        function stop = shouldStop(app)
            %shouldStop - Observe cancellation between experiments
            stop = app.CancelRequested || app.CloseRequested;
            if ~isempty(app.ProgressDialog) && isvalid(app.ProgressDialog)
                stop = stop || app.ProgressDialog.CancelRequested;
            end
        end

        function closeProgress(app)
            %closeProgress - Close an existing progress dialog
            if ~isempty(app.ProgressDialog) && isvalid(app.ProgressDialog)
                close(app.ProgressDialog);
            end
            app.ProgressDialog = [];
        end

        function requestClose(app)
            %requestClose - Keep completed work consistent before closing
            if app.IsBusy
                app.CloseRequested = true;
                app.CancelRequested = true;
                if ~isempty(app.ProgressDialog) && isvalid(app.ProgressDialog)
                    app.ProgressDialog.Message = "Closing after the current bounded operation…";
                end
            else
                delete(app);
            end
        end

        function requireIdle(app)
            %requireIdle - Prevent overlapping scientific state mutations
            if app.IsBusy
                error("virtuallab:AppBusy","Wait for the current action or cancel the running batch.");
            end
        end

        function requireSession(app)
            %requireSession - Require a successfully initialized session
            if isempty(fieldnames(app.Session))
                error("virtuallab:NoSession","Reset the session after resolving the startup error.");
            end
        end

        function refreshView(app)
            %refreshView - Commit display data from the shared backend
            app.CurrentView = virtuallab.viewState(app.Session);
            app.sendState;
        end

        function handleEvent(app,event)
            %handleEvent - Validate frontend requests and call the public API
            requestID = 0;
            try
                payload = event.HTMLEventData;
                if ~isstruct(payload) || ~isscalar(payload) || ~isfield(payload,"requestId")
                    error("virtuallab:BridgePayload","The request is incomplete. Reset the interface.");
                end
                requestID = payload.requestId;
                if ~isnumeric(requestID) || ~isscalar(requestID) || ~isreal(requestID) || ...
                        ~isfinite(requestID) || requestID < 0 || requestID ~= fix(requestID) || requestID > flintmax
                    error("virtuallab:BridgeRequestID","The request identifier is invalid.");
                end
                eventName = string(event.HTMLEventName);
                if eventName == "Rendered"
                    if isfield(payload,"updateId") && isnumeric(payload.updateId) && ...
                            isscalar(payload.updateId) && isfinite(payload.updateId)
                        app.LastRenderedRequestID = max(app.LastRenderedRequestID,payload.updateId);
                    end
                    return
                end
                if requestID < app.LastRequestID
                    return
                end
                app.LastRequestID = requestID;
                switch eventName
                    case "Initialize"
                        app.IsReady = true;
                        app.sendState;
                    case "Suggest"
                        app.proposeBatch;
                    case "Run"
                        app.runBatch;
                    case "SetConstraint"
                        if ~isfield(payload,"threshold")
                            error("virtuallab:MissingThreshold","Select a growth requirement of 0.8 or 0.9.");
                        end
                        app.setGrowthThreshold(payload.threshold);
                    case "Reset"
                        app.resetSession;
                    case "Export"
                        saved = app.exportRun;
                        sendEventToHTMLSource(app.HTML,"ExportComplete",struct("requestId",requestID,"saved",saved));
                    case "OpenModel"
                        app.openModel;
                    otherwise
                        error("virtuallab:UnknownAction","The requested Virtual Lab action is not supported.");
                end
            catch exception
                app.sendError(exception,requestID);
            end
        end

        function sendState(app)
            %sendState - Publish confirmed scientific state with UI status
            if ~app.IsReady || ~isgraphics(app.HTML)
                return
            end
            if isempty(fieldnames(app.CurrentView))
                app.sendStatus;
                return
            end
            app.UpdateID = app.UpdateID + 1;
            response = app.CurrentView;
            response.requestId = app.LastRequestID;
            response.updateId = app.UpdateID;
            response.busy = app.IsBusy;
            response.busyMessage = app.BusyMessage;
            sendEventToHTMLSource(app.HTML,"State",response);
        end

        function sendStatus(app)
            %sendStatus - Show a real backend action before it runs
            if app.IsReady && isgraphics(app.HTML)
                response = struct("requestId",app.LastRequestID,"busy",app.IsBusy,"message",app.BusyMessage);
                sendEventToHTMLSource(app.HTML,"Status",response);
            end
        end

        function sendError(app,exception,requestID)
            %sendError - Surface an action failure without discarding state
            if app.IsReady && isgraphics(app.HTML)
                response = struct("requestId",requestID,"identifier",string(exception.identifier), ...
                    "message",string(exception.message),"busy",app.IsBusy);
                sendEventToHTMLSource(app.HTML,"Error",response);
            end
        end
    end
end
