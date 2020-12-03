classdef GlobalSensitivityAnalysisPane < QSPViewerNew.Application.ViewPane
    %  GlobalSensitivityAnalysisPane - A Class for the Global Sensitivity
    %  Analysis Pane view. This is the 'viewer' counterpart to the 'model'
    %  class QSP.GlobalSensitivityAnalysis

    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks
    %   $Author: faugusti $
    %   $Revision: 1 $  $Date: Wed, 04 Nov 2020 $

    % ---------------------------------------------------------------------
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        GlobalSensitivityAnalysis = QSP.GlobalSensitivityAnalysis.empty()
        TemporaryGlobalSensitivityAnalysis = QSP.GlobalSensitivityAnalysis.empty()
        IsDirty = false
    end
    
    properties (Access=private)
        
        TaskPopupTableItems = {'yellow','blue'}
        LineStyles = {'-','--','.-',':'}
        PlotNumber = {' ','1','2','3','4','5','6','7','8','9','10','11','12'}
        PlotItemsColor = {};
        Type = {'first order', 'total order', 'unexpl. frac.', 'variance'};
        
        SelectedRow = struct('TaskTable', 0, ...
                             'PlotItemsTable', 0, ...
                             'PlotSobolIndexTable', [0,0]);
                         
        StaleFlag
        ValidFlag
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = private)
        ResultFolderListener
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        
        %% Edit panel 
        EditGrid                    matlab.ui.container.GridLayout
        ResultFolderSelector        QSPViewerNew.Widgets.FolderSelector
        SamplingConfigurationGrid   matlab.ui.container.GridLayout
        NumberIterationsEditField   matlab.ui.control.NumericEditField
        NumberIterationsLabel       matlab.ui.control.Label
        NumberSamplesEditField      matlab.ui.control.NumericEditField
        NumberSamplesLabel          matlab.ui.control.Label
        SeedSubLayout               matlab.ui.container.GridLayout
        FixSeedLabel                matlab.ui.control.Label
        FixSeedCheckBox             matlab.ui.control.CheckBox
        SeedLabel                   matlab.ui.control.Label
        SeedEdit                    matlab.ui.control.NumericEditField
        SensitivityInputsDropDown   matlab.ui.control.DropDown
        SensitivityInputsLabel      matlab.ui.control.Label
        
        % Table for task selection for sensitivity outputs
        TaskLabel                   matlab.ui.control.Label
        TaskGrid                    matlab.ui.container.GridLayout
        TaskButtonGrid              matlab.ui.container.GridLayout
        NewTaskButton               matlab.ui.control.Button
        TaskTable                   matlab.ui.control.Table
        RemoveItemButton            matlab.ui.control.Button
        
        %% Plot panel
        PlotGrid                    matlab.ui.container.GridLayout
        PlotModeLabel               matlab.ui.control.Label
        PlotModeDropDown            matlab.ui.control.DropDown
        
        % Table for selecting Sobol indices for plotting
        SobolIndexLabel             matlab.ui.control.Label
        SobolIndexGrid              matlab.ui.container.GridLayout
        SobolIndexButtonGrid        matlab.ui.container.GridLayout
        NewSobolIndexButton         matlab.ui.control.Button
        RemoveSobolIndexButton      matlab.ui.control.Button
        MoveUpSobolIndexButton      matlab.ui.control.Button
        MoveDownSobolIndexButton    matlab.ui.control.Button
        SobolIndexTable             matlab.ui.control.Table
        
        % Table for selecting tasks for inclusion in plots
        PlotItemsGrid               matlab.ui.container.GridLayout
        SelectColorGrid             matlab.ui.container.GridLayout
        SelectColorButton           matlab.ui.control.Button
        PlotItemsLabel              matlab.ui.control.Label
        PlotItemsTable              matlab.ui.control.Table
        
        % Table for managing iteration results
        IterationsTable             matlab.ui.control.Table
        IterationsLabel             matlab.ui.control.Label
        IterationsGrid              matlab.ui.container.GridLayout
        IterationsButtonGrid        matlab.ui.container.GridLayout
        RemoveIterationButton       matlab.ui.control.Button
        ShowIterationsCheckBox      matlab.ui.control.CheckBox

    end
        
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = GlobalSensitivityAnalysisPane(varargin)
            obj = obj@QSPViewerNew.Application.ViewPane(varargin{:}{:},true);
            obj.create();
            obj.createListenersAndCallbacks();
        end
        
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function create(obj)
            
            %% Edit panel 
            obj.EditGrid = uigridlayout(obj.getEditGrid());
            obj.EditGrid.ColumnWidth   = {'1x'};
            obj.EditGrid.RowHeight     = {obj.WidgetHeight, ...        % results folder selection
                                          obj.WidgetHeight, ...        % number of samples/iterations
                                          obj.WidgetHeight, ...        % random number seed
                                          obj.WidgetHeight, ...        % sensitivity inputs
                                          obj.WidgetHeight, '1x'};     % task selection table
            obj.EditGrid.Layout.Row    = 3;
            obj.EditGrid.Layout.Column = 1;
            obj.EditGrid.Padding       = obj.WidgetPadding;
            obj.EditGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.EditGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            % Results path selector
            obj.ResultFolderSelector = QSPViewerNew.Widgets.FolderSelector(obj.EditGrid,1,1,'Results Path');
            
            % Sampling configuration grid
            obj.SamplingConfigurationGrid               = uigridlayout(obj.EditGrid);
            obj.SamplingConfigurationGrid.ColumnWidth   = {1.50*obj.LabelLength, '1x', ... 
                                                           1.25*obj.LabelLength,'1x'};     
            obj.SamplingConfigurationGrid.RowHeight     = {obj.WidgetHeight, ... % number samples/iterations
                                                           obj.WidgetHeight, ... % random seed
                                                           obj.WidgetHeight};    % sensitivity inputs
            obj.SamplingConfigurationGrid.Layout.Row    = [2,4];
            obj.SamplingConfigurationGrid.Layout.Column = 1;
            obj.SamplingConfigurationGrid.Padding       = obj.WidgetPadding;
            obj.SamplingConfigurationGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.SamplingConfigurationGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            % Number of samples
            obj.NumberSamplesLabel               = uilabel(obj.SamplingConfigurationGrid);
            obj.NumberSamplesLabel.Layout.Column = 1;
            obj.NumberSamplesLabel.Layout.Row    = 1;
            obj.NumberSamplesLabel.Text          = 'Add number of samples';
            obj.NumberSamplesEditField                       = uieditfield(obj.SamplingConfigurationGrid, 'numeric');
            obj.NumberSamplesEditField.Layout.Column         = 2;
            obj.NumberSamplesEditField.Layout.Row            = 1;
            obj.NumberSamplesEditField.Limits                = [0,Inf];
            obj.NumberSamplesEditField.ValueChangedFcn       = @(h,e)obj.onNumberSamplesChange();            
            obj.NumberSamplesEditField.RoundFractionalValues = true;
            
            % Number of iterations
            obj.NumberIterationsLabel               = uilabel(obj.SamplingConfigurationGrid);
            obj.NumberIterationsLabel.Layout.Column = 3;
            obj.NumberIterationsLabel.Layout.Row    = 1;
            obj.NumberIterationsLabel.Text          = 'Number of iterations';
            obj.NumberIterationsEditField                       = uieditfield(obj.SamplingConfigurationGrid, 'numeric');
            obj.NumberIterationsEditField.Layout.Column         = 4;
            obj.NumberIterationsEditField.Layout.Row            = 1;
            obj.NumberIterationsEditField.Limits                = [1,Inf];
            obj.NumberIterationsEditField.RoundFractionalValues = true;
            obj.NumberIterationsEditField.ValueChangedFcn       = @(h,e)obj.onNumberIterationsChange();            

            % Random seed configuration
            % checkbox
            obj.FixSeedCheckBox                 = uicheckbox(obj.SamplingConfigurationGrid);
            obj.FixSeedCheckBox.Text            = "Fix seed for random number generation";
            obj.FixSeedCheckBox.Layout.Column   = [1,2];
            obj.FixSeedCheckBox.Layout.Row      = 2;
            obj.FixSeedCheckBox.Visible         = 'off';
            obj.FixSeedCheckBox.Enable          = 'on';
            obj.FixSeedCheckBox.Value           = false;
            obj.FixSeedCheckBox.ValueChangedFcn = @(h,e)obj.onFixRandomSeedChange();
            % label
            obj.SeedLabel               = uilabel(obj.SamplingConfigurationGrid);
            obj.SeedLabel.Text          = 'RNG Seed';
            obj.SeedLabel.Layout.Row    = 2;
            obj.SeedLabel.Layout.Column = 3;
            obj.SeedLabel.Visible       = 'off';
            obj.SeedLabel.Enable        = 'off';
            % edit field
            obj.SeedEdit                       = uieditfield(obj.SamplingConfigurationGrid,'numeric');
            obj.SeedEdit.Layout.Row            = 2;
            obj.SeedEdit.Layout.Column         = 4;
            obj.SeedEdit.Limits                = [0,Inf];
            obj.SeedEdit.RoundFractionalValues = true;
            obj.SeedEdit.Visible               = 'off';
            obj.SeedEdit.Enable                = 'off';
            
            % Sensitivity inputs 
            obj.SensitivityInputsLabel               = uilabel(obj.SamplingConfigurationGrid);
            obj.SensitivityInputsLabel.Layout.Column = 1;
            obj.SensitivityInputsLabel.Layout.Row    = 3;
            obj.SensitivityInputsLabel.Text          = 'Sensitivity inputs';
            obj.SensitivityInputsDropDown                 = uidropdown(obj.SamplingConfigurationGrid);
            obj.SensitivityInputsDropDown.Layout.Column   = [2,4];
            obj.SensitivityInputsDropDown.Layout.Row      = 3;
            obj.SensitivityInputsDropDown.Items           = {'foo', 'bar'};
            obj.SensitivityInputsDropDown.ValueChangedFcn = @(h,e)obj.onSensitivityInputChange();            
            
            % Table for task selection for sensitivity outputs
            obj.TaskLabel               = uilabel(obj.EditGrid);
            obj.TaskLabel.Layout.Row    = 5;
            obj.TaskLabel.Layout.Column = 1;
            obj.TaskLabel.Text          = 'Global Sensitivity Analysis Items';
            obj.TaskLabel.FontWeight    = 'bold';
            obj.TaskGrid               = uigridlayout(obj.EditGrid);
            obj.TaskGrid.ColumnWidth   = {obj.ButtonWidth,'1x'};
            obj.TaskGrid.RowHeight     = {'1x'};
            obj.TaskGrid.Layout.Row    = 6;
            obj.TaskGrid.Layout.Column = 1;
            obj.TaskGrid.Padding       = [0,0,0,0];
            obj.TaskGrid.RowSpacing    = 0;
            obj.TaskGrid.ColumnSpacing = 0;
            % buttons
            obj.TaskButtonGrid = uigridlayout(obj.TaskGrid);
            obj.TaskButtonGrid.ColumnWidth = {'1x'};
            obj.TaskButtonGrid.RowHeight = {obj.ButtonHeight, ... % add
                                            obj.ButtonHeight};    % remove
            obj.TaskButtonGrid.Layout.Row = 1;
            obj.TaskButtonGrid.Layout.Column = 1;
            obj.TaskButtonGrid.Padding = [0,0,0,0];
            obj.TaskButtonGrid.RowSpacing = 0;
            obj.TaskButtonGrid.ColumnSpacing = 0;
            % add task
            obj.NewTaskButton                 = uibutton(obj.TaskButtonGrid,'push');
            obj.NewTaskButton.Layout.Row      = 1;
            obj.NewTaskButton.Layout.Column   = 1;
            obj.NewTaskButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.NewTaskButton.Text            = '';
            obj.NewTaskButton.ButtonPushedFcn = @(h,e)obj.onAddSensitivityOutput();
            % remove task
            obj.RemoveItemButton                 = uibutton(obj.TaskButtonGrid,'push');
            obj.RemoveItemButton.Layout.Row      = 2;
            obj.RemoveItemButton.Layout.Column   = 1;
            obj.RemoveItemButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveItemButton.Text            = '';
            obj.RemoveItemButton.ButtonPushedFcn = @(h,e)obj.onRemoveSensitivityOutput();
            % task table
            obj.TaskTable                       = uitable(obj.TaskGrid);
            obj.TaskTable.Layout.Row            = 1;
            obj.TaskTable.Layout.Column         = 2;
            obj.TaskTable.Data                  = {[],[],[],[]};
            obj.TaskTable.ColumnName            = {'Include','Task','Number of Samples'};
            obj.TaskTable.ColumnFormat          = {'logical',obj.TaskPopupTableItems,'numeric'};
            obj.TaskTable.ColumnEditable        = [true,true,false];
            obj.TaskTable.ColumnWidth           = {'fit', 'auto', 'fit'};
            obj.TaskTable.CellEditCallback      = @(h,e) obj.onTaskTableEdit(e);
            obj.TaskTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);

            %% Plot panel
            obj.PlotGrid               = uigridlayout(obj.getVisualizationGrid());
            obj.PlotGrid.Layout.Row    = 2;
            obj.PlotGrid.Layout.Column = 1;
            obj.PlotGrid.RowHeight     = {obj.WidgetHeight, ...        % display mode
                                          obj.WidgetHeight, '2x', ...  % Sobol index table
                                          obj.WidgetHeight, '1x', ...  % task selection table
                                          obj.WidgetHeight, '1x', ...  % iterations table
                                          obj.WidgetHeight};           % show iterations checkbox
            obj.PlotGrid.ColumnWidth   = {obj.LabelLength,'1x'};
            
            % Plot mode
            obj.PlotModeLabel               = uilabel(obj.PlotGrid);
            obj.PlotModeLabel.Layout.Column = 1;
            obj.PlotModeLabel.Layout.Row    = 1;
            obj.PlotModeLabel.Text          = 'Mode';
            obj.PlotModeDropDown                 = uidropdown(obj.PlotGrid);
            obj.PlotModeDropDown.Layout.Column   = 2;
            obj.PlotModeDropDown.Layout.Row      = 1;
            obj.PlotModeDropDown.Items           = {'Time course','Bar plot (mean)','Bar plot (median)','Bar plot (max)','Bar plot (min)'};
            obj.PlotModeDropDown.ValueChangedFcn = @(h,e)obj.onVisualizationModeChange();
            
            % Table for selecting Sobol indices for plotting
            obj.SobolIndexLabel               = uilabel(obj.PlotGrid);
            obj.SobolIndexLabel.Layout.Row    = 2;
            obj.SobolIndexLabel.Layout.Column = [1,2];
            obj.SobolIndexLabel.Text          = 'Results';
            obj.SobolIndexLabel.FontWeight    = 'bold';
            obj.SobolIndexGrid               = uigridlayout(obj.PlotGrid);
            obj.SobolIndexGrid.ColumnWidth   = {obj.ButtonWidth,'1x'};
            obj.SobolIndexGrid.RowHeight     = {'1x'};
            obj.SobolIndexGrid.Layout.Row    = 3;
            obj.SobolIndexGrid.Layout.Column = [1,2];
            obj.SobolIndexGrid.Padding       = [0,0,0,0];
            obj.SobolIndexGrid.RowSpacing    = 0;
            obj.SobolIndexGrid.ColumnSpacing = 0;
            % buttons
            obj.SobolIndexButtonGrid               = uigridlayout(obj.SobolIndexGrid);
            obj.SobolIndexButtonGrid.ColumnWidth   = {'1x'};
            obj.SobolIndexButtonGrid.RowHeight     = {obj.ButtonHeight,... % add
                                                      obj.ButtonHeight,... % remove
                                                      obj.ButtonHeight,... % move up
                                                      obj.ButtonHeight};   % move down
            obj.SobolIndexButtonGrid.Layout.Row    = 1;
            obj.SobolIndexButtonGrid.Layout.Column = 1;
            obj.SobolIndexButtonGrid.Padding       = [0,0,0,0];
            obj.SobolIndexButtonGrid.RowSpacing    = 0;
            obj.SobolIndexButtonGrid.ColumnSpacing = 0;
            % add Sobol index to plot
            obj.NewSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.NewSobolIndexButton.Layout.Row      = 1;
            obj.NewSobolIndexButton.Layout.Column   = 1;
            obj.NewSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.NewSobolIndexButton.Text            = '';
            obj.NewSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % remove Sobol index from plot
            obj.RemoveSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.RemoveSobolIndexButton.Layout.Row      = 2;
            obj.RemoveSobolIndexButton.Layout.Column   = 1;
            obj.RemoveSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveSobolIndexButton.Text            = '';
            obj.RemoveSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % move up Sobol index up
            obj.MoveUpSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.MoveUpSobolIndexButton.Layout.Row      = 3;
            obj.MoveUpSobolIndexButton.Layout.Column   = 1;
            obj.MoveUpSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('arrow_up_24.png');
            obj.MoveUpSobolIndexButton.Text            = '';
            obj.MoveUpSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % move up Sobol index down
            obj.MoveDownSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.MoveDownSobolIndexButton.Layout.Row      = 4;
            obj.MoveDownSobolIndexButton.Layout.Column   = 1;
            obj.MoveDownSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('arrow_down_24.png');
            obj.MoveDownSobolIndexButton.Text            = '';
            obj.MoveDownSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % table
            obj.SobolIndexTable                       = uitable(obj.SobolIndexGrid);
            obj.SobolIndexTable.Layout.Row            = 1;
            obj.SobolIndexTable.Layout.Column         = 2;
            obj.SobolIndexTable.Data                  = cell(0,6);
            obj.SobolIndexTable.ColumnName            = {'Plot','Style','Input','Output','Type','Display'};
            obj.SobolIndexTable.ColumnFormat          = {obj.PlotNumber,obj.LineStyles,obj.TaskPopupTableItems,obj.TaskPopupTableItems,obj.Type,'char'};
            obj.SobolIndexTable.ColumnEditable        = [true,true,true,true,true,true];
            obj.SobolIndexTable.ColumnWidth           = '1x';
            obj.SobolIndexTable.SelectionHighlight    = 'off';
            obj.SobolIndexTable.CellEditCallback      = @(h,e) obj.onVisualizationTableEdit(h,e);
            obj.SobolIndexTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);

            % Table for selecting tasks for inclusion in plots
            obj.PlotItemsLabel               = uilabel(obj.PlotGrid);
            obj.PlotItemsLabel.Layout.Row    = 4;
            obj.PlotItemsLabel.Layout.Column = [1,2];
            obj.PlotItemsLabel.Text          = 'Task selection';
            obj.PlotItemsLabel.FontWeight    = 'bold';
            obj.PlotItemsGrid               = uigridlayout(obj.PlotGrid);
            obj.PlotItemsGrid.ColumnWidth   = {obj.ButtonWidth,'1x'};
            obj.PlotItemsGrid.RowHeight     = {'1x'};
            obj.PlotItemsGrid.Layout.Row    = 5;
            obj.PlotItemsGrid.Layout.Column = [1,2];
            obj.PlotItemsGrid.Padding       = [0,0,0,0];
            obj.PlotItemsGrid.RowSpacing    = 0;
            obj.PlotItemsGrid.ColumnSpacing = 0;
            % button
            obj.SelectColorGrid               = uigridlayout(obj.PlotItemsGrid);
            obj.SelectColorGrid.ColumnWidth   = {'1x'};
            obj.SelectColorGrid.RowHeight     = {obj.ButtonHeight};
            obj.SelectColorGrid.Layout.Row    = 1;
            obj.SelectColorGrid.Layout.Column = 1;
            obj.SelectColorGrid.Padding       = [0,0,0,0];
            obj.SelectColorGrid.RowSpacing    = 0;
            obj.SelectColorGrid.ColumnSpacing = 0;
            % color selection
            obj.SelectColorButton                 = uibutton(obj.SelectColorGrid,'push');
            obj.SelectColorButton.Layout.Row      = 1;
            obj.SelectColorButton.Layout.Column   = 1;
            obj.SelectColorButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('fillColor_24.png');
            obj.SelectColorButton.Text            = '';
            obj.SelectColorButton.ButtonPushedFcn = @(h,e)obj.setPlotItemColor();
            % table
            obj.PlotItemsTable                       = uitable(obj.PlotItemsGrid);
            obj.PlotItemsTable.Layout.Row            = 1;
            obj.PlotItemsTable.Layout.Column         = 2;
            obj.PlotItemsTable.Data                  = cell(0,4);
            obj.PlotItemsTable.ColumnName            = {'Include','Color','Task','Description'};
            obj.PlotItemsTable.ColumnFormat          = {'logical','char','char'};
            obj.PlotItemsTable.ColumnEditable        = [true,false,false,true];
            obj.PlotItemsTable.ColumnWidth           = {'fit','fit','auto','auto'};
            obj.PlotItemsTable.CellEditCallback      = @(h,e) obj.onVisualizationTableEdit(h,e);
            obj.PlotItemsTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);
            
            % Table for managing iteration results
            obj.IterationsLabel = uilabel(obj.PlotGrid);
            obj.IterationsLabel.Layout.Row = 6;
            obj.IterationsLabel.Layout.Column = [1,2];
            obj.IterationsLabel.Text = 'Iterations: select a task';
            obj.IterationsLabel.FontWeight = 'bold';
            obj.IterationsGrid = uigridlayout(obj.PlotGrid);
            obj.IterationsGrid.ColumnWidth = {obj.ButtonWidth,'1x'};
            obj.IterationsGrid.RowHeight = {'1x'};
            obj.IterationsGrid.Layout.Row = 7;
            obj.IterationsGrid.Layout.Column = [1,2];
            obj.IterationsGrid.Padding = [0,0,0,0];
            obj.IterationsGrid.RowSpacing = 0;
            obj.IterationsGrid.ColumnSpacing = 0;
            % buttons
            obj.IterationsButtonGrid               = uigridlayout(obj.IterationsGrid);
            obj.IterationsButtonGrid.ColumnWidth   = {'1x'};
            obj.IterationsButtonGrid.RowHeight     = {obj.ButtonHeight};
            obj.IterationsButtonGrid.Layout.Row    = 1;
            obj.IterationsButtonGrid.Layout.Column = 1;
            obj.IterationsButtonGrid.Padding       = [0,0,0,0];
            obj.IterationsButtonGrid.RowSpacing    = 0;
            obj.IterationsButtonGrid.ColumnSpacing = 0;
            % clear iteration
            obj.RemoveIterationButton                 = uibutton(obj.IterationsButtonGrid,'push');
            obj.RemoveIterationButton.Layout.Row      = 1;
            obj.RemoveIterationButton.Layout.Column   = 1;
            obj.RemoveIterationButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('clearPlot_24.png');
            obj.RemoveIterationButton.Text            = '';
            obj.RemoveIterationButton.ButtonPushedFcn = @(h,e)obj.onRemoveIteration();
            % table
            obj.IterationsTable                = uitable(obj.IterationsGrid);
            obj.IterationsTable.Layout.Row     = 1;
            obj.IterationsTable.Layout.Column  = 2;
            obj.IterationsTable.Data           = {[],[],[],[],[]};
            obj.IterationsTable.ColumnName     = {'Remove','Color','Max. difference','Mean difference','Samples'};
            obj.IterationsTable.ColumnFormat   = {'logical','char','char','char','numeric'};
            obj.IterationsTable.ColumnEditable = [true,false,false,false,false];
            obj.IterationsTable.ColumnWidth    = {'fit','fit','auto','auto','fit'};
            % show iterations checkbox
            obj.ShowIterationsCheckBox                 = uicheckbox(obj.PlotGrid);
            obj.ShowIterationsCheckBox.Text            = "Show iterations in plot";
            obj.ShowIterationsCheckBox.Layout.Column   = [1,2];
            obj.ShowIterationsCheckBox.Layout.Row      = 8;
            obj.ShowIterationsCheckBox.Value           = true;
            obj.ShowIterationsCheckBox.ValueChangedFcn = @(h,e)obj.onShowIterationsChange();
            

        end
        
        function createListenersAndCallbacks(obj)
            obj.ResultFolderListener = addlistener(obj.ResultFolderSelector,'StateChanged',@(src,event) obj.onResultsPath(event.Source.RelativePath));
        end
        
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onRemoveSensitivityOutput(obj)
            DeleteIdx = obj.SelectedRow.TaskTable;
            if DeleteIdx == 0
                uialert(obj.getUIFigure(), ...
                    ['Select a task to remove the corresponding ', ...
                     'global sensitivity analysis.'],'Selection required');
                return;
            end
            obj.TemporaryGlobalSensitivityAnalysis.remove('item', DeleteIdx);
            obj.updateGSAItemTable();
            obj.SelectedRow.TaskTable = 0;
            obj.IsDirty = true;
        end
        
        function onAddSensitivityOutput(obj)
            if isempty(obj.TaskPopupTableItems)
                uialert(obj.getUIFigure(), ...
                    ['At least one task and one parameter set must be ', ...
                    'defined in order to add a global sensitivity analysis item.'],...
                    'Cannot Add');
            end
            obj.TemporaryGlobalSensitivityAnalysis.add('item');
            obj.updateGSAItemTable();
            obj.IsDirty = true;
        end

        function onNumberSamplesChange(obj)
            obj.TemporaryGlobalSensitivityAnalysis.NumberSamples = obj.NumberSamplesEditField.Value;
            obj.IsDirty = true;
        end
        
        function onNumberIterationsChange(obj)
            obj.TemporaryGlobalSensitivityAnalysis.NumberIterations = obj.NumberIterationsEditField.Value;
            obj.IsDirty = true;
        end
        
        function onFixRandomSeedChange(obj)
            if obj.FixSeedCheckBox.Value
                obj.TemporaryGlobalSensitivityAnalysis.RandomSeed = obj.SeedEdit.Value;
                obj.SeedLabel.Enable = 'on';
                obj.SeedEdit.Enable  = 'on';
            else
                obj.TemporaryGlobalSensitivityAnalysis.RandomSeed = [];
                obj.SeedLabel.Enable = 'off';
                obj.SeedEdit.Enable  = 'off';
            end
        end
        
        function onSensitivityInputChange(obj)
            obj.TemporaryGlobalSensitivityAnalysis.ParametersName = obj.SensitivityInputsDropDown.Value;
            suggestedSamples = max([1000, 10^numel(obj.TemporaryGlobalSensitivityAnalysis.PlotInputs), ...
                obj.TemporaryGlobalSensitivityAnalysis.NumberSamples]);
            obj.TemporaryGlobalSensitivityAnalysis.NumberSamples = suggestedSamples;
            obj.NumberSamplesEditField.Value = suggestedSamples;
            obj.IsDirty = true;
        end
        
        function onTableSelectionChange(obj, source, eventData)
            % Keep track of selected row in GSA tables
            if source == obj.TaskTable
                % Sensitivity output table
                obj.SelectedRow.TaskTable = eventData.Indices(1);
                obj.updateIterationsTable();
            elseif source == obj.SobolIndexTable
                % Sobol index table for plotting.
                % The first index indicates the user-visible selected row.
                % The second index indicates tha actual selected row of the
                % table.
                obj.SelectedRow.PlotSobolIndexTable = eventData.Indices(1)*[1,1];
                obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), false);
                obj.updatePlotTables();
            else
                % Item (sens. outputs) selection table for plotting
                obj.SelectedRow.PlotItemsTable = eventData.Indices(1);
                obj.updateIterationsTable();
            end
            obj.IsDirty = true;
        end
        
        function onTaskTableEdit(obj,eventData)
            Indices = eventData.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            obj.SelectedRow.TaskTable = RowIdx;
            
            % Update entry if necessary:
            % Map table column header/index to field name in 
            % GlobalSensitivityAnalysis.Item property.
            ColumnToItemProperty = {'Include','TaskName','ParametersName'};
            item = obj.TemporaryGlobalSensitivityAnalysis.Item(RowIdx);
            if ~isequal(item.(ColumnToItemProperty{ColIdx}),eventData.NewData)
                if item.NumberSamples > 0
                    selection = uiconfirm(obj.getUIFigure(),'Changing the task will delete results.','Change task',...
                        'Icon','warning');
                    if strcmp(selection, 'Cancel')
                        obj.TaskTable.Data{RowIdx, ColIdx} = eventData.PreviousData;
                        return;
                    end
                end
                item.(ColumnToItemProperty{ColIdx}) = eventData.NewData;                
                item.MATFileName = '';
                item.NumberSamples = 0;
                item.Results = [];
                obj.TemporaryGlobalSensitivityAnalysis.updateItem(RowIdx, item);
            end
            
            obj.updateGSAItemTable();
            if ColIdx == 2
                obj.updateIterationsTable();
            end
            obj.IsDirty = true;
        end
        
        function onResultsPath(obj, resultsPath)
            obj.TemporaryGlobalSensitivityAnalysis.ResultsFolderName = resultsPath;
            obj.IsDirty = true;
        end
        
        function setPlotItemColor(obj)
            if obj.SelectedRow.PlotItemsTable > 0
                currentColor = obj.TemporaryGlobalSensitivityAnalysis.Item(obj.SelectedRow.PlotItemsTable).Color;
                newColor = uisetcolor(currentColor);
                if isequal(newColor, currentColor)
                    return;
                end
                obj.TemporaryGlobalSensitivityAnalysis.Item(obj.SelectedRow.PlotItemsTable).Color = newColor;
                stylesTable = obj.PlotItemsTable.StyleConfigurations;
                idx = vertcat(stylesTable.TargetIndex{:});
                updateIdx = find(idx(:,1)==obj.SelectedRow.PlotItemsTable,1);
                removeStyle(obj.PlotItemsTable, updateIdx);
                style = uistyle('BackgroundColor',newColor);
                addStyle(obj.PlotItemsTable,style,'cell',[obj.SelectedRow.PlotItemsTable,2]);
                plotSobolIndices(obj.TemporaryGlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
                obj.updateIterationsTable();
            end
        end
        
        function onVisualizationTableEdit(obj, source, eventData)
            indices = eventData.Indices;
            rowIdx = indices(1,1);
            colIdx = indices(1,2);
            if source == obj.SobolIndexTable
                fieldName = obj.SobolIndexTable.ColumnName{colIdx};
                obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).(fieldName) = eventData.NewData;    
            elseif source == obj.PlotItemsTable
                fieldName = obj.PlotItemsTable.ColumnName{colIdx};
                obj.GlobalSensitivityAnalysis.Item(rowIdx).(fieldName) = eventData.NewData;
            end
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
        end
        
        function onVisualizationModeChange(obj)
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
        end
        
        function onRemoveIteration(obj)
            if isempty(obj.IterationsTable.Data)
                uialert(obj.getUIFigure(),'No iterations available to remove.','No iterations');
                return;
            end
            removeIterationIdx = fliplr(find([obj.IterationsTable.Data{:,1}]));
            if isempty(removeIterationIdx)
                uialert(obj.getUIFigure(),'Mark iterations to be removed before clicking the erase button.','Selection required');
                return;
            end
            obj.TemporaryGlobalSensitivityAnalysis.removeResults(obj.TaskTable.Data{obj.SelectedRow.TaskTable,2}, removeIterationIdx);
            obj.updateIterationsTable();
        end
        
        function onPlotTableButtonPress(obj, src)
            if src == obj.NewSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.add('sobolIndex');
            elseif src == obj.RemoveSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.remove('sobolIndex', obj.SelectedRow.PlotSobolIndexTable(1));
                if statusOk && obj.SelectedRow.PlotSobolIndexTable(1) == size(obj.SobolIndexTable.Data,1)
                    obj.SelectedRow.PlotSobolIndexTable = [0,0];
                    obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, 0, false);
                end
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
            elseif src == obj.MoveUpSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.moveUp(obj.SelectedRow.PlotSobolIndexTable(1));
                if statusOk
                    obj.SelectedRow.PlotSobolIndexTable(1) = obj.SelectedRow.PlotSobolIndexTable(1) - 1;
                    tfRenewTable = obj.SelectedRow.PlotSobolIndexTable(2) > 0;
                    if tfRenewTable
                        obj.SelectedRow.PlotSobolIndexTable(2) = 0;
                    end
                    obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), tfRenewTable);
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
                end
            elseif src == obj.MoveDownSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.moveDown(obj.SelectedRow.PlotSobolIndexTable(1));
                if statusOk
                    obj.SelectedRow.PlotSobolIndexTable(1) = obj.SelectedRow.PlotSobolIndexTable(1) + 1;
                    tfRenewTable = obj.SelectedRow.PlotSobolIndexTable(2) > 0;
                    if tfRenewTable
                        obj.SelectedRow.PlotSobolIndexTable(2) = 0;
                    end
                    obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), tfRenewTable);
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
                end
            end
            if statusOk
                obj.updatePlotTables();
                obj.IsDirty = true;
            else
                uialert(obj.getUIFigure(), message, 'Error')
            end

        end

        function onShowIterationsChange(obj)
            obj.GlobalSensitivityAnalysis.ShowIterations = obj.ShowIterationsCheckBox.Value;
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
        end
    end
    
    methods (Access = public) 

        function Value = getRootDirectory(obj)
            Value = obj.GlobalSensitivityAnalysis.Session.RootDirectory;
        end

        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewGlobalSensitivityAnalysis(obj,NewGlobalSensitivityAnalysis)
            obj.GlobalSensitivityAnalysis = NewGlobalSensitivityAnalysis;
            obj.GlobalSensitivityAnalysis.PlotSettings = getSummary(obj.getPlotSettings());
            obj.TemporaryGlobalSensitivityAnalysis = copy(obj.GlobalSensitivityAnalysis);
           
            for index = 1:obj.MaxNumPlots
               Summary = obj.GlobalSensitivityAnalysis.PlotSettings(index);
               % If Summary is empty (i.e., new node), then use
               % defaults
               if isempty(fieldnames(Summary))
                   Summary = QSP.PlotSettings.getDefaultSummary();
               end
               obj.setPlotSettings(index,fieldnames(Summary),struct2cell(Summary)');
            end
            
            obj.draw();
            obj.onSensitivityInputChange(); % ensure model is in sync with view
            obj.IsDirty = false;
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
        function runModel(obj)
            axs = obj.getPlotArray();
            hold(axs(1),'on');
            cleanupObj = onCleanup(@()hold(axs(1),'off'));
            [StatusOK,Message] = run(obj.GlobalSensitivityAnalysis, obj.getUIFigure, axs(1));
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            end
        end
        
        function drawVisualization(obj)
            
            %DropDown Update
            obj.updatePlotConfig(obj.GlobalSensitivityAnalysis.SelectedPlotLayout);
            
            %Determine if the values are valid
            if ~isempty(obj.GlobalSensitivityAnalysis)
                % Check what items are stale or invalid
                [obj.StaleFlag,obj.ValidFlag] = getStaleItemIndices(obj.GlobalSensitivityAnalysis);
            end
            
%             obj.updateGSAItemTable();
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
            
        end
        
        function refreshVisualization(obj,axIndex)
                        
            obj.updateIterationsTable();
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());

        end
        
        function updateIterationsTable(obj)
            if isempty(obj.TaskTable.Data)
                obj.IterationsTable.Data = cell(0,5);
                return
            elseif obj.SelectedRow.PlotItemsTable(1) == 0
                selectedRow = 1;
            else
                selectedRow = obj.SelectedRow.PlotItemsTable(1);
            end
            [~, itemIdx] = ismember(obj.TaskTable.Data{selectedRow,2}, ...
                {obj.GlobalSensitivityAnalysis.Item.TaskName});
            item = obj.GlobalSensitivityAnalysis.Item(itemIdx);
            obj.IterationsLabel.Text = ['Iterations: ', item.TaskName];
            if isempty(item.Results)
               obj.IterationsLabel.Text = [obj.IterationsLabel.Text, ...
                   ' (no iterations available)'];
                obj.IterationsTable.Data = cell(0,5);
            else
                numResults = numel(item.Results);
                [maxDifference, meanDifference] = obj.GlobalSensitivityAnalysis.getConvergenceStats(itemIdx);
                obj.IterationsTable.Data = [repmat({false}, numResults, 1), ...
                    repmat({' '}, numResults, 1), flipud([maxDifference]), flipud([meanDifference]), ...
                    fliplr(num2cell([item.Results.NumberSamples]))'];
                alphaValues = fliplr(linspace(0.2, 1, numResults));
                removeStyle(obj.IterationsTable);
                for i = 1:numResults
                    iterationColor = alphaValues(i)*item.Color + [1,1,1]*(1-alphaValues(i));
                    style = uistyle('BackgroundColor',iterationColor);
                    addStyle(obj.IterationsTable,style,'cell',[i,2]);
                end
            end
        end
        
        function UpdateBackendPlotSettings(obj)
            obj.GlobalSensitivityAnalysis.PlotSettings = getSummary(obj.getPlotSettings());
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryGlobalSensitivityAnalysis.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryGlobalSensitivityAnalysis.Description= value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInPlotConfig(obj,value)
            obj.GlobalSensitivityAnalysis.SelectedPlotLayout = value;
            obj.updatePlotConfig(value);
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryGlobalSensitivityAnalysis.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryGlobalSensitivityAnalysis.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.GlobalSensitivityAnalysis = copy(obj.TemporaryGlobalSensitivityAnalysis,obj.GlobalSensitivityAnalysis);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.TemporaryGlobalSensitivityAnalysis.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function removeInvalidVisualization(obj)
            obj.updateGSAItemTable();
            obj.updatePlotTables();
        end
           
        function deleteTemporary(obj)
            delete(obj.TemporaryGlobalSensitivityAnalysis)
            obj.TemporaryGlobalSensitivityAnalysis = copy(obj.GlobalSensitivityAnalysis);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryGlobalSensitivityAnalysis.Description);
            obj.updateNameBox(obj.TemporaryGlobalSensitivityAnalysis.Name);
            obj.updateSummary(obj.TemporaryGlobalSensitivityAnalysis.getSummary());
            
            obj.updateResultsDir();
            obj.ResultFolderSelector.RootDirectory = obj.TemporaryGlobalSensitivityAnalysis.Session.RootDirectory;
            
            obj.updateGSAConfiguration();
            obj.updateGSAItemTable();
            obj.updatePlotTables();
            obj.updateIterationsTable();
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryGlobalSensitivityAnalysis,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.GlobalSensitivityAnalysis.Session.GlobalSensitivityAnalysis;
            ixDup = find(strcmp( obj.TemporaryGlobalSensitivityAnalysis.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.GlobalSensitivityAnalysis)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
        function [ValidTF] = isValid(obj)
            [~,Valid] = getStaleItemIndices(obj.GlobalSensitivityAnalysis);
            ValidTF = all(Valid);
        end
        
        function BackEnd = getBackEnd(obj)
            BackEnd = obj.GlobalSensitivityAnalysis;
        end
    end
    
    methods (Access = private)
        
       
        function updateResultsDir(obj)
            obj.ResultFolderSelector.RelativePath = obj.TemporaryGlobalSensitivityAnalysis.ResultsFolderName;
        end
        
        function updateGSAConfiguration(obj)
            
            if isempty(obj.TemporaryGlobalSensitivityAnalysis)
                return;
            end

            obj.NumberSamplesEditField.Value = obj.TemporaryGlobalSensitivityAnalysis.NumberSamples;
            obj.NumberIterationsEditField.Value = obj.TemporaryGlobalSensitivityAnalysis.NumberIterations;

            % Refresh Sensitivity Inputs 
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis)
                parameters = obj.TemporaryGlobalSensitivityAnalysis.Settings.Parameters;
                if isempty(parameters)
                    obj.SensitivityInputsDropDown.Items = {};
                else
                    obj.SensitivityInputsDropDown.Items = {parameters.Name};
                end
            else
                obj.SensitivityInputsDropDown.Items = {};
            end
            if ~isempty(obj.SensitivityInputsDropDown.Items)
                if isempty(obj.TemporaryGlobalSensitivityAnalysis.ParametersName) || ...
                        ~ismember(obj.TemporaryGlobalSensitivityAnalysis.ParametersName, ...
                            obj.SensitivityInputsDropDown.Items)
                    obj.TemporaryGlobalSensitivityAnalysis.ParametersName = ...
                        obj.SensitivityInputsDropDown.Items{1};
                    obj.SensitivityInputsDropDown.Value = ...
                        obj.SensitivityInputsDropDown.Items{1};
                else
                    obj.SensitivityInputsDropDown.Value = ...
                        obj.TemporaryGlobalSensitivityAnalysis.ParametersName;
                end
            else
                obj.TemporaryGlobalSensitivityAnalysis.ParametersName = '';
            end
        end
        
        function updatePlotTables(obj)
            if isempty(obj.GlobalSensitivityAnalysis)
                assert(false, "Internal error: missing temporary GSA object.");
                return
            end
            
            % Sobol indices table
            plot      = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Plot};
            lineStyle = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Style};
            inputs    = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Input};
            output    = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Output};
            type      = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Type};
            tfVariance = ismember(type, {'variance', 'unexpl. frac.'});
            inputs(tfVariance) = {'-'};
            display   = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Display};
            obj.SobolIndexTable.Data = [plot(:),lineStyle(:),inputs(:),output(:), type(:),display(:)];
            if isempty(obj.SobolIndexTable.Data)
                columnWidth = '1x';
            else
                columnWidth = {'fit','fit','auto','auto','fit','auto'};
            end
            columnFormat = obj.SobolIndexTable.ColumnFormat;
            editableTF   = obj.SobolIndexTable.ColumnEditable;
            if isempty(obj.GlobalSensitivityAnalysis.PlotInputs) || ...
                    (obj.SelectedRow.PlotSobolIndexTable(1) > 0 && ...
                    tfVariance(obj.SelectedRow.PlotSobolIndexTable(1)))
                columnFormat{3} = 'char';
                editableTF(3) = false;
            else
                columnFormat{3} = obj.GlobalSensitivityAnalysis.PlotInputs';
                editableTF(3) = true;
            end
            if isempty(obj.GlobalSensitivityAnalysis.PlotOutputs)
                columnFormat{4} = 'char';
                editableTF(4) = false;
            else
                columnFormat{4} = obj.GlobalSensitivityAnalysis.PlotOutputs';
                editableTF(4) = true;
            end
            obj.SobolIndexTable.ColumnWidth = columnWidth;
            obj.SobolIndexTable.ColumnFormat = columnFormat;
            obj.SobolIndexTable.ColumnEditable = editableTF;

            % Task selection table
            include         = {obj.GlobalSensitivityAnalysis.Item.Include};
            taskNames       = {obj.GlobalSensitivityAnalysis.Item.TaskName};
            taskColor       = {obj.GlobalSensitivityAnalysis.Item.Color};
            taskDescription = {obj.GlobalSensitivityAnalysis.Item.Description};
            removeStyle(obj.PlotItemsTable)
            obj.PlotItemsTable.Data = [include(:),repmat({' '},numel(taskNames),1),taskNames(:),taskDescription(:)];
            for i = 1:numel(taskNames)
                style = uistyle('BackgroundColor',taskColor{i});
                addStyle(obj.PlotItemsTable,style,'cell',[i,2]);
            end
        end
        
        function updateGSAItemTable(obj)
            
            % Find the correct set of values for the in-table popup menus
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis)
                ValidItemTasks = getValidSelectedTasks(obj.TemporaryGlobalSensitivityAnalysis.Settings,...
                    {obj.TemporaryGlobalSensitivityAnalysis.Settings.Task.Name});
                if ~isempty(ValidItemTasks)
                    obj.TaskPopupTableItems = {ValidItemTasks.Name};
                else
                    obj.TaskPopupTableItems = {};
                end
            else
                obj.TaskPopupTableItems = 'char';
            end

            
            %Find the correct Data to be stored
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis) 
                
                TaskNames       = {obj.TemporaryGlobalSensitivityAnalysis.Item.TaskName};
                NumberSamples   = {obj.TemporaryGlobalSensitivityAnalysis.Item.NumberSamples};
                Include         = {obj.TemporaryGlobalSensitivityAnalysis.Item.Include};
                Data = [Include(:), TaskNames(:), NumberSamples(:)];

                % Mark any invalid entries
                if ~isempty(Data)
                    % Task
                    MatchIdx = find(~ismember(TaskNames(:),obj.TaskPopupTableItems(:)));
                    for index = MatchIdx(:)'
                        Data{index,2} = QSP.makeInvalid(Data{index,2});
                    end        
                end
            else
                Data = {};
            end
            
            %First, reset the data
            obj.TaskTable.Data = Data;
            s = uistyle('Fontcolor', [0.75,0.75,0.75]);
            addStyle(obj.TaskTable,s,'column',3)
            
            %Then, reset the pop up options.
            %New uitable API cannot handle empty lists for table dropdowns.
            %Instead, we need to set the format to char.
            columnFormat = {'logical',obj.TaskPopupTableItems,'numeric'};
            editableTF = [true,true,false];
            if isempty(columnFormat{2})
                columnFormat{2} = 'char';
                editableTF(2) = false;
            end
            obj.TaskTable.ColumnFormat = columnFormat;
            obj.TaskTable.ColumnEditable = editableTF;
        end
        
        function mode = getPlotMode(obj)
           [~, mode] = ismember(obj.PlotModeDropDown.Value,obj.PlotModeDropDown.Items);
        end
        
        function tbl = selectRow(~, tbl, rowIdx, resetSelection)
            if resetSelection
                tmp = tbl;
                tbl = copy(tbl);
                tbl.Parent = tmp.Parent;
                tbl.CellEditCallback = tmp.CellEditCallback;
                tbl.CellSelectionCallback = tmp.CellSelectionCallback;    
                tmp.Visible = 'off';
                tmp.Parent = [];
                drawnow;
            end
            removeStyle(tbl);
            if rowIdx > 0 && rowIdx <= size(tbl.Data, 1)
                alpha = 0.1;
                blue = [0,0.447,0.741];
                style = uistyle('BackgroundColor', blue*alpha + [1,1,1]*(1-alpha));
                addStyle(tbl, style, 'row', rowIdx);
            end
        end
        
    end
end

