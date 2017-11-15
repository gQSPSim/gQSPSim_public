classdef VirtualPopulationGeneration < uix.abstract.CardViewPane
    % VirtualPopulationGeneration - View Pane for the object
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
    properties (SetAccess=private)
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetGroupPopupItems = {'-'}        
        DatasetGroupPopupItemsWithInvalid = {'-'}
        
        ParameterPopupItems = {'-'}
        ParameterPopupItemsWithInvalid = {'-'}
        
        TaskPopupTableItems = {}
        GroupIDPopupTableItems = {}
        SpeciesPopupTableItems = {} % From Tasks
        
        DatasetHeader = {}
        DatasetDataColumn = {}
        DatasetData = {};
        
        ParametersHeader = {} % From RefParamName
        ParametersData = {} % From RefParamName
        
        ObjectiveFunctions = {'defaultObj'}
        
        PlotSpeciesAsInvalidTable = cell(0,3)
        PlotItemAsInvalidTable = cell(0,4)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []       
        
    end
    
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = VirtualPopulationGeneration(varargin)
            
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
    
    
    %% Methods from CardViewPane
    methods
       function onPlotConfigChange(obj,h,e)
            
            Value = get(h,'Value');
            obj.Data.SelectedPlotLayout = obj.PlotLayoutOptions{Value};
            
            % Update the view
            updateVisualizationView(obj);
            update(obj);
        end 
    end
    
    
    %% Callbacks
    methods
        
        function onFolderSelection(vObj,h,evt) %#ok<*INUSD>
            
            % Update the value
            vObj.TempData.VPopResultsFolderName = evt.NewValue;
            
            % Update the view
            updateResultsDir(vObj);
            
        end %function
        
        function onDatasetPopup(vObj,h,e)
            
            vObj.TempData.DatasetName = vObj.DatasetPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            
        end %function
        
        function onParametersPopup(vObj,h,e)
            
            vObj.TempData.RefParamName = vObj.ParameterPopupItems{get(h,'Value')};
            
            % Try importing to load data for Parameters view
            MatchIdx = strcmp({vObj.TempData.Settings.Parameters.Name},vObj.TempData.RefParamName);
            if any(MatchIdx)
                pObj = vObj.TempData.Settings.Parameters(MatchIdx);
                [StatusOk,Message,vObj.ParametersHeader,vObj.ParametersData] = importData(pObj,pObj.FilePath);
                if ~StatusOk
                    hDlg = errordlg(Message,'Parameter Import Failed','modal');
                    uiwait(hDlg);
                end
            end
            
            % Update the view
            refreshParameters(vObj);
            
        end %function
        
        function onGroupNamePopup(vObj,h,e)
            
            vObj.TempData.GroupName = vObj.DatasetGroupPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            refreshItemsTable(vObj);
            
        end %function
        
        function onTableButtonPressed(vObj,h,e,TableTag)
            
            FlagRefreshTables = true;
            
            switch e.Interaction
                
                case 'Add'
                    
                    if strcmpi(TableTag,'OptimItems')
                        if ~isempty(vObj.TaskPopupTableItems) && ~isempty(vObj.GroupIDPopupTableItems)
                            NewTaskGroup = QSP.TaskGroup;
                            NewTaskGroup.TaskName = vObj.TaskPopupTableItems{1};
                            NewTaskGroup.GroupID = vObj.GroupIDPopupTableItems{1};
                            vObj.TempData.Item(end+1) = NewTaskGroup;
                        else
                            hDlg = errordlg('At least one task and the group column must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                            
                    elseif strcmpi(TableTag,'SpeciesData')
                        if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.DatasetDataColumn)
                            NewSpeciesData = QSP.SpeciesData;
                            NewSpeciesData.SpeciesName = vObj.SpeciesPopupTableItems{1};
                            NewSpeciesData.DataName = vObj.DatasetDataColumn{1};
                            DefaultExpression = 'x';
                            NewSpeciesData.FunctionExpression = DefaultExpression;
                            vObj.TempData.SpeciesData(end+1) = NewSpeciesData;
                        else
                            hDlg = errordlg('At least one task with active species and a non-empty ''Data'' column in the dataset must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                    end
                    
                case 'Remove'
                    
                    DeleteIdx = e.Indices;
                    
                    if DeleteIdx <= numel(vObj.TempData.Item) && strcmpi(TableTag,'OptimItems')
                        vObj.TempData.Item(DeleteIdx) = [];
                    elseif DeleteIdx <= numel(vObj.TempData.SpeciesData) && strcmpi(TableTag,'SpeciesData')
                        vObj.TempData.SpeciesData(DeleteIdx) = [];
                    else
                        FlagRefreshTables = false;
                    end
            end
                
            % Update the view
            if FlagRefreshTables
                if strcmpi(TableTag,'OptimItems')
                    Title = 'Refreshing view';
                    hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
                    
                    % Tasks => Species
                    uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Tables...');
                    refreshItemsTable(vObj);
                    refreshSpeciesDataTable(vObj);
                    
                    uix.utility.CustomWaitbar(1,hWbar,'Done');
                    if ~isempty(hWbar) && ishandle(hWbar)
                        delete(hWbar);
                    end
                    
                elseif strcmpi(TableTag,'SpeciesData')
                    refreshSpeciesDataTable(vObj);
                end
            end
            
        end %function
        
        function onTableEdit(vObj,h,e,TableTag)
            
            NewData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            % Update entry
            if strcmpi(TableTag,'OptimItems')            
                if ColIdx == 1
                    vObj.TempData.Item(RowIdx).TaskName = NewData{RowIdx,1};            
                elseif ColIdx == 2
                    vObj.TempData.Item(RowIdx).GroupID = NewData{RowIdx,2};
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                if ColIdx == 1
                    vObj.TempData.SpeciesData(RowIdx).SpeciesName = NewData{RowIdx,1};
                elseif ColIdx == 3
                    vObj.TempData.SpeciesData(RowIdx).FunctionExpression = NewData{RowIdx,3};
                elseif ColIdx == 4
                    vObj.TempData.SpeciesData(RowIdx).DataName = NewData{RowIdx,4};
                elseif ColIdx == 5
                    vObj.TempData.SpeciesData(RowIdx).ObjectiveName = NewData{RowIdx,5};
                end
                
            end
            
            % Update the view
            if strcmpi(TableTag,'OptimItems')
                Title = 'Refreshing view';
                hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
                
                % Tasks => Species
                uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Tables...');
                refreshItemsTable(vObj);
                refreshSpeciesDataTable(vObj);
                
                uix.utility.CustomWaitbar(1,hWbar,'Done');
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                refreshSpeciesDataTable(vObj);
            end
            
        end %function
        
        function onTableSelect(vObj,h,e,TableTag)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            if strcmpi(TableTag,'OptimItems')
                updateItemsTable(vObj);                
            elseif strcmpi(TableTag,'SpeciesData')
                updateSpeciesDataTable(vObj);
            end
            
        end %function
        
        function onMaxNumSimulationsEdit(vObj,h,e)
            
            value = vObj.TempData.MaxNumSimulations;
            try
                value = str2double(get(h,'Value'));
            catch ME
                hDlg = errordlg(ME.message,'Invalid Value','modal');
                uiwait(hDlg);
            end
            if isnan(value) || value <= 0
                hDlg = errordlg('Invalid Value','modal');
                uiwait(hDlg);
            else
                vObj.TempData.MaxNumSimulations = value;
            end
            % Update the view
            updateMaxNumSims(vObj);
            
        end %function
        
        function onMaxNumVirtualPatientsEdit(vObj,h,e)
            
            value = vObj.TempData.MaxNumVirtualPatients;
            try
                value = str2double(get(h,'Value'));
            catch ME
                hDlg = errordlg(ME.message,'Invalid Value','modal');
                uiwait(hDlg);
            end
            if isnan(value) || value <= 0
                hDlg = errordlg('Invalid Value','modal');
                uiwait(hDlg);
            else
                vObj.TempData.MaxNumVirtualPatients = value;
            end
            
            % Update the view
            updateMaxNumVirtualPatients(vObj);
            
        end %function
        
        function onPlotParameterDistributionDiagnostics(vObj,h,e)
            
            % TODO: Genentech
%             hDlg = msgbox('TODO: Plot Parameter Distribution Diagnostics','Not Implemented','modal');
%             uiwait(hDlg);            
            if ~isempty(vObj.Data.VPopName)
                h = figure('Name', 'Parameter Distribution Diagnostic'); %('Units', 'pixels', 'Position', [0 0 1000 6000]);
                p = uix.ScrollingPanel('Parent', h, 'Units', 'Normalized', 'Position', [0 0 1 1]); %,  'Units', 'pixels', 'Position', [0 0 1000 600]);
