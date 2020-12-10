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
        PlotItemsColor = {}
        Types = {'first order', 'total order', 'unexpl. frac.', 'variance'}
        Modes = {'time course', 'bar plot', 'convergence'}
        SummaryTypes = {'mean', 'median', 'max', 'min'}
        
        SelectedRow = struct('TaskTable', [0,0], ...         % selected [row, column]
                             'PlotItemsTable', 0, ...        % selected column
                             'PlotSobolIndexTable', [0,0])   % selected row in [displayed, ui-] table
                         
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
        StoppingCriterionGrid       matlab.ui.container.GridLayout
        StoppingCriterionLabel      matlab.ui.control.Label
        StoppingCriterionEditField matlab.ui.control.NumericEditField
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
        RemoveTaskButton            matlab.ui.control.Button
        PropagateTaskValueButton    matlab.ui.control.Button
        TaskTable                   matlab.ui.control.Table
        
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
        IterationsLabel             matlab.ui.control.Label
        IterationsTable             matlab.ui.control.Table
        IterationsTableContextMenu  matlab.ui.container.ContextMenu
        IterationsTableMenu         matlab.ui.container.Menu
        
        
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
                                          obj.WidgetHeight, ...        % sensitivity inputs
                                          obj.WidgetHeight, ...        % random number seed
                                          obj.WidgetHeight, '1x', ...  % task selection table
                                          obj.WidgetHeight};           % tolerance for convergence
            obj.EditGrid.Layout.Row    = 3;
            obj.EditGrid.Layout.Column = 1;
            obj.EditGrid.Padding       = obj.WidgetPadding;
            obj.EditGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.EditGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            % Results path selector
            obj.ResultFolderSelector = QSPViewerNew.Widgets.FolderSelector(obj.EditGrid,1,1,'Results Path');
            
            % Sampling configuration grid
            obj.SamplingConfigurationGrid               = uigridlayout(obj.EditGrid);
            obj.SamplingConfigurationGrid.ColumnWidth   = {2.00*obj.LabelLength, 2.00*obj.LabelLength, obj.LabelLength, '1x'};     
            obj.SamplingConfigurationGrid.RowHeight     = {obj.WidgetHeight, ... % sensitivity inputs
                                                           obj.WidgetHeight};    % random seed
            obj.SamplingConfigurationGrid.Layout.Row    = [2,3];
            obj.SamplingConfigurationGrid.Layout.Column = 1;
            obj.SamplingConfigurationGrid.Padding       = obj.WidgetPadding;
            obj.SamplingConfigurationGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.SamplingConfigurationGrid.ColumnSpacing = 0;

            % Sensitivity inputs 
            obj.SensitivityInputsLabel               = uilabel(obj.SamplingConfigurationGrid);
            obj.SensitivityInputsLabel.Layout.Column = 1;
            obj.SensitivityInputsLabel.Layout.Row    = 1;
            obj.SensitivityInputsLabel.Text          = 'Sensitivity inputs';
            obj.SensitivityInputsDropDown                 = uidropdown(obj.SamplingConfigurationGrid);
            obj.SensitivityInputsDropDown.Layout.Column   = [2,4];
            obj.SensitivityInputsDropDown.Layout.Row      = 1;
            obj.SensitivityInputsDropDown.Items           = {'foo', 'bar'};
            obj.SensitivityInputsDropDown.ValueChangedFcn = @(h,e)obj.onSensitivityInputChange();            
            
            % Random seed configuration
            % checkbox
            obj.FixSeedCheckBox                 = uicheckbox(obj.SamplingConfigurationGrid);
            obj.FixSeedCheckBox.Text            = "Fix seed for random number generation";
            obj.FixSeedCheckBox.Layout.Column   = [1,2];
            obj.FixSeedCheckBox.Layout.Row      = 2;
            obj.FixSeedCheckBox.Enable          = 'on';
            obj.FixSeedCheckBox.Value           = false;
            obj.FixSeedCheckBox.ValueChangedFcn = @(h,e)obj.onFixRandomSeedChange();
            % label
            obj.SeedLabel               = uilabel(obj.SamplingConfigurationGrid);
            obj.SeedLabel.Text          = 'RNG Seed';
            obj.SeedLabel.Layout.Row    = 2;
            obj.SeedLabel.Layout.Column = 3;
            obj.SeedLabel.Enable        = 'off';
            % edit field
            obj.SeedEdit                       = uieditfield(obj.SamplingConfigurationGrid,'numeric');
            obj.SeedEdit.Layout.Row            = 2;
            obj.SeedEdit.Layout.Column         = 4;
            obj.SeedEdit.Limits                = [0,Inf];
            obj.SeedEdit.RoundFractionalValues = true;
            obj.SeedEdit.Enable                = 'off';
            
            % Table for task selection for sensitivity outputs
            obj.TaskLabel               = uilabel(obj.EditGrid);
            obj.TaskLabel.Layout.Row    = 4;
            obj.TaskLabel.Layout.Column = 1;
            obj.TaskLabel.Text          = 'Global Sensitivity Analysis Items';
            obj.TaskLabel.FontWeight    = 'bold';
            obj.TaskGrid               = uigridlayout(obj.EditGrid);
            obj.TaskGrid.ColumnWidth   = {obj.ButtonWidth,'1x'};
            obj.TaskGrid.RowHeight     = {'1x'};
            obj.TaskGrid.Layout.Row    = 5;
            obj.TaskGrid.Layout.Column = 1;
            obj.TaskGrid.Padding       = [0,0,0,0];
            obj.TaskGrid.RowSpacing    = 0;
            obj.TaskGrid.ColumnSpacing = 0;
            % buttons
            obj.TaskButtonGrid = uigridlayout(obj.TaskGrid);
            obj.TaskButtonGrid.ColumnWidth = {'1x'};
            obj.TaskButtonGrid.RowHeight = {obj.ButtonHeight, ... % add
                                            obj.ButtonHeight, ... % remove
                                            obj.ButtonHeight};    % propagate value
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
            obj.NewTaskButton.Tooltip         = 'Add new sensitivity outputs';
            obj.NewTaskButton.ButtonPushedFcn = @(h,e)obj.onAddSensitivityOutput();
            % remove task
            obj.RemoveTaskButton                 = uibutton(obj.TaskButtonGrid,'push');
            obj.RemoveTaskButton.Layout.Row      = 2;
            obj.RemoveTaskButton.Layout.Column   = 1;
            obj.RemoveTaskButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveTaskButton.Text            = '';
            obj.RemoveTaskButton.Tooltip         = 'Remove selected sensitivity outputs';
            obj.RemoveTaskButton.ButtonPushedFcn = @(h,e)obj.onRemoveSensitivityOutput();
            % remove task
            obj.PropagateTaskValueButton                 = uibutton(obj.TaskButtonGrid,'push');
            obj.PropagateTaskValueButton.Layout.Row      = 3;
            obj.PropagateTaskValueButton.Layout.Column   = 1;
            obj.PropagateTaskValueButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('labelerCustomReader_24.png');
            obj.PropagateTaskValueButton.Text            = '';
            obj.PropagateTaskValueButton.Tooltip         = 'Propagate selected value to all sensitivity outputs';
            obj.PropagateTaskValueButton.ButtonPushedFcn = @(h,e)obj.onPropagateSensitivityOutputValue();
            
            % task table
            obj.TaskTable                       = uitable(obj.TaskGrid);
            obj.TaskTable.Layout.Row            = 1;
            obj.TaskTable.Layout.Column         = 2;
            obj.TaskTable.Data                  = cell(0,4);
            obj.TaskTable.ColumnName            = {'Task', 'Samples Per Iteration', 'Iterations', 'Total Samples'};
            obj.TaskTable.ColumnFormat          = {obj.TaskPopupTableItems,'numeric','numeric','numeric'};
            obj.TaskTable.ColumnEditable        = [true,true,true,false];
            obj.TaskTable.ColumnWidth           = {'auto', 'fit', 'fit','fit'};
            obj.TaskTable.CellEditCallback      = @(h,e) obj.onTaskTableEdit(e);
            obj.TaskTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);
            s = uistyle;
            s.FontColor = [0.75, 0.75, 0.75];
            addStyle(obj.TaskTable, s, 'column', 4);
            
            % Stopping criterion
            obj.StoppingCriterionGrid               = uigridlayout(obj.EditGrid);
            obj.StoppingCriterionGrid.ColumnWidth   = {'1x', obj.LabelLength};
            obj.StoppingCriterionGrid.RowHeight     = {obj.WidgetHeight};
            obj.StoppingCriterionGrid.Layout.Row    = 6;
            obj.StoppingCriterionGrid.Layout.Column = 1;
            obj.StoppingCriterionGrid.Padding       = obj.WidgetPadding;
            obj.StoppingCriterionGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.StoppingCriterionGrid.ColumnSpacing = 0;
            obj.StoppingCriterionLabel               = uilabel(obj.StoppingCriterionGrid);
            obj.StoppingCriterionLabel.Layout.Column = 1;
            obj.StoppingCriterionLabel.Layout.Row    = 1;
            obj.StoppingCriterionLabel.Text          = 'Stop adding samples if max. difference of Sobol indices between iterations is below';
            obj.StoppingCriterionEditField                 = uieditfield(obj.StoppingCriterionGrid, 'numeric');
            obj.StoppingCriterionEditField.Layout.Column   = 2;
            obj.StoppingCriterionEditField.Layout.Row      = 1;
            obj.StoppingCriterionEditField.Limits          = [0,Inf];
            obj.StoppingCriterionEditField.ValueChangedFcn = @(h,e)obj.onStoppingCriterionChange(e);   

            %% Plot panel
            obj.PlotGrid               = uigridlayout(obj.getVisualizationGrid());
            obj.PlotGrid.Layout.Row    = 2;
            obj.PlotGrid.Layout.Column = 1;
            obj.PlotGrid.RowHeight     = {obj.WidgetHeight, '2x', ...  % Sobol index table
                                          obj.WidgetHeight, ...        % summary mode
                                          obj.WidgetHeight, '1x', ...  % task selection table
                                          obj.WidgetHeight, '1x', ...  % iterations table
                                          obj.WidgetHeight};           % show iterations checkbox
            obj.PlotGrid.ColumnWidth   = {'1x', obj.LabelLength};
            
            % Table for selecting Sobol indices for plotting
            obj.SobolIndexLabel               = uilabel(obj.PlotGrid);
            obj.SobolIndexLabel.Layout.Row    = 1;
            obj.SobolIndexLabel.Layout.Column = [1,2];
            obj.SobolIndexLabel.Text          = 'Results';
            obj.SobolIndexLabel.FontWeight    = 'bold';
            obj.SobolIndexGrid               = uigridlayout(obj.PlotGrid);
            obj.SobolIndexGrid.ColumnWidth   = {obj.ButtonWidth,'1x'};
            obj.SobolIndexGrid.RowHeight     = {'1x'};
            obj.SobolIndexGrid.Layout.Row    = 2;
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
            obj.SobolIndexTable.Data                  = cell(0,7);
            obj.SobolIndexTable.ColumnName            = {'Plot','Style','Input','Output','Type','Mode','Display'};
            obj.SobolIndexTable.ColumnFormat          = {obj.PlotNumber,obj.LineStyles, ...
                                                         obj.TaskPopupTableItems,obj.TaskPopupTableItems, ...
                                                         obj.Types, obj.Modes,'char'};
            obj.SobolIndexTable.ColumnEditable        = [true,true,true,true,true,true,true];
            obj.SobolIndexTable.ColumnWidth           = '1x';
            obj.SobolIndexTable.SelectionHighlight    = 'off';
            obj.SobolIndexTable.CellEditCallback      = @(h,e) obj.onVisualizationTableEdit(h,e);
            obj.SobolIndexTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);

            % Summary mode for bar and convergence plots
            obj.PlotModeLabel               = uilabel(obj.PlotGrid);
            obj.PlotModeLabel.Layout.Column = 1;
            obj.PlotModeLabel.Layout.Row    = 3;
            obj.PlotModeLabel.Text          = 'Summary of time courses for bar and convergence plots';
            obj.PlotModeDropDown                 = uidropdown(obj.PlotGrid);
            obj.PlotModeDropDown.Layout.Column   = 2;
            obj.PlotModeDropDown.Layout.Row      = 3;
            obj.PlotModeDropDown.Items           = obj.SummaryTypes;
            obj.PlotModeDropDown.ValueChangedFcn = @(h,e)obj.onVisualizationModeChange();
            
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
            obj.IterationsTable                = uitable(obj.PlotGrid);
            obj.IterationsTable.Layout.Row     = 7;
            obj.IterationsTable.Layout.Column  = [1,2];
            obj.IterationsTable.Data           = {[],[],[]};
            obj.IterationsTable.ColumnName     = {'Maximum of maximal difference between Sobol indices', 'Samples'};
            obj.IterationsTable.ColumnFormat   = {'char','numeric'};
            obj.IterationsTable.ColumnEditable = [false,false];
            obj.IterationsTable.ColumnWidth    = {'fit','auto'};
            
            obj.IterationsTableContextMenu = uicontextmenu(obj.getUIFigure());
            obj.IterationsTableMenu = uimenu(obj.IterationsTableContextMenu);
            obj.IterationsTableMenu.Label = 'Plot iterations';
            obj.IterationsTableMenu.MenuSelectedFcn = @(h,e)obj.onIterationsTableContextMenu(h,e);
            obj.IterationsTable.ContextMenu = obj.IterationsTableContextMenu;

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
            DeleteIdx = obj.SelectedRow.TaskTable(1);
            if DeleteIdx == 0
                uialert(obj.getUIFigure(), ...
                    ['Select a task to remove the corresponding ', ...
                     'global sensitivity analysis.'],'Selection required');
                return;
            end
            obj.TemporaryGlobalSensitivityAnalysis.remove('item', DeleteIdx);
            obj.updateTaskTable();
            obj.SelectedRow.TaskTable = [0, 0];
            obj.IsDirty = true;
        end
        
        function onAddSensitivityOutput(obj)
            if isempty(obj.TaskPopupTableItems)
                uialert(obj.getUIFigure(), ...
                    'At least one task must be defined in order to add a global sensitivity analysis item.',...
                    'Cannot Add');
                return;
            end
            obj.TemporaryGlobalSensitivityAnalysis.add('item');
            obj.updateTaskTable();
            obj.IsDirty = true;
        end

        function onPropagateSensitivityOutputValue(obj)
            if isempty(obj.TaskPopupTableItems) || ...
                    obj.SelectedRow.TaskTable(2) == 1 || ...
                    obj.SelectedRow.TaskTable(2) == 4
                uialert(obj.getUIFigure(), ...
                    sprintf('Select a value in the column ''%s'' or ''%s'' to propagate it to all tasks.',...
                    obj.TaskTable.ColumnName{2}, obj.TaskTable.ColumnName{3}), 'Cannot propagate value');
                return;
            end
            if obj.SelectedRow.TaskTable(2) == 2
                property = 'Samples';
            else
                property = 'Iterations';
            end
            obj.TemporaryGlobalSensitivityAnalysis.propagateValue(property, obj.SelectedRow.TaskTable(1));
            obj.updateTaskTable();
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
            obj.IsDirty = true;
        end
        
        function onTableSelectionChange(obj, source, eventData)
            % Keep track of selected row in GSA tables
            if source == obj.TaskTable
                % Sensitivity output table
                obj.SelectedRow.TaskTable = eventData.Indices;
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
                assert(false, "Is this assertion ever hit?");
                return;
            end
            
            rowIdx = Indices(1,1);
            colIdx = Indices(1,2);
            
            obj.SelectedRow.TaskTable = Indices;
            
            % Update item:
            item = obj.TemporaryGlobalSensitivityAnalysis.Item(rowIdx);
            
            switch colIdx
                case 1 % Task
                    if isequal(item.TaskName,eventData.NewData)
                        return;
                    end
                    if item.NumberSamples > 0
                        selection = uiconfirm(obj.getUIFigure(), ...
                            'Changing the task will delete results.','Change task',...
                            'Icon','warning');
                        if strcmp(selection, 'Cancel')
                            obj.TaskTable.Data{rowIdx, colIdx} = eventData.PreviousData;
                            return;
                        end
                    end
                    obj.TemporaryGlobalSensitivityAnalysis.removeResultsFromItem(rowIdx);
                    item.TaskName = eventData.NewData;  
                case 2 % Samples per iteration
                    if eventData.NewData < 0 || ~isfinite(eventData.NewData)
                        uialert(obj.getUIFigure(),'Specify a non-negative number of samples.','Invalid input');
                        obj.TaskTable.Data{rowIdx, colIdx} = eventData.PreviousData;
                        return;
                    end
                    item.IterationInfo(1) = ceil(eventData.NewData);
                    obj.TaskTable.Data{rowIdx, colIdx} = item.IterationInfo(1);
                case 3 % Number of iterations
                    if eventData.NewData < 0 || ~isfinite(eventData.NewData)
                        uialert(obj.getUIFigure(),'Specify a non-negative number of iterations.','Invalid input');
                        obj.TaskTable.Data{rowIdx, colIdx} = eventData.PreviousData;
                        return;
                    end
                    item.IterationInfo(2) = ceil(eventData.NewData);
                    obj.TaskTable.Data{rowIdx, colIdx} = item.IterationInfo(2);
            end
            
            obj.TemporaryGlobalSensitivityAnalysis.updateItem(rowIdx, item);
            
            obj.updateTaskTable();
            obj.IsDirty = true;
        end
        
        function onStoppingCriterionChange(obj, eventData)
            if ~isfinite(eventData.Value)
                uialert(obj.getUIFigure(),'Specify a finite, non-nan value for the stopping criterion.','Invalid input');
                obj.StoppingCriterionEditField.Value = eventData.PreviousValue;
                return;
            end
            obj.TemporaryGlobalSensitivityAnalysis.StoppingTolerance = eventData.Value;
        end
        
        function onResultsPath(obj, resultsPath)
            obj.TemporaryGlobalSensitivityAnalysis.ResultsFolder = resultsPath;
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
                plotSobolIndices(obj.TemporaryGlobalSensitivityAnalysis,obj.getPlotArray());
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
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());
        end
        
        function onVisualizationModeChange(obj)
            obj.GlobalSensitivityAnalysis.SummaryType = obj.PlotModeDropDown.Value;
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());
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
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());
            elseif src == obj.MoveUpSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.moveUp(obj.SelectedRow.PlotSobolIndexTable(1));
                if statusOk
                    obj.SelectedRow.PlotSobolIndexTable(1) = obj.SelectedRow.PlotSobolIndexTable(1) - 1;
                    tfRenewTable = obj.SelectedRow.PlotSobolIndexTable(2) > 0;
                    if tfRenewTable
                        obj.SelectedRow.PlotSobolIndexTable(2) = 0;
                    end
                    obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), tfRenewTable);
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());
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
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());
                end
            end
            if statusOk
                obj.updatePlotTables();
                obj.IsDirty = true;
            else
                uialert(obj.getUIFigure(), message, 'Error')
            end

        end
        
        function onIterationsTableContextMenu(obj,~,~)
            if isempty(obj.IterationsTable.Data)
                return;
            elseif obj.SelectedRow.PlotItemsTable(1) == 0
                selectedRow = 1;
            else
                selectedRow = obj.SelectedRow.PlotItemsTable(1);
            end
            if numel(obj.TemporaryGlobalSensitivityAnalysis.Item(selectedRow).Results) < 2
                return;
            end
            
            [numSamples, maxDifferences] = obj.GlobalSensitivityAnalysis.getConvergenceStats(selectedRow);
            modalWindow = QSPViewerNew.Widgets.GlobalSensitivityAnalysisProgress(sprintf('Showing %s', ...
                obj.GlobalSensitivityAnalysis.Item(selectedRow).TaskName));
            modalWindow.open(obj.getUIFigure());
            modalWindow.customizeButton('Close', 'Close window', @()delete(modalWindow));
            modalWindow.reset(obj.GlobalSensitivityAnalysis.StoppingTolerance, obj.GlobalSensitivityAnalysis.Item(selectedRow).Color);
            messages = cell(1,7);
            messages{1} = sprintf('Task: %s', obj.GlobalSensitivityAnalysis.Item(selectedRow).TaskName);
            messages{2} = '';
            messages{3} = sprintf('Available iterations: %d', numel(numSamples));
            messages{4} = sprintf('Total number of samples: %d', obj.GlobalSensitivityAnalysis.Item(selectedRow).NumberSamples);
            messages{5} = '';
            messages{6} = '';
            messages{7} = '';
            modalWindow.update(messages, numSamples, maxDifferences);
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
            
