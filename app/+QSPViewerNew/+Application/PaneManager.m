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

            obj.paneToolbar = QSPViewerNew.Application.PaneToolbar(obj.parent); % Don't like that panetoolbar decides where to put itself. Fix this by standardizing to passing in the row, column.
            addlistener(obj.paneToolbar, "Run", @(h,e)obj.onRun(h,e));
            addlistener(obj.paneToolbar, "Edit", @(h,e)obj.onEdit(h,e));
            addlistener(obj.paneToolbar, "Summary", @(h,e)obj.onSummary(h,e));
            addlistener(obj.paneToolbar, "Visualize", @(h,e)obj.onVisualize(h,e));
        end

        function openPane(obj, nodeData, type)
            arguments
                obj (1,1) QSPViewerNew.Application.PaneManager
                nodeData
                type (1,1) string = "unknown" % TODOpax remove this here. NodeData should be able to tell me what type it is.
            end

            if ~isempty(nodeData)
                if isfield(nodeData, "Type")
                    type = nodeData.Type;
                else
                    type = string(class(nodeData)).extractAfter("QSP.");
                end

                pane = obj.paneContainer.(type);
                if isempty(pane)
                    obj.paneContainer.(type) = obj.constructPane(nodeData, type);
                else
                    obj.paneContainer.(type).("attachNew"+type)(nodeData);
                end
            end
        end

        function activePane = constructPane(obj, nodeData, type)
            arguments
                obj
                nodeData
                type
            end
            
            constructFcn = eval("@QSPViewerNew.Application." + type + "Pane");            

            activePane = feval(constructFcn, "Parent", obj.parent, "parentApp", obj.parentApp);
            activePane.("attachNew"+type)(nodeData); %todopax, this should just be a call to update method of the pane. No need for custom names.

            addlistener(activePane, "Alert", @(h,e)obj.onAlert(h,e));

            obj.activePane = activePane;
            activePane.showThisPane();
        end
               
        function onRun(obj, h, e)                        
            disp('running');
            obj.activePane.runModel();
        end

        function onSummary(obj, h, e)
            obj.activePane.show('Summary');
        end

        function onEdit(obj, h, e)
            obj.activePane.show('Edit');            
        end

        function onVisualize(obj, h, e)
            obj.activePane.show('Visualization');
        end

        function onAlert(obj, hSource, eventData)
            notify(obj, "Alert", eventData);
        end
    end
end
