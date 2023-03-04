classdef FunctionalitySummaryPane < matlab.mixin.Heterogeneous & handle
    %  FunctionalitySummaryPane - A Class for the summary view for
    %  functionality blocks
    %
    % 
    events
        Alert
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        NodeData 
        Parent
        LayoutRow
        LayoutColumn
        ParentApp
        toolbarMode (1,1) QSPViewerNew.Application.ToolbarMode = QSPViewerNew.Application.ToolbarMode.None;
    end
    
    properties(Access = private)
        GridMain         matlab.ui.container.GridLayout
        TableMain        matlab.ui.control.Table
        EmptyParent = matlab.ui.Figure.empty(1,0);
        SummaryLabel     matlab.ui.control.Label
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = FunctionalitySummaryPane(pvargs)
            arguments
                pvargs.Parent (1,1) matlab.ui.container.GridLayout
                pvargs.layoutrow (1,1) double = 2 
                pvargs.layoutcolumn (1,1) double = 1
                pvargs.parentApp
                pvargs.HasVisualization(1,1) logical = false
            end
             
            obj.Parent       = pvargs.Parent;
            obj.LayoutRow    = pvargs.layoutrow;
            obj.LayoutColumn = pvargs.layoutcolumn;
            obj.ParentApp    = pvargs.parentApp;            
            
            obj.create();
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Public methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function create(obj)
            % Create Main Grid
            obj.GridMain = uigridlayout(obj.Parent);
            obj.GridMain.Layout.Row = obj.LayoutRow;
            obj.GridMain.Layout.Column = obj.LayoutColumn;
            obj.GridMain.ColumnWidth = {'1x'};
            obj.GridMain.RowHeight = {'fit', '1x'};
            
            %Add label to the top
           obj.SummaryLabel = uilabel(obj.GridMain);
           obj.SummaryLabel.Text = " Summary";
           obj.SummaryLabel.FontSize = 20;
           obj.SummaryLabel.FontWeight = 'bold';
           obj.SummaryLabel.Layout.Row = 1;
           obj.SummaryLabel.Layout.Column = 1;
            
            % Create UITable
            obj.TableMain = uitable(obj.GridMain, 'ColumnSortable', true);
            obj.TableMain.Layout.Row = 2;
            obj.TableMain.Layout.Column = 1;
            
            % Update table with data
            obj.update();
        end
        
        function update(obj)
            if ~isempty(obj.NodeData)
                childrenFieldName = "ChildNodeData";
                if class(obj.NodeData) == "QSP.Folder"
                    childrenFieldName = "Children";
                end
                
                summaryData = arrayfun(@(x) x.getSummaryTableItems, obj.NodeData.(childrenFieldName), 'UniformOutput', false);
                summaryData1 = cellfun(@(x) x(:,2)', summaryData, 'UniformOutput', false);
                
                if ~isempty(summaryData1)
                    tableData = cell2table(vertcat(summaryData1{:}), 'VariableNames', summaryData{1}(:,1));
                    obj.TableMain.Data = tableData;
                end
            end
        end
        
        function hideThisPane(obj)
            %hide this pane
            obj.GridMain.Parent = obj.EmptyParent;
        end
        
        function showThisPane(obj)
            obj.GridMain.Parent = obj.Parent;
        end
        
        function attachNewNodeData(obj, nodeData)
            obj.NodeData = nodeData;
            obj.update();
        end

        function attachNewFunctionalitySummary(obj, nodeData)
            obj.NodeData = nodeData;
            obj.update();
        end
    end
end