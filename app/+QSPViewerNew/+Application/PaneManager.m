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
            obj.paneContainer.Session              = []; %todopax: should be called SessionSummary

            obj.parent    = parent;
            obj.parentApp = parentApp;

            % Don't like that panetoolbar decides where to put itself. Fix this by standardizing to passing in the row, column.
            obj.paneToolbar = paneToolbar; %QSPViewerNew.Application.PaneToolbar(obj.parent); 
            
            if ~isempty(obj.paneToolbar)
                addlistener(obj.paneToolbar, "Run",       @(h,e)obj.onRun);
                addlistener(obj.paneToolbar, "Edit",      @(h,e)obj.onEdit(h,e));
                addlistener(obj.paneToolbar, "Summary",   @(h,e)obj.onSummary(h,e));
                addlistener(obj.paneToolbar, "Visualize", @(h,e)obj.onVisualize(h,e));
            end
        end
                
        function openPane(obj, nodeData)
            arguments
                obj (1,1) QSPViewerNew.Application.PaneManager
                nodeData (1,1)
            end

            if ~isempty(nodeData)
                % Summary panes will be invoked for nodeDatas of type
                % struct with a Type filed in them.
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
                end

                pane.("attachNew" + type)(nodeData);

                % Configure the Toolbar according to the pane prefs.
                obj.paneToolbar.mode = pane.toolbarMode;

                % todopax, we can optimize this if we can get a type
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
            addlistener(newPane, "Alert", @(h,e)obj.onAlert(h,e));            
        end
               
        function onRun(obj)
            obj.activePane.runModel();
        end

        function onSummary(obj, ~, ~)
            obj.activePane.show('Summary');
        end

        function onEdit(obj, ~, ~)
            obj.activePane.show('Edit');            
        end

        function onVisualize(obj, ~, ~)
            obj.activePane.show('Visualize');
        end

        function onAlert(obj, ~, eventData)
            notify(obj, "Alert", eventData);
        end        
    end
end
