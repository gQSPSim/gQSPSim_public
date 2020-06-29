classdef VirtualPopulationGenerationPane < QSPViewerNew.Application.ViewPane
    %  VirtualPopulationGenerationPane -This is the
    %  'viewer' counterpart to the 'model' class
    %  QSP.VirtualPopulationGeneration
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  6/1/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        VirtualPopulationGeneration = QSP.VirtualPopulationGeneration.empty()
        TemporaryVirtualPopulationGeneration = QSP.VirtualPopulationGeneration.empty()
        IsDirty = false
    end
    
    properties (Access=private)
        GroupIDs = {};
        UniqueDataVals = {};
        
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetGroupPopupItems = {'-'}        
        DatasetGroupPopupItemsWithInvalid = {'-'}
        
        VpopPopupItems = {'-'}   
        VpopPopupItemsWithInvalid = {'-'}

        MethodItems = {'Maximum likelihood'; 'Bayesian'}   
        MethodItemsWithInvalid = {'-'}
        
        TaskPopupTableItems = {}
        GroupIDPopupTableItems = {}
        SpeciesPopupTableItems = {} % From Tasks
        
        DatasetHeader = {}
        DatasetDataColumn = {}
        DatasetData = {};
        
        ParametersHeader = {} % From RefParamName
        ParametersData = {} % From RefParamName
               
        PlotSpeciesAsInvalidTable = cell(0,3)
        PlotItemAsInvalidTable = cell(0,4)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []       
        
        ShowTraces = true;
        ShowSEBar = false;
        SelectedRow =0;
        SpeciesGroup
        DatasetGroup
        AxesLegend
        AxesLegendChildren
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
            ResultsPathListener
            VirtualItemsTableListener 
            SpeciesDataTableListener 
            VirtualItemsTableAddListener 
            SpeciesDataTableAddListener 
            VirtualItemsTableRemoveListener 
            SpeciesDataTableRemoveListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        EditLayout                      matlab.ui.container.GridLayout
        ResultsPath                     QSPViewerNew.Widgets.FolderSelector
        InnerLayout                     matlab.ui.container.GridLayout
        VirtualCohortLabel              matlab.ui.control.Label
        VirtualCohortDropDown           matlab.ui.control.DropDown
        TargetStatsLabel                matlab.ui.control.Label
        TargetStatsDropDown             matlab.ui.control.DropDown
        MinNumLabel                     matlab.ui.control.Label
        MinNumEdit                      matlab.ui.control.NumericEditField
        GroupColumnLabel                matlab.ui.control.Label
        GroupColumnDropDown             matlab.ui.control.DropDown
        MethodLabel                     matlab.ui.control.Label
        MethodDropDown                  matlab.ui.control.DropDown
        MaxDiversityCheckBox            matlab.ui.control.CheckBox
        TableLayout                     matlab.ui.container.GridLayout
        VirtualItemsTable               QSPViewerNew.Widgets.AddRemoveTable
        SpeciesDataTable                QSPViewerNew.Widgets.AddRemoveTable
        
        %Visual display components     
        VisLayout                       matlab.ui.container.GridLayout
        VisSpeciesDataTableLabel        matlab.ui.control.Label
        VisSpeciesDataTable             matlab.ui.control.Table
        VisVirtPopItemsTableLabel       matlab.ui.control.Label
        VisVirtPopItemsTable            matlab.ui.control.Table
        
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = VirtualPopulationGenerationPane(varargin)
            obj = obj@QSPViewerNew.Application.ViewPane(varargin{:}{:},true);
            obj.create();
            obj.createListenersAndCallbacks();
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function create(obj)
            obj.EditLayout = uigridlayout(obj.getEditGrid());
            obj.EditLayout.Layout.Row = 3;
            obj.EditLayout.Layout.Column = 1;
            obj.EditLayout.ColumnWidth = {'1x'};
            obj.EditLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight*4,'1x'};
            obj.EditLayout.ColumnSpacing = 0;
            obj.EditLayout.RowSpacing = 0;
            obj.EditLayout.Padding = [0 0 0 0];
            

            obj.ResultsPath = QSPViewerNew.Widgets.FolderSelector(obj.EditLayout,1,1,'ResultsPath');
            
            obj.InnerLayout = uigridlayout(obj.EditLayout);
            obj.InnerLayout.Layout.Row = 2;
            obj.InnerLayout.Layout.Column = 1;
            obj.InnerLayout.ColumnWidth = {obj.LabelLength,'1x',obj.LabelLength,'1x'};
            obj.InnerLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight,obj.LabelHeight};
            obj.InnerLayout.ColumnSpacing = 0;
            obj.InnerLayout.RowSpacing = 0;
            obj.InnerLayout.Padding = [0 0 0 0];
            
            obj.VirtualCohortLabel = uilabel(obj.InnerLayout);
            obj.VirtualCohortLabel.Text = 'Virtual Cohort';
            obj.VirtualCohortLabel.Layout.Row = 1;
            obj.VirtualCohortLabel.Layout.Column = 1;
           
            obj.VirtualCohortDropDown = uidropdown(obj.InnerLayout);
            obj.VirtualCohortDropDown.Layout.Row = 1;
            obj.VirtualCohortDropDown.Layout.Column = 2;
     
            obj.TargetStatsLabel = uilabel(obj.InnerLayout);
            obj.TargetStatsLabel.Text = 'Target Statistics';
            obj.TargetStatsLabel.Layout.Row = 2;
            obj.TargetStatsLabel.Layout.Column = 1;
            
            obj.TargetStatsDropDown = uidropdown(obj.InnerLayout);
            obj.TargetStatsDropDown.Layout.Row = 2;
            obj.TargetStatsDropDown.Layout.Column = 2;
            
            obj.MinNumLabel = uilabel(obj.InnerLayout);
            obj.MinNumLabel.Text = 'Min # of Virtual';
            obj.MinNumLabel.Layout.Row = 3;
            obj.MinNumLabel.Layout.Column = 1;
            
            obj.MinNumEdit = uieditfield(obj.InnerLayout,'numeric');
            obj.MinNumEdit.Layout.Row = 3;
            obj.MinNumEdit.Layout.Column = 2;
            obj.MinNumEdit.Limits = [0,inf];
            obj.MinNumEdit.RoundFractionalValues = true;
           
            obj.GroupColumnLabel = uilabel(obj.InnerLayout);
            obj.GroupColumnLabel.Text = 'Group Column';
            obj.GroupColumnLabel.Layout.Row = 1;
            obj.GroupColumnLabel.Layout.Column = 3;
            
            obj.GroupColumnDropDown = uidropdown(obj.InnerLayout);
            obj.GroupColumnDropDown.Layout.Row = 1;
            obj.GroupColumnDropDown.Layout.Column = 4;

            obj.MethodLabel = uilabel(obj.InnerLayout);
            obj.MethodLabel.Text = 'Method';
            obj.MethodLabel.Layout.Row = 2;
            obj.MethodLabel.Layout.Column = 3;
            
            obj.MethodDropDown = uidropdown(obj.InnerLayout);
            obj.MethodDropDown.Layout.Row = 2;
            obj.MethodDropDown.Layout.Column = 4;
            
            obj.MaxDiversityCheckBox = uicheckbox(obj.InnerLayout);
            obj.MaxDiversityCheckBox.Text = "Maximize Virtual Population Diversity";
            obj.MaxDiversityCheckBox.Layout.Row = 3;
            obj.MaxDiversityCheckBox.Layout.Column = [3,4];
            
            obj.TableLayout = uigridlayout(obj.EditLayout);
            obj.TableLayout.Layout.Row = 3;
            obj.TableLayout.Layout.Column = 1;
            obj.TableLayout.ColumnWidth = {'1x','1x'};
            obj.TableLayout.RowHeight = {'1x'};
            obj.TableLayout.ColumnSpacing = 0;
            obj.TableLayout.RowSpacing = 0;
            obj.TableLayout.Padding = [0 0 0 0];
            
            obj.VirtualItemsTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,1,"Virtual Population Items");
            obj.SpeciesDataTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,2,"Species-Data Mapping");
            
            %Visualize elements
            obj.VisLayout = uigridlayout(obj.getVisualizationGrid());
            obj.VisLayout.Layout.Row = 2;
            obj.VisLayout.Layout.Column = 1;
            obj.VisLayout.ColumnWidth = {'1x'};
            obj.VisLayout.RowHeight = {obj.LabelHeight,'1x',obj.LabelHeight,'1x'};
            obj.VisLayout.ColumnSpacing = 0;
            obj.VisLayout.RowSpacing = 0;
            obj.VisLayout.Padding = [0 0 0 0];
            
            obj.VisSpeciesDataTableLabel = uilabel(obj.VisLayout);
            obj.VisSpeciesDataTableLabel.Text = 'Species-Data';
            obj.VisSpeciesDataTableLabel.Layout.Row = 1;
            obj.VisSpeciesDataTableLabel.Layout.Column = 1;
            
            obj.VisSpeciesDataTable = uitable(obj.VisLayout);
            obj.VisSpeciesDataTable.Layout.Row = 2;
            obj.VisSpeciesDataTable.Layout.Column = 1;
            obj.VisSpeciesDataTable.ColumnEditable = false;
             obj.VisSpeciesDataTable.CellEditCallback = @obj.onEditSpeciesTable;
            
            
            obj.VisVirtPopItemsTableLabel = uilabel(obj.VisLayout);
            obj.VisVirtPopItemsTableLabel.Text = 'Virtual Population Items';
            obj.VisVirtPopItemsTableLabel.Layout.Row = 3;
            obj.VisVirtPopItemsTableLabel.Layout.Column = 1;
            
            obj.VisVirtPopItemsTable = uitable(obj.VisLayout);
            obj.VisVirtPopItemsTable.Layout.Row = 4;
            obj.VisVirtPopItemsTable.Layout.Column = 1;
            obj.VisVirtPopItemsTable.ColumnEditable = false;
            obj.VisVirtPopItemsTable.CellEditCallback = @obj.onEditVirtualPopTable;
            obj.VisVirtPopItemsTable.CellSelectionCallback = @obj.onSelectVirtualPopTable;
        end
        
        function createListenersAndCallbacks(obj)
             %Attach callbacks
            obj.VirtualCohortDropDown.ValueChangedFcn = @(h,e) obj.onEditVirtualCohort(e.Value);
            obj.TargetStatsDropDown.ValueChangedFcn = @(h,e) obj.onEditTargetStats(e.Value);
            obj.MinNumEdit.ValueChangedFcn = @(h,e) obj.onEditMinNum(e.Value);
            obj.GroupColumnDropDown.ValueChangedFcn = @(h,e) obj.onEditGroupColumn(e.Value);
            obj.MethodDropDown.ValueChangedFcn = @(h,e) obj.onEditMethod(e.Value);
            obj.MaxDiversityCheckBox.ValueChangedFcn = @(h,e) obj.onEditMaxDiversity(e.Value);

            %Create listeners
            obj.ResultsPathListener = addlistener(obj.ResultsPath,'StateChanged',@(src,event) obj.onEditResultsPath(event.Source.getRelativePath()));

            obj.VirtualItemsTableListener = addlistener(obj.VirtualItemsTable,'EditValueChange',@(src,event) obj.onEditVirtualItemsTable());
            obj.SpeciesDataTableListener = addlistener(obj.SpeciesDataTable,'EditValueChange',@(src,event) obj.onEditSpeciesDataTable());
            
            obj.VirtualItemsTableAddListener = addlistener(obj.VirtualItemsTable,'NewRowChange',@(src,event) obj.onNewVirtualItemsTable());
            obj.SpeciesDataTableAddListener = addlistener(obj.SpeciesDataTable,'NewRowChange',@(src,event) obj.onNewSpeciesDataTable());
            
            obj.VirtualItemsTableRemoveListener = addlistener(obj.VirtualItemsTable,'DeleteRowChange',@(src,event) obj.onRemoveVirtualItemsTable());
            obj.SpeciesDataTableRemoveListener = addlistener(obj.SpeciesDataTable,'DeleteRowChange',@(src,event) obj.onRemoveSpeciesDataTable());

        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onEditResultsPath(obj,newValue)
            obj.TemporaryVirtualPopulationGeneration.VPopResultsFolderName = newValue;
            obj.IsDirty = true;
        end
        
        function onEditVirtualCohort(obj,newValue)
            obj.TemporaryVirtualPopulationGeneration.DatasetName = newValue;
            obj.redrawVirtualCohort();
            obj.redrawTargetStats();
            obj.redrawGroupColumn();
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
        
        function onEditTargetStats(obj,newValue)         
            obj.TemporaryVirtualPopulationGeneration.VpopGenDataName = newValue;
            obj.redrawVirtualCohort();
            obj.redrawTargetStats();
            obj.redrawGroupColumn();
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
        
        function onEditMinNum(obj,newValue)
            obj.TemporaryVirtualPopulationGeneration.MinNumVirtualPatients = newValue;
            obj.IsDirty = true;
        end
        
        function onEditGroupColumn(obj,newValue)
            obj.TemporaryVirtualPopulationGeneration.DatasetName = newValue;
            obj.redrawVirtualCohort();
            obj.redrawTargetStats();
            obj.redrawVirtualItems();
            obj.redrawGroupColumn();
            obj.IsDirty = true;
        end
        
        function onEditMethod(obj,newValue)
            obj.TemporaryVirtualPopulationGeneration.MethodName = newValue;
            obj.redrawMethod();
            obj.IsDirty = true;
        end
        
        function onEditMaxDiversity(obj,newValue)
            obj.TemporaryVirtualPopulationGeneration.RedistributeWeights = newValue;
            obj.IsDirty = true;
        end
        
        function onEditVirtualItemsTable(obj)
            [Row,Column,Value] = obj.VirtualItemsTable.lastChangedElement();
            
            if Column == 1
                obj.TemporaryVirtualPopulationGeneration.Item(Row).TaskName = Value;       
            elseif Column == 2
                obj.TemporaryVirtualPopulationGeneration.Item(Row).GroupID = Value;
            end
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
        
        function onEditSpeciesDataTable(obj)
            [Row,Column,Value] = obj.SpeciesDataTable.lastChangedElement();
            if Column == 2
                obj.TemporaryVirtualPopulationGeneration.SpeciesData(Row).SpeciesName =Value;
            elseif Column == 4
                obj.TemporaryVirtualPopulationGeneration.SpeciesData(Row).FunctionExpression = Value;
            elseif Column == 1
                obj.TemporaryVirtualPopulationGeneration.SpeciesData(Row).DataName = Value;
            elseif Column == 5
                obj.TemporaryVirtualPopulationGeneration.SpeciesData(Row).ObjectiveName = Value;
            end
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
        
        function onNewVirtualItemsTable(obj)
            if ~isempty(obj.TaskPopupTableItems) && ~isempty(obj.GroupIDPopupTableItems)
                NewTaskGroup = QSP.TaskGroup;
                NewTaskGroup.TaskName = obj.TaskPopupTableItems{1};
                NewTaskGroup.GroupID = obj.GroupIDPopupTableItems{1};
                obj.TemporaryVirtualPopulationGeneration.Item(end+1) = NewTaskGroup;
            else
               uialert(obj.getUIFigure,'At least one task and the group column must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
        
        function onNewSpeciesDataTable(obj)
            if ~isempty(obj.SpeciesPopupTableItems) && ~isempty(obj.DatasetDataColumn)
                NewSpeciesData = QSP.SpeciesData;
                NewSpeciesData.SpeciesName = obj.SpeciesPopupTableItems{1};
                NewSpeciesData.DataName = obj.DatasetDataColumn{1};
                DefaultExpression = 'x';
                NewSpeciesData.FunctionExpression = DefaultExpression;
                obj.TemporaryVirtualPopulationGeneration.SpeciesData(end+1) = NewSpeciesData;
            else
                uialert(obj.getUIFigure,'At least one task with active species and a non-empty ''Species'' column in the dataset must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
         
        function onRemoveVirtualItemsTable(obj)
            Index = obj.VirtualItemsTable.getSelectedRow();
            obj.TemporaryVirtualPopulationGeneration.Item(Index) = [];
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end
        
        function onRemoveSpeciesDataTable(obj)
            Index = obj.VirtualItemsTable.getSelectedRow();
            obj.TemporaryVirtualPopulationGeneration.SpeciesData(Index) = [];
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = true;
        end 
        
        function onEditSpeciesTable(obj)
            
        end
        
        function onEditVirtualPopTable(obj)
            
        end
        
        function onSelectVirtualPopTable(obj)
            
        end
        
        function onContextMenu(obj)
            
        end
        
    end
    
    methods (Access = public) 
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewVirtualPopulationGeneration(obj,NewVirtualPopulationGeneration)
            obj.VirtualPopulationGeneration = NewVirtualPopulationGeneration;
            obj.VirtualPopulationGeneration.PlotSettings = getSummary(obj.getPlotSettings());
            obj.TemporaryVirtualPopulationGeneration = copy(obj.VirtualPopulationGeneration);
            
            
            for index = 1:obj.MaxNumPlots
               Summary = obj.VirtualPopulationGeneration.PlotSettings(index);
               % If Summary is empty (i.e., new node), then use
               % defaults
               if isempty(fieldnames(Summary))
                   Summary = QSP.PlotSettings.getDefaultSummary();
               end
               obj.setPlotSettings(index,fieldnames(Summary),struct2cell(Summary)');
            end
            obj.draw();
            obj.IsDirty = false;
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
        function runModel(obj)
            [StatusOK,Message,~] = run(obj.VirtualPopulationGeneration);
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            end
        end
        
        function drawVisualization(obj)
            
            %DropDown Update
            obj.updatePlotConfig(obj.VirtualPopulationGeneration.SelectedPlotLayout);
            
            %Determine if the values are valid
            if ~isempty(obj.VirtualPopulationGeneration)
                % Check what items are stale or invalid
                [StaleFlag,ValidFlag] = getStaleItemIndices(obj.VirtualPopulationGeneration);
                InvalidItemIndices = ~ValidFlag;    
            end
            
            %Set flags for determing what to display
            if ~isempty(obj.VirtualPopulationGeneration)
                obj.VirtualPopulationGeneration.bShowTraces = obj.bShowTraces;
                obj.VirtualPopulationGeneration.bShowQuantiles = obj.bShowQuantiles;
                obj.VirtualPopulationGeneration.bShowMean = obj.bShowMean;
                obj.VirtualPopulationGeneration.bShowMedian = obj.bShowMedian;
                obj.VirtualPopulationGeneration.bShowSD = obj.bShowSD;
            end
            
            obj.redrawSpeciesTable();
            obj.redrawVirtualPopTable();
            obj.redrawContextMenu();
            [obj.SpeciesGroup,obj.DatasetGroup,obj.AxesLegend,obj.AxesLegendChildren] = ...
                plotVirtualPopulationGeneration(obj.VirtualPopulationGeneration,obj.PlotArray);
          
        end
        
        function UpdateBackendPlotSettings(obj)
            obj.VirtualPopulationGeneration.PlotSettings = getSummary(obj.getPlotSettings());
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryVirtualPopulationGeneration.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryVirtualPopulationGeneration.Description= value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInPlotConfig(obj,value)
            obj.VirtualPopulationGeneration.SelectedPlotLayout = value;
            obj.updatePlotConfig(value);
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryVirtualPopulationGeneration.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryVirtualPopulationGeneration.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.VirtualPopulationGeneration = copy(obj.TemporaryVirtualPopulationGeneration,obj.VirtualPopulationGeneration);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.TemporaryVirtualPopulationGeneration.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function saveVisualizationView(obj)
            disp("You shouldve saved the layout")
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryVirtualPopulationGeneration)
            obj.TemporaryVirtualPopulationGeneration = copy(obj.VirtualPopulationGeneration);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryVirtualPopulationGeneration.Description);
            obj.updateNameBox(obj.TemporaryVirtualPopulationGeneration.Name);
            obj.updateSummary(obj.TemporaryVirtualPopulationGeneration.getSummary());
            obj.redrawResultsPath();
            obj.redrawVirtualCohort();
            obj.redrawTargetStats();
            obj.redrawMinNum();
            obj.redrawGroupColumn();
            obj.redrawMethod();
            obj.redrawMaxDiversity();
            obj.redrawVirtualItems();
            obj.redrawSpeciesData();
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryVirtualPopulationGeneration,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.VirtualPopulationGeneration.Session.VirtualPopulationGeneration;
            ixDup = find(strcmp( obj.TemporaryVirtualPopulationGeneration.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.VirtualPopulationGeneration)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
    end
    
    methods (Access = private)
        
        function redrawResultsPath(obj)
            obj.ResultsPath.setRootDirectory(obj.TemporaryVirtualPopulationGeneration.Session.RootDirectory);
            obj.ResultsPath.setRelativePath(obj.TemporaryVirtualPopulationGeneration.VPopResultsFolderName);
        end
        
        function redrawVirtualCohort(obj)
            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                ThisList = {obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulation.Name};
                Selection = obj.TemporaryVirtualPopulationGeneration.DatasetName;
                MatchIdx = strcmpi(ThisList,Selection);    
                if any(MatchIdx)
                    ThisStatusOk = validate(obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulation(MatchIdx));
                    ForceMarkAsInvalid = ~ThisStatusOk;
                else
                    ForceMarkAsInvalid = false;
                end
                [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
            else
                FullList = {'-'};
                FullListWithInvalids = {QSP.makeInvalid('-')};    
                Value = 1;
            end
            obj.DatasetPopupItems = FullList;
            obj.DatasetPopupItemsWithInvalid = FullListWithInvalids;
            
            obj.VirtualCohortDropDown.Items = obj.DatasetPopupItemsWithInvalid;
            obj.VirtualCohortDropDown.Value = obj.DatasetPopupItemsWithInvalid{Value};
        end          
        
        function redrawTargetStats(obj)
            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                ThisList = {obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulationGenerationData.Name};
                Selection = obj.TemporaryVirtualPopulationGeneration.VpopGenDataName;

                MatchIdx = strcmpi(ThisList,Selection);    
                if any(MatchIdx)
                    ThisStatusOk = validate(obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulationGenerationData(MatchIdx));
                    ForceMarkAsInvalid = ~ThisStatusOk;
                else
                    ForceMarkAsInvalid = false;
                end
                [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
            else
                FullList = {'-'};
                FullListWithInvalids = {QSP.makeInvalid('-')};    
                Value = 1;
            end
            obj.VpopPopupItems = FullList;
            obj.VpopPopupItemsWithInvalid = FullListWithInvalids;
  
            if ~isempty(obj.TemporaryVirtualPopulationGeneration) && ~isempty(obj.TemporaryVirtualPopulationGeneration.DatasetName) && ~isempty(obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulationGenerationData)
                Names = {obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulationGenerationData.Name};
                MatchIdx = strcmpi(Names,obj.TemporaryVirtualPopulationGeneration.VpopGenDataName);

                if any(MatchIdx)
                    dObj = obj.TemporaryVirtualPopulationGeneration.Settings.VirtualPopulationGenerationData(MatchIdx);

                    [~,~,VPopHeader,VPopData] = importData(dObj,dObj.FilePath);
                else
                    VPopHeader = {};
                    VPopData = {};
                end
            else
                VPopHeader = {};
                VPopData = {};
            end
            obj.DatasetHeader = VPopHeader;
            obj.DatasetData = VPopData;

            if ~isempty(VPopHeader) && ~isempty(VPopData)
                MatchIdx = find(strcmpi(VPopHeader,'Species'));
                if numel(MatchIdx) == 1
                    obj.DatasetDataColumn = unique(VPopData(:,MatchIdx));
                elseif numel(MatchIdx) == 0
                    obj.DatasetDataColumn = {};
                    warning('VpopGen Data %s has 0 ''Species'' column names',vpopObj.FilePath);
                else
                    obj.DatasetDataColumn = {};
                    warning('VpopGen Data %s has multiple ''Species'' column names',vpopObj.FilePath);
                end
            else
                obj.DatasetDataColumn = {};
            end

            if ~isempty(obj.TemporaryVirtualPopulationGeneration) && ~isempty(obj.DatasetHeader) && ~isempty(obj.DatasetData)
                MatchIdx = strcmp(obj.DatasetHeader,obj.TemporaryVirtualPopulationGeneration.GroupName);
                TempGroupIDs = obj.DatasetData(:,MatchIdx);
                if iscell(TempGroupIDs)
                    try
                        TempGroupIDs = cell2mat(TempGroupIDs);
                    catch
                        uialert(obj.getUIFigure,'Invalid group ID column selected. Only numeric values are allowed','Warning')
                        return
                    end

                end
                TempGroupIDs = unique(TempGroupIDs);
                obj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(TempGroupIDs),'UniformOutput',false);
            else
                obj.GroupIDPopupTableItems = {};
            end
            
            obj.TargetStatsDropDown.Items = obj.VpopPopupItemsWithInvalid;
            obj.TargetStatsDropDown.Value = obj.VpopPopupItemsWithInvalid{Value};
        end
                 
        function redrawMinNum(obj)
            obj.MinNumEdit.Value = obj.TemporaryVirtualPopulationGeneration.MinNumVirtualPatients;
        end            
        
        function redrawGroupColumn(obj)
            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                GroupSelection = obj.TemporaryVirtualPopulationGeneration.GroupName;
                [FullGroupListWithInvalids,FullGroupList,GroupValue] = QSP.highlightInvalids(obj.DatasetHeader,GroupSelection);
            else
                FullGroupList = {'-'};
                FullGroupListWithInvalids = {QSP.makeInvalid('-')};
                GroupValue = 1;
            end
            obj.DatasetGroupPopupItems = FullGroupList;
            obj.DatasetGroupPopupItemsWithInvalid = FullGroupListWithInvalids;
            
            
            obj.GroupColumnDropDown.Items = obj.DatasetGroupPopupItemsWithInvalid;
            obj.GroupColumnDropDown.Value = obj.DatasetGroupPopupItemsWithInvalid{GroupValue};
        end
                
        function redrawMethod(obj)
             obj.MethodDropDown.Items = obj.MethodItems;
             obj.MethodDropDown.Value = obj.TemporaryVirtualPopulationGeneration.MethodName;
             obj.MethodDropDown.Enable = 'off';
        end
                
        function redrawMaxDiversity(obj)
            obj.MaxDiversityCheckBox.Value = obj.TemporaryVirtualPopulationGeneration.RedistributeWeights;
        end
                
        function redrawVirtualItems(obj)
            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                ValidItemTasks = getValidSelectedTasks(obj.TemporaryVirtualPopulationGeneration.Settings,{obj.TemporaryVirtualPopulationGeneration.Settings.Task.Name});
                if ~isempty(ValidItemTasks)
                    obj.TaskPopupTableItems = {ValidItemTasks.Name};
                else
                    obj.TaskPopupTableItems = {};
                end
            else
                obj.TaskPopupTableItems = {};
            end

            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                ItemTaskNames = {obj.TemporaryVirtualPopulationGeneration.Item.TaskName};    
                obj.SpeciesPopupTableItems = getSpeciesFromValidSelectedTasks(obj.TemporaryVirtualPopulationGeneration.Settings,ItemTaskNames);    
            else
                obj.SpeciesPopupTableItems = {};
            end
                
            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                TaskNames = {obj.TemporaryVirtualPopulationGeneration.Item.TaskName};
                TempGroupIDs = {obj.TemporaryVirtualPopulationGeneration.Item.GroupID};
                RunToSteadyState = false(size(TaskNames));

                for index = 1:numel(TaskNames)
                    MatchIdx = strcmpi(TaskNames{index},{obj.TemporaryVirtualPopulationGeneration.Settings.Task.Name});
                    if any(MatchIdx)
                        RunToSteadyState(index) = obj.TemporaryVirtualPopulationGeneration.Settings.Task(MatchIdx).RunToSteadyState;
                    end
                end
                
                Data = [TaskNames(:) TempGroupIDs(:) num2cell(RunToSteadyState(:))];
                if ~isempty(Data)
                    for index = 1:numel(TaskNames)
                        ThisTask = getValidSelectedTasks(obj.TemporaryVirtualPopulationGeneration.Settings,TaskNames{index});
                        % Mark invalid if empty
                        if isempty(ThisTask)            
                            Data{index,1} = QSP.makeInvalid(Data{index,1});
                        end
                    end
                    MatchIdx = find(~ismember(TempGroupIDs(:),obj.GroupIDPopupTableItems(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
                    end
                end
            else
                Data = {};
            end
            
            if ~isempty(obj.TemporaryVirtualPopulationGeneration) && ~isempty(obj.DatasetHeader) && ~isempty(obj.DatasetData)
                MatchIdx = strcmp(obj.DatasetHeader,obj.TemporaryVirtualPopulationGeneration.GroupName);
                TempGroupIDs = obj.DatasetData(:,MatchIdx);
                if iscell(TempGroupIDs)
                    TempGroupIDs = cell2mat(TempGroupIDs);        
                end    
                TempGroupIDs = unique(TempGroupIDs);
                obj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(TempGroupIDs),'UniformOutput',false);
            else
                obj.GroupIDPopupTableItems = {};
            end
            
            obj.VirtualItemsTable.setEditable([true true false]);
            obj.VirtualItemsTable.setName({'Task','Group','Run To Steady State'}');
            obj.VirtualItemsTable.setFormat({obj.TaskPopupTableItems(:)',obj.GroupIDPopupTableItems(:)','char'})
            obj.VirtualItemsTable.setData(Data)
        end
               
        function redrawSpeciesData(obj)

            if ~isempty(obj.TemporaryVirtualPopulationGeneration)
                SpeciesNames = {obj.TemporaryVirtualPopulationGeneration.SpeciesData.SpeciesName};
                DataNames = {obj.TemporaryVirtualPopulationGeneration.SpeciesData.DataName};
                FunctionExpressions = {obj.TemporaryVirtualPopulationGeneration.SpeciesData.FunctionExpression};
                
                ItemTaskNames = {obj.TemporaryVirtualPopulationGeneration.Item.TaskName};
                ValidSelectedTasks = getValidSelectedTasks(obj.TemporaryVirtualPopulationGeneration.Settings,ItemTaskNames);
                
                NumTasksPerSpecies = zeros(size(SpeciesNames));
                for iSpecies = 1:numel(SpeciesNames)
                    for iTask = 1:numel(ValidSelectedTasks)
                        if any(strcmpi(SpeciesNames{iSpecies},ValidSelectedTasks(iTask).SpeciesNames))
                            NumTasksPerSpecies(iSpecies) = NumTasksPerSpecies(iSpecies) + 1;
                        end
                    end
                end
                
                Data = [DataNames(:) SpeciesNames(:) num2cell(NumTasksPerSpecies(:)) FunctionExpressions(:)];
                
                if ~isempty(Data)
                    MatchIdx = find(~ismember(SpeciesNames(:),obj.SpeciesPopupTableItems(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),1});
                    end
                    MatchIdx = find(~ismember(DataNames(:),obj.DatasetDataColumn(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),4});
                    end
                end
            else
                Data = {};
            end
            
            obj.SpeciesDataTable.setEditable([true true false true]);
            obj.SpeciesDataTable.setName({'Data (y)','Species (x)','# Tasks per Species','y=f(x)'}');
            obj.SpeciesDataTable.setFormat({obj.DatasetDataColumn(:)',obj.SpeciesPopupTableItems(:)','numeric','char'})
            obj.SpeciesDataTable.setData(Data);
        end
        
        
        %Visualization redraw
        function reimport(obj)
             if ~isempty(obj.VirtualPopulationGeneration) && ~isempty(obj.VirtualPopulationGeneration.DatasetName) && ~isempty(obj.VirtualPopulationGeneration.Settings.VirtualPopulationGenerationData)
                Names = {obj.VirtualPopulationGeneration.Settings.VirtualPopulationGenerationData.Name};
                MatchIdx = strcmpi(Names,obj.VirtualPopulationGeneration.VpopGenDataName);
                
                if any(MatchIdx)
                    vpopObj = obj.VirtualPopulationGeneration.Settings.VirtualPopulationGenerationData(MatchIdx);
                    
                    [~,~,VpopHeader,VpopData] = importData(vpopObj,vpopObj.FilePath);
                else
                    VpopHeader = {};
                    VpopData = {};
                end
            else
                VpopHeader = {};
                VpopData = {};
             end
            
            % Get unique values from Data Column
            MatchIdx = strcmpi(VpopHeader,'Species');
            if any(MatchIdx)
                TempUniqueDataVals = unique(VpopData(:,MatchIdx));
            else
                TempUniqueDataVals = {};
            end
            obj.UniqueDataVals = TempUniqueDataVals;
            % Get the GroupID column
            if ~isempty(VpopHeader) && ~isempty(VpopData)
                MatchIdx = strcmp(VpopHeader,obj.VirtualPopulationGeneration.GroupName);
                TempGroupIDs = VpopData(:,MatchIdx);
                if iscell(TempGroupIDs)
                    TempGroupIDs = cell2mat(TempGroupIDs);
                end
                TempGroupIDs = unique(TempGroupIDs);
                TempGroupIDs = cellfun(@(x)num2str(x),num2cell(TempGroupIDs),'UniformOutput',false);
            else
                TempGroupIDs = [];
            end
            
            obj.GroupIDs = TempGroupIDs;
        end
        
        function redrawSpeciesTable(obj)

            if ~isempty(obj.VirtualPopulationGeneration)
                
                % Get the raw TaskNames, GroupIDNames
                TaskNames = {obj.VirtualPopulationGeneration.Item.TaskName};
                GroupIDNames = {obj.VirtualPopulationGeneration.Item.GroupID};
                
                InvalidIndices = false(size(TaskNames));
                for idx = 1:numel(TaskNames)
                    % Check if the task is valid
                    ThisTask = getValidSelectedTasks(obj.VirtualPopulationGeneration.Settings,TaskNames{idx});
                    MissingGroup = ~ismember(GroupIDNames{idx},obj.GroupIDs(:)');
                    if isempty(ThisTask) || MissingGroup
                        InvalidIndices(idx) = true;
                    end
                end
                
                % If empty, populate
                if isempty(obj.VirtualPopulationGeneration.PlotItemTable)
                    
                    if any(InvalidIndices)
                        % remove an invalid items
                        TaskNames(InvalidIndices) = [];
                        GroupIDNames(InvalidIndices) = [];
                    end
                    
                    obj.VirtualPopulationGeneration.PlotItemTable = cell(numel(TaskNames),5);
                    obj.VirtualPopulationGeneration.PlotItemTable(:,1) = {false};
                    obj.VirtualPopulationGeneration.PlotItemTable(:,3) = TaskNames;
                    obj.VirtualPopulationGeneration.PlotItemTable(:,4) = GroupIDNames;
                    obj.VirtualPopulationGeneration.PlotItemTable(:,5) = TaskNames;
                    
                    % Update the item colors
                    ItemColors = getItemColors(obj.VirtualPopulationGeneration.Session,numel(TaskNames));
                    obj.VirtualPopulationGeneration.PlotItemTable(:,2) = num2cell(ItemColors,2);
                    
                    obj.PlotItemAsInvalidTable = obj.VirtualPopulationGeneration.PlotItemTable;
                    obj.PlotItemInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(TaskNames),5);
                    NewPlotTable(:,1) = {false};
                    NewPlotTable(:,3) = TaskNames;
                    NewPlotTable(:,4) = GroupIDNames;
                    NewPlotTable(:,5) = TaskNames;
                    
                    NewColors = getItemColors(obj.VirtualPopulationGeneration.Session,numel(TaskNames));
                    NewPlotTable(:,2) = num2cell(NewColors,2);
                    
                    if size(obj.VirtualPopulationGeneration.PlotItemTable,2) == 4
                        obj.VirtualPopulationGeneration.PlotItemTable(:,5) = obj.VirtualPopulationGeneration.PlotItemTable(:,3);
                    end
                    
                    % Update Table
                    KeyColumn = [3 4];
                    [obj.VirtualPopulationGeneration.PlotItemTable,obj.PlotItemAsInvalidTable,obj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.VirtualPopulationGeneration.PlotItemTable,NewPlotTable,InvalidIndices,KeyColumn);
                end
                
                % Check for invalid files
                ResultsDir = fullfile(obj.VirtualPopulationGeneration.Session.RootDirectory,obj.VirtualPopulationGeneration.VPopResultsFolderName);
                if exist(fullfile(ResultsDir,obj.VirtualPopulationGeneration.ExcelResultFileName),'file') == 2
                    FlagIsInvalidResultFile = false; % Exists, not invalid
                else
                    FlagIsInvalidResultFile = true;
                end
                
                % Only make the "valids" missing. Leave the invalids as is
                TableData = obj.PlotItemAsInvalidTable;
                if ~isempty(TableData)
                    for index = 1:size(obj.VirtualPopulationGeneration.PlotItemTable,1)
                        % If results file is missing and it's not already an invalid
                        % row, then mark as missing
                        if FlagIsInvalidResultFile && any(~ismember(obj.PlotItemInvalidRowIndices,index))
                            TableData{index,3} = QSP.makeItalicized(TableData{index,3});
                            TableData{index,4} = QSP.makeItalicized(TableData{index,4});
                        end 
                    end 
                end 
                
                % Update Colors column
                TableData(:,2) = repmat({''},size(TableData,1),1);
                
                %Fill in items information and edit limitations
                obj.VisSpeciesDataTable.Data = TableData;
                obj.VisSpeciesDataTable.ColumnName = {'Include','Color','Task','Group','Display'};
                obj.VisSpeciesDataTable.ColumnFormat = {'logical','char','char','char','char'};
                obj.VisSpeciesDataTable.ColumnEditable = [true,false,false,false,true];
                
                %Fill in the colors of the table
                for index = 1:size(TableData,1)
                    ThisColor = obj.VirtualPopulationGeneration.PlotItemTable{index,2};
                    if ~isempty(ThisColor)
                        addStyle(obj.VisSpeciesDataTable,uistyle('BackgroundColor',ThisColor),'cell',[index,2])
                    end
                end
            else         
                %Fill in items information and edit limitations
                obj.VisSpeciesDataTable.Data = cell(0,5);
                obj.VisSpeciesDataTable.ColumnName = {'Include','Color','Task','Group','Display'};
                obj.VisSpeciesDataTable.ColumnFormat = {'logical','char','char','char','char'};
                obj.VisSpeciesDataTable.ColumnEditable = [true,false,false,false,true];
            end
        end
        
        function redrawVirtualPopTable(obj)
            
            AxesOptions = obj.getAxesOptions();
            if ~isempty(obj.VirtualPopulationGeneration)
                % Get the raw SpeciesNames, DataNames
                TaskNames = {obj.VirtualPopulationGeneration.Item.TaskName};
                SpeciesNames = {obj.VirtualPopulationGeneration.SpeciesData.SpeciesName};
                DataNames = {obj.VirtualPopulationGeneration.SpeciesData.DataName};
                
                % Get the list of all active species from all valid selected tasks
                ValidSpeciesList = getSpeciesFromValidSelectedTasks(obj.VirtualPopulationGeneration.Settings,TaskNames);
                
                InvalidIndices = false(size(SpeciesNames));
                for idx = 1:numel(SpeciesNames)
                    % Check if the species is missing
                    MissingSpecies = ~ismember(SpeciesNames{idx},ValidSpeciesList);
                    MissingData = ~ismember(DataNames{idx},obj.UniqueDataVals);
                    if MissingSpecies || MissingData
                        InvalidIndices(idx) = true;
                    end
                end
                
                if isempty(obj.VirtualPopulationGeneration.PlotSpeciesTable)
                    
                    if any(InvalidIndices)
                        % Then, prune
                        SpeciesNames(InvalidIndices) = [];
                        DataNames(InvalidIndices) = [];
                    end
                    
                    % If empty, populate, but first update line styles
                    obj.VirtualPopulationGenerationData.PlotSpeciesTable = cell(numel(SpeciesNames),5);
                    updateSpeciesLineStyles(obj.VirtualPopulationGeneration);
                    
                    obj.VirtualPopulationGeneration.PlotSpeciesTable(:,1) = {' '};
                    obj.VirtualPopulationGeneration.PlotSpeciesTable(:,2) = obj.VirtualPopulationGeneration.SpeciesLineStyles(:);
                    obj.VirtualPopulationGeneration.PlotSpeciesTable(:,3) = SpeciesNames;
                    obj.VirtualPopulationGeneration.PlotSpeciesTable(:,4) = DataNames;
                    obj.VirtualPopulationGeneration.PlotSpeciesTable(:,5) = SpeciesNames;
                    
                    obj.PlotSpeciesAsInvalidTable = obj.VirtualPopulationGeneration.PlotSpeciesTable;
                    obj.PlotSpeciesInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(SpeciesNames),5);
                    NewPlotTable(:,1) = {' '};
                    NewPlotTable(:,2) = {'-'}; 
                    NewPlotTable(:,3) = SpeciesNames;
                    NewPlotTable(:,4) = DataNames;
                    NewPlotTable(:,5) = SpeciesNames;
                    
                    % Adjust size if from an old saved session
                    if size(obj.VirtualPopulationGeneration.PlotSpeciesTable,2) == 3
                        obj.VirtualPopulationGeneration.PlotSpeciesTable(:,5) = obj.VirtualPopulationGeneration.PlotSpeciesTable(:,3);
                        obj.VirtualPopulationGeneration.PlotSpeciesTable(:,4) = obj.VirtualPopulationGeneration.PlotSpeciesTable(:,3);
                        obj.VirtualPopulationGeneration.PlotSpeciesTable(:,3) = obj.VirtualPopulationGeneration.PlotSpeciesTable(:,2);
                        obj.VirtualPopulationGeneration.PlotSpeciesTable(:,2) = {'-'}; 
                    elseif size(obj.VirtualPopulationGeneration.PlotSpeciesTable,2) == 4
                        obj.VirtualPopulationGeneration.PlotSpeciesTable(:,5) = obj.VirtualPopulationGeneration.PlotSpeciesTable(:,3);
                    end
                    
                    % Update Table
                    KeyColumn = [3 4];
                    [obj.VirtualPopulationGeneration.PlotSpeciesTable,obj.PlotSpeciesAsInvalidTable,obj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.VirtualPopulationGeneration.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);
                    % Update line styles
                    updateSpeciesLineStyles(obj.VirtualPopulationGeneration);
                end
                
                % Species table
                
                obj.VisVirtPopItemsTable.Data = obj.PlotSpeciesAsInvalidTable;
                obj.VisVirtPopItemsTable.ColumnName = {'Plot','Style','Species','Data','Display'};
                obj.VisVirtPopItemsTable.ColumnFormat = {AxesOptions',obj.VirtualPopulationGeneration.Settings.LineStyleMap,'char','char','char'};
                obj.VisVirtPopItemsTable.ColumnEditable = [true,true,false,false,true];
            else
                
                obj.VisVirtPopItemsTable.Data = cell(0,5);
                obj.VisVirtPopItemsTable.ColumnName = {'Plot','Style','Species','Data','Display'};
                obj.VisVirtPopItemsTable.ColumnFormat = {AxesOptions','char','char','char','char'};
                obj.VisVirtPopItemsTable.ColumnEditable = [true,true,false,false,true];
            end
        end
        
        function redrawContextMenu(obj)
            %TODO Need to figure out the uisetcolor situation
        end
        
    end
        
end