%                 set(p, 'Widths', 900)

                vpopFile = fullfile(vObj.Data.FilePath, vObj.Data.VPopResultsFolderName, vObj.Data.ExcelResultFileName);                
                try
                    [num,txt,Raw] = xlsread(vpopFile);                
                catch err
                    warning('Could not open vpop xlsx file')
                    disp(err)
                    return
                end
                    
                nCol = size(Raw,2);
                [dims,n] = numSubplots(nCol);
                
                g = uix.Grid('Parent', p); %,  'Units', 'pixels', 'Position', [0 0 200*dims(1) 200*dims(2)], 'Spacing', 1);
                MatchIdx = find(strcmp(vObj.Data.RefParamName,vObj.Data.Settings.Parameters.Name));
                
                LB = [];
                UB = [];
                
                if ~isempty(MatchIdx)
                    lbub = xlsread(vObj.Data.Settings.Parameters(MatchIdx).FilePath);
                    LB = lbub(:,1);
                    UB = lbub(:,2);
                end
                
                for k=1:nCol
                    ax=axes('Parent', g);
                    hist(ax, num(:,k))
                    if k <= length(LB)
                        h2(1)=line(LB(k)*ones(1,2), get(ax,'YLim'));
                        h2(2)=line(UB(k)*ones(1,2), get(ax,'YLim'));
                        set(h2,'LineStyle','--','Color','r')
                    end
                    title(ax, txt{k}, 'Interpreter', 'none')
                    set(ax, 'TitleFontWeight', 'bold' )
                end          
                
                for k=(nCol+1):prod(dims)
                    uix.Empty('Parent', g)
                end
