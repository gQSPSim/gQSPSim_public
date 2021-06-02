classdef OptimizationPane < QSPViewerNew.Application.ViewPane
    %  OptimizationPane -This is the
    %  'viewer' counterpart to the 'model' class
    %  QSP.Optimization
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
        Optimization = QSP.Optimization.empty()
        TemporaryOptimization = QSP.Optimization.empty()
        IsDirty = false
    end
    
    properties (Access=private)
        SelectedRow =0;

        OptimHeader
        
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
        SpeciesPopupTableItems = {}
        ThisProfileData = {}
        
        PlotSpeciesAsInvalidTable = cell(0,3)
        PlotItemAsInvalidTable = cell(0,4)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []  
        
        DiagnosticHandle = [];
        
        DatasetHeader = {}
        PrunedDatasetHeader = {};
        DatasetData = {};
        
        ParametersHeader = {} 
        ParametersData = {} 
        
        FixRNGSeed = false
        RNGSeed = 100
        
        ObjectiveFunctions = {'defaultObj'}
        
        StaleFlag
        ValidFlag
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        ResultsPathListener
        OptimizationTableListener
        SpeciesDataTableListener
        SpeciesInitialTableListener
        OptimizationTableAddListener 
        SpeciesDataTableAddListener 
        SpeciesInitialTableAddListener 
        OptimizationTableRemoveListener
        SpeciesDataTableRemoveListener 
        SpeciesInitialTableRemoveListener 
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OptimizationEditGrid            matlab.ui.container.GridLayout
        EditLayout                      matlab.ui.container.GridLayout
        ResultsPath                     QSPViewerNew.Widgets.FolderSelector
        InnerLayout                     matlab.ui.container.GridLayout
        AlgorithmLabel                  matlab.ui.control.Label
        AlgorithmDropDown               matlab.ui.control.DropDown
        ParametersLabel                 matlab.ui.control.Label
        ParametersDropDown              matlab.ui.control.DropDown
        DatasetLabel                    matlab.ui.control.Label
        DatasetDropDown                 matlab.ui.control.DropDown
        GroupColumnLabel                matlab.ui.control.Label
        GroupColumnDropDown             matlab.ui.control.DropDown
        IDColumnLabel                   matlab.ui.control.Label
        IDColumnDropDown                matlab.ui.control.DropDown
        FixSeedLabel                    matlab.ui.control.Label
        FixSeedCheckBox                 matlab.ui.control.CheckBox
        RNGSeedLabel                    matlab.ui.control.Label
        RNGSeedEdit                     matlab.ui.control.NumericEditField
        TableLayout                     matlab.ui.container.GridLayout
        OptimizationTable               QSPViewerNew.Widgets.AddRemoveTable
        SpeciesDataTable                QSPViewerNew.Widgets.AddRemoveTable
        SpeciesInitialTable             QSPViewerNew.Widgets.AddRemoveTable
        ParametersTableLabel            matlab.ui.control.Label
        ParametersTable                 matlab.ui.control.Table
        SeedSubLayout                   matlab.ui.container.GridLayout

        %Elements for the visualization view
        VisLayout                       matlab.ui.container.GridLayout
        VisSpeciesDataTableLabel        matlab.ui.control.Label
        VisSpeciesDataTable             matlab.ui.control.Table
        VisOptimItemsTableLabel         matlab.ui.control.Label
        VisOptimItemsTable              matlab.ui.control.Table
        PanelMain                       matlab.ui.container.Panel     
        VisInnerLayout                  matlab.ui.container.GridLayout  
        VisProfilesTableLabel           matlab.ui.control.Label
        VisProfilesTable                matlab.ui.control.Table 
        VisParametersTableLabel         matlab.ui.control.Label
        VisParametersTable              matlab.ui.control.Table
        VisAddButton                    matlab.ui.control.Button
        VisRemoveButton                 matlab.ui.control.Button
        VisCopyButton                   matlab.ui.control.Button
        VisSwapButton                   matlab.ui.control.Button
        VisPencilMatButtonm             matlab.ui.control.Button
        VisDataButton                   matlab.ui.control.Button
        VisApplyButton                  matlab.ui.control.Button

        PlotItemsTableContextMenu
        PlotItemsTableMenu
        
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = OptimizationPane(varargin)
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
            %Edit Layout
            obj.EditLayout = uigridlayout(obj.getEditGrid());
            obj.EditLayout.Layout.Row = 3;
            obj.EditLayout.Layout.Column = 1;
            obj.EditLayout.ColumnWidth = {'1x'};
            obj.EditLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight*5,'1x',obj.LabelHeight,'1x'};
            obj.EditLayout.ColumnSpacing = 0;
            obj.EditLayout.RowSpacing = 0;
            obj.EditLayout.Padding = [0 0 0 0];

            %Results Path Folder Selector
            obj.ResultsPath = QSPViewerNew.Widgets.FolderSelector(obj.EditLayout,1,1,'ResultsPath');
            
            %InnerLayout
            obj.InnerLayout = uigridlayout(obj.EditLayout());
            obj.InnerLayout.ColumnWidth = {obj.LabelLength,'1x',obj.LabelLength,'1x'};
            obj.InnerLayout.RowHeight = {obj.LabelHeight,obj.LabelHeight,obj.LabelHeight};
            obj.InnerLayout.ColumnSpacing = 0;
            obj.InnerLayout.RowSpacing = 0;
            obj.InnerLayout.Padding = [0 0 0 0];
            
            %Algorithm Label
            obj.AlgorithmLabel = uilabel(obj.InnerLayout);
            obj.AlgorithmLabel.Text = 'Algorithm';
            obj.AlgorithmLabel.Layout.Row = 1;
            obj.AlgorithmLabel.Layout.Column = 1;
            
            %Algorithm DropDown
            obj.AlgorithmDropDown = uidropdown(obj.InnerLayout);
            obj.AlgorithmDropDown.Layout.Row = 1;
            obj.AlgorithmDropDown.Layout.Column = 2;
            
            %Parameters Label
            obj.ParametersLabel = uilabel(obj.InnerLayout);
            obj.ParametersLabel.Text = 'Parameters';
            obj.ParametersLabel.Layout.Row = 2;
            obj.ParametersLabel.Layout.Column = 1;
            
            %Parameters Dropdown
            obj.ParametersDropDown = uidropdown(obj.InnerLayout);
            obj.ParametersDropDown.Layout.Row = 2;
            obj.ParametersDropDown.Layout.Column = 2;
            
            %Dataset Label
            obj.DatasetLabel = uilabel(obj.InnerLayout);
            obj.DatasetLabel.Text = 'Dataset';
            obj.DatasetLabel.Layout.Row = 3;
            obj.DatasetLabel.Layout.Column = 1;
            
            %Dataset Dropdown
            obj.DatasetDropDown = uidropdown(obj.InnerLayout);
            obj.DatasetDropDown.Layout.Row = 3;
            obj.DatasetDropDown.Layout.Column = 2;
            
            %Group Column Label
            obj.GroupColumnLabel = uilabel(obj.InnerLayout);
            obj.GroupColumnLabel.Text = 'Group Column';
            obj.GroupColumnLabel.Layout.Row = 1;
            obj.GroupColumnLabel.Layout.Column = 3;
            
            %Group Column Dropdown
            obj.GroupColumnDropDown = uidropdown(obj.InnerLayout);
            obj.GroupColumnDropDown.Layout.Row = 1;
            obj.GroupColumnDropDown.Layout.Column = 4;
            
            %ID Column Label
            obj.IDColumnLabel = uilabel(obj.InnerLayout);
            obj.IDColumnLabel.Text = 'ID Column';
            obj.IDColumnLabel.Layout.Row = 2;
            obj.IDColumnLabel.Layout.Column = 3;
            
            %ID Column Dropdown
            obj.IDColumnDropDown = uidropdown(obj.InnerLayout);
            obj.IDColumnDropDown.Layout.Row = 2;
            obj.IDColumnDropDown.Layout.Column = 4;
            
            %SeedSubLayout
            obj.SeedSubLayout = uigridlayout(obj.InnerLayout());
            obj.SeedSubLayout.ColumnWidth = {'1x',obj.LabelLength,'1x'};
            obj.SeedSubLayout.RowHeight = {'1x'};
            obj.SeedSubLayout.ColumnSpacing = 0;
            obj.SeedSubLayout.RowSpacing = 0;
            obj.SeedSubLayout.Padding = [0 0 0 0];
            obj.SeedSubLayout.Layout.Row = 3;
            obj.SeedSubLayout.Layout.Column = [3,4];
            
            %FixSeed CheckBox
            obj.FixSeedCheckBox = uicheckbox(obj.SeedSubLayout);
            obj.FixSeedCheckBox.Text = "Fix seed for random number generation";
            obj.FixSeedCheckBox.Layout.Row = 1;
            obj.FixSeedCheckBox.Layout.Column = 1;
            
            % RNG Seed Label
            obj.RNGSeedLabel = uilabel(obj.SeedSubLayout);
            obj.RNGSeedLabel.Text = 'RNG Seed';
            obj.RNGSeedLabel.Layout.Row = 1;
            obj.RNGSeedLabel.Layout.Column = 2;
            
            %RNG Seed Edit
            obj.RNGSeedEdit = uieditfield(obj.SeedSubLayout,'numeric');
            obj.RNGSeedEdit.Layout.Row = 1;
            obj.RNGSeedEdit.Layout.Column = 3;
            obj.RNGSeedEdit.Limits = [0,Inf];
            obj.RNGSeedEdit.RoundFractionalValues = true;
            
            %Table Layout
            obj.TableLayout = uigridlayout(obj.EditLayout());
            obj.TableLayout.ColumnWidth = {'1x','1x','1x'};
            obj.TableLayout.RowHeight = {'1x'};
            obj.TableLayout.ColumnSpacing = 0;
            obj.TableLayout.RowSpacing = 0;
            obj.TableLayout.Padding = [0 0 0 0];
            
            %OptimizationItem Table
            obj.OptimizationTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,1,"Optimization Items");
            
            %SpeciesDataMapping
            obj.SpeciesDataTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,2,"Species-Data Mapping");
            
            %Species initial conditions 
            obj.SpeciesInitialTable = QSPViewerNew.Widgets.AddRemoveTable(obj.TableLayout,1,3,"Species Initial Conditions");
            
            %ParametersTable Label
            obj.ParametersLabel = uilabel(obj.EditLayout);
            obj.ParametersLabel.Text = 'Parameters';
            obj.ParametersLabel.Layout.Row = 4;
            obj.ParametersLabel.Layout.Column = 1;
            
            %Parameters table(No interaction, just for user to look at)
            obj.ParametersTable = uitable(obj.EditLayout, 'ColumnSortable', true);
            obj.ParametersTable.Layout.Row = 5;
            obj.ParametersTable.Layout.Column = 1;
            obj.ParametersTable.ColumnEditable = false;
            
            %Elements for the visualization view
            obj.VisLayout = uigridlayout(obj.getVisualizationGrid());
            obj.VisLayout.Layout.Row = 2;
            obj.VisLayout.Layout.Column = 1;
            obj.VisLayout.ColumnWidth = {'1x'};
            obj.VisLayout.RowHeight = {obj.LabelHeight,'1x',obj.LabelHeight,'1x','2x'};
            obj.VisLayout.ColumnSpacing = 0;
            obj.VisLayout.RowSpacing = 0;
            obj.VisLayout.Padding = [0 0 0 0];
            
            obj.VisSpeciesDataTableLabel = uilabel(obj.VisLayout);
            obj.VisSpeciesDataTableLabel.Text = 'Species-Data';
            obj.VisSpeciesDataTableLabel.Layout.Row = 1;
            obj.VisSpeciesDataTableLabel.Layout.Column = 1;
            
            obj.VisSpeciesDataTable = uitable(obj.VisLayout, 'ColumnSortable', true);
            obj.VisSpeciesDataTable.Layout.Row = 2;
            obj.VisSpeciesDataTable.Layout.Column = 1;
            obj.VisSpeciesDataTable.ColumnEditable = false;
            obj.VisSpeciesDataTable.CellEditCallback = @obj.onEditVisSpeciesTable;
            
            obj.VisOptimItemsTableLabel = uilabel(obj.VisLayout);
            obj.VisOptimItemsTableLabel.Text = 'Optimization Items';
            obj.VisOptimItemsTableLabel.Layout.Row = 3;
            obj.VisOptimItemsTableLabel.Layout.Column = 1;
            
            obj.VisOptimItemsTable = uitable(obj.VisLayout, 'ColumnSortable', true);
            obj.VisOptimItemsTable.Layout.Row = 4;
            obj.VisOptimItemsTable.Layout.Column = 1;
            obj.VisOptimItemsTable.ColumnEditable = false;
            obj.VisOptimItemsTable.CellEditCallback = @obj.onEditPlotItemsTable;
            obj.VisOptimItemsTable.CellSelectionCallback = @obj.onSelectionPlotItemsTable;
          
            obj.PanelMain = uipanel('Parent',obj.VisLayout);
            obj.PanelMain.Title = '';
            obj.PanelMain.Layout.Row = 5;
            obj.PanelMain.Layout.Column = 1;
            
            obj.VisInnerLayout = uigridlayout(obj.PanelMain);
            obj.VisInnerLayout.ColumnWidth = {obj.ButtonWidth,'1x'};
            obj.VisInnerLayout.RowHeight = {obj.LabelHeight,obj.ButtonHeight,obj.ButtonHeight,obj.ButtonHeight,'1x',obj.LabelHeight,obj.ButtonHeight,obj.ButtonHeight,obj.ButtonHeight,'1x',obj.ButtonHeight};
            obj.VisInnerLayout.ColumnSpacing = 0;
            obj.VisInnerLayout.RowSpacing = 0;
            obj.VisInnerLayout.Padding = [0 0 0 0];

            obj.VisProfilesTableLabel = uilabel(obj.VisInnerLayout);
            obj.VisProfilesTableLabel.Text = 'Run Profiles';
            obj.VisProfilesTableLabel.Layout.Row = 1;
            obj.VisProfilesTableLabel.Layout.Column = [1,2];
            
            obj.VisProfilesTable = uitable(obj.VisInnerLayout, 'ColumnSortable', true);
            obj.VisProfilesTable.Layout.Row = [2,5];
            obj.VisProfilesTable.Layout.Column = 2;
            obj.VisProfilesTable.ColumnEditable = false;
            obj.VisProfilesTable.CellEditCallback = @obj.onEditProfileTable;
            obj.VisProfilesTable.CellSelectionCallback = @obj.onSelectionProfileTable;
            
            obj.VisParametersTableLabel = uilabel(obj.VisInnerLayout);
            obj.VisParametersTableLabel.Text = 'Parameters(Run=2)';
            obj.VisParametersTableLabel.Layout.Row = 6;
            obj.VisParametersTableLabel.Layout.Column = [1,2];
            
            obj.VisParametersTable = uitable(obj.VisInnerLayout, 'ColumnSortable', true);
            obj.VisParametersTable.Layout.Row = [7,10];
            obj.VisParametersTable.Layout.Column = 2;
            obj.VisParametersTable.ColumnEditable = false;
            obj.VisParametersTable.CellEditCallback = @obj.onEditParametersTable;
            
            obj.VisAddButton = uibutton(obj.VisInnerLayout,'push');
            obj.VisAddButton.Layout.Row = 2;
            obj.VisAddButton.Layout.Column = 1;
            obj.VisAddButton.Icon = QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.VisAddButton.Text = '';
            obj.VisAddButton.Tooltip = 'Add new row';
            obj.VisAddButton.ButtonPushedFcn = @obj.onVisAddButton;

            obj.VisRemoveButton = uibutton(obj.VisInnerLayout,'push');
            obj.VisRemoveButton.Layout.Row = 3;
            obj.VisRemoveButton.Layout.Column = 1;
            obj.VisRemoveButton.Icon = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.VisRemoveButton.Text = '';
            obj.VisRemoveButton.Tooltip = 'Delete the highlighted row';
            obj.VisRemoveButton.ButtonPushedFcn = @obj.onVisRemoveButton;

            obj.VisCopyButton = uibutton(obj.VisInnerLayout,'push');
            obj.VisCopyButton.Layout.Row = 4;
            obj.VisCopyButton.Layout.Column = 1;
            obj.VisCopyButton.Icon = QSPViewerNew.Resources.LoadResourcePath('copy_24.png');
            obj.VisCopyButton.Text = '';
            obj.VisCopyButton.Tooltip = 'Duplicate the highlighted row';
            obj.VisCopyButton.ButtonPushedFcn = @obj.onVisCopyButton;

            obj.VisSwapButton = uibutton(obj.VisInnerLayout,'push');
            obj.VisSwapButton.Layout.Row = 7;
            obj.VisSwapButton.Layout.Column = 1;
            obj.VisSwapButton.Icon = QSPViewerNew.Resources.LoadResourcePath('reset_24.png');
            obj.VisSwapButton.Text = '';
            obj.VisSwapButton.Tooltip = 'Reset to original values';
            obj.VisSwapButton.ButtonPushedFcn = @obj.onVisSwapButton;

            obj.VisPencilMatButtonm = uibutton(obj.VisInnerLayout,'push');
            obj.VisPencilMatButtonm.Layout.Row = 8;
            obj.VisPencilMatButtonm.Layout.Column = 1;
            obj.VisPencilMatButtonm.Icon = QSPViewerNew.Resources.LoadResourcePath('param_edit_24.png');
            obj.VisPencilMatButtonm.Text = '';
            obj.VisPencilMatButtonm.Tooltip = 'Save as Parameters set';
            obj.VisPencilMatButtonm.ButtonPushedFcn = @obj.onVisPencilMatButton;

            obj.VisDataButton = uibutton(obj.VisInnerLayout,'push');
            obj.VisDataButton.Layout.Row = 9;
            obj.VisDataButton.Layout.Column = 1;
            obj.VisDataButton.Icon = QSPViewerNew.Resources.LoadResourcePath('datatable_24.png');
            obj.VisDataButton.Text = '';
            obj.VisDataButton.Tooltip = 'Save as Vpop';
            obj.VisDataButton.ButtonPushedFcn = @obj.onVisDataButton;
            
            obj.VisApplyButton = uibutton(obj.VisInnerLayout,'push');
            obj.VisApplyButton.Layout.Row = 11;
            obj.VisApplyButton.Layout.Column = 2;
            obj.VisApplyButton.Text = 'Apply';
            obj.VisApplyButton.ButtonPushedFcn = @obj.onVisApplyButton;
            
        end
        
        function createListenersAndCallbacks(obj)
        %Listeners
        obj.ResultsPathListener = addlistener(obj.ResultsPath,'StateChanged',@(src,event) obj.onEditResultsPath(event.Source.RelativePath));
        
        obj.OptimizationTableListener = addlistener(obj.OptimizationTable,'EditValueChange',@(src,event) obj.onEditOptimItems());
        obj.SpeciesDataTableListener = addlistener(obj.SpeciesDataTable,'EditValueChange',@(src,event) obj.onEditSpecies());
        obj.SpeciesInitialTableListener = addlistener(obj.SpeciesInitialTable,'EditValueChange',@(src,event) obj.onEditInitialConditions());
        
        obj.OptimizationTableAddListener = addlistener(obj.OptimizationTable,'NewRowChange',@(src,event) obj.onNewOptimItems());
        obj.SpeciesDataTableAddListener = addlistener(obj.SpeciesDataTable,'NewRowChange',@(src,event) obj.onNewSpecies());
        obj.SpeciesInitialTableAddListener = addlistener(obj.SpeciesInitialTable,'NewRowChange',@(src,event) obj.onNewInitialConditions());
        
        obj.OptimizationTableRemoveListener = addlistener(obj.OptimizationTable,'DeleteRowChange',@(src,event) obj.onRemoveOptimItems());
        obj.SpeciesDataTableRemoveListener = addlistener(obj.SpeciesDataTable,'DeleteRowChange',@(src,event) obj.onRemoveSpecies());
        obj.SpeciesInitialTableRemoveListener = addlistener(obj.SpeciesInitialTable,'DeleteRowChange',@(src,event) obj.onRemoveInitialConditions());
        
        %Callbacks
        obj.AlgorithmDropDown.ValueChangedFcn = @(h,e) obj.onEditAlgorithm(e.Value);
        obj.ParametersDropDown.ValueChangedFcn = @(h,e) obj.onEditParametersEdit(e.Value);
        obj.DatasetDropDown.ValueChangedFcn  =  @(h,e) obj.onEditDataset(e.Value);
        obj.GroupColumnDropDown.ValueChangedFcn = @(h,e) obj.onEditGroupColumn(e.Value);
        obj.IDColumnDropDown.ValueChangedFcn = @(h,e) obj.onEditIDColumn(e.Value);
        obj.FixSeedCheckBox.ValueChangedFcn = @(h,e) obj.onEditRNGCheck(e.Value);
        obj.RNGSeedEdit.ValueChangedFcn = @(h,e) obj.onEditRNGSeed(e.Value);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %Methods to redraw each of the components
    %Not all the fields are independent
    %Here is the relationship
    %Edited -> Impacts(Must redraw)
    %Group Column -> Optim Items
    %Dataset -> all 3 tables
    %Check box -> RNG edit box 
    methods (Access = private)
        
        function onEditResultsPath(obj,newValue)
            obj.TemporaryOptimization.OptimResultsFolderName = newValue;
            obj.IsDirty = true;
        end
        
        function onEditAlgorithm(obj,newValue)
            obj.TemporaryOptimization.AlgorithmName = newValue;
            obj.IsDirty = true;
        end
        
        function onEditParametersEdit(obj,newValue)
            obj.TemporaryOptimization.RefParamName = newValue;
           
            % Try importing to load data for Parameters view
            MatchIdx = strcmp({obj.TemporaryOptimization.Settings.Parameters.Name},obj.TemporaryOptimization.RefParamName);
            if any(MatchIdx)
                pObj = obj.TemporaryOptimization.Settings.Parameters(MatchIdx);
                [StatusOk,Message,obj.ParametersHeader,obj.ParametersData] = importData(pObj,pObj.FilePath);
                if ~StatusOk
                     uialert(obj.getUIFigure,Message,'Parameter Import Failed');
                else
                    %In the old implementation, they edit the main copy
                    %instead of the temporary. Need to see why
                    obj.TemporaryOptimization.clearData();
                end
            end
            
            %Update impact components
            obj.redrawParametersTable();
            obj.IsDirty = true;
        end
        
        function onEditDataset(obj,newValue)
            obj.TemporaryOptimization.DatasetName = newValue;
            
            %redraw impacted components (All 3 tables)
            obj.redrawGroupColumn();
            obj.redrawIDColumn();
            obj.redrawOptimItems();
            obj.redrawSpecies();
            obj.redrawInitialConditions();
            obj.IsDirty = true;
        end
        
        function onEditGroupColumn(obj,newValue)
            obj.TemporaryOptimization.GroupName = newValue;
            
            %redraw impacted components
            obj.redrawOptimItems();
            obj.IsDirty = true;
        end
        
        function onEditIDColumn(obj,newValue)
            obj.TemporaryOptimization.IDName = newValue;
            obj.IsDirty = true;
        end
        
        function onEditRNGCheck(obj,newValue)
            obj.TemporaryOptimization.FixRNGSeed = newValue;
            obj.redrawRNGSeed();
            obj.IsDirty = true;
        end
        
        function onEditRNGSeed(obj,newValue)
            obj.TemporaryOptimization.RNGSeed = newValue;      
            obj.IsDirty = true;
        end
        
        function onEditOptimItems(obj)
            [Row,Column,Value] = obj.OptimizationTable.lastChangedElement();
            
            if Column == 1
                obj.TemporaryOptimization.Item(Row).TaskName = Value;    
            elseif Column == 2
                obj.TemporaryOptimization.Item(Row).GroupID = Value;
            end
            obj.IsDirty = true;
        end
        
        function onEditSpecies(obj)
            [Row,Column,Value] = obj.SpeciesDataTable.lastChangedElement();
            if Column == 1
                obj.TemporaryOptimization.SpeciesData(Row).DataName = Value;
            elseif Column == 2
                obj.TemporaryOptimization.SpeciesData(Row).SpeciesName = Value;       
            elseif Column == 4
                obj.TemporaryOptimization.SpeciesData(Row).FunctionExpression = Value;
            elseif Column == 5
                obj.TemporaryOptimization.SpeciesData(Row).ObjectiveName = Value;
            end
            obj.IsDirty = true;
        end
        
        function onEditInitialConditions(obj)
            [Row,Column,Value] = obj.SpeciesInitialTable.lastChangedElement();
            if Column == 1
                obj.TemporaryOptimization.SpeciesIC(Row).SpeciesName = Value;
            elseif Column == 2
                obj.TemporaryOptimization.SpeciesIC(Row).DataName = Value;
            elseif Column == 3
                obj.TemporaryOptimization.SpeciesIC(Row).FunctionExpression = Value;
            end
            obj.IsDirty = true;
        end
        
        function onNewOptimItems(obj)
            if ~isempty(obj.TaskPopupTableItems) && ~isempty(obj.GroupIDPopupTableItems)
                NewTaskGroup = QSP.TaskGroup;
                NewTaskGroup.TaskName = obj.TaskPopupTableItems{1};
                NewTaskGroup.GroupID = obj.GroupIDPopupTableItems{1};
                obj.TemporaryOptimization.Item(end+1) = NewTaskGroup;
                obj.redrawOptimItems();
                obj.redrawSpecies();
                obj.redrawInitialConditions();
            else
                uialert(obj.getUIFigure,'At least one task and the group column must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.IsDirty = true;
        end
        
        function onNewSpecies(obj)
            if ~isempty(obj.SpeciesPopupTableItems) && ~isempty(obj.PrunedDatasetHeader)
                NewSpeciesData = QSP.SpeciesData;
                NewSpeciesData.SpeciesName = obj.SpeciesPopupTableItems{1};
                NewSpeciesData.DataName = obj.PrunedDatasetHeader{1};
                DefaultExpression = 'x';
                NewSpeciesData.FunctionExpression = DefaultExpression;
                obj.TemporaryOptimization.SpeciesData(end+1) = NewSpeciesData;
                obj.redrawSpecies()
            else
                uialert(obj.getUIFigure,'At least one task with active species and a non-empty datset must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.IsDirty = true;
        end
        
        function onNewInitialConditions(obj)
            if ~isempty(obj.SpeciesPopupTableItems) && ~isempty(obj.PrunedDatasetHeader)
                NewSpeciesIC = QSP.SpeciesData;
                NewSpeciesIC.SpeciesName = obj.SpeciesPopupTableItems{1};
                NewSpeciesIC.DataName = obj.PrunedDatasetHeader{1};
                DefaultExpression = 'x';
                NewSpeciesIC.FunctionExpression = DefaultExpression;
                obj.TemporaryOptimization.SpeciesIC(end+1) = NewSpeciesIC;
                obj.redrawInitialConditions();
            else
                uialert(obj.getUIFigure,'At least one task with active species and a non-empty datset must be defined in order to add an optimization item.','Cannot Add');
            end
            obj.IsDirty = true;
        end
        
        function onRemoveOptimItems(obj)
            Index = obj.OptimizationTable.getSelectedRow();
            if ~isempty(Index)
                obj.TemporaryOptimization.Item(Index) = [];
                obj.redrawOptimItems();
                obj.redrawSpecies();
                obj.redrawInitialConditions();
            end
            obj.IsDirty = true;
        end
        
        function onRemoveSpecies(obj)
            Index = obj.SpeciesDataTable.getSelectedRow();
            if ~isempty(Index)
                obj.TemporaryOptimization.SpeciesData(Index) = [];
                obj.redrawSpecies();
            end
            obj.IsDirty = true;
        end
        
        function onRemoveInitialConditions(obj)
            Index = obj.SpeciesInitialTable.getSelectedRow();
            if ~isempty(Index)
                obj.TemporaryOptimization.SpeciesIC(Index) = [];
                obj.redrawInitialConditions();
            end
            obj.IsDirty = true;
        end
        
        %Callbacks for the Visualization View
        
        function onEditVisSpeciesTable(obj,h,e)
            
            RowIdx = e.Indices(1);
            ColIdx = e.Indices(2);
            
            newAxIdx = str2double(h.Data{RowIdx,1});
            if isnan(newAxIdx)
                newAxIdx = [];
            end
            
            switch ColIdx
                case 1
                    %The axis was changed
                    
                    if any(strcmp(h.ColumnFormat{ColIdx},e.NewData))
                        %The new value was already in the dropdown, so we can
                        %continue
                        
                        newAxisIndex = str2double(e.NewData);
                        oldAxisIndex = find(~cellfun(@isempty,obj.SpeciesGroup(RowIdx,:)),1,'first');
                        obj.Optimization.PlotSpeciesTable(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                        
                        % If originally not plotted
                        if isempty(oldAxisIndex) && ~isempty(newAxisIndex)
                            obj.SpeciesGroup(RowIdx,newAxisIndex,:) = obj.SpeciesGroup(RowIdx,1,:);
                            obj.DatasetGroup(RowIdx,newAxisIndex) = obj.DatasetGroup(RowIdx,1);
                            % Parent
                            set([obj.SpeciesGroup{RowIdx,newAxisIndex,:}],'Parent',obj.PlotArray(newAxisIndex));
                            set([obj.DatasetGroup{RowIdx,newAxisIndex}],'Parent',obj.PlotArray(newAxisIndex));
                        elseif ~isempty(oldAxisIndex) && isempty(newAxisIndex)
                            obj.SpeciesGroup(RowIdx,1,:) = obj.SpeciesGroup(RowIdx,oldAxisIndex,:);
                            obj.DatasetGroup(RowIdx,1) = obj.DatasetGroup(RowIdx,oldAxisIndex);
                            % Un-parent
                            set([obj.SpeciesGroup{RowIdx,1,:}],'Parent',matlab.graphics.GraphicsPlaceholder.empty());
                            set([obj.DatasetGroup{RowIdx,1}],'Parent',matlab.graphics.GraphicsPlaceholder.empty());
                            if oldAxisIndex ~= 1
                                ThisSize = size(obj.SpeciesGroup(RowIdx,oldAxisIndex,:));
                                obj.SpeciesGroup(RowIdx,oldAxisIndex,:) = cell(ThisSize);
                                obj.DatasetGroup{RowIdx,oldAxisIndex} = [];
                            end
                        elseif ~isempty(oldAxisIndex) && ~isempty(newAxisIndex)
                            obj.SpeciesGroup(RowIdx,newAxisIndex,:) = obj.SpeciesGroup(RowIdx,oldAxisIndex,:);
                            obj.DatasetGroup(RowIdx,newAxisIndex) = obj.DatasetGroup(RowIdx,oldAxisIndex);
                            % Re-parent
                            set([obj.SpeciesGroup{RowIdx,newAxisIndex,:}],'Parent',obj.PlotArray(newAxisIndex));
                            set([obj.DatasetGroup{RowIdx,newAxisIndex}],'Parent',obj.PlotArray(newAxisIndex));
                            if oldAxisIndex ~= newAxisIndex
                                ThisSize = size(obj.SpeciesGroup(RowIdx,oldAxisIndex,:));
                                obj.SpeciesGroup(RowIdx,oldAxisIndex,:) = cell(ThisSize);
                                obj.DatasetGroup{RowIdx,oldAxisIndex} = [];
                            end
                        end
                        
                        AxIndices = [oldAxisIndex,newAxisIndex];
                        AxIndices(isnan(AxIndices)) = [];
                        % Redraw legend
                        [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                            obj.Optimization,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                            'AxIndices',AxIndices);
                        obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                        obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                        obj.updateLines();
                        obj.updateLegends();
                        
                    else
                        h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                    end
                    
                case 2
                    %the Line style was changed
                    
                    if any(strcmp(h.ColumnFormat{ColIdx},e.NewData))
                        %The new value was already in the dropdown, so we can
                        %continue
                        
                        obj.Optimization.PlotSpeciesTable(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                        NewLineStyle = h.Data{RowIdx,2};
                        setSpeciesLineStyles(obj.Optimization,RowIdx,NewLineStyle);
                        
                        for RowIdx = 1:size(obj.Optimization.PlotSpeciesTable,1)
                            axIdx = str2double(obj.Optimization.PlotSpeciesTable{RowIdx,1});
                            if ~isnan(axIdx)
                                Ch = get(obj.SpeciesGroup{RowIdx,axIdx},'Children');
                                HasLineStyle = isprop(Ch,'LineStyle');
                                set(Ch(HasLineStyle),'LineStyle',obj.Optimization.PlotSpeciesTable{RowIdx,2});
                            end
                        end
                        AxIndices = newAxIdx;
                        if isempty(AxIndices)
                            AxIndices = 1:numel(obj.PlotArray);
                        end
                        % Redraw legend
                        [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                            obj.Optimization,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                            'AxIndices',AxIndices);
                        obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                        obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                        
                    else
                        h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                    end
                    
                    
                case 5
                    %the display name was changed
                    obj.Optimization.PlotSpeciesTable(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                    
                    AxIndices = newAxIdx;
                    if isempty(AxIndices)
                        AxIndices = 1:numel(obj.PlotArray);
                    end
                    % Redraw legend
                    [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                        obj.Optimization,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                        'AxIndices',AxIndices);
                    obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                    obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
            end
            
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end
        
        function onEditPlotItemsTable(obj,h,e)
            rowIdx = e.Indices(1);
            colIdx = e.Indices(2);
            
            obj.Optimization.PlotItemTable(rowIdx,colIdx) = h.Data(rowIdx,colIdx);
            
            switch colIdx
                case 5
                    [obj.AxesLegend,obj.AxesLegendChildren] = obj.Optimization.updatePlots(obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup);
                case 1
                    obj.Optimization.updatePlots(obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                        'RedrawLegend',false);
            end
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end
        
        function onSelectionPlotItemsTable(obj,~,e)
            obj.SelectedRow = e.Indices(1);
            
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end
        
        function onEditProfileTable(obj,h,e)
            
                set(obj.getUIFigure,'pointer','watch');
                RowIdx = e.Indices(1);
                ColIdx = e.Indices(2); 

                if ~isempty(RowIdx)
                    ThisProfile = obj.Optimization.PlotProfile(RowIdx);
                    switch ColIdx
                        case 2
                            % Show
                            ThisProfile.Show = h.Data{RowIdx,ColIdx};
                            
                            % Update the view
                            obj.refreshVisualization();
                            
                            % Don't overwrite the output
                            obj.Optimization.updatePlots(obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                                'RedrawLegend',false);
                        case 3
                            % Source
                            % Re-import the source values for
                            % ThisProfile.Source (before changing)
                            
                            if any(strcmp(h.ColumnFormat{ColIdx},e.NewData))
                                ThisSourceData = {};
                                if ~isempty(ThisProfile.Source) && ~any(strcmpi(ThisProfile.Source,{'','N/A'}))
                                    [~,~,ThisSourceData] = importParametersSource(obj.Optimization,ThisProfile.Source);
                                end
                                
                                % Get the name of the new source
                                NewSource = h.Data{RowIdx,ColIdx};
                                
                                % First check if values have been changed. If so,
                                % then alert the user
                                if ~isempty(ThisSourceData)
                                    Result = 'Yes';
                                    [~,ix1] = sort(ThisProfile.Values(:,1));
                                    [~,ix2] = sort(ThisSourceData(:,1));
                                    
                                    if ~isequal(ThisProfile.Values(ix1,2), ThisSourceData(ix2,2)) && ...
                                            ~any(strcmpi(ThisProfile.Source,{'','N/A'})) && ~any(strcmpi(NewSource,{'','N/A'}))
                                        
                                        % Has the source changed?
                                        if ~strcmpi(ThisProfile.Source,NewSource)
                                            % Confirm with user
                                            Prompt = 'ChangUIFing the source will clear overriden source parameters. Do you want to continue?';
                                        else
                                            % Source did not change but reset the parameter values
                                            Prompt = 'This action will clear overriden source parameters. Do you want to continue? Press Cancel to save.';
                                        end
                                        Result = uiconfirm(obj.getUIFigure,Prompt,'Continue?','Option',{'Yes','Cancel'},'DefaultOption','Cancel');
                                    end
                                    
                                end
                                % Set the source and values
                                if isempty(NewSource) || any(strcmpi(NewSource,{'','N/A'}))
                                    ThisProfile.Source = '';
                                    ThisProfile.Values = cell(0,2);
                                elseif isempty(ThisSourceData) || strcmpi(Result,'Yes')
                                    tempObj = obj.Optimization;
                                    Names = {tempObj.Settings.Parameters.Name};
                                    MatchIdx = strcmpi(Names,tempObj.RefParamName);
                                    if any(MatchIdx)
                                        pObj = tempObj.Settings.Parameters(MatchIdx);
                                        importData(pObj,pObj.FilePath);
                                    else
                                        warning('Could not find match for specified parameter file')
                                    end
                                    
                                    
                                    % Get NewSource Data
                                    NewSourceData = {};
                                    if ~isempty(NewSource) && ~any(strcmpi(NewSource,{'','N/A'}))
                                        [StatusOk,Message,NewSourceData] = importParametersSource(obj.Optimization,NewSource);
                                        if ~StatusOk
                                            uialert(obj.getUIFigure,Message,'Cannot import');
                                        end
                                    end
                                    
                                    ThisProfile.Source = NewSource;
                                    [~,index] = sort(upper(NewSourceData(:,1)));
                                    ThisProfile.Values = NewSourceData(index,:);
                                end
                                
                                % Update the view
                                obj.refreshVisualization(obj);
                            end
                            
                        case 4
                            % Description
                            ThisProfile.Description = h.Data{RowIdx,ColIdx};
                            
                            % Update the view
                            obj.refreshVisualization();
                    end %switch
                end %if
                
                obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
                set(obj.getUIFigure,'pointer','arrow');

        end
        
        function onSelectionProfileTable(obj,~,e)     
            obj.Optimization.SelectedProfileRow = e.Indices(1);
            obj.redrawVisProfileTable();
            obj.redrawVisParametersTable();
            obj.redrawProfileButtonGroup();
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation 
            
        end
       
        function onVisAddButton(obj,~,~)
                obj.Optimization.PlotProfile(end+1) = QSP.Profile;
                obj.Optimization.SelectedProfileRow = numel(obj.Optimization.PlotProfile);

                obj.redrawVisEverything();
                obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation 
        end
        
        function onVisRemoveButton(obj,~,~)

            if ~isempty(obj.Optimization.SelectedProfileRow)
                if numel(obj.Optimization.PlotProfile) > 1
                    obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow) = [];
                else
                    obj.Optimization.PlotProfile = QSP.Profile.empty(0,1);
                end
                if size(obj.SpeciesGroup,3) >=obj.Optimization.SelectedProfileRow
                    delete([obj.SpeciesGroup{:,:,obj.Optimization.SelectedProfileRow}]); % remove objects
                    obj.SpeciesGroup(:,:,obj.Optimization.SelectedProfileRow) = []; % remove group
                end
                
                obj.Optimization.SelectedProfileRow = [];
                % Update the view
                obj.redrawVisEverything();
                obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
            end
        end
        
        function onVisCopyButton(obj,~,~)
            if ~isempty(obj.Optimization.SelectedProfileRow)
                obj.Optimization.PlotProfile(end+1) = QSP.Profile;
                obj.Optimization.PlotProfile(end).Source = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow).Source;
                obj.Optimization.PlotProfile(end).Description = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow).Description;
                obj.Optimization.PlotProfile(end).Show = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow).Show;
                obj.Optimization.PlotProfile(end).Values = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow).Values;
                obj.Optimization.SelectedProfileRow = numel(obj.Optimization.PlotProfile);
                % Update the view
                obj.redrawVisProfileTable();
                obj.redrawVisParametersTable();
                obj.redrawProfileButtonGroup();
                obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
            end
        end
        
        function onEditParametersTable(obj,h,e)
            set(obj.getUIFigure,'pointer','watch');
            obj.VisApplyButton.Enable = 'off';
            RowIdx = e.Indices(1);
            ColIdx = e.Indices(2);
            
            if ~isempty(obj.Optimization.SelectedProfileRow) && ~isempty(h.Data{RowIdx,ColIdx})
                ThisProfile = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow);
                if ischar(h.Data{RowIdx,ColIdx})
                    ThisProfile.Values(RowIdx,ColIdx) = {str2double(h.Data{RowIdx,ColIdx})};
                else
                    ThisProfile.Values(RowIdx,ColIdx) = h.Data(RowIdx,ColIdx);
                end
                
            else
                uierror(obj.getUIFigure,'Invalid value specified for parameter. Values must be numeric','Invalid value');
            end
            % Update the view
            obj.redrawVisEverything();
            
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
            set(obj.getUIFigure,'pointer','arrow');
            obj.VisApplyButton.Enable = 'on';
        end
            
        function onVisSwapButton(obj,~,~)
            set(obj.getUIFigure,'pointer','watch');
           
            ThisProfile = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow);
            
            Prompt = 'This action will clear overriden source parameters. Do you want to continue? Press Cancel to save.';
            Result = uiconfirm(obj.getUIFigure,Prompt,'Continue?','Option',{'Yes','Cancel'},'DefaultOption','Cancel');
            
            if strcmpi(Result,'Yes')
                Names = {obj.Optimization.Settings.Parameters.Name};
                MatchIdx = strcmpi(Names,obj.Optimization.RefParamName);
                if any(MatchIdx)
                    pObj = obj.Optimization.Settings.Parameters(MatchIdx);
                    importData(pObj,pObj.FilePath);
                else
                    warning('Could not find match for specified parameter file')
                end

                ThisSourceData = {};
                if ~isempty(ThisProfile.Source) && ~any(strcmpi(ThisProfile.Source,{'','N/A'}))
                    [~,~,ThisSourceData] = importParametersSource(obj.Optimization,ThisProfile.Source);
                end  
                [~,index] = sort(upper(ThisSourceData(:,1)));
                ThisProfile.Values = ThisSourceData(index,:);
           end
           % Update the view
           obj.redrawVisEverything();

           set(obj.getUIFigure,'pointer','arrow');
           obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end
        
        function onVisPencilMatButton(obj,~,~)
            Question = 'Save Parameter set as?';
            DefaultAnswer = sprintf('%s - %s', obj.Optimization.RefParamName,datestr(now,'dd-mmm-yyyy_HH-MM-SS'));
            Answer = obj.dialogPopupHelper(Question,DefaultAnswer);
            
            if ~isempty(Answer)
                AllParameters = obj.Optimization.Settings.Parameters;
                AllParameterNames = get(AllParameters,'Name');
                AllParameterFilePaths = get(AllParameters,'FilePath');
                
                % Append the source with the postfix appender
                ThisParameterName = matlab.lang.makeValidName(strtrim(Answer));
                
                % get the parameter that was used to run this
                % optimization
                pObj = obj.Optimization.Settings.getParametersWithName(obj.Optimization.RefParamName);

                ThisFilePath = fullfile(fileparts(pObj.FilePath), [ThisParameterName '.xlsx']);
                
                if isempty(ThisParameterName) || any(strcmpi(ThisParameterName,AllParameterNames)) || ...
                        any(strcmpi(ThisFilePath,AllParameterFilePaths))
                    Message = 'Please provide a valid, unique virtual population name.';
                    Title = 'Invalid name';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                else
                    
                    % Create a new parameter set 
                    parameterObj = QSP.Parameters;
                    parameterObj.Session = obj.Optimization.Session;
                    parameterObj.Name = ThisParameterName;                    
                    parameterObj.FilePath = ThisFilePath;                 
                    
                    ThisProfile = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow);
                    
                    Values = ThisProfile.Values(~cellfun(@isempty, ThisProfile.Values(:,2)), :)'; % Take first 2 rows and transpose
                    
                    
                    [StatusOk,~,Header,Data] = importData(pObj, pObj.FilePath);
                    if StatusOk
                        idP0 = strcmpi(Header,'P0_1');
                        idName = strcmpi(Header,'Name');
                        [~,ix] = ismember(Data(:,idName), Values(1,:));
                        Data(:,idP0) = Values(2,ix); 
                        writecell([Header; Data],parameterObj.FilePath);
                    end
                    
                    % Update last saved time
                    updateLastSavedTime(parameterObj);
                    
                    % Validate
                    validate(parameterObj,false);
                    
                    obj.notifyOfChange(parameterObj);
                end
            end
        end
        
        function onVisDataButton(obj,~,~)
            DefaultAnswer = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
            Answer = obj.dialogPopupHelper('Save Virtual Population as?',DefaultAnswer);
            
            if ~isempty(Answer)
                AllVPops = obj.Optimization.Settings.VirtualPopulation;
                AllVPopNames = get(AllVPops,'Name');
                AllVPopFilePaths = get(AllVPops,'FilePath');
                
                % Append the source with the postfix appender
                ThisProfile = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow);
                if iscell(Answer)
                    Answer = Answer{1};
                end
                
                ThisVPopName = matlab.lang.makeValidName(strtrim(Answer));
                ThisVPopName = sprintf('%s - %s',ThisProfile.Source,ThisVPopName);
                
                ThisFilePath = fullfile(obj.Optimization.Session.RootDirectory, obj.Optimization.OptimResultsFolderName,[ThisVPopName '.xlsx']);
                
                if isempty(ThisVPopName) || any(strcmpi(ThisVPopName,AllVPopNames)) || ...
                        any(strcmpi(ThisFilePath,AllVPopFilePaths))
                    Message = 'Please provide a valid, unique virtual population name.';
                    Title = 'Invalid name';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                else
                    
                    % Create a new virtual population
                    vpopObj = QSP.VirtualPopulation;
                    vpopObj.Session = obj.Optimization.Session;
                    vpopObj.Name = ThisVPopName;                    
                    vpopObj.FilePath = ThisFilePath;                 
                    
                    ThisProfile = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow);
                    
                    Values = ThisProfile.Values(~cellfun(@isempty, ThisProfile.Values(:,2)), :)'; % Take first 2 rows and transpose
                    writecell(Values,vpopObj.FilePath);

                    % Update last saved time
                    updateLastSavedTime(vpopObj);
                    
                    % Validate
                    validate(vpopObj,false);
                    
                    obj.notifyOfChange(vpopObj);
                end
            end
            
        end
        
        function onVisApplyButton(obj,~,~)
            obj.redrawPlots();
            obj.redrawVisEverything();
        end
        
        function onPlotItemsContextMenu(~,~,~)
            %TODO when uisetcolor is supported or a workaround
        end

    end
    
    methods (Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.Optimization.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewOptimization(obj,NewOptimization)
            obj.Optimization = NewOptimization;
            obj.Optimization.PlotSettings = getSummary(obj.getPlotSettings());
            obj.TemporaryOptimization = copy(obj.Optimization);
            
            
            for index = 1:obj.MaxNumPlots
               Summary = obj.Optimization.PlotSettings(index);
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
            [StatusOK,Message,vpopObj] = run(obj.Optimization);
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            else
                obj.notifyOfChange(vpopObj);
            end
        end
        
        function drawVisualization(obj)
            
            %DropDown Update
            obj.updatePlotConfig(obj.Optimization.SelectedPlotLayout);
            
            %Determine if the values are valid
            if ~isempty(obj.Optimization)
                % Check what items are stale or invalid
                [obj.StaleFlag,obj.ValidFlag] = getStaleItemIndices(obj.Optimization);  
            end
            
            obj.redrawAxesContextMenu();
            obj.redrawVisContextMenus();
            obj.redrawOptimItemsTable();
            obj.redrawSpeciesDataTable();
            obj.redrawProfileButtonGroup();
            obj.redrawVisProfileTable();
            obj.redrawVisParametersTable();
            obj.redrawVisLineWidth();
            obj.redrawPlots();
        end
        
        function refreshVisualization(obj,~)
            
            obj.redrawAxesContextMenu();
            obj.redrawVisContextMenus();
            obj.redrawOptimItemsTable();
            obj.redrawSpeciesDataTable();
            obj.redrawProfileButtonGroup();
            obj.redrawVisProfileTable();
            obj.redrawVisParametersTable();
            obj.redrawVisLineWidth();
            obj.redrawPlots();
        end
        
        function UpdateBackendPlotSettings(obj)
            obj.Optimization.PlotSettings = getSummary(obj.getPlotSettings());
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryOptimization.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryOptimization.Description= value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInPlotConfig(obj,value)
            obj.Optimization.SelectedPlotLayout = value;
            obj.updatePlotConfig(value);
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryOptimization.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryOptimization.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.Optimization = copy(obj.TemporaryOptimization,obj.Optimization);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.TemporaryOptimization.Session);
                
            else
                uialert(obj.getUIFigure(),sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function removeInvalidVisualization(obj)
            if ~isempty(obj.PlotSpeciesInvalidRowIndices)
                obj.Optimization.PlotSpeciesTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotSpeciesAsInvalidTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotSpeciesInvalidRowIndices = [];
            end
            
            if ~isempty(obj.PlotItemInvalidRowIndices)
                obj.Optimization.PlotItemTable(obj.PlotItemInvalidRowIndices,:) = [];
                obj.PlotItemAsInvalidTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotItemInvalidRowIndices = [];
            end
            
            % Update
            obj.redrawVisContextMenus();
            obj.redrawOptimItemsTable();
            obj.redrawSpeciesDataTable();
            obj.redrawProfileButtonGroup();
            obj.redrawVisProfileTable();
            obj.redrawVisParametersTable();
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryOptimization)
            obj.TemporaryOptimization = copy(obj.Optimization);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryOptimization.Description);
            obj.updateNameBox(obj.TemporaryOptimization.Name);
            obj.updateSummary(obj.TemporaryOptimization.getSummary());
            obj.IsDirty = false;
            obj.redrawResultsPath();
            obj.redrawAlgorithm();
            obj.redrawParametersEdit();
            obj.redrawParametersTable();
            obj.redrawDataset();
            obj.redrawGroupColumn();
            obj.redrawIDColumn();
            obj.redrawRNGCheck();
            obj.redrawRNGSeed();
            obj.redrawOptimItems();
            obj.redrawSpecies();
            obj.redrawInitialConditions();
            
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryOptimization,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.Optimization.Session.Optimization;
            ixDup = find(strcmp( obj.TemporaryOptimization.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.Optimization)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
        function [ValidTF] = isValid(obj)
            [~,Valid] = getStaleItemIndices(obj.Optimization);
            ValidTF = all(Valid);
        end
        
        function BackEnd = getBackEnd(obj)
            BackEnd = obj.Optimization;
        end
    end
    
    methods (Access = private)
        
        function redrawResultsPath(obj)
            obj.ResultsPath.RootDirectory = obj.TemporaryOptimization.Session.RootDirectory;
            obj.ResultsPath.RelativePath  = obj.TemporaryOptimization.OptimResultsFolderName;
        end
        
        function redrawAlgorithm(obj)
            if ~isempty(obj.TemporaryOptimization)
                ThisList = obj.TemporaryOptimization.OptimAlgorithms;
                Selection = obj.TemporaryOptimization.AlgorithmName;
                [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection);
            else
                FullList = {'-'};
                FullListWithInvalids = {QSP.makeInvalid('-')};
                Value = 1;
            end
            obj.AlgorithmPopupItems = FullList;
            obj.AlgorithmPopupItemsWithInvalid = FullListWithInvalids;
            obj.AlgorithmDropDown.Items = obj.AlgorithmPopupItemsWithInvalid;
            obj.AlgorithmDropDown.Value = obj.AlgorithmPopupItemsWithInvalid{Value};
        end
        
        function redrawParametersEdit(obj)
            if ~isempty(obj.TemporaryOptimization)
                ThisList = {obj.TemporaryOptimization.Settings.Parameters.Name};
                Selection = obj.TemporaryOptimization.RefParamName;

                MatchIdx = strcmpi(ThisList,Selection);
                %If we find a match, it was valid input
                if any(MatchIdx)
                    ThisStatusOk = validate(obj.TemporaryOptimization.Settings.Parameters(MatchIdx));
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
            obj.ParametersDropDown.Items = FullListWithInvalids;
            obj.ParametersDropDown.Value = FullListWithInvalids{Value};
        end
        
        function redrawParametersTable(obj)

            obj.ParametersHeader = {};
            obj.ParametersData = {};

            if ~isempty(obj.TemporaryOptimization) && ~isempty(obj.TemporaryOptimization.RefParamName)
                Names = {obj.TemporaryOptimization.Settings.Parameters.Name};
                MatchIdx = strcmpi(Names,obj.TemporaryOptimization.RefParamName);
                % we found a match, it is valid
                if any(MatchIdx)
                    pObj = obj.TemporaryOptimization.Settings.Parameters(MatchIdx);
                    [StatusOk,~,obj.ParametersHeader,obj.ParametersData] = importData(pObj,pObj.FilePath);
                    %Import was okay
                    if ~StatusOk
                        obj.ParametersHeader = {};
                        obj.ParametersData = {};
                    end
                end
            end

            ColumnEditable = false(1,numel(obj.ParametersHeader));
            ColumnFormat = repmat({'char'},1,numel(obj.ParametersHeader));
            
            %Depends on number of inputs. Anything more than 3 is numeric
            if numel(obj.ParametersHeader) >= 3
                ColumnFormat = repmat({'numeric'},1,numel(obj.ParametersHeader));
                ColumnFormat(1:3) = {'char','char','char'};
            end
            obj.ParametersTable.ColumnName = obj.ParametersHeader;
            obj.ParametersTable.ColumnEditable = ColumnEditable;
            obj.ParametersTable.ColumnFormat = ColumnFormat;
            obj.ParametersTable.Data = obj.ParametersData;
        end
        
        function redrawDataset(obj)
            if ~isempty(obj.TemporaryOptimization)
                ThisList = {obj.TemporaryOptimization.Settings.OptimizationData.Name};
                Selection = obj.TemporaryOptimization.DatasetName;

                MatchIdx = strcmpi(ThisList,Selection);    
                if any(MatchIdx)
                    ThisStatusOk = validate(obj.TemporaryOptimization.Settings.OptimizationData(MatchIdx));
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
            obj.DatasetDropDown.Items = FullListWithInvalids;
            obj.DatasetDropDown.Value = FullListWithInvalids{Value};
            
        end
        
        function redrawGroupColumn(obj)
            if ~isempty(obj.TemporaryOptimization) && ~isempty(obj.TemporaryOptimization.DatasetName) && ~isempty(obj.TemporaryOptimization.Settings.OptimizationData)
                Names = {obj.TemporaryOptimization.Settings.OptimizationData.Name};
                MatchIdx = strcmpi(Names,obj.TemporaryOptimization.DatasetName);
                
                if any(MatchIdx)
                    dobj = obj.TemporaryOptimization.Settings.OptimizationData(MatchIdx);
                    
                    DestDatasetType = 'wide';
                    [~,~,TempOptimHeader,OptimData] = importData(dobj,dobj.FilePath,DestDatasetType);
                else
                    TempOptimHeader = {};
                    OptimData = {};
                end
            else
                TempOptimHeader = {};
                OptimData = {};
            end
            obj.DatasetHeader = TempOptimHeader;
            obj.PrunedDatasetHeader = setdiff(TempOptimHeader,{'Time','Group'});
            obj.DatasetData = OptimData;
            
            if ~isempty(obj.TemporaryOptimization)
                GroupSelection = obj.TemporaryOptimization.GroupName;
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

        function redrawIDColumn(obj)
            if ~isempty(obj.TemporaryOptimization)
                IDSelection = obj.TemporaryOptimization.IDName;
                [FullIDListWithInvalids,FullIDList,IDValue] = QSP.highlightInvalids(obj.DatasetHeader,IDSelection);
            else
                FullIDList = {'-'};
                FullIDListWithInvalids = {QSP.makeInvalid('-')};
                IDValue = 1;
            end
            obj.DatasetIDPopupItems = FullIDList;
            obj.DatasetIDPopupItemsWithInvalid = FullIDListWithInvalids;
            
            obj.IDColumnDropDown.Items = obj.DatasetIDPopupItemsWithInvalid;
            obj.IDColumnDropDown.Value = obj.DatasetIDPopupItemsWithInvalid{IDValue};
        end
        
        function redrawRNGCheck(obj)
            obj.FixSeedCheckBox.Value = obj.TemporaryOptimization.FixRNGSeed;
        end
        
        function redrawRNGSeed(obj)
            obj.RNGSeedEdit.Value = obj.TemporaryOptimization.RNGSeed;
            obj.RNGSeedEdit.Enable = obj.FixSeedCheckBox.Value;
        end
        
        function redrawOptimItems(obj)
            if ~isempty(obj.TemporaryOptimization)
                ValidItemTasks = getValidSelectedTasks(obj.TemporaryOptimization.Settings,{obj.TemporaryOptimization.Settings.Task.Name});
                if ~isempty(ValidItemTasks)
                    obj.TaskPopupTableItems = {ValidItemTasks.Name};
                else
                    obj.TaskPopupTableItems = {};
                end
            else
                obj.TaskPopupTableItems = {};
            end
            
            if ~isempty(obj.TemporaryOptimization) && all(isvalid(obj.TemporaryOptimization.Item))
                ItemTaskNames = {obj.TemporaryOptimization.Item.TaskName};    
                obj.SpeciesPopupTableItems = getSpeciesFromValidSelectedTasks(obj.TemporaryOptimization.Settings,ItemTaskNames);    
            else
                obj.SpeciesPopupTableItems = {};
            end

            if ~isempty(obj.TemporaryOptimization)
                TaskNames = {obj.TemporaryOptimization.Item.TaskName};
                GroupIDs = {obj.TemporaryOptimization.Item.GroupID};
                RunToSteadyState = false(size(TaskNames));

                for index = 1:numel(TaskNames)
                    MatchIdx = strcmpi(TaskNames{index},{obj.TemporaryOptimization.Settings.Task.Name});
                    if any(MatchIdx)
                        RunToSteadyState(index) = obj.TemporaryOptimization.Settings.Task(MatchIdx).RunToSteadyState;
                    end
                end
                Data = [TaskNames(:) GroupIDs(:) num2cell(RunToSteadyState(:))];

                if ~isempty(Data)
                    for index = 1:numel(TaskNames)
                        ThisTask = getValidSelectedTasks(obj.TemporaryOptimization.Settings,TaskNames{index});
                        % Mark invalid if empty
                        if isempty(ThisTask)            
                            Data{index,1} = QSP.makeInvalid(Data{index,1});
                        end
                    end
                    MatchIdx = find(~ismember(GroupIDs(:),obj.GroupIDPopupTableItems(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
                    end
                end
            else
                Data = {};
            end
            
            if ~isempty(obj.TemporaryOptimization) && ~isempty(obj.DatasetHeader) && ~isempty(obj.DatasetData)
                MatchIdx = strcmp(obj.DatasetHeader,obj.TemporaryOptimization.GroupName);
                GroupIDs = obj.DatasetData(:,MatchIdx);
                if iscell(GroupIDs)
                    GroupIDs = cell2mat(GroupIDs);        
                end    
                GroupIDs = unique(GroupIDs);
                obj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
                obj.OptimizationTable.setFormat({obj.TaskPopupTableItems(:)',obj.GroupIDPopupTableItems(:)','char'});
                obj.OptimizationTable.setEditable([true true false]);
            else
                obj.OptimizationTable.setFormat({'char','char','char'});
                obj.OptimizationTable.setEditable([false false false]);
                obj.GroupIDPopupTableItems = {};
            end
            
            obj.OptimizationTable.setEditable([true true false]);
            obj.OptimizationTable.setName({'Task','Group','Run To Steady State'});
            obj.OptimizationTable.setData(Data)
        end
        
        function redrawSpecies(obj)
            if ~isempty(obj.TemporaryOptimization)
                if exist(obj.TemporaryOptimization.Session.ObjectiveFunctionsDirectory,'dir')
                    FileList = dir(obj.TemporaryOptimization.Session.ObjectiveFunctionsDirectory);
                    IsDir = [FileList.isdir];
                    Names = {FileList(~IsDir).name};
                    obj.ObjectiveFunctions = vertcat('defaultObj',Names(:));
                else
                    obj.ObjectiveFunctions = {'defaultObj'};
                end
            else
                obj.ObjectiveFunctions = {'defaultObj'};
            end


            if ~isempty(obj.TemporaryOptimization)
                SpeciesNames = {obj.TemporaryOptimization.SpeciesData.SpeciesName};
                DataNames = {obj.TemporaryOptimization.SpeciesData.DataName};
                FunctionExpressions = {obj.TemporaryOptimization.SpeciesData.FunctionExpression};
                ObjectiveNames = {obj.TemporaryOptimization.SpeciesData.ObjectiveName};

                
                ItemTaskNames = {obj.TemporaryOptimization.Item.TaskName};
                ValidSelectedTasks = getValidSelectedTasks(obj.TemporaryOptimization.Settings,ItemTaskNames);

                NumTasksPerSpecies = zeros(size(SpeciesNames));
                for iSpecies = 1:numel(SpeciesNames)
                    for iTask = 1:numel(ValidSelectedTasks)
                        if any(strcmpi(SpeciesNames{iSpecies},ValidSelectedTasks(iTask).ActiveSpeciesNames))
                            NumTasksPerSpecies(iSpecies) = NumTasksPerSpecies(iSpecies) + 1;
                        end
                    end
                end

                Data = [DataNames(:) SpeciesNames(:) num2cell(NumTasksPerSpecies(:)) FunctionExpressions(:) ObjectiveNames(:)];

                
                if ~isempty(Data)
                    % Data
                    MatchIdx = find(~ismember(DataNames(:),obj.PrunedDatasetHeader(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),1});
                    end
                    % Species
                    MatchIdx = find(~ismember(SpeciesNames(:),obj.SpeciesPopupTableItems(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
                    end
                    % ObjectiveNames
                    MatchIdx = find(~ismember(ObjectiveNames(:),obj.ObjectiveFunctions(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),5} = QSP.makeInvalid(Data{MatchIdx(index),5});
                    end
                end
            else
                Data = {};
            end
            
            EditTF = [true true false true true];
            if isempty(obj.PrunedDatasetHeader)
                ColumnA = 'char';
                EditTF(1) = false;
            else
                ColumnA = obj.PrunedDatasetHeader(:)';
            end
            
            if isempty(obj.SpeciesPopupTableItems)
                ColumnB = 'char';
                EditTF(2) = false;
            else
                ColumnB = obj.SpeciesPopupTableItems(:)';
            end
                
            obj.SpeciesDataTable.setEditable(EditTF);
            obj.SpeciesDataTable.setName({'Data (y)','Species (x)','# Tasks per Species','y=f(x)','ObjectiveFcn'});
            obj.SpeciesDataTable.setFormat({ColumnA,ColumnB,'numeric','char',obj.ObjectiveFunctions(:)'});
            obj.SpeciesDataTable.setData(Data)
        end
        
        function redrawInitialConditions(obj)
                        
            if ~isempty(obj.TemporaryOptimization)
                SpeciesNames = {obj.TemporaryOptimization.SpeciesIC.SpeciesName};
                DataNames = {obj.TemporaryOptimization.SpeciesIC.DataName};
                FunctionExpressions = {obj.TemporaryOptimization.SpeciesIC.FunctionExpression};
                Data = [SpeciesNames(:) DataNames(:) FunctionExpressions(:)];

                % Mark any invalid entries
                if ~isempty(Data)
                    % Species
                    MatchIdx = find(~ismember(SpeciesNames(:),obj.SpeciesPopupTableItems(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),1} = QSP.makeInvalid(Data{MatchIdx(index),1});
                    end
                    % Data
                    MatchIdx = find(~ismember(DataNames(:),obj.PrunedDatasetHeader(:)));
                    for index = 1:numel(MatchIdx)
                        Data{MatchIdx(index),2} = QSP.makeInvalid(Data{MatchIdx(index),2});
                    end
                end
            else
                Data = {};
            end
            
            EditTF = [true true true];
            if isempty(obj.PrunedDatasetHeader)
                ColumnA = 'char';
                EditTF(1) = false;
            else
                ColumnA = obj.SpeciesPopupTableItems(:)';
            end
            
            if isempty(obj.SpeciesPopupTableItems)
                ColumnB = 'char';
                EditTF(2) = false;
            else
                ColumnB = obj.PrunedDatasetHeader(:)';
            end
            
            obj.SpeciesInitialTable.setEditable(EditTF);
            obj.SpeciesInitialTable.setName({'Species (y)','Data (x)','y=f(x)'});
            obj.SpeciesInitialTable.setFormat({ColumnA,ColumnB,'char'});
            obj.SpeciesInitialTable.setData(Data)
            
        end
        
        %We draw using  'Optimization', not 'temporaryOptimization' for the visulization
        %side
        
        function redrawVisEverything(obj)
            obj.redrawVisContextMenus();
            obj.redrawSpeciesDataTable();
            obj.redrawOptimItemsTable();
            obj.redrawVisProfileTable();
            obj.redrawVisParametersTable();
            obj.redrawVisLineWidth();
            obj.redrawProfileButtonGroup();
            
        end
        
        function redrawVisContextMenus(obj)
             %Set Context Menus;
            obj.PlotItemsTableContextMenu = uicontextmenu(ancestor(obj.EditLayout,'figure'));
            obj.PlotItemsTableMenu = uimenu(obj.PlotItemsTableContextMenu);
            obj.PlotItemsTableMenu.Label = 'Set Color';
            obj.PlotItemsTableMenu.Tag = 'PlotItemsCM';
            obj.PlotItemsTableMenu.MenuSelectedFcn = @(h,e)onPlotItemsContextMenu(obj,h,e);
            obj.VisOptimItemsTable.ContextMenu = obj.PlotItemsTableContextMenu;
        end
        
        function redrawSpeciesDataTable(obj)
            AxesOptions = getAxesOptions(obj);
            if ~isempty(obj.Optimization)
                
                %Get all Task, Species, and Data Names
                TaskNames = {obj.Optimization.Item.TaskName};
                SpeciesNames = {obj.Optimization.SpeciesData.SpeciesName};
                DataNames = {obj.Optimization.SpeciesData.DataName};
                ValidSpeciesList = getSpeciesFromValidSelectedTasks(obj.Optimization.Settings,TaskNames);

                %Determine all species that are invalid
                InvalidIndices = false(size(SpeciesNames));
                for idx = 1:numel(SpeciesNames)
                    % Check if the species is missing
                    MissingSpecies = ~ismember(SpeciesNames{idx},ValidSpeciesList);        
                    MissingData = ~ismember(DataNames{idx},obj.OptimHeader);
                    if MissingSpecies || MissingData
                        InvalidIndices(idx) = true;
                    end
                end

                %If the table is currently empty, fill it in for the first
                %time
                if isempty(obj.Optimization.PlotSpeciesTable)
                    
                    %Remove Invalid Species and Data
                    if any(InvalidIndices)
                        SpeciesNames(InvalidIndices) = [];
                        DataNames(InvalidIndices) = [];
                    end

                    obj.Optimization.PlotSpeciesTable = cell(numel(SpeciesNames),5);
                    obj.Optimization.PlotSpeciesTable(:,1) = {' '};
                    
                    %Fill in Second Column, Line Styles
                    if ~isempty(obj.Optimization.SpeciesLineStyles(:))
                        obj.Optimization.PlotSpeciesTable(:,2) = obj.Optimization.SpeciesLineStyles(:);
                    else
                        obj.Optimization.PlotSpeciesTable(:,2) = {'-'};
                    end
                    %Fill in third Column, Species Name
                    obj.Optimization.PlotSpeciesTable(:,3) = SpeciesNames;
                    
                    %Fill in fourth Column, Data Names
                    obj.Optimization.PlotSpeciesTable(:,4) = DataNames;
                    
                    %Fill in fifth Column, Species Names
                    obj.Optimization.PlotSpeciesTable(:,5) = SpeciesNames;

                    obj.PlotSpeciesAsInvalidTable = obj.Optimization.PlotSpeciesTable;
                    obj.PlotSpeciesInvalidRowIndices = [];
                else
                    %The table has been filled in before. Simply fill in
                    NewPlotTable = cell(numel(SpeciesNames),5);
                    NewPlotTable(:,1) = {' '};
                    NewPlotTable(:,2) = {'-'}; 
                    NewPlotTable(:,3) = SpeciesNames;
                    NewPlotTable(:,4) = DataNames;
                    NewPlotTable(:,5) = SpeciesNames;

                    % Adjust for changes from a previous session with a
                    % different size.
                    if size(obj.Optimization.PlotSpeciesTable,2) == 3
                        obj.Optimization.PlotSpeciesTable(:,5) = obj.Optimization.PlotSpeciesTable(:,3);
                        obj.Optimization.PlotSpeciesTable(:,4) = obj.Optimization.PlotSpeciesTable(:,3);
                        obj.Optimization.PlotSpeciesTable(:,3) = obj.Optimization.PlotSpeciesTable(:,2);
                        obj.Optimization.PlotSpeciesTable(:,2) = {'-'}; 
                    elseif size(obj.Optimization.PlotSpeciesTable,2) == 4
                        obj.Optimization.PlotSpeciesTable(:,5) = obj.Optimization.PlotSpeciesTable(:,3);
                    end

                    % Update Table
                    KeyColumn = [3 4];
                    [obj.Optimization.PlotSpeciesTable,obj.PlotSpeciesAsInvalidTable,obj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.Optimization.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);                     
                    % Update line styles
                    updateSpeciesLineStyles(obj.Optimization);
                end
                
                NewColumnFormat = {AxesOptions',obj.Optimization.Settings.LineStyleMap,'char','char','char'};
                NewData = obj.PlotSpeciesAsInvalidTable;
            else
                %If the backend is empty
                NewColumnFormat = {AxesOptions','char','char','char','char'};
                NewData = cell(0,5);
            end
            
            %Finally, write this information to the actual table         
            obj.VisSpeciesDataTable.ColumnEditable = [true,true,false,false,true];
            obj.VisSpeciesDataTable.ColumnName = {'Plot','Style','Species','Data','Display'};
            obj.VisSpeciesDataTable.ColumnFormat = NewColumnFormat;
            obj.VisSpeciesDataTable.Data = NewData;
        end
        
        function redrawOptimItemsTable(obj)
            %We need to obtain OptimHeader and OptimData from the backend
            if ~isempty(obj.Optimization) && ~isempty(obj.Optimization.DatasetName) && ~isempty(obj.Optimization.Settings.OptimizationData)
                Names = {obj.Optimization.Settings.OptimizationData.Name};
                MatchIdx = strcmpi(Names,obj.Optimization.DatasetName);

                if any(MatchIdx)
                    dObj = obj.Optimization.Settings.OptimizationData(MatchIdx);
                    [~,~,TempOptimHeader,OptimData] = importData(dObj,dObj.FilePath,'wide');
                else
                    TempOptimHeader = {};
                    OptimData = {};
                end
            else
                TempOptimHeader = {};
                OptimData = {};
            end
            obj.OptimHeader = TempOptimHeader;
            
            %Use OptimHeader and OptimData to obtain GroupIDs
            if ~isempty(TempOptimHeader) && ~isempty(OptimData)
                MatchIdx = strcmp(TempOptimHeader,obj.Optimization.GroupName);
                GroupIDs = OptimData(:,MatchIdx);
                if iscell(GroupIDs)
                    GroupIDs = cell2mat(GroupIDs);
                end
                GroupIDs = unique(GroupIDs);
                GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
            else
                GroupIDs = [];
            end
            
            %We have the OptimHeader, OptimData, and GroupIDS. 
            if ~isempty(obj.Optimization)

                TaskNames = {obj.Optimization.Item.TaskName};
                GroupIDNames = {obj.Optimization.Item.GroupID};
                
                InvalidIndices = false(size(TaskNames));
                for idx = 1:numel(TaskNames)
                    ThisTask = getValidSelectedTasks(obj.Optimization.Settings,TaskNames{idx});
                    MissingGroup = ~ismember(GroupIDNames{idx},GroupIDs(:)');
                    if isempty(ThisTask) || MissingGroup
                        InvalidIndices(idx) = true;
                    end
                end

                % If the table is empty
                if isempty(obj.Optimization.PlotItemTable)

                    if any(InvalidIndices)
                        TaskNames(InvalidIndices) = [];
                        GroupIDNames(InvalidIndices) = [];
                    end

                    obj.Optimization.PlotItemTable = cell(numel(TaskNames),5);
                    obj.Optimization.PlotItemTable(:,1) = {false};
                    obj.Optimization.PlotItemTable(:,3) = TaskNames;
                    obj.Optimization.PlotItemTable(:,4) = GroupIDNames;
                    obj.Optimization.PlotItemTable(:,5) = TaskNames;

                    % Update the item colors
                    ItemColors = getItemColors(obj.Optimization.Session,numel(TaskNames));
                    obj.Optimization.PlotItemTable(:,2) = num2cell(ItemColors,2);        

                    obj.PlotItemAsInvalidTable = obj.Optimization.PlotItemTable;
                    obj.PlotItemInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(TaskNames),5);
                    NewPlotTable(:,1) = {false};
                    NewPlotTable(:,3) = TaskNames;
                    NewPlotTable(:,4) = GroupIDNames;
                    NewPlotTable(:,5) = TaskNames;

                    NewColors = getItemColors(obj.Optimization.Session,numel(TaskNames));
                    NewPlotTable(:,2) = num2cell(NewColors,2);   

                    if size(obj.Optimization.PlotItemTable,2) == 4
                        obj.Optimization.PlotItemTable(:,5) = obj.Optimization.PlotItemTable(:,3);
                    end

                    % Update Table
                    KeyColumn = [3 4];
                    [obj.Optimization.PlotItemTable,obj.PlotItemAsInvalidTable,obj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.Optimization.PlotItemTable,NewPlotTable,InvalidIndices,KeyColumn);        
                end

                % Update Colors column 
                TableData = obj.PlotItemAsInvalidTable;
                
                %Fill the table with empty chars so only the color is
                %displayed
                TableData(:,2) =convertStringsToChars(strings(size(TableData(:,2),1),1));


                % Set cell color
                for index = 1:size(TableData,1)
                    ThisColor = obj.Optimization.PlotItemTable{index,2};
                    if ~isempty(ThisColor)
                        if isnumeric(ThisColor)
                            Style = uistyle('BackGroundColor',ThisColor);
                            addStyle(obj.VisOptimItemsTable,Style,'cell',[index,2]);
                        else
                            warning('Error: invalid color')
                        end
                    end
                end
            else
               %Empty table, just use an empty table
                TableData = cell(0,5);
            end
            
            %Finally, write this information to the actual table         
            obj.VisOptimItemsTable.ColumnEditable = [true,false,false,false,true];
            obj.VisOptimItemsTable.ColumnName = {'Include','Color','Task','Group','Display'};
            obj.VisOptimItemsTable.ColumnFormat = {'logical','char','char','char','char'};
            obj.VisOptimItemsTable.Data = '';
            obj.VisOptimItemsTable.Data = (TableData);
        end
        
        function redrawProfileButtonGroup(obj)

            if ~isempty(obj.Optimization) && ~isempty(obj.Optimization.SelectedProfileRow) && 0 ~= obj.Optimization.SelectedProfileRow
                %turn on buttons if we have a selected row 
                obj.VisAddButton.Enable = true;
                obj.VisRemoveButton.Enable = true;
                obj.VisCopyButton.Enable = true;
            else %If there is no selected row  
                obj.VisAddButton.Enable = false;
                obj.VisRemoveButton.Enable = false;
                obj.VisCopyButton.Enable = false; 
            end
            
            if isempty(obj.VisParametersTable.Data)
                obj.VisPencilMatButtonm.Enable = false;
                obj.VisDataButton.Enable = false;
                obj.VisApplyButton.Enable = false;
                obj.VisSwapButton.Enable = false;
            else
                obj.VisPencilMatButtonm.Enable = true;
                obj.VisDataButton.Enable = true;
                obj.VisApplyButton.Enable = true;
                obj.VisSwapButton.Enable = true;
                
            end
        end
        
        function redrawVisProfileTable(obj)
            if ~isempty(obj.Optimization)
                Names = {obj.Optimization.Settings.Parameters.Name};
                MatchIdx = strcmpi(Names,obj.Optimization.RefParamName);

                % construct the VPopname from the name of the optimization
                VPopNames = {sprintf('Results - Optimization = %s -', obj.Optimization.Name)};

                % Filter VPopNames list (only if name does not exist, not if invalid)
                AllVPopNames = {obj.Optimization.Session.Settings.VirtualPopulation.Name};
                MatchVPopIdx = false(1,numel(AllVPopNames));
                
                %For Every VPopName we have
                for idx = 1:numel(VPopNames)
                    %Only if the value is not empty
                    if ~isempty(VPopNames{idx})
                        %Flip all entries that match this expression to
                        %true
                        MatchVPopIdx = MatchVPopIdx | ~cellfun(@isempty,regexp(AllVPopNames,VPopNames{idx}));
                    end
                end
                
                %Index for the names that we have found are present. 
                VPopNames = AllVPopNames(MatchVPopIdx);

                if any(MatchIdx)
                    pObj = obj.Optimization.Settings.Parameters(MatchIdx);    
                    pObj_derivs = AllVPopNames(~cellfun(@isempty, strfind(AllVPopNames, obj.Optimization.RefParamName )));
                    PlotParametersSourceOptions = vertcat('N/A',{pObj.Name},reshape(pObj_derivs,[],1), VPopNames(:));
                else
                    PlotParametersSourceOptions = vertcat('N/A',VPopNames(:));
                end
            else
                PlotParametersSourceOptions = {'N/A'};
            end

            % History table
            obj.ThisProfileData = {};
            if ~isempty(obj.Optimization)
                
                TableData = horzcat(...
                    num2cell(1:numel(obj.Optimization.PlotProfile))',...        
                    {obj.Optimization.PlotProfile.Show}',...
                    {obj.Optimization.PlotProfile.Source}',...
                    {obj.Optimization.PlotProfile.Description}');

                % Import the parmaters using helper
                [IsSourceMatch,~,obj.ThisProfileData] = importParametersSourceHelper(obj);    

                ColumnFormat = {'numeric','logical',PlotParametersSourceOptions(:)','char'};
                ColumnEditable = [false,true,true,true];

            else
                %No italicized items for empty table
                IsSourceMatch = [];
                TableData = cell(0,5);
                ColumnFormat = {'numeric','logical','char','char'};
                ColumnEditable = [false,true,false,true];
            end
            %Finally, write this information to the actual table         
            obj.VisProfilesTable.ColumnEditable = ColumnEditable;
            obj.VisProfilesTable.ColumnName = {'Run','Show','Source','Description'};
            obj.VisProfilesTable.ColumnFormat = ColumnFormat;
            obj.VisProfilesTable.Data = TableData;
            removeStyle(obj.VisProfilesTable);
            %italicize items that do not match   
            
            for rowIdx = 1:size(TableData,1)
                %If the source does not match, italicize
                if ~IsSourceMatch(rowIdx)
                    Style = uistyle('FontAngle','italic','HorizontalAlignment','left');
                    addStyle(obj.VisProfilesTable,Style,'cell',[rowIdx,1]);
                    addStyle(obj.VisProfilesTable,Style,'cell',[rowIdx,4]);
                end
            end
        end
        
        function redrawVisParametersTable(obj)
            %If do not have currently selected profile
            if isempty(obj.ThisProfileData)
                [~,~,obj.ThisProfileData] = importParametersSourceHelper(obj);
            end
            
            %Verify the dimensions of the input. This could vary between
            %sessions
            if size(obj.ThisProfileData,2)==3
                TableData = obj.ThisProfileData;
                LabelString = sprintf('Parameters (Run = %d)', obj.Optimization.SelectedProfileRow);
            else
                TableData = cell(0,3);
                LabelString =  sprintf('Parameters');
            end
            
            %Finally, write this information to the actual table        
            obj.VisParametersTable.ColumnEditable = [false,true,false];
            obj.VisParametersTable.ColumnName = {'Parameter','Value','Source Value'};
            obj.VisParametersTable.ColumnFormat = {'char','numeric','numeric'};
            obj.VisParametersTable.Data = TableData;
            obj.VisParametersTableLabel.Text = LabelString;
            removeStyle(obj.VisParametersTable);
            
            %italicize entries that dont match
            for rowIdx = 1:size(TableData,1)
                if ~isequal(TableData{rowIdx,2}, TableData{rowIdx,3})
                    Style = uistyle('FontAngle','italic','HorizontalAlignment','left');
                    addStyle(obj.VisParametersTable,Style,'row',rowIdx);
                end
            end
        end
        
        function redrawVisLineWidth(obj)
            %For every line, specify the line width.
            %If the line is from the selected row in the table, add 2
            
            if ~isempty(obj.Optimization)
                %For every element in the SpeciesGroup (3 dimensional)
                
                for i=1:size(obj.SpeciesGroup,1)
                    for j=1:size(obj.SpeciesGroup,2)
                        for k=1:size(obj.SpeciesGroup,3)
                            %If the element is a handle or vector of
                            %handles
                            
                            if ~isempty(obj.SpeciesGroup{i,j,k}) && ishandle(obj.SpeciesGroup{i,j,k})
                                Ch = obj.SpeciesGroup{i,j,k}.Children;
                                Ch = flip(Ch);
                                %Based on the QSP class, they use a single
                                %dummy line, skip it
                                
                                if numel(Ch) > 1
                                    %Use set syntax so we dont have to
                                    %loop
                                    
                                    set(Ch(2:end),'LineWidth',obj.Optimization.PlotSettings(j).LineWidth);
                                    %Only for the selectedLine, Bolden
                                    
                                    if (k==obj.Optimization.SelectedProfileRow)
                                        set(Ch,'LineWidth',obj.Optimization.PlotSettings(j).LineWidth+2);
                                    end
                                end
                            end 
                        end 
                    end 
                end
            end
        end
        
        function [IsSourceMatch,IsRowEmpty,SelectedProfileData] = importParametersSourceHelper(obj)
            
            UniqueSourceNames = unique({obj.Optimization.PlotProfile.Source});
            UniqueSourceData = cell(1,numel(UniqueSourceNames));
            
            % First import just the unique sources
            for index = 1:numel(UniqueSourceNames)
                % Import from QSP
                [StatusOk,Message,SourceData] = importParametersSource(obj.Optimization,UniqueSourceNames{index});
                if StatusOk
                    [~,order] = sort(upper(SourceData(:,1)));
                    UniqueSourceData{index} = SourceData(order,:);
                else
                    UniqueSourceData{index} = cell(0,2);
                    uialert(obj.getUIFigure(),Message,'Parameter Import Failed');
                end
            end
    
            
            % Determine for each row of the Profiles, if the source matches
            % and if the row is emoty
            
            %preallocate
            nProfiles = numel(obj.Optimization.PlotProfile);
            IsSourceMatch = true(1,nProfiles);
            IsRowEmpty = false(1,nProfiles);
            
            %for every row
            for index = 1:nProfiles
                ThisProfile = obj.Optimization.PlotProfile(index);
                ThisProfileValues = ThisProfile.Values;
                uIdx = ismember(UniqueSourceNames,ThisProfile.Source);
                
                %check if it matches
                if ~isequal(ThisProfileValues,UniqueSourceData{uIdx})
                    IsSourceMatch(index) = false;
                end
                
                %check if it is empty
                if isempty(UniqueSourceData{uIdx})
                    IsRowEmpty(index) = true;
                end
            end
            
            %Only if we have a selected row
            if ~isempty(obj.Optimization.SelectedProfileRow)
                try
                    SelectedProfile = obj.Optimization.PlotProfile(obj.Optimization.SelectedProfileRow);
                    Success = true;
                catch thisError
                    warning(thisError.message);
                    SelectedProfileData = [];
                    Success = false;
                end
                
                
                if Success 
                    
                    uIdx = ismember(UniqueSourceNames,SelectedProfile.Source);
                    SelectedProfileData = SelectedProfile.Values;
                    if ~isempty(UniqueSourceData{uIdx})
                        missingIndices = ~cellfun(@ischar, SelectedProfileData(:,1));
                        SelectedProfileData(missingIndices,:) = [];
                        [hMatch,MatchIdx] = ismember(SelectedProfileData(:,1), UniqueSourceData{uIdx}(:,1));
                        SelectedProfileData(hMatch,3) = UniqueSourceData{uIdx}(MatchIdx(hMatch),end);
                        [~,index] = sort(upper(SelectedProfileData(:,1)));
                        SelectedProfileData = SelectedProfileData(index,:);
                    end
                end
            else
                SelectedProfileData = cell(0,3);
            end
            
        end
        
        function redrawPlots(obj,varargin)
            [obj.SpeciesGroup,obj.DatasetGroup,obj.AxesLegend,obj.AxesLegendChildren] = plotOptimization(obj.Optimization,obj.getPlotArray(),varargin);
        end
        
        function Value = dialogPopupHelper(obj,Question,DefaultValue)
            TemporaryPanel = QSPViewerNew.Widgets.InputDlgCustom(obj.getUIFigure(),Question,DefaultValue);
            TemporaryPanel.wait();
            Value = TemporaryPanel.getValue();
            delete(TemporaryPanel);
        end

    end
        
end


