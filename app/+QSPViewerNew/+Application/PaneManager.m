classdef PaneManager < handle
    properties(Access = private)
        paneContainer (1,1) struct
        parent
        parentApp %todopax nice if removed.
        activePane
        paneToolbar
    end

    events
        Alert
    end

    methods
        function obj = PaneManager(itemTypes, parent, parentApp)
            arguments
                itemTypes cell
                parent
                parentApp
            end
            
            % Nodes that correspond to Model types.
            for i = 1:size(itemTypes, 1)
                obj.paneContainer.(itemTypes{i,2}) = [];
            end

            % Nodes purely on the UI side. E.g., summary nodes.
            obj.paneContainer.FunctionalitySummary = [];

            obj.parent = parent;
            obj.parentApp = parentApp;

            % Don't like that panetoolbar decides where to put itself. Fix this by standardizing to passing in the row, column.
            obj.paneToolbar = QSPViewerNew.Application.PaneToolbar(obj.parent); 
            
            addlistener(obj.paneToolbar, "Run", @(h,e)obj.onRun(h,e));
            addlistener(obj.paneToolbar, "Edit", @(h,e)obj.onEdit(h,e));
            addlistener(obj.paneToolbar, "Summary", @(h,e)obj.onSummary(h,e));
            addlistener(obj.paneToolbar, "Visualize", @(h,e)obj.onVisualize(h,e));
        end

        function openPane(obj, nodeData)
            arguments
                obj (1,1) QSPViewerNew.Application.PaneManager
                nodeData
            end

            if ~isempty(nodeData)
                if isfield(nodeData, "Type")
                    type = nodeData.Type;
                else
                    type = string(class(nodeData)).extractAfter("QSP.");
                end
                
                pane = obj.paneContainer.(type);

                if isempty(pane)
                    obj.paneContainer.(type) = obj.constructPane(type);
                    pane = obj.paneContainer.(type);
                end

                pane.("attachNew"+type)(nodeData);

                % Configure the Toolbar given the active pane.
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

        function newPane = constructPane(obj, type)
            arguments
                obj                
                type
            end    

            constructFcn = eval("@QSPViewerNew.Application." + type + "Pane");            
            newPane = feval(constructFcn, "Parent", obj.parent, "parentApp", obj.parentApp);            
            addlistener(newPane, "Alert", @(h,e)obj.onAlert(h,e));            
        end
               
        function onRun(obj, ~, ~)                                    
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
