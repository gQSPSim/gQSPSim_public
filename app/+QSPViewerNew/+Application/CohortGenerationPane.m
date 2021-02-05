classdef CohortGenerationPane < QSPViewerNew.Application.ViewPane
    %  CohortGenerationPane -This is the
    %  'viewer' counterpart to the 'model' class
    %  QSP.CohortGeneration
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
        CohortGeneration = QSP.CohortGeneration.empty()
        TemporaryCohortGeneration = QSP.CohortGeneration.empty()
        IsDirty = false
    end
    
    properties (Access = private)
        SelectedRow = 0;
        SaveValues = {
            'Save all virtual subjects','all';
            'Save valid virtual subjects','valid'
            }
        
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetGroupPopupItems = {'-'}
        DatasetGroupPopupItemsWithInvalid = {'-'}
        
        ParameterPopupItems = {'-'}
        ParameterPopupItemsWithInvalid = {'-'}
        
        MethodPopupItems = {'Distribution','MCMC'}
        
        TaskPopupTableItems = {}
        GroupIDPopupTableItems = {}
        SpeciesPopupTableItems = {} % From Tasks
        
        DatasetHeader = {}
        DatasetDataColumn = {}
        DatasetData = {};
        
        UniqueDataVals = {};
        GroupIDs = {};
        
        ParametersHeader = {} % From RefParamName
        ParametersData = {} % From RefParamName
        
        ObjectiveFunctions = {'defaultObj'}
        
        PlotSpeciesAsInvalidTable = cell(0,3)
        PlotItemAsInvalidTable = cell(0,4)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []
        
        ShowTraces = true;
        ShowSEBar = false;
        
        StaleFlag
        ValidFlag
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = private)
        ResultsPathListener
        InitialConditionsPathListener
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
        ParametersLabel                 matlab.ui.control.Label
        ParametersDropDown              matlab.ui.control.DropDown
        NumSimsLabel                    matlab.ui.control.Label
        NumSimsEdit                     matlab.ui.control.NumericEditField
        NumVirtualLabel                 matlab.ui.control.Label
        NumVirtualEdit                  matlab.ui.control.NumericEditField
        AcceptanceLabel                 matlab.ui.control.Label
        AcceptanceDropDown              matlab.ui.control.DropDown
        GroupColumnLabel                matlab.ui.control.Label
        GroupColumnDropDown             matlab.ui.control.DropDown
        SavePrefLabel                   matlab.ui.control.Label
        SavePrefDropDown                matlab.ui.control.DropDown
        SearchMethodLabel               matlab.ui.control.Label
        SearchMethodDropDown            matlab.ui.control.DropDown
        MCMCtuningLabel                 matlab.ui.control.Label
        MCMCtuningEdit                  matlab.ui.control.NumericEditField
        FixSeedLabel                    matlab.ui.control.Label
        FixSeedCheckBox                 matlab.ui.control.CheckBox
        RNGSeedLabel                    matlab.ui.control.Label
        RNGSeedEdit                     matlab.ui.control.NumericEditField
        InitialConditionsPath           QSPViewerNew.Widgets.FileSelector
        TableLayout                     matlab.ui.container.GridLayout
        VirtualItemsTable               QSPViewerNew.Widgets.AddRemoveTable
        SpeciesDataTable                QSPViewerNew.Widgets.AddRemoveTable
        ParametersTableLabel            matlab.ui.control.Label
        ParametersTable                 matlab.ui.control.Table
        SearchMethodLayout              matlab.ui.container.GridLayout
        
        %Items for visualization
        VisLayout                       matlab.ui.container.GridLayout
        VisButtonGroup                  matlab.ui.container.ButtonGroup
        VisNormalButton                 matlab.ui.control.RadioButton
        VisDiagnosticButton             matlab.ui.control.RadioButton
        VisParamatersDiagnosticButton   matlab.ui.control.Button
        VisSpeciesDataTableLabel        matlab.ui.control.Label
        VisSpeciesDataTable             matlab.ui.control.Table
        VisInvalidCheckBox              matlab.ui.control.CheckBox
        VisVirtCohortItemsTableLabel    matlab.ui.control.Label
        VisVirtCohortItemsTable         matlab.ui.control.Table
        
        PlotItemsTableContextMenu
        PlotItemsTableMenu
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function obj = CohortGenerationPane(varargin)
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
            obj.EditLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight*5,'1x',obj.LabelHeight,obj.LabelHeight,'1x'};
            obj.EditLayout.ColumnSpacing = 0;
            obj.EditLayout.RowSpacing = 0;
            obj.EditLayout.Padding = [0 0 0 0];
            
            obj.ResultsPath = QSPViewerNew.Widgets.FolderSelector(obj.EditLayout,1,1,'ResultsPath');
            
            obj.InnerLayout = uigridlayout(obj.EditLayout());
            obj.InnerLayout.Layout.Row = 2;
            obj.InnerLayout.Layout.Column = 1;
            obj.InnerLayout.ColumnWidth = {obj.LabelLength,'1x',obj.LabelLength,'1x'};
            obj.InnerLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight,obj.LabelHeight,obj.LabelHeight};
            obj.InnerLayout.ColumnSpacing = 0;
            obj.InnerLayout.RowSpacing = 0;
            obj.InnerLayout.Padding = [0 0 0 0];
            
            obj.ParametersLabel = uilabel(obj.InnerLayout);
            obj.ParametersLabel.Text = 'Parameters';
            obj.ParametersLabel.Layout.Row = 1;
            obj.ParametersLabel.Layout.Column = 1;
            
            obj.ParametersDropDown = uidropdown(obj.InnerLayout);
            obj.ParametersDropDown.Layout.Row = 1;
            obj.ParametersDropDown.Layout.Column = 2;
            
            obj.NumSimsLabel = uilabel(obj.InnerLayout);
            obj.NumSimsLabel.Text = 'Max # of Sims';
            obj.NumSimsLabel.Layout.Row = 2;
            obj.NumSimsLabel.Layout.Column = 1;
            
            obj.NumSimsEdit = uieditfield(obj.InnerLayout,'numeric');
            obj.NumSimsEdit.Layout.Row = 2;
            obj.NumSimsEdit.Layout.Column = 2;
            obj.NumSimsEdit.Limits = [0,Inf];
            obj.NumSimsEdit.RoundFractionalValues = true;
            
            obj.NumVirtualLabel = uilabel(obj.InnerLayout);
            obj.NumVirtualLabel.Text = 'Max # of Virtual';
            obj.NumVirtualLabel.Layout.Row = 3;
            obj.NumVirtualLabel.Layout.Column = 1;
            
            obj.NumVirtualEdit = uieditfield(obj.InnerLayout,'numeric');
            obj.NumVirtualEdit.Layout.Row = 3;
            obj.NumVirtualEdit.Layout.Column = 2;
            obj.NumVirtualEdit.Limits = [0,Inf];
            obj.NumVirtualEdit.RoundFractionalValues = true;
            
            obj.AcceptanceLabel = uilabel(obj.InnerLayout);
            obj.AcceptanceLabel.Text = 'Acceptance Criteria';
            obj.AcceptanceLabel.Layout.Row = 4;
            obj.AcceptanceLabel.Layout.Column = 1;
            
            obj.AcceptanceDropDown = uidropdown(obj.InnerLayout);
            obj.AcceptanceDropDown.Layout.Row = 4;
            obj.AcceptanceDropDown.Layout.Column = 2;
            
            obj.GroupColumnLabel = uilabel(obj.InnerLayout);
            obj.GroupColumnLabel.Text = 'Group Column';
            obj.GroupColumnLabel.Layout.Row = 1;
            obj.GroupColumnLabel.Layout.Column = 3;
            
            obj.GroupColumnDropDown = uidropdown(obj.InnerLayout);
            obj.GroupColumnDropDown.Layout.Row = 1;
            obj.GroupColumnDropDown.Layout.Column = 4;
            
            obj.SavePrefLabel = uilabel(obj.InnerLayout);
            obj.SavePrefLabel.Text = 'Save Preference';
            obj.SavePrefLabel.Layout.Row = 2;
            obj.SavePrefLabel.Layout.Column = 3;
            
            obj.SavePrefDropDown = uidropdown(obj.InnerLayout);
            obj.SavePrefDropDown.Layout.Row = 2;
            obj.SavePrefDropDown.Layout.Column = 4;
            
            obj.SearchMethodLayout = uigridlayout(obj.InnerLayout);
            obj.SearchMethodLayout.Layout.Row = [3,4];
            obj.SearchMethodLayout.Layout.Column = [3,4];
            obj.SearchMethodLayout.ColumnWidth = {obj.LabelLength,'1x',obj.LabelLength,'1x'};
            obj.SearchMethodLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight};
            obj.SearchMethodLayout.ColumnSpacing = 0;
            obj.SearchMethodLayout.RowSpacing = 0;
            obj.SearchMethodLayout.Padding = [0 0 0 0];
            
            obj.SearchMethodLabel = uilabel(obj.SearchMethodLayout);
            obj.SearchMethodLabel.Text = 'Search Method';
            obj.SearchMethodLabel.Layout.Row = 1;
            obj.SearchMethodLabel.Layout.Column = 1;
            
            obj.SearchMethodDropDown = uidropdown(obj.SearchMethodLayout);
            obj.SearchMethodDropDown.Layout.Row = 1;
            obj.SearchMethodDropDown.Layout.Column = 2;
            
            obj.MCMCtuningLabel = uilabel(obj.SearchMethodLayout);
            obj.MCMCtuningLabel.Text = 'MCMC tuning';
            obj.MCMCtuningLabel.Layout.Row = 1;
            obj.MCMCtuningLabel.Layout.Column = 3;
            
            obj.MCMCtuningEdit = uieditfield(obj.SearchMethodLayout,'numeric');
            obj.MCMCtuningEdit.Layout.Row = 1;
            obj.MCMCtuningEdit.Layout.Column = 4;
            obj.MCMCtuningEdit.Limits = [0,1];
            
            obj.FixSeedCheckBox = uicheckbox(obj.SearchMethodLayout);
            obj.FixSeedCheckBox.Text = "Fix seed for random number generation";
            obj.FixSeedCheckBox.Layout.Row = 2;
            obj.FixSeedCheckBox.Layout.Column = [1,2];
            
            obj.RNGSeedLabel = uilabel(obj.SearchMethodLayout);
            obj.RNGSeedLabel.Text = 'RNG Seed';
            obj.RNGSeedLabel.Layout.Row = 2;
            obj.RNGSeedLabel.Layout.Column = 3;
            
            obj.RNGSeedEdit = uieditfield(obj.SearchMethodLayout,'numeric');
            obj.RNGSeedEdit.Layout.Row = 2;
            obj.RNGSeedEdit.Layout.Column = 4;
            obj.RNGSeedEdit.Limits = [0,Inf];
            obj.RNGSeedEdit.RoundFractionalValues = true;
            
            obj.InitialConditionsPath = QSPViewerNew.Widgets.FileSelector(obj.EditLayout,4,1,'Initial Conditions');
            
            obj.TableLayout = uigridlayout(obj.EditLayout());
            obj.TableLayout.Layout.Row = 3;
            obj.TableLayout.Layout.Column = 1;
            obj.TableLayout.ColumnWidth = {'1x','1x'};
            obj.TableLayout.RowHeight = {'1x'};
            obj.TableLayout.ColumnSpacing = 0;
            obj.TableLayout.RowSpacing = 0;
            obj.TableLayout.Padding = [0 0 0 0];
            
            obj.VirtualItemsTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,1,"Species-Data Mapping");
            
            obj.SpeciesDataTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,2,"Species-Data Mapping");
            
            obj.ParametersTableLabel = uilabel(obj.EditLayout);
            obj.ParametersTableLabel.Text = 'Parameters';
            obj.ParametersTableLabel.Layout.Row = 5;
            obj.ParametersTableLabel.Layout.Column = 1;
            
            obj.ParametersTable = uitable(obj.EditLayout);
            obj.ParametersTable.Layout.Row = 6;
            obj.ParametersTable.Layout.Column = 1;
            obj.ParametersTable.ColumnEditable = false;
            
            %Visualization Components
            obj.VisLayout = uigridlayout(obj.getVisualizationGrid());
            obj.VisLayout.Layout.Row = 2;
            obj.VisLayout.Layout.Column = 1;
            obj.VisLayout.ColumnWidth = {'1x'};
            obj.VisLayout.RowHeight = {obj.LabelHeight*3,obj.LabelHeight,obj.LabelHeight,'1x',obj.LabelHeight,obj.LabelHeight,'1x'};
            obj.VisLayout.ColumnSpacing = 0;
            obj.VisLayout.RowSpacing = 0;
            obj.VisLayout.Padding = [0 0 0 0];
            
            obj.VisButtonGroup = uibuttongroup(obj.VisLayout);
            obj.VisButtonGroup.Title = 'Plot Type';
            obj.VisButtonGroup.Layout.Column =1;
            obj.VisButtonGroup.Layout.Row =1;
            obj.VisButtonGroup.SelectionChangedFcn = @obj.onEditPlotType;
            
            obj.VisNormalButton = uiradiobutton(obj.VisButtonGroup);
            obj.VisNormalButton.Text = 'Normal';
            obj.VisNormalButton.Tag = 'Normal';
            obj.VisNormalButton.Tooltip = 'Plot Type: Normal';
            obj.VisNormalButton.Value = true;
            obj.VisNormalButton.Position = [14 46 100 22];
            
            obj.VisDiagnosticButton = uiradiobutton(obj.VisButtonGroup);
            obj.VisDiagnosticButton.Text = 'Diagnostic';
            obj.VisDiagnosticButton.Tag = 'Diagnostic';
            obj.VisDiagnosticButton.Tooltip = 'Plot Type: Diagnostic';
            obj.VisDiagnosticButton.Value = false;
            obj.VisDiagnosticButton.Position = [14 15 100 22];
            
            obj.VisParamatersDiagnosticButton = uibutton(obj.VisLayout,'push');
            obj.VisParamatersDiagnosticButton.Layout.Row = 2;
            obj.VisParamatersDiagnosticButton.Layout.Column = 1;
            obj.VisParamatersDiagnosticButton.Text = 'Parameter Distribution Diagnostics';
            obj.VisParamatersDiagnosticButton.Tooltip = 'Plot Parameter Distribution Diagnostics';
            obj.VisParamatersDiagnosticButton.ButtonPushedFcn = @obj.onParameterButton;
            
            obj.VisSpeciesDataTableLabel = uilabel(obj.VisLayout);
            obj.VisSpeciesDataTableLabel.Text = 'Species-Data';
            obj.VisSpeciesDataTableLabel.Layout.Row = 3;
            obj.VisSpeciesDataTableLabel.Layout.Column = 1;
            
            obj.VisSpeciesDataTable = uitable(obj.VisLayout);
            obj.VisSpeciesDataTable.Layout.Row = 4;
            obj.VisSpeciesDataTable.Layout.Column = 1;
            obj.VisSpeciesDataTable.ColumnEditable = false;
            obj.VisSpeciesDataTable.CellEditCallback = @obj.onEditSpeciesTable;
            
            obj.VisInvalidCheckBox = uicheckbox(obj.VisLayout);
            obj.VisInvalidCheckBox.Text = "Show Invalid Virtual Subjects";
            obj.VisInvalidCheckBox.Layout.Row = 5;
            obj.VisInvalidCheckBox.Layout.Column = 1;
            obj.VisInvalidCheckBox.ValueChangedFcn = @obj.onEditInvalidCheckBox;
            
            obj.VisVirtCohortItemsTableLabel = uilabel(obj.VisLayout);
            obj.VisVirtCohortItemsTableLabel.Text = 'Virtual Cohort Items';
            obj.VisVirtCohortItemsTableLabel.Layout.Row = 6;
            obj.VisVirtCohortItemsTableLabel.Layout.Column = 1;
            
            obj.VisVirtCohortItemsTable = uitable(obj.VisLayout);
            obj.VisVirtCohortItemsTable.Layout.Row = 7;
            obj.VisVirtCohortItemsTable.Layout.Column = 1;
            obj.VisVirtCohortItemsTable.ColumnEditable = false;
            obj.VisVirtCohortItemsTable.CellEditCallback = @obj.onEditVirtualCohortTable;
            obj.VisVirtCohortItemsTable.CellSelectionCallback = @obj.onSelectionVirtualCohortTable;
            
        end
        
        function createListenersAndCallbacks(obj)
            %Attach callbacks
            obj.ParametersDropDown.ValueChangedFcn = @(h,e) obj.onEditParameters(e.Value);
            obj.NumSimsEdit.ValueChangedFcn = @(h,e) obj.onEditNumSims(e.Value);
            obj.NumVirtualEdit.ValueChangedFcn = @(h,e) obj.onEditNumVirtual(e.Value);
            obj.AcceptanceDropDown.ValueChangedFcn = @(h,e) obj.onEditAcceptance(e.Value);
            obj.GroupColumnDropDown.ValueChangedFcn = @(h,e) obj.onEditGroupColumn(e.Value);
            obj.SavePrefDropDown.ValueChangedFcn = @(h,e) obj.onEditSavePref(e.Value);
            obj.SearchMethodDropDown.ValueChangedFcn = @(h,e) obj.onEditSearchMethod(e.Value);
            obj.MCMCtuningEdit.ValueChangedFcn = @(h,e) obj.onEditMCMCtuning(e.Value);
            obj.FixSeedCheckBox.ValueChangedFcn = @(h,e) obj.onEditFixSeed(e.Value);
            obj.RNGSeedEdit.ValueChangedFcn = @(h,e) obj.onEditRNGSeed(e.Value);
            
            %Create listeners
            obj.ResultsPathListener = addlistener(obj.ResultsPath,'StateChanged',@(src,event) obj.onEditResultsPath(event.Source.RelativePath));
            obj.InitialConditionsPathListener = addlistener(obj.InitialConditionsPath,'StateChanged',@(src,event) obj.onEditInitialConditionsPath(event.Source.RelativePath));
            
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
        
        function onEditParameters(obj,newValue)
            %Save value to backend
            obj.TemporaryCohortGeneration.RefParamName = newValue;
            
            MatchIdx = strcmp({obj.TemporaryCohortGeneration.Settings.Parameters.Name},obj.TemporaryCohortGeneration.RefParamName);
            if any(MatchIdx)
                pObj = obj.TemporaryCohortGeneration.Settings.Parameters(MatchIdx);
                [StatusOk,Message,obj.ParametersHeader,obj.ParametersData] = importData(pObj,pObj.FilePath);
                if ~StatusOk
                    uialert(obj.getUIFigure,Message,'Parameter Import Failed');
                end
            end
            
            % Update the paramters dropdown items and the corresponding
            % table
            obj.redrawParameters();
            obj.redrawParametersTable();
            obj.IsDirty = true;
            
        end
        
        function onEditNumSims(obj,newValue)
            obj.TemporaryCohortGeneration.MaxNumSimulations = newValue;
            obj.redrawNumSims();
            obj.IsDirty = true;
        end
        
        function onEditNumVirtual(obj,newValue)
            obj.TemporaryCohortGeneration.MaxNumVirtualPatients = newValue;
            obj.redrawNumVirtual();
            obj.IsDirty = true;
        end
        
        function onEditAcceptance(obj,newValue)
            obj.TemporaryCohortGeneration.DatasetName = newValue;
            obj.redrawGroupColumn();
            obj.redrawVirtualItemsTable();
            obj.redrawSpeciesDataTable();
            obj.IsDirty = true;
        end
        
        function onEditGroupColumn(obj,newValue)
            obj.TemporaryCohortGeneration.GroupName = newValue;
            obj.redrawGroupColumn();
            obj.redrawVirtualItemsTable();
            obj.IsDirty = true;
        end
        
        function onEditSavePref(obj,newValue)
            obj.TemporaryCohortGeneration.SaveInvalid = newValue;
            obj.redrawGroupColumn();
            obj.redrawVirtualItemsTable();
            obj.IsDirty = true;
        end
        
        function onEditSearchMethod(obj,newValue)
            obj.TemporaryCohortGeneration.Method = newValue;
            obj.redrawGroupColumn();
            obj.redrawVirtualItemsTable();
            obj.redrawMCMCTuning();
            obj.IsDirty = true;
        end
        
        function onEditMCMCtuning(obj,newValue)
            obj.TemporaryCohortGeneration.MCMCTuningParam = newValue;
            obj.IsDirty = true;
        end
        
        function onEditFixSeed(obj,newValue)
            obj.TemporaryCohortGeneration.FixRNGSeed = newValue;
            obj.redrawRNGSeed();
            obj.IsDirty = true;
        end
        
        function onEditRNGSeed(obj,newValue)
            obj.TemporaryCohortGeneration.RNGSeed = newValue;
            obj.IsDirty = true;
        end
        
        function onEditResultsPath(obj,newValue)
            if isempty(newValue)
                obj.TemporaryCohortGeneration.VPopResultsFolderName = char.empty(1,0);
            else
                obj.TemporaryCohortGeneration.VPopResultsFolderName = newValue;
            end
            obj.IsDirty = true;
        end
        
        function onEditInitialConditionsPath(obj,newValue)
            if isempty(newValue)
                obj.TemporaryCohortGeneration.ICFileName = char.empty(1,0);
            else
                obj.TemporaryCohortGeneration.ICFileName = newValue;
            end
            obj.IsDirty = true;
        end
        
        function onEditVirtualItemsTable(obj)
            [Row,Column,Value] = obj.VirtualItemsTable.lastChangedElement();
            
            if Column == 1
                obj.TemporaryCohortGeneration.Item(Row).TaskName = Value;
            elseif Column == 2
                obj.TemporaryCohortGeneration.Item(Row).GroupID = Value;
            end
            obj.IsDirty = true;
        end
        
        function onEditSpeciesDataTable(obj)
            [Row,Column,Value] = obj.SpeciesDataTable.lastChangedElement();
            
            if Column == 2
                obj.TemporaryCohortGeneration.SpeciesData(Row).SpeciesName = Value;
            elseif Column == 4
                obj.TemporaryCohortGeneration.SpeciesData(Row).FunctionExpression = Value;
            elseif ColColumnIdx == 1
                obj.TemporaryCohortGeneration.SpeciesData(Row).DataName = Value;
            elseif Column == 5
                obj.TemporaryCohortGeneration.SpeciesData(Row).ObjectiveName = Value;
            end
            obj.IsDirty = true;
        end
        
        function onNewVirtualItemsTable(obj)
            if ~isempty(obj.TaskPopupTableItems) && ~isempty(obj.GroupIDPopupTableItems)
                NewTaskGroup = QSP.TaskGroup;
                NewTaskGroup.TaskName = obj.TaskPopupTableItems{1};
                NewTaskGroup.GroupID = obj.GroupIDPopupTableItems{1};
                obj.TemporaryCohortGeneration.Item(end+1) = NewTaskGroup;
                obj.redrawVirtualItemsTable();
                obj.redrawSpeciesDataTable();
            else
                uialert(obj.getUIFigure,'At least one task and the group column must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.IsDirty = true;
        end
        
        function onNewSpeciesDataTable(obj)
            if ~isempty(obj.SpeciesPopupTableItems) && ~isempty(obj.DatasetDataColumn)
                NewSpeciesData = QSP.SpeciesData;
                NewSpeciesData.SpeciesName = obj.SpeciesPopupTableItems{1};
                NewSpeciesData.DataName = obj.DatasetDataColumn{1};
                DefaultExpression = 'x';
                NewSpeciesData.FunctionExpression = DefaultExpression;
                obj.TemporaryCohortGeneration.SpeciesData(end+1) = NewSpeciesData;
                obj.redrawVirtualItemsTable();
                obj.redrawSpeciesDataTable();
            else
                uialert(obj.getUIFigure,'At least one task with active species and a non-empty ''Data'' column in the dataset must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.IsDirty = true;
        end
        
        function onRemoveVirtualItemsTable(obj)
            Index = obj.VirtualItemsTable.getSelectedRow();
            if ~isempty(Index)
                obj.TemporaryCohortGeneration.SpeciesIC(Index) = [];
                obj.redrawVirtualItemsTable();
                obj.redrawSpeciesDataTable();
            end
            obj.IsDirty = true;
        end
        
        function onRemoveSpeciesDataTable(obj)
            Index = obj.SpeciesDataTable.getSelectedRow();
            if ~isempty(Index)
                obj.TemporaryCohortGeneration.SpeciesIC(Index) = [];
                obj.redrawVirtualItemsTable();
                obj.redrawSpeciesDataTable();
            end
            
        end
        
        %Visualization panel
        
        function onParameterButton(obj,~,~)
            if ~isempty(obj.CohortGeneration.VPopName)

                vpopFile = fullfile(obj.CohortGeneration.FilePath, obj.CohortGeneration.VPopResultsFolderName, obj.CohortGeneration.ExcelResultFileName);                
                try
                    Raw = readtable(vpopFile);
                    ParamNames = Raw.Properties.VariableNames;
                    Raw = [ParamNames;table2cell(Raw)];                    
                catch err
                    warning('Could not open vpop xlsx file.')
                    disp(err)
                    return
                end
                
                % Get the parameter values (everything but the header)
                if size(Raw,1) > 1
                    ParamValues = cell2mat(Raw(2:end,:));                    
                else
                    ParamValues = [];
                end
                    
                
                % filter invalids if checked
                if ~obj.VisInvalidCheckBox.Value && ismember('PWeight', ParamNames)
                    ParamValues = ParamValues( ParamValues(:, strcmp(ParamNames,'PWeight')) > 0, :);
                end
                
                ParamValues = ParamValues(:,~ismember(ParamNames,{'PWeight','Groups'}));
                ParamNames = ParamNames(~ismember(ParamNames,{'PWeight','Groups'}));
                
                MatchIdx = find(strcmp(obj.CohortGeneration.RefParamName,{obj.CohortGeneration.Settings.Parameters.Name}));
                
                LB = [];
                UB = [];                
                if ~isempty(MatchIdx)
                    try
                        Raw = readtable(obj.CohortGeneration.Settings.Parameters(MatchIdx).FilePath);
                        LB = Raw.LB;
                        UB = Raw.UB;
                    catch err
                        warning('Could not open parameters xlsx file or LB and/or UB column headers are missing. Setting lower and upper bounds to empty.')
                        disp(err)                       
                    end
                end
                
                
                %Create the popup panel
                nAxes = length(ParamNames);
                ParentFigure = obj.getUIFigure;
                PlotPopup = QSPViewerNew.Widgets.HistPlotLayoutCustom(ParentFigure,nAxes);
                nCols = PlotPopup.getWidth();
                nRows = round(nAxes/nCols);
                scrollingPanel = PlotPopup.getPlotGrid();
                
                %fill the grid with axes
                for k=1:nAxes
                    ax=uiaxes(scrollingPanel);
                    %Fill in the left to right
                    ax.Layout.Column = floor((k-1)/nRows)+1; 
                    ax.Layout.Row = mod(k-1,nCols)+2;
                    histogram(ax, ParamValues(:,k))
                    if k <= length(LB)
                        h2(1)=line(ax,LB(k)*ones(1,2), get(ax,'YLim'));
                        h2(2)=line(ax,UB(k)*ones(1,2), get(ax,'YLim'));
                        set(h2,'LineStyle','--','Color','r')
                    end
                    title(ax, ParamNames{k}, 'Interpreter', 'none', 'FontSize', 20)
                    set(ax, 'TitleFontWeight', 'bold', 'FontSize', 20 )
                    if strcmpi(Raw.Scale(k), 'log')
                        set(ax,'XScale', 'log')
                    end
                end          
                PlotPopup.wait();
                PlotPopup.delete();

            end
        end
        
        function onEditSpeciesTable(obj,h,e)
            
            RowIdx = e.Indices(1,1);
            ColIdx = e.Indices(1,2);
            
            if strcmpi(obj.CohortGeneration.PlotType,'Diagnostic')
                %In diagnostic Mode, just redraw all the plots
                
                if (ColIdx==1 || ColIdx == 2) && any(strcmp(h.ColumnFormat{ColIdx},e.NewData))
                    obj.CohortGeneration.PlotSpeciesTable(RowIdx,ColIdx) =e.NewData(RowIdx,ColIdx);
                    obj.drawVisualization();
                else
                    %revert, entry not valid
                    h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                end
            else
                switch ColIdx
                    case 1
                        sIdx = RowIdx;
                        OldAxIdx = str2double(e.PreviousData);
                        NewAxIdx = str2double(e.NewData);
                        
                        %Determine if change was valid
                        if any(strcmp(h.ColumnFormat{ColIdx},e.NewData))
                            %Update backend
                            obj.CohortGeneration.PlotSpeciesTable(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                            
                            % If originally not plotted
                            if isempty(OldAxIdx) && ~isempty(NewAxIdx)
                                obj.SpeciesGroup{sIdx,NewAxIdx} = obj.SpeciesGroup{sIdx,1};
                                obj.DatasetGroup{sIdx,NewAxIdx} = obj.DatasetGroup{sIdx,1};
                                % Parent
                                obj.SpeciesGroup{sIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                                obj.DatasetGroup{sIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                                
                            elseif ~isempty(OldAxIdx) && isempty(NewAxIdx)
                                obj.SpeciesGroup{sIdx,1} = obj.SpeciesGroup{sIdx,OldAxIdx};
                                obj.DatasetGroup{sIdx,1} = obj.DatasetGroup{sIdx,OldAxIdx};
                                % Un-parent
                                obj.SpeciesGroup{sIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                                obj.DatasetGroup{sIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                                if OldAxIdx ~= 1
                                    obj.SpeciesGroup{sIdx,OldAxIdx} = [];
                                    obj.DatasetGroup{sIdx,OldAxIdx} = [];
                                end
                                
                            elseif ~isempty(OldAxIdx) && ~isempty(NewAxIdx)
                                obj.SpeciesGroup{sIdx,NewAxIdx} = obj.SpeciesGroup{sIdx,OldAxIdx};
                                obj.DatasetGroup{sIdx,NewAxIdx} = obj.DatasetGroup{sIdx,OldAxIdx};
                                % Re-parent
                                obj.SpeciesGroup{sIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                                obj.DatasetGroup{sIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                                if OldAxIdx ~= NewAxIdx
                                    obj.SpeciesGroup{sIdx,OldAxIdx} = [];
                                    obj.DatasetGroup{sIdx,OldAxIdx} = [];
                                end
                                
                            end
                            
                            % Update lines (line widths, marker sizes)
                            obj.updateLines();
                            
                            AxIndices = [OldAxIdx,NewAxIdx];
                            AxIndices(isnan(AxIndices)) = [];
                            
                            % Redraw legend
                            [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                                obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                                'AxIndices',AxIndices);
                            obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                            obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                        else
                           %revert, entry not valid
                            h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                        end
                        
                    case 2
                        %Determine if change was valid
                        if any(strcmp(h.ColumnFormat{ColIdx},e.NewData))
                            
                            %Update backend
                            obj.CohortGeneration.PlotSpeciesTable(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                            
                            %Set line style
                            NewLineStyle = h.Data{RowIdx,2};
                            setSpeciesLineStyles(obj.CohortGeneration,RowIdx,NewLineStyle);
                            
                            
                            AxIndices = str2double(h.Data{RowIdx,1});
                            if isempty(AxIndices)
                                AxIndices = 1:numel(obj.PlotArray);
                            end
                            
                            % Redraw legend
                            [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                                obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                                'AxIndices',AxIndices);
                            obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                            obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                            
                        else
                            %revert, entry not valid
                            h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                        end
                        
                    case 5
                        %update backend
                        obj.CohortGeneration.PlotSpeciesTable(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                        
                        AxIndices = str2double(h.Data{RowIdx,1});
                        if isempty(AxIndices)
                            AxIndices = 1:numel(obj.PlotArray);
                        end
                        
                        % Redraw legend
                        [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                            obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                            'AxIndices',AxIndices);
                        obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                        obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                end
            end
        end
        
        function onEditVirtualCohortTable(obj,h,e)
            
            %update the backend table
            obj.CohortGeneration.PlotItemTable(e.Indices(1),e.Indices(2)) = h.Data(e.Indices(1),e.Indices(2));
             
            if strcmpi(obj.CohortGeneration.PlotType,'Diagnostic')
                obj.drawVisualization();
            else
                switch e.Indices(2)
                    %Only save the legends if they were edited
                    case 1
                        updatePlots(obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,'RedrawLegend',false);
                    case 5
                        [obj.AxesLegend,obj.AxesLegendChildren] = updatePlots(obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup);
                end
            end
        end
        
        function onSelectionVirtualCohortTable(obj,~,e)
            obj.SelectedRow =e.Indices(1);
        end
        
        function onEditInvalidCheckBox(obj,h,~)
            obj.CohortGeneration.ShowInvalidVirtualPatients = h.Value;
            if strcmpi(obj.CohortGeneration.PlotType,'Diagnostic')
                obj.drawVisualization();
            else
                [obj.AxesLegend,obj.AxesLegendChildren] = updatePlots(obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup);
            end
        end
        
        function onEditPlotType(obj,~,e)
            obj.CohortGeneration.PlotType = e.NewValue.Tag;
            
            % Update the view
            obj.drawVisualization();
        end
        
        function onContextMenu(~,~,~)
            %TODO when uisetcolor is supported or a workaround
        end
        
    end
    
    methods (Access = public)
        
        function Value = getRootDirectory(obj)
            Value = obj.CohortGeneration.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewCohortGeneration(obj,NewCohortGeneration)
            obj.CohortGeneration = NewCohortGeneration;
            obj.CohortGeneration.PlotSettings = getSummary(obj.getPlotSettings());
            
            obj.TemporaryCohortGeneration = copy(obj.CohortGeneration);
            
            
            for index = 1:obj.MaxNumPlots
                Summary = obj.CohortGeneration.PlotSettings(index);
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
            [StatusOK,Message,vpopobj] = run(obj.CohortGeneration);
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            else
                obj.notifyOfChange(vpopobj);
            end
        end
        
        function drawVisualization(obj)
            
            %DropDown Update
            obj.updatePlotConfig(obj.CohortGeneration.SelectedPlotLayout);
            
            %Determine if the values are valid
            if ~isempty(obj.CohortGeneration)
                % Check what items are stale or invalid
                [obj.StaleFlag,obj.ValidFlag] = getStaleItemIndices(obj.CohortGeneration);
            end
            
            obj.reimport();
            obj.redrawPlotType();
            obj.redrawSpeciesTable();
            obj.redrawVirtualCohortTable();
            obj.redrawInvalidCheckBox();
            obj.redrawAxesContextMenu();
            obj.redrawContextMenu();
            
            %Reset Xticks only for CohortGeneration
            set(obj.PlotArray,'XTickMode','auto','XTickLabelMode','auto');
            [obj.SpeciesGroup,obj.DatasetGroup,obj.AxesLegend,obj.AxesLegendChildren] = ...
                plotCohortGeneration(obj.CohortGeneration,obj.PlotArray);
        end
        
        function refreshVisualization(obj,axIndex)
            
            obj.reimport();
            obj.redrawPlotType();
            obj.redrawSpeciesTable();
            obj.redrawVirtualCohortTable();
            obj.redrawInvalidCheckBox();
            obj.redrawAxesContextMenu();
            obj.redrawContextMenu();
            
            if ~isempty(axIndex)
                [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                    obj.CohortGeneration,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'AxIndices',axIndex);
                obj.AxesLegend(axIndex) = UpdatedAxesLegend(axIndex);
                obj.AxesLegendChildren(axIndex) = UpdatedAxesLegendChildren(axIndex);
            end
           
        end
        
        function UpdateBackendPlotSettings(obj)
            obj.CohortGeneration.PlotSettings = getSummary(obj.getPlotSettings());
        end
        
    end
    
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryCohortGeneration.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryCohortGeneration.Description= value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInPlotConfig(obj,value)
            obj.CohortGeneration.SelectedPlotLayout = value;
            obj.updatePlotConfig(value);
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryCohortGeneration.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryCohortGeneration.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.CohortGeneration = copy(obj.TemporaryCohortGeneration,obj.CohortGeneration);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.TemporaryCohortGeneration.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function removeInvalidVisualization(obj)
            % Remove invalid indices
            if ~isempty(obj.PlotSpeciesInvalidRowIndices)
                obj.CohortGeneration.PlotSpeciesTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotSpeciesAsInvalidTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotSpeciesInvalidRowIndices = [];
            end
            
            if ~isempty(obj.PlotItemInvalidRowIndices)
                obj.CohortGeneration.PlotItemTable(obj.PlotItemInvalidRowIndices,:) = [];
                obj.PlotItemAsInvalidTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotItemInvalidRowIndices = [];
            end
            
            % reset the cached simulation results
            obj.CohortGeneration.SimResults = {};
            
            % Update
            obj.reimport();
            obj.redrawPlotType();
            obj.redrawSpeciesTable();
            obj.redrawVirtualCohortTable();
            obj.redrawInvalidCheckBox();
            obj.redrawContextMenu();
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryCohortGeneration)
            obj.TemporaryCohortGeneration = copy(obj.CohortGeneration);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryCohortGeneration.Description);
            obj.updateNameBox(obj.TemporaryCohortGeneration.Name);
            obj.updateSummary(obj.TemporaryCohortGeneration.getSummary());
            
            %Draw every element from scratch
            obj.redrawParameters();
            obj.redrawNumSims();
            obj.redrawNumVirtual();
            obj.redrawAcceptance();
            obj.redrawGroupColumn();
            obj.redrawSavePref();
            obj.redrawSearchMethod();
            obj.redrawMCMCTuning();
            obj.redrawFixSeed();
            obj.redrawRNGSeed();
            obj.redrawResultsPath();
            obj.redrawInitialConditionsPath();
            obj.redrawVirtualItemsTable();
            obj.redrawSpeciesDataTable();
            obj.redrawParametersTable();
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryCohortGeneration,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.CohortGeneration.Session.CohortGeneration;
            ixDup = find(strcmp( obj.TemporaryCohortGeneration.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.CohortGeneration)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
        function [ValidTF] = isValid(obj)
            [~,Valid] = getStaleItemIndices(obj.CohortGeneration);
            ValidTF = all(Valid);
        end
        
        function BackEnd = getBackEnd(obj)
            BackEnd = obj.CohortGeneration;
        end
    end
    
    %redraw methods
    methods (Access = private)
        
        function redrawParameters(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                ThisList = {obj.TemporaryCohortGeneration.Settings.Parameters.Name};
                Selection = obj.TemporaryCohortGeneration.RefParamName;
                
                MatchIdx = strcmpi(ThisList,Selection);
                if any(MatchIdx)
                    ThisStatusOk = validate(obj.TemporaryCohortGeneration.Settings.Parameters(MatchIdx));
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
            obj.ParameterPopupItems = FullList;
            obj.ParameterPopupItemsWithInvalid = FullListWithInvalids;
            
            obj.ParametersDropDown.Items = obj.ParameterPopupItemsWithInvalid;
            obj.ParametersDropDown.Value = obj.ParameterPopupItemsWithInvalid{Value};
        end
        
        function redrawNumSims(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                obj.NumSimsEdit.Value = obj.TemporaryCohortGeneration.MaxNumSimulations;
            else
                obj.NumSimsEdit.Value = 0;
            end
        end
        
        function redrawNumVirtual(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                obj.NumVirtualEdit.Value = obj.TemporaryCohortGeneration.MaxNumVirtualPatients;
            else
                obj.NumVirtualEdit.Value = 0;
            end
        end
        
        function redrawAcceptance(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                ThisList = {obj.TemporaryCohortGeneration.Settings.VirtualPopulationData.Name};
                Selection = obj.TemporaryCohortGeneration.DatasetName;
                
                MatchIdx = strcmpi(ThisList,Selection);
                if any(MatchIdx)
                    ThisStatusOk = validate(obj.TemporaryCohortGeneration.Settings.VirtualPopulationData(MatchIdx));
                    ForceMarkAsInvalid = ~ThisStatusOk;
                else
                    ForceMarkAsInvalid = false;
                end
                
                % Invoke helper
                [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
            else
                FullList = {'-'};
                FullListWithInvalids = {QSP.makeInvalid('-')};
                Value = 1;
            end
            obj.DatasetPopupItems = FullList;
            obj.DatasetPopupItemsWithInvalid = FullListWithInvalids;
            
            obj.AcceptanceDropDown.Items = obj.DatasetPopupItemsWithInvalid;
            obj.AcceptanceDropDown.Value = obj.DatasetPopupItemsWithInvalid{Value};
            
            if ~isempty(obj.TemporaryCohortGeneration) && ~isempty(obj.TemporaryCohortGeneration.DatasetName) && ~isempty(obj.TemporaryCohortGeneration.Settings.VirtualPopulationData)
                Names = {obj.TemporaryCohortGeneration.Settings.VirtualPopulationData.Name};
                MatchIdx = strcmpi(Names,obj.TemporaryCohortGeneration.DatasetName);
                
                if any(MatchIdx)
                    dObj = obj.TemporaryCohortGeneration.Settings.VirtualPopulationData(MatchIdx);
                    
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
                MatchIdx = find(strcmpi(VPopHeader,'Data'));
                if numel(MatchIdx) == 1
                    obj.DatasetDataColumn = unique(VPopData(:,MatchIdx));
                elseif numel(MatchIdx) == 0
                    obj.DatasetDataColumn = {};
                    warning('Acceptance Criteria %s has 0 ''Data'' column names',vpopObj.FilePath);
                else
                    obj.DatasetDataColumn = {};
                    warning('Acceptance Criteria %s has multiple ''Data'' column names',vpopObj.FilePath);
                end
            else
                obj.DatasetDataColumn = {};
            end
        end
        
        function redrawGroupColumn(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                GroupSelection = obj.TemporaryCohortGeneration.GroupName;
                [FullGroupListWithInvalids,FullGroupList,GroupValue] = QSP.highlightInvalids(obj.DatasetHeader,GroupSelection);
            else
                FullGroupList = {'-'};
                FullGroupListWithInvalids = {QSP.makeInvalid('-')};
                
                GroupValue = 1;
            end
            obj.DatasetGroupPopupItems = FullGroupList;
            obj.DatasetGroupPopupItemsWithInvalid = FullGroupListWithInvalids;
            
            if ~isempty(obj.TemporaryCohortGeneration) && ~isempty(obj.DatasetHeader) && ~isempty(obj.DatasetData)
                MatchIdx = strcmp(obj.DatasetHeader,obj.TemporaryCohortGeneration.GroupName);
                TempGroupIDs = obj.DatasetData(:,MatchIdx);
                if iscell(TempGroupIDs)
                    TempGroupIDs = cell2mat(TempGroupIDs);
                end
                TempGroupIDs = unique(TempGroupIDs);
                obj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(TempGroupIDs),'UniformOutput',false);
            else
                obj.GroupIDPopupTableItems = {};
            end
            obj.GroupColumnDropDown.Items = obj.DatasetGroupPopupItemsWithInvalid;
            obj.GroupColumnDropDown.Value = obj.DatasetGroupPopupItemsWithInvalid{GroupValue};
        end
        
        function redrawSavePref(obj)
            obj.SavePrefDropDown.Items = obj.SaveValues(:,1);
            obj.SavePrefDropDown.ItemsData = obj.SaveValues(:,2);
            if any(contains(obj.SaveValues(:,2),obj.TemporaryCohortGeneration.SaveInvalid))
                obj.SavePrefDropDown.Value =  obj.TemporaryCohortGeneration.SaveInvalid;
            else
                obj.SavePrefDropDown.Value = obj.SaveValues{1,2};
            end
            
        end
        
        function redrawSearchMethod(obj)
            obj.SearchMethodDropDown.Items = obj.MethodPopupItems;
            obj.SearchMethodDropDown.Value =  obj.TemporaryCohortGeneration.Method;
        end
        
        function redrawMCMCTuning(obj)
            if strcmpi(obj.TemporaryCohortGeneration.Method, 'MCMC')
                obj.MCMCtuningEdit.Enable = true;
            else
                obj.MCMCtuningEdit.Enable = false;
            end
            obj.MCMCtuningEdit.Value = obj.TemporaryCohortGeneration.MCMCTuningParam;
            
        end
        
        function redrawFixSeed(obj)
            obj.FixSeedCheckBox.Value = obj.TemporaryCohortGeneration.FixRNGSeed;
        end
        
        function redrawRNGSeed(obj)
            obj.RNGSeedEdit.Value = obj.TemporaryCohortGeneration.RNGSeed;
            obj.RNGSeedEdit.Enable = obj.FixSeedCheckBox.Value;
        end
        
        function redrawResultsPath(obj)
            obj.ResultsPath.RootDirectory = obj.TemporaryCohortGeneration.Session.RootDirectory;
            obj.ResultsPath.RelativePath = obj.TemporaryCohortGeneration.VPopResultsFolderName;
        end
        
        function redrawInitialConditionsPath(obj)
            obj.InitialConditionsPath.RootDirectory = obj.TemporaryCohortGeneration.Session.RootDirectory;
            obj.InitialConditionsPath.RelativePath = obj.TemporaryCohortGeneration.ICFileName;
        end
        
        function redrawVirtualItemsTable(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                ValidItemTasks = getValidSelectedTasks(obj.TemporaryCohortGeneration.Settings,{obj.TemporaryCohortGeneration.Settings.Task.Name});
                if ~isempty(ValidItemTasks)
                    obj.TaskPopupTableItems = {ValidItemTasks.Name};
                else
                    obj.TaskPopupTableItems = {};
                end
            else
                obj.TaskPopupTableItems = {};
            end
            
            if ~isempty(obj.TemporaryCohortGeneration)
                ItemTaskNames = {obj.TemporaryCohortGeneration.Item.TaskName};
                obj.SpeciesPopupTableItems = getSpeciesFromValidSelectedTasks(obj.TemporaryCohortGeneration.Settings,ItemTaskNames);
            else
                obj.SpeciesPopupTableItems = {};
            end
            
            if ~isempty(obj.TemporaryCohortGeneration)
                TaskNames = {obj.TemporaryCohortGeneration.Item.TaskName};
                TempGroupIDs = {obj.TemporaryCohortGeneration.Item.GroupID};
                RunToSteadyState = false(size(TaskNames));
                
                for index = 1:numel(TaskNames)
                    MatchIdx = strcmpi(TaskNames{index},{obj.TemporaryCohortGeneration.Settings.Task.Name});
                    if any(MatchIdx)
                        RunToSteadyState(index) = obj.TemporaryCohortGeneration.Settings.Task(MatchIdx).RunToSteadyState;
                    end
                end
                Data = [TaskNames(:) TempGroupIDs(:) num2cell(RunToSteadyState(:))];
                
                % Mark any invalid entries
                if ~isempty(Data)
                    % Task
                    
                    for index = 1:numel(TaskNames)
                        ThisTask = getValidSelectedTasks(obj.TemporaryCohortGeneration.Settings,TaskNames{index});
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
            if ~isempty(obj.TemporaryCohortGeneration) && ~isempty(obj.DatasetHeader) && ~isempty(obj.DatasetData)
                MatchIdx = strcmp(obj.DatasetHeader,obj.TemporaryCohortGeneration.GroupName);
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
            obj.VirtualItemsTable.setName({'Task','Group','Run To Steady State'});
            obj.VirtualItemsTable.setFormat({obj.TaskPopupTableItems(:)',obj.GroupIDPopupTableItems(:)','char'})
            obj.VirtualItemsTable.setData(Data)
        end
        
        function redrawSpeciesDataTable(obj)
            if ~isempty(obj.TemporaryCohortGeneration)
                if exist(obj.TemporaryCohortGeneration.Session.ObjectiveFunctionsDirectory,'dir')
                    FileList = dir(obj.TemporaryCohortGeneration.Session.ObjectiveFunctionsDirectory);
                    IsDir = [FileList.isdir];
                    Names = {FileList(~IsDir).name};
                    obj.ObjectiveFunctions = vertcat('defaultObj',Names(:));
                else
                    obj.ObjectiveFunctions = {'defaultObj'};
                end
            else
                obj.ObjectiveFunctions = {'defaultObj'};
            end
            
            
            if ~isempty(obj.TemporaryCohortGeneration)
                SpeciesNames = {obj.TemporaryCohortGeneration.SpeciesData.SpeciesName};
                DataNames = {obj.TemporaryCohortGeneration.SpeciesData.DataName};
                FunctionExpressions = {obj.TemporaryCohortGeneration.SpeciesData.FunctionExpression};
                
                % Get the selected tasks based on Optim Items
                ItemTaskNames = {obj.TemporaryCohortGeneration.Item.TaskName};
                ValidSelectedTasks = getValidSelectedTasks(obj.TemporaryCohortGeneration.Settings,ItemTaskNames);
                
                NumTasksPerSpecies = zeros(size(SpeciesNames));
                for iSpecies = 1:numel(SpeciesNames)
                    for iTask = 1:numel(ValidSelectedTasks)
                        if any(strcmpi(SpeciesNames{iSpecies},ValidSelectedTasks(iTask).SpeciesNames))
                            NumTasksPerSpecies(iSpecies) = NumTasksPerSpecies(iSpecies) + 1;
                        end
                    end
                end
                
                Data = [DataNames(:) SpeciesNames(:) num2cell(NumTasksPerSpecies(:)) FunctionExpressions(:)];
                
                % Mark any invalid entries
                if ~isempty(Data)
                    % Species
                    MatchIdx = find(~ismember(SpeciesNames(:),obj.SpeciesPopupTableItems(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),1});
                    end
                    % Data
                    MatchIdx = find(~ismember(DataNames(:),obj.DatasetDataColumn(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),4});
                    end
                end
            else
                Data = {};
            end
            
            obj.SpeciesDataTable.setEditable([true true false true]);
            obj.SpeciesDataTable.setName({'Data (y)','Species (x)','# Tasks per Species','y=f(x)'});
            obj.SpeciesDataTable.setFormat({obj.DatasetDataColumn(:)',obj.SpeciesPopupTableItems(:)','numeric','char'})
            obj.SpeciesDataTable.setData(Data)
        end
        
        function redrawParametersTable(obj)
            if ~isempty(obj.TemporaryCohortGeneration) && ~isempty(obj.TemporaryCohortGeneration.RefParamName)
                Names = {obj.TemporaryCohortGeneration.Settings.Parameters.Name};
                MatchIdx = strcmpi(Names,obj.TemporaryCohortGeneration.RefParamName);
                if any(MatchIdx)
                    pObj = obj.TemporaryCohortGeneration.Settings.Parameters(MatchIdx);
                    [StatusOk,~,TempParametersHeader,TempParametersData] = importData(pObj,pObj.FilePath);
                    if StatusOk
                        % Display only select columns
                        [~,ColIndices] = ismember({'Include','Name','Scale','LB','UB'},TempParametersHeader);
                        
                        if any(~ColIndices)
                            error('Parameters file contains invalid column names')
                        end
                        
                        
                        obj.ParametersHeader = TempParametersHeader(ColIndices);
                        obj.ParametersData = TempParametersData(:,ColIndices);
                    else
                        obj.ParametersHeader = {};
                        obj.ParametersData = {};
                    end
                else
                    obj.ParametersHeader = {};
                    obj.ParametersData = {};
                end
            else
                obj.ParametersHeader = {};
                obj.ParametersData = {};
            end
            obj.ParametersTable.ColumnName = obj.ParametersHeader;
            obj.ParametersTable.Data = obj.ParametersData;
            
        end
        
        %Redrew on Visualize panel
        function reimport(obj)
            if ~isempty(obj.CohortGeneration) && ~isempty(obj.CohortGeneration.DatasetName) && ~isempty(obj.CohortGeneration.Settings.VirtualPopulationData)
                Names = {obj.CohortGeneration.Settings.VirtualPopulationData.Name};
                MatchIdx = strcmpi(Names,obj.CohortGeneration.DatasetName);
                
                if any(MatchIdx)
                    vpopObj = obj.CohortGeneration.Settings.VirtualPopulationData(MatchIdx);
                    
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
            MatchIdx = strcmpi(VpopHeader,'Data');
            if any(MatchIdx)
                obj.UniqueDataVals = unique(VpopData(:,MatchIdx));
            else
                obj.UniqueDataVals = {};
            end
            
            % Get the group column
            % GroupID
            if ~isempty(VpopHeader) && ~isempty(VpopData)
                MatchIdx = strcmp(VpopHeader,obj.CohortGeneration.GroupName);
                tempGroupIDs = VpopData(:,MatchIdx);
                if iscell(tempGroupIDs)
                    tempGroupIDs = cell2mat(tempGroupIDs);
                end
                tempGroupIDs = unique(tempGroupIDs);
                tempGroupIDs = cellfun(@(x)num2str(x),num2cell(tempGroupIDs),'UniformOutput',false);
            else
                tempGroupIDs = [];
            end
            obj.GroupIDs = tempGroupIDs;
        end

        function redrawPlotType(obj)
            if ~isempty(obj.CohortGeneration)
                if strcmpi(obj.CohortGeneration.PlotType,'Normal')
                    obj.VisButtonGroup.SelectedObject = obj.VisNormalButton;
                else
                    obj.VisButtonGroup.SelectedObject = obj.VisDiagnosticButton;
                end
            end
        end
        
        function redrawSpeciesTable(obj)
            
            if ~isempty(obj.CohortGeneration)
                % Get the raw SpeciesNames, DataNames
                TaskNames = {obj.CohortGeneration.Item.TaskName};
                SpeciesNames = {obj.CohortGeneration.SpeciesData.SpeciesName};
                [~,order] = sort(upper(SpeciesNames));
                obj.CohortGeneration.SpeciesData = obj.CohortGeneration.SpeciesData(order);
                
                SpeciesNames = {obj.CohortGeneration.SpeciesData.SpeciesName};
                DataNames = {obj.CohortGeneration.SpeciesData.DataName};
                
                
                
                % Get the list of all active species from all valid selected tasks
                ValidSpeciesList = getSpeciesFromValidSelectedTasks(obj.CohortGeneration.Settings,TaskNames);
                
                InvalidIndices = false(size(SpeciesNames));
                for idx = 1:numel(SpeciesNames)
                    % Check if the species is missing
                    MissingSpecies = ~ismember(SpeciesNames{idx},ValidSpeciesList);
                    MissingData = ~ismember(DataNames{idx},obj.UniqueDataVals);
                    if MissingSpecies || MissingData
                        InvalidIndices(idx) = true;
                    end
                end
                
                if isempty(obj.CohortGeneration.PlotSpeciesTable)
                    
                    if any(InvalidIndices)
                        % Then, prune
                        SpeciesNames(InvalidIndices) = [];
                        DataNames(InvalidIndices) = [];
                    end
                    
                    % If empty, populate, but first update line styles
                    obj.CohortGeneration.PlotSpeciesTable = cell(numel(SpeciesNames),5);
                    updateSpeciesLineStyles(obj.CohortGeneration);
                    
                    obj.CohortGeneration.PlotSpeciesTable(:,1) = {' '};
                    obj.CohortGeneration.PlotSpeciesTable(:,2) = obj.CohortGeneration.SpeciesLineStyles(:);
                    obj.CohortGeneration.PlotSpeciesTable(:,3) = SpeciesNames;
                    obj.CohortGeneration.PlotSpeciesTable(:,4) = DataNames;
                    obj.CohortGeneration.PlotSpeciesTable(:,5) = SpeciesNames;
                    
                    obj.PlotSpeciesAsInvalidTable = obj.CohortGeneration.PlotSpeciesTable;
                    obj.PlotSpeciesInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(SpeciesNames),5);
                    NewPlotTable(:,1) = {' '};
                    NewPlotTable(:,2) = {'-'}; 
                    NewPlotTable(:,3) = SpeciesNames;
                    NewPlotTable(:,4) = DataNames;
                    NewPlotTable(:,5) = SpeciesNames;
                    
                    % Adjust size if from an old saved session
                    if size(obj.CohortGeneration.PlotSpeciesTable,2) == 3
                        obj.CohortGeneration.PlotSpeciesTable(:,5) = obj.CohortGeneration.PlotSpeciesTable(:,3);
                        obj.CohortGeneration.PlotSpeciesTable(:,4) = obj.CohortGeneration.PlotSpeciesTable(:,3);
                        obj.CohortGeneration.PlotSpeciesTable(:,3) = obj.CohortGeneration.PlotSpeciesTable(:,2);
                        obj.CohortGeneration.PlotSpeciesTable(:,2) = {'-'};  
                    elseif size(obj.CohortGeneration.PlotSpeciesTable,2) == 4
                        obj.CohortGeneration.PlotSpeciesTable(:,5) = obj.CohortGeneration.PlotSpeciesTable(:,3);
                    end
                    
                    % Update Table
                    KeyColumn = [3 4];
                    [obj.CohortGeneration.PlotSpeciesTable,obj.PlotSpeciesAsInvalidTable,obj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.CohortGeneration.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);
                    % Update line styles
                    obj.CohortGeneration.updateSpeciesLineStyles();
                end
                AxesOptions = obj.getAxesOptions();
                
                obj.VisSpeciesDataTable.Data = obj.PlotSpeciesAsInvalidTable;
                obj.VisSpeciesDataTable.ColumnName = {'Plot','Style','Species','Data','Display'};
                obj.VisSpeciesDataTable.ColumnFormat = {AxesOptions',obj.CohortGeneration.Settings.LineStyleMap,'char','char','char'};
                obj.VisSpeciesDataTable.ColumnEditable =[true,true,false,false,true];
            else
                AxesOptions = obj.getAxesOptions();
                
                obj.VisSpeciesDataTable.Data = obj.PlotSpeciesAsInvalidTable;
                obj.VisSpeciesDataTable.ColumnName = {'Plot','Style','Species','Data','Display'};
                obj.VisSpeciesDataTable.ColumnFormat = {AxesOptions','char','char','char','char'};
                obj.VisSpeciesDataTable.ColumnEditable =[true,true,false,false,true];
            end
        end
        
        function redrawVirtualCohortTable(obj)
            if ~isempty(obj.CohortGeneration)
                
                % Get the raw TaskNames, GroupIDNames
                TaskNames = {obj.CohortGeneration.Item.TaskName};
                GroupIDNames = {obj.CohortGeneration.Item.GroupID};
                
                InvalidIndices = false(size(TaskNames));
                for idx = 1:numel(TaskNames)
                    % Check if the task is valid
                    ThisTask = getValidSelectedTasks(obj.CohortGeneration.Settings,TaskNames{idx});
                    MissingGroup = ~ismember(GroupIDNames{idx},obj.GroupIDs(:)');
                    if isempty(ThisTask) || MissingGroup
                        InvalidIndices(idx) = true;
                    end
                end
                
                % If empty, populate
                if isempty(obj.CohortGeneration.PlotItemTable)
                    
                    if any(InvalidIndices)
                        % Then, prune
                        TaskNames(InvalidIndices) = [];
                        GroupIDNames(InvalidIndices) = [];
                    end
                    
                    obj.CohortGeneration.PlotItemTable = cell(numel(TaskNames),5);
                    obj.CohortGeneration.PlotItemTable(:,1) = {false};
                    obj.CohortGeneration.PlotItemTable(:,3) = TaskNames;
                    obj.CohortGeneration.PlotItemTable(:,4) = GroupIDNames;
                    obj.CohortGeneration.PlotItemTable(:,5) = TaskNames;
                    
                    % Update the item colors
                    ItemColors = getItemColors(obj.CohortGeneration.Session,numel(TaskNames));
                    obj.CohortGeneration.PlotItemTable(:,2) = num2cell(ItemColors,2);
                    
                    obj.PlotItemAsInvalidTable = obj.CohortGeneration.PlotItemTable;
                    obj.PlotItemInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(TaskNames),5);
                    NewPlotTable(:,1) = {false};
                    NewPlotTable(:,3) = TaskNames;
                    NewPlotTable(:,4) = GroupIDNames;
                    NewPlotTable(:,5) = TaskNames;
                    
                    NewColors = getItemColors(obj.CohortGeneration.Session,numel(TaskNames));
                    NewPlotTable(:,2) = num2cell(NewColors,2);
                    
                    if size(obj.CohortGeneration.PlotItemTable,2) == 4
                        obj.CohortGeneration.PlotItemTable(:,5) = obj.CohortGeneration.PlotItemTable(:,3);
                    end
                    
                    % Update Table
                    KeyColumn = [3 4];
                    [obj.CohortGeneration.PlotItemTable,obj.PlotItemAsInvalidTable,obj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.CohortGeneration.PlotItemTable,NewPlotTable,InvalidIndices,KeyColumn);
                end
                
                % Check which results files are invalid
                ResultsDir = fullfile(obj.CohortGeneration.Session.RootDirectory,obj.CohortGeneration.VPopResultsFolderName);
                if exist(fullfile(ResultsDir,obj.CohortGeneration.ExcelResultFileName),'file') == 2
                    FlagIsInvalidResultFile = false; % Exists, not invalid
                else
                    FlagIsInvalidResultFile = true;
                end
                
                % Only make the "valids" missing. Leave the invalids as is
                TableData = obj.PlotItemAsInvalidTable;
                if ~isempty(TableData)
                    for index = 1:size(obj.CohortGeneration.PlotItemTable,1)
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

                obj.VisVirtCohortItemsTable.Data = TableData;
                obj.VisVirtCohortItemsTable.ColumnName = {'Include','Color','Task','Group','Display'};
                obj.VisVirtCohortItemsTable.ColumnFormat = {'logical','char','char','char','char'};
                obj.VisVirtCohortItemsTable.ColumnEditable =[true,false,false,false,true];
                
                for index = 1:size(TableData,1)
                    ThisColor = obj.CohortGeneration.PlotItemTable{index,2};
                    if ~isempty(ThisColor)
                        addStyle(obj.VisVirtCohortItemsTable,uistyle('BackgroundColor',ThisColor),'cell',[index,2])
                    end
                end
                
            else
                obj.VisVirtCohortItemsTable.Data = cell(0,5);
                obj.VisVirtCohortItemsTable.ColumnName = {'Include','Color','Task','Group','Display'};
                obj.VisVirtCohortItemsTable.ColumnFormat = {'logical','char','char','char','char'};
                obj.VisVirtCohortItemsTable.ColumnEditable =[true,false,false,false,true];
            end
        end
        
        function redrawInvalidCheckBox(obj)
            if ~isempty(obj.CohortGeneration)
                obj.VisInvalidCheckBox.Value = obj.CohortGeneration.ShowInvalidVirtualPatients;
            else
                obj.VisInvalidCheckBox.Value = true;        
            end
        end
        
        function redrawContextMenu(obj)
            %Set Context Menus;
            obj.PlotItemsTableContextMenu = uicontextmenu(ancestor(obj.EditLayout,'figure'));
            obj.PlotItemsTableMenu = uimenu(obj.PlotItemsTableContextMenu);
            obj.PlotItemsTableMenu.Label = 'Set Color';
            obj.PlotItemsTableMenu.Tag = 'PlotItemsCM';
            obj.PlotItemsTableMenu.MenuSelectedFcn = @(h,e)onContextMenu(obj,h,e);
            obj.VisVirtCohortItemsTable.ContextMenu = obj.PlotItemsTableContextMenu;
        end
        
    end
    
end