%                 set(g, 'Heights', 300*ones(dims(1),1), 'Widths', 300*ones(dims(2),1))

                set(g, 'Widths', 300*ones(1,dims(2)), 'Heights', 300*ones(1,dims(1)) )
                set(p, 'Widths', 900, 'Heights', 900)

                
%                 set(g, 'Heights', -ones(dims(1),1), 'Widths', -ones(dims(2),1))
                
                
                
            end
            uiwait(h)
            
            
        end %function
        
        function onSpeciesDataTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            if ~isequal(vObj.Data.PlotSpeciesTable,[ThisData(:,1) ThisData(:,2) ThisData(:,3) ThisData(:,4)]) || ...
                    ColIdx == 2
                
                if ~isempty(RowIdx) && ColIdx == 2
                    NewLineStyle = ThisData{RowIdx,2};
                    setSpeciesLineStyles(vObj.Data,RowIdx,NewLineStyle);
                end
                
                vObj.Data.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
                
                % Plot
                plotVirtualPopulationGeneration(vObj.Data,vObj.h.MainAxes);
                
                % Update the view
                updateVisualizationView(vObj);
                
            end
            
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
        
        function onEditTypePlot(vObj,h,e)
            
            vObj.Data.PlotType = get(get(h,'SelectedObject'),'Tag');
            
            % Plot
            plotVirtualPopulationGeneration(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
        end %function        
        
        function onShowInvalidVirtualPatients(vObj,h,e)
            
            set(h,'Enable','off');
            
            vObj.Data.ShowInvalidVirtualPatients = logical(get(h,'Value'));
            
            % Plot
            plotVirtualPopulationGeneration(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
            set(h,'Enable','on');
            
        end %function
        
        function onItemsTablePlot(vObj,h,e)
            
            % Temporarily disable column 1 to prevent quick clicking of
            % 'Include'
            OrigColumnEditable = get(h,'ColumnEditable');
            ColumnEditable = OrigColumnEditable;
            ColumnEditable(1) = false;
            set(h,'ColumnEditable',ColumnEditable);            
            
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
            plotVirtualPopulationGeneration(vObj.Data,vObj.h.MainAxes);
            
            % Update the view
            updateVisualizationView(vObj);
            
            % Enable column 1
            set(h,'ColumnEditable',OrigColumnEditable);
            
        end %function
        
        function onPlotItemsTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotItemsTable,'SelectedRows');
            if ~isempty(SelectedRow)
                ThisColor = vObj.Data.PlotItemTable{SelectedRow,2};
                
                NewColor = uisetcolor(ThisColor);
                
                if ~isequal(NewColor,0)
                    vObj.Data.PlotItemTable{SelectedRow,2} = NewColor;
                    
                    %                 try
                    % Plot
                    plotVirtualPopulationGeneration(vObj.Data,vObj.h.MainAxes);
                    %                 catch ME
                    %                     hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
                    %                     uiwait(hDlg);
                    %                 end
                    
                    % Update the view
                    updateVisualizationView(vObj);
                    
                end
            else
                hDlg = errordlg('Please select a row first to set new color.','No row selected','modal');
                uiwait(hDlg);
            end
        end %function
        
        function onNavigation(vObj,View)
            
            onNavigation@uix.abstract.CardViewPane(vObj,View);
            
        end %function
        
    end
    
    
end %classdef