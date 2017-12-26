classdef Optimization < uix.abstract.CardViewPane
    % Optimization - View Pane for the object
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
        
        DatasetGroupPopupItems = {'-'}        
        DatasetGroupPopupItemsWithInvalid = {'-'}
        
        DatasetIDPopupItems = {'-'}        
        DatasetIDPopupItemsWithInvalid = {'-'}
        
        AlgorithmPopupItems = {'-'}
        AlgorithmPopupItemsWithInvalid = {'-'}
        
        ParameterPopupItems = {'-'}
        ParameterPopupItemsWithInvalid = {'-'}
                
        TaskPopupTableItems = {}
        GroupIDPopupTableItems = {}
        SpeciesPopupTableItems = {} % From Tasks
        
        DatasetHeader = {}
        PrunedDatasetHeader = {};
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
        function obj = Optimization(varargin)
            
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
            vObj.TempData.OptimResultsFolderName = evt.NewValue;
            
            % Update the view
            updateResultsDir(vObj);
            
        end %function
        
        function onDatasetPopup(vObj,h,e)
            
            vObj.TempData.DatasetName = vObj.DatasetPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            refreshSpeciesICTable(vObj);
                        
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
        
        function onAlgorithmPopup(vObj,h,e)
            
            vObj.TempData.AlgorithmName = vObj.AlgorithmPopupItems{get(h,'Value')};
            
            % Update the view
            updateAlgorithms(vObj);
            
        end %function
        
        function onGroupNamePopup(vObj,h,e)
            
            vObj.TempData.GroupName = vObj.DatasetGroupPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            refreshItemsTable(vObj);
            
        end %function
        
        function onIDNamePopup(vObj,h,e)
            
            vObj.TempData.IDName = vObj.DatasetIDPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            
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
                        if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.PrunedDatasetHeader)
                            NewSpeciesData = QSP.SpeciesData;
                            NewSpeciesData.SpeciesName = vObj.SpeciesPopupTableItems{1};
                            NewSpeciesData.DataName = vObj.PrunedDatasetHeader{1};
                            DefaultExpression = 'x';
                            NewSpeciesData.FunctionExpression = DefaultExpression;
                            vObj.TempData.SpeciesData(end+1) = NewSpeciesData;
                        else
                            hDlg = errordlg('At least one task with active species and a non-empty datset must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                    elseif strcmpi(TableTag,'SpeciesIC')
                        if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.PrunedDatasetHeader)
                            NewSpeciesIC = QSP.SpeciesData;
                            NewSpeciesIC.SpeciesName = vObj.SpeciesPopupTableItems{1};
                            NewSpeciesIC.DataName = vObj.PrunedDatasetHeader{1};
                            DefaultExpression = 'x';
                            NewSpeciesIC.FunctionExpression = DefaultExpression;
                            vObj.TempData.SpeciesIC(end+1) = NewSpeciesIC;
                        else
                            hDlg = errordlg('At least one task with active species and a non-empty dataset must be defined in order to add an optimization item.','Cannot Add','modal');
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
                    elseif DeleteIdx <= numel(vObj.TempData.SpeciesIC) && strcmpi(TableTag,'SpeciesIC')
                        vObj.TempData.SpeciesIC(DeleteIdx) = [];
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
                    refreshSpeciesICTable(vObj);
                    
                    uix.utility.CustomWaitbar(1,hWbar,'Done');
                    if ~isempty(hWbar) && ishandle(hWbar)
                        delete(hWbar);
                    end
                    
                elseif strcmpi(TableTag,'SpeciesData')
                    refreshSpeciesDataTable(vObj);
                elseif strcmpi(TableTag,'SpeciesIC')
                    refreshSpeciesICTable(vObj);
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
                    vObj.TempData.SpeciesData(RowIdx).DataName = NewData{RowIdx,1};
                elseif ColIdx == 2
                    vObj.TempData.SpeciesData(RowIdx).SpeciesName = NewData{RowIdx,2};                    
                elseif ColIdx == 4
                    vObj.TempData.SpeciesData(RowIdx).FunctionExpression = NewData{RowIdx,4};
                elseif ColIdx == 5
                    vObj.TempData.SpeciesData(RowIdx).ObjectiveName = NewData{RowIdx,5};
                end
                
            elseif strcmpi(TableTag,'SpeciesIC')
                if ColIdx == 1
                    vObj.TempData.SpeciesIC(RowIdx).SpeciesName = NewData{RowIdx,1};
                elseif ColIdx == 2
                    vObj.TempData.SpeciesIC(RowIdx).DataName = NewData{RowIdx,2};
                elseif ColIdx == 3
                    vObj.TempData.SpeciesIC(RowIdx).FunctionExpression = NewData{RowIdx,3};
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
                refreshSpeciesICTable(vObj);
                
                uix.utility.CustomWaitbar(1,hWbar,'Done');
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                refreshSpeciesDataTable(vObj);
            elseif strcmpi(TableTag,'SpeciesIC')
                refreshSpeciesICTable(vObj);
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
            elseif strcmpi(TableTag,'SpeciesIC')
                updateSpeciesICTable(vObj);
            end
            
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
            
            vObj.Data.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