%             obj.updateTaskTable();
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());
            
        end
        
        function refreshVisualization(obj,axIndex)
                        
            obj.updateIterationsTable();
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray());

        end
        
        function updateIterationsTable(obj)
            if isempty(obj.TaskTable.Data)
                obj.IterationsTable.Data = cell(0,2);
                return
            elseif obj.SelectedRow.PlotItemsTable(1) == 0
                selectedRow = 1;
            else
                selectedRow = obj.SelectedRow.PlotItemsTable(1);
            end
            item = obj.TemporaryGlobalSensitivityAnalysis.Item(selectedRow);
            obj.IterationsLabel.Text = ['Iterations: ', item.TaskName];
            if isempty(item.Results)
               obj.IterationsLabel.Text = [obj.IterationsLabel.Text, ...
                   ' (no iterations available)'];
                obj.IterationsTable.Data = cell(0,2);
            else
                [numSamples, maxDifferences] = obj.TemporaryGlobalSensitivityAnalysis.getConvergenceStats(selectedRow);
                maxDifferences = num2cell(maxDifferences);
                for i = 1:numel(maxDifferences)
                    if isnan(maxDifferences{i})
                        maxDifferences{i} = '-';
                    else
                        maxDifferences{i} = num2str(maxDifferences{i});
                    end
                end
                obj.IterationsTable.Data = [maxDifferences, num2cell(numSamples)];
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
            obj.updateTaskTable();
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
            
            obj.StoppingCriterionEditField.Value   = obj.TemporaryGlobalSensitivityAnalysis.StoppingTolerance;
            
            obj.updateGSAConfiguration();
            obj.updateTaskTable();
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
            obj.ResultFolderSelector.RelativePath = obj.TemporaryGlobalSensitivityAnalysis.ResultsFolder;
        end
        
        function updateGSAConfiguration(obj)
            
            if isempty(obj.TemporaryGlobalSensitivityAnalysis)
                return;
            end

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
            mode      = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Mode};
            tfVariance = ismember(type, {'variance', 'unexpl. frac.'});
            inputs(tfVariance) = {'-'};
            display   = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Display};
            obj.SobolIndexTable.Data = [plot(:),lineStyle(:),inputs(:),output(:),type(:),mode(:),display(:)];
            if isempty(obj.SobolIndexTable.Data)
                columnWidth = '1x';
            else
                columnWidth = {'fit','fit','auto','auto','fit','fit','auto'};
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
        
        function updateTaskTable(obj)
            
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
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis.Item) 
                
                iterationInfo         = vertcat(obj.TemporaryGlobalSensitivityAnalysis.Item.IterationInfo);
                ExistingNumberSamples = vertcat(obj.TemporaryGlobalSensitivityAnalysis.Item.NumberSamples);
                AddNumberSamples      = ExistingNumberSamples + iterationInfo(:,1).*iterationInfo(:,2);
                TaskNames             = {obj.TemporaryGlobalSensitivityAnalysis.Item.TaskName}';
                TotalSamples          = cellfun(@(i,j) sprintf('%d/%d', i, j), ...
                    num2cell(ExistingNumberSamples), num2cell(AddNumberSamples), 'UniformOutput', false);
                
                Data = [TaskNames, num2cell(iterationInfo), TotalSamples];

                % Mark any invalid entries
                if ~isempty(Data)
                    % Task
                    MatchIdx = find(~ismember(TaskNames(:),obj.TaskPopupTableItems(:)));
                    for index = MatchIdx(:)'
                        Data{index,1} = QSP.makeInvalid(Data{index,2});
                    end        
                end
            else
                Data = cell(0,4);
            end
            
            %First, reset the data
            obj.TaskTable.Data = Data;
            
            %Then, reset the pop up options.
            %New uitable API cannot handle empty lists for table dropdowns.
            %Instead, we need to set the format to char.
            columnFormat = {obj.TaskPopupTableItems,'numeric','numeric','numeric'};
            editableTF = [true,true,true,false];
            if isempty(columnFormat{1})
                columnFormat{1} = 'char';
                editableTF(1) = false;
            end
            obj.TaskTable.ColumnFormat = columnFormat;
            obj.TaskTable.ColumnEditable = editableTF;
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

