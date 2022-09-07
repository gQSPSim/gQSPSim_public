classdef FunctionalitySummaryPane < matlab.mixin.Heterogeneous & handle
    %  FunctionalitySummaryPane - A Class for the summary view for
    %  functionality blocks
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2021 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Karthiga Mahalingam
    %
    %  6/24/21
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        NodeData 
        Parent
        LayoutRow
        LayoutColumn
        ParentApp
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
        function obj = FunctionalitySummaryPane(varargin)
             if length(varargin{1}) == 4 && isa(varargin{1}{1},'matlab.ui.container.GridLayout')
                obj.Parent = varargin{1}{1};
                obj.LayoutRow = varargin{1}{2};
                obj.LayoutColumn = varargin{1}{3};
                obj.ParentApp = varargin{1}{4};
             else
                message = ['This constructor requires the following inputs' ...
                    newline '1.' ...
                    newline '-Graphical Parent: uigridlayout...' ...
                    newline '-GridRow: int' ...
                    newline '-GridColumn: int' ...
                    newline '-uigridlayout...' ...
                    newline '-Parent application: matlab.apps.AppBase'];
                    error(message)
            end

            %create the objects on our end
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
                summaryData = arrayfun(@(x) x.getSummaryTableItems, obj.NodeData, 'UniformOutput', false);
                summaryData1 = cellfun(@(x) x(:,2)', summaryData, 'UniformOutput', false);
                
                tableData = cell2table(vertcat(summaryData1{:}), 'VariableNames', summaryData{1}(:,1));
                
                obj.TableMain.Data = tableData;
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
    end
end