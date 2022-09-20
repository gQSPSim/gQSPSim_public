classdef PaneManager < handle
    properties
        paneContainer (1,1) struct
        parent
        parentApp %todopax nice if removed.
        activePane
        paneToolbar
    end

    methods
        function obj = PaneManager(itemTypes, parent, parentApp)
            arguments
                itemTypes cell
                parent
                parentApp
            end
            
            for i = 1:size(itemTypes, 1)
                obj.paneContainer.(itemTypes{i,2}) = [];
            end

            obj.parent = parent;
            obj.parentApp = parentApp;

            obj.paneToolbar = QSPViewerNew.Application.PaneToolbar(obj.parent); % Don't like that panetoolbar decides where to put itself.
        end

        function openPane(obj, nodeData, type)
            arguments
                obj (1,1) QSPViewerNew.Application.PaneManager
                nodeData
                type (1,1) string = "unknown" % TODOpax remove this here. NodeData should be able to tell me what type it is.
            end
            
            if ~isempty(nodeData)
                type = string(class(nodeData)).extractAfter("QSP.");
            else
                type = "unknown";
                return; %TODOpax
            end

            pane = obj.paneContainer.(type);
            if isempty(pane)
                obj.paneContainer.(type) = obj.constructPane(nodeData, type);
            else
                obj.paneContainer.(type).("attachNew"+type)(nodeData);                
            end            
        end

        function activePane = constructPane(obj, nodeData, type)
            arguments
                obj
                nodeData
                type
            end
            
            constructFcn = eval("@QSPViewerNew.Application." + type + "Pane");            

            if isempty(nodeData)
                % Must be a summary node
                activePane = QSPViewerNew.Application.FunctionalitySummaryPane(Parent=obj.parent, parentApp=obj.parentApp);
                if ~isempty(selectedNode.Children)
                    activePane.attachNewNodeData([selectedNode.Children.NodeData]);
                end
            else                
                activePane = feval(constructFcn, "Parent", obj.parent, "parentApp", obj.parentApp);
                activePane.("attachNew"+type)(nodeData);
            end

            obj.activePane = activePane;
            activePane.showThisPane();
        end        
    end
end
