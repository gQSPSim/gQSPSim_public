classdef Simulation < uix.abstract.CardViewPane
    % Simulation - View Pane for the object
    % ---------------------------------------------------------------------
    % Display a viewer/editor for the object
    %

    
    %   Copyright 2014-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
  
    %% Private properties
    properties (Access=private)
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetHeader = {}
        DatasetHeaderPopupItems = {'-'}        
        DatasetHeaderPopupItemsWithInvalid = {'-'}
        
        TaskPopupTableItems = {}
        VPopPopupTableItems = {}
        
        PlotSpeciesAsInvalidTable = cell(0,2)
        PlotItemAsInvalidTable = cell(0,4)
        PlotDataAsInvalidTable = cell(0,2)
        PlotGroupAsInvalidTable = cell(0,3)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []
        PlotDataInvalidRowIndices = []
        PlotGroupInvalidRowIndices = []
        
    end
    
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = Simulation(varargin)
            
            % Call superclass constructor
            RunVis = true;
            obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the view
            obj.refresh();
            
        end
        
    end %methods
    
    
    %RAJ - for callbacks:
    %notify(obj, 'DataEdited', <eventdata>);
    
    
    %% Callbacks
    methods
        
        function onFolderSelection(vObj,h,evt) %#ok<*INUSD>
            
            % Update the value
            vObj.TempData.SimResultsFolderName = evt.NewValue;
            
            % Update the view
            updateResultsDir(vObj);
            
        end %function
        
        function onDatasetPopup(vObj,h,e)
            
            vObj.TempData.DatasetName = vObj.DatasetPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            
        end %function
        
        function onGroupNamePopup(vObj,h,e)
            
            vObj.TempData.GroupName = vObj.DatasetHeaderPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            
        end %function
        
        function onItemsButtonPressed(vObj,h,e)
            
            switch e.Interaction
                
                case 'Add'
                    
                    if ~isempty(vObj.TaskPopupTableItems) && ~isempty(vObj.VPopPopupTableItems)
                        NewTaskVPop = QSP.TaskVirtualPopulation;
                        NewTaskVPop.TaskName = vObj.TaskPopupTableItems{1};
                        NewTaskVPop.VPopName = vObj.VPopPopupTableItems{1};
                        vObj.TempData.Item(end+1) = NewTaskVPop;
                    else
                        hDlg = errordlg('At least one task and virtual population must be defined in order to add a simulation item.','Cannot Add','modal');
                        uiwait(hDlg);
                    end
                    
                case 'Remove'
                    
                    DeleteIdx = e.Indices;
                    if DeleteIdx <= numel(vObj.TempData.Item)
                        vObj.TempData.Item(DeleteIdx) = [];
                    end
            end
                
            Title = 'Refreshing view';
            hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
            
            uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Table...');
            % Update the view
            refreshItemsTable(vObj);
            uix.utility.CustomWaitbar(1,hWbar,'Done');
            if ~isempty(hWbar) && ishandle(hWbar)
                delete(hWbar);
            end
            
        end %function
        
        function onItemsTableEdit(vObj,h,e)
            
            NewData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            % Update entry
            if ColIdx == 1
                vObj.TempData.Item(RowIdx).TaskName = NewData{RowIdx,1};            
            elseif ColIdx == 2
                vObj.TempData.Item(RowIdx).VPopName = NewData{RowIdx,2};
            end
            
            Title = 'Refreshing view';
            hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
            
            uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Table...');
            % Update the view
            refreshItemsTable(vObj);
            uix.utility.CustomWaitbar(1,hWbar,'Done');
            if ~isempty(hWbar) && ishandle(hWbar)
                delete(hWbar);
            end
            
        end %function
        
        function onItemsTableSelect(vObj,h,e)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            updateItemsTable(vObj);
            
        end %function
        
        function onSpeciesTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            % Plot
            plotSimulation(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
        end %function
        
        function onItemsTableSelectionPlot(vObj,h,e)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            updateVisualizationView(vObj);
        end %function  
        
        function onItemsTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotItemTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            % Plot
            plotSimulation(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
        end %function
        
        function onDataTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotDataTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            % Plot
            plotSimulation(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
        end %function
        
        function onGroupTableSelectionPlot(vObj,h,e)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            updateVisualizationView(vObj);
        end %function        
        
        function onGroupTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotGroupTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            % Plot
            plotSimulation(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
        end %function
        
        function onPlotItemsTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotItemsTable,'SelectedRows');
            ThisColor = vObj.Data.PlotItemTable{SelectedRow,2};
            
            NewColor = uisetcolor(ThisColor);
            
            if ~isequal(NewColor,0)
                vObj.Data.PlotItemTable{SelectedRow,2} = NewColor;                 
                
%                 try
                % Plot
                plotSimulation(vObj.Data,vObj.h.MainAxes);
                %                 catch ME
%                     hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                     uiwait(hDlg);
%                 end

                % Update the view
                updateVisualizationView(vObj);
                
            end
        end %function
        
        function onPlotGroupTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotGroupTable,'SelectedRows');
            ThisColor = vObj.Data.PlotGroupTable{SelectedRow,2};
            
            NewColor = uisetcolor(ThisColor);
            
            if ~isequal(NewColor,0)
                vObj.Data.PlotGroupTable{SelectedRow,2} = NewColor;                                  
                
%                 try
                % Plot
                plotSimulation(vObj.Data,vObj.h.MainAxes);
                                %                 catch ME
%                     hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                     uiwait(hDlg);
%                 end

                % Update the view
                updateVisualizationView(vObj);
                
            end
            
        end %function
        
    end
        
    
end %classdef