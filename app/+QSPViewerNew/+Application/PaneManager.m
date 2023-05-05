classdef PaneManager < handle
    properties(Access = private)
        paneContainer (1,1) struct
        parent
        parentApp
        activePane
        paneToolbar
    end

    events
        Alert
        PaneStateChange
    end

    methods
        function obj = PaneManager(parent, parentApp, itemTypes, paneToolbar)
            arguments                
                parent
                parentApp
                itemTypes cell
                paneToolbar QSPViewerNew.Application.PaneToolbar = QSPViewerNew.Application.PaneToolbar.empty();
            end
            
            % Nodes that correspond to Model types.
            for i = 1:size(itemTypes, 1)
                obj.paneContainer.(itemTypes{i,2}) = [];
            end

            % Nodes purely on the UI side. E.g., summary nodes.
            % Note that since these types are purely in the UI they do not
            % appear in the itemTypes and should not.
            obj.paneContainer.FunctionalitySummary = [];
            obj.paneContainer.Session              = [];

            obj.parent    = parent;
            obj.parentApp = parentApp;

            % The MainView supplies the toolbar. empty is supported and
            % used when there is no UI.
            obj.paneToolbar = paneToolbar;
            
            if ~isempty(obj.paneToolbar)
                addlistener(obj.paneToolbar, "Run",       @(h,e)obj.onRun);
                addlistener(obj.paneToolbar, "Edit",      @(h,e)obj.onEdit);
                addlistener(obj.paneToolbar, "Summary",   @(h,e)obj.onSummary);
                addlistener(obj.paneToolbar, "Visualize", @(h,e)obj.onVisualize);
                addlistener(obj.paneToolbar, "Settings",  @(h,e)obj.onSettings);
            end
        end
                
        function openPane(obj, nodeData)
            arguments
                obj (1,1) QSPViewerNew.Application.PaneManager
                nodeData (1,1)
            end

            if ~isempty(nodeData)
                % Summary panes will be invoked for nodeDatas of type
                % struct with a Type field in them.
                if isfield(nodeData, "Type")
                    type = nodeData.Type;
                elseif class(nodeData) == "QSP.Folder"
                    % Also invoke a summary pane for the children in the
                    % Folder
                    type = "FunctionalitySummary";
                else                    
                    type = string(class(nodeData)).extractAfter("QSP.");
                end

                pane = obj.paneContainer.(type);

                if isempty(pane)
                    obj.paneContainer.(type) = obj.constructPane(type);
                    pane = obj.paneContainer.(type);
                    % Some panes don't have a StateChange event therefore
                    % conditionally add a listener.
                    if any(string(events(pane)) == "StateChange")
                        addlistener(pane, 'StateChange', @(h,e)obj.onUpdateTree(e));
                    end
                end

                % This should be a call to a method named update.
                % No need for special names for such a class method.
                pane.("attachNew" + type)(nodeData);

                % Configure the Toolbar according to the pane prefs.
                obj.paneToolbar.mode = pane.toolbarMode;

                % This can be optimized if we can get a type
                % off the activePane, that is not available right now.

                if ~isempty(obj.activePane)
                    obj.activePane.hideThisPane();
                end
                pane.showThisPane();
                obj.activePane = pane;
            end
        end

        function closeActivePane(obj)
            % this could be done via events or just a function call. 
            % opting for function call for now since this is all inside the
            % view.
            if ~isempty(obj.activePane)
                obj.activePane.hideThisPane();
            end
        end
    end

    methods(Access = private)
        function newPane = constructPane(obj, type)
            arguments
                obj                
                type
            end    

            constructFcn = eval("@QSPViewerNew.Application." + type + "Pane");            
            newPane = feval(constructFcn, "Parent", obj.parent, "parentApp", obj.parentApp);            
            addlistener(newPane, "Alert", @(h,e)obj.onAlert(e));
        end
               
        function onRun(obj)
            obj.activePane.runModel();
        end

        function onSummary(obj)
            obj.activePane.show('Summary');
        end

        function onEdit(obj)
            obj.activePane.show('Edit');            
        end

        function onVisualize(obj)
            obj.activePane.show('Visualize');
        end

        function onSettings(obj)
            obj.activePane.show('Settings');
        end

        function onAlert(obj, eventData)
            notify(obj, "Alert", eventData);
        end

        function onUpdateTree(obj, eventData)
            % could filter the information passed along to the tree control
            % but at this point there may be uses for data beyond Name and
            % Description so lets go ahead and apps the whole thing.
            notify(obj, 'PaneStateChange', eventData);
        end
    end
end