%             try
                % Plot
                plotOptimization(vObj.Data,vObj.h.MainAxes);
%             catch ME
%                 hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                 uiwait(hDlg);
%             end
                
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
            
%             try
                % Plot
                plotOptimization(vObj.Data,vObj.h.MainAxes);
%             catch ME
%                 hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                 uiwait(hDlg);
%             end
            
            % Update the view
            updateVisualizationView(vObj);
            
            % Enable column 1
            set(h,'ColumnEditable',OrigColumnEditable);
            
        end %function
        
        function onPlotParameters(vObj,h,e)
            
            % Plot
            plotOptimization(vObj.Data,vObj.h.MainAxes);
            
        end %function
        
        function onPlotParametersSourcePopup(vObj,h,e)
            
            NewSource = vObj.Data.PlotParametersSourceOptions{get(h,'Value')};
            
            [StatusOk,Message] = importParametersSource(vObj.Data,NewSource);
            if ~StatusOk
                hDlg = errordlg(Message,'Cannot import','modal');
                uiwait(hDlg);           
            end
            
            % Update the view
            updateVisualizationView(vObj);
            update(vObj);
        end %function
                
        function onParametersTablePlot(vObj,h,e)
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            if ~isempty(ThisData{RowIdx,ColIdx}) && isnumeric(ThisData{RowIdx,ColIdx})
                vObj.Data.PlotParametersData(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            else
                hDlg = errordlg('Invalid value specified for parameter. Values must be numeric','Invalid value','modal');
                uiwait(hDlg);
            end
            
            % Update the view
            updateVisualizationView(vObj);
            
        end %function   
        
        function onSaveParametersAsVPopButton(vObj,h,e)
            
            Options.Resize = 'on';
            Options.WindowStyle = 'modal';
            Answer = inputdlg('Save Virtual Population as?','Save VPop',[1 50],{''},Options);
            
            if ~isempty(Answer)
                AllVPops = vObj.Data.Settings.VirtualPopulation;
                AllVPopNames = get(AllVPops,'Name');
                AllVPopFilePaths = get(AllVPops,'FilePath');
                
                ThisVPopName = strtrim(Answer{1});
                FileName = matlab.lang.makeValidName(ThisVPopName);
                ThisFilePath = fullfile(vObj.Data.Session.RootDirectory,[FileName '.xlsx']);
                
                if isempty(ThisVPopName) || any(strcmpi(ThisVPopName,AllVPopNames)) || ...
                        any(strcmpi(ThisFilePath,AllVPopFilePaths))
                    Message = 'Please provide a valid, unique virtual population name.';
                    Title = 'Invalid name';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                else
                    
                    % Create a new virtual population
                    vpopObj = QSP.VirtualPopulation;
                    vpopObj.Session = vObj.Data.Session;
                    vpopObj.Name = ThisVPopName;                    
                    vpopObj.FilePath = ThisFilePath;                 
                    
                    xlswrite(vpopObj.FilePath,vObj.Data.PlotParametersData(:,1:2)'); % Take first 2 rows and transpose
                    
                    % Update last saved time
                    updateLastSavedTime(vpopObj);
                    % Validate
                    validate(vpopObj,false);
                    
                    % Call the callback
                    evt.InteractionType = sprintf('Updated %s',class(vpopObj));
                    evt.Data = vpopObj;
                    vObj.callCallback(evt);                    
                end
            end
            
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
                    plotOptimization(vObj.Data,vObj.h.MainAxes);
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