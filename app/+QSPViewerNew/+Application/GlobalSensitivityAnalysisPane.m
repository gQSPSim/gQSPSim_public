classdef GlobalSensitivityAnalysisPane < QSPViewerNew.Application.ViewPane
    %  GlobalSensitivityAnalysisPane - A Class for the Global Sensitivity
    %  Analysis Pane view. This is the 'viewer' counterpart to the 'model'
    %  class QSP.GlobalSensitivityAnalysis


    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        GlobalSensitivityAnalysis          = QSP.GlobalSensitivityAnalysis.empty()
        TemporaryGlobalSensitivityAnalysis = QSP.GlobalSensitivityAnalysis.empty()
        IsDirty = false
    end

    properties (Access=private)

        SensitivityOutputs  = {}
        LineStyles          = {'-','--','-.',':'}
        MarkerStyles        = {'d','o','s','*','+','v','^','<','>','p','h'}
        PlotNumber          = {' ','1','2','3','4','5','6','7','8','9','10','11','12'}
        Types               = {'first order', 'total order', 'unexpl. frac.', 'variance'}
        ExtendedTypes       = {'first order', 'total order', 'unexpl. frac.', 'variance', 'worst case Sobol index'}
        Modes               = {'time course', 'bar plot', 'convergence', 'limit value'}
        Metric              = {'mean', 'median', 'max', 'min'}

        SelectedRow = struct('TaskTable', [0,0], ...         % selected [row, column]
            'PlotItemsTable', 0, ...        % selected column
            'PlotSobolIndexTable', [0,0])   % selected row in [displayed, ui-] table

        StaleFlag
        ValidFlag

        PlotSelectionCallback
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
        SensitivityInputsGrid       matlab.ui.container.GridLayout
        SeedConfigurationGrid       matlab.ui.container.GridLayout
        StoppingCriterionGrid       matlab.ui.container.GridLayout
        StoppingCriterionLabel      matlab.ui.control.Label
        StoppingCriterionEditField  matlab.ui.control.NumericEditField
        SeedSubLayout               matlab.ui.container.GridLayout
        FixSeedLabel                matlab.ui.control.Label
        FixSeedCheckBox             matlab.ui.control.CheckBox
        SeedLabel                   matlab.ui.control.Label
        SeedEdit                    matlab.ui.control.NumericEditField
        SensitivityInputsValueLabel matlab.ui.control.Label
        SensitivityInputsButton     matlab.ui.control.Button
        SensitivityInputsLabel      matlab.ui.control.Label

        % Table for task selection for sensitivity outputs
        TaskLabel                   matlab.ui.control.Label
        TaskGrid                    matlab.ui.container.GridLayout
        TaskButtonGrid              matlab.ui.container.GridLayout
        NewTaskButton               matlab.ui.control.Button
        RemoveTaskButton            matlab.ui.control.Button
        PropagateTaskValueButton    matlab.ui.control.Button
        DuplicateRowButton          matlab.ui.control.Button
        TaskTable                   matlab.ui.control.Table
        TaskTableContextMenu        matlab.ui.container.ContextMenu
        TaskTableMenu               matlab.ui.container.Menu

        %% Plot panel
        PlotGrid                    matlab.ui.container.GridLayout
        PlotModeLabel               matlab.ui.control.Label
        PlotModeDropDown            matlab.ui.control.DropDown
        PlotConvergenceLineCheckBox matlab.ui.control.CheckBox

        % Table for selecting Sobol indices for plotting
        SobolIndexLabel             matlab.ui.control.Label
        SobolIndexGrid              matlab.ui.container.GridLayout
        SobolIndexButtonGrid        matlab.ui.container.GridLayout
        NewSobolIndexButton         matlab.ui.control.Button
        EditSobolIndexButton        matlab.ui.control.Button
        DuplicateSobolIndexButton   matlab.ui.control.Button
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

    % public property to be set by the pop-up dialog
    properties
        SelectedNodePath
    end

    properties(Constant)
        ButtonWidth = 30;
        ButtonHeight = 30;
    end

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = GlobalSensitivityAnalysisPane(pvargs)
            arguments
                pvargs.Parent (1,1) matlab.ui.container.GridLayout
                pvargs.layoutrow (1,1) double = 1
                pvargs.layoutcolumn (1,1) double = 1
                pvargs.parentApp
                pvargs.HasVisualization (1,1) logical = true
            end

            args = namedargs2cell(pvargs);
            obj = obj@QSPViewerNew.Application.ViewPane(args{:});
            obj.create();
            obj.createListenersAndCallbacks();
            obj.PlotSelectionCallback = @(src,~)obj.lineSelectionCallback(src);
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

            % Sensitivity inputs grid
            obj.SensitivityInputsGrid = uigridlayout(obj.EditGrid);
            obj.SensitivityInputsGrid.ColumnWidth   = {2.00*obj.LabelLength, 2.00*obj.LabelLength, '1x', obj.ButtonWidth};
            obj.SensitivityInputsGrid.RowHeight     = {obj.WidgetHeight}; % sensitivity inputs
            obj.SensitivityInputsGrid.Layout.Row    = 2;
            obj.SensitivityInputsGrid.Layout.Column = 1;
            obj.SensitivityInputsGrid.Padding       = obj.WidgetPadding;
            obj.SensitivityInputsGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.SensitivityInputsGrid.ColumnSpacing = 0;

            % Sensitivity inputs
            obj.SensitivityInputsLabel               = uilabel(obj.SensitivityInputsGrid);
            obj.SensitivityInputsLabel.Layout.Column = 1;
            obj.SensitivityInputsLabel.Layout.Row    = 1;
            obj.SensitivityInputsLabel.Text          = 'Sensitivity inputs';
            obj.SensitivityInputsValueLabel                 = uilabel(obj.SensitivityInputsGrid);
            obj.SensitivityInputsValueLabel.Layout.Column   = 2;
            obj.SensitivityInputsValueLabel.Layout.Row      = 1;
            obj.SensitivityInputsValueLabel.Text            = '';
            obj.SensitivityInputsButton                 = uibutton(obj.SensitivityInputsGrid);
            obj.SensitivityInputsButton.Layout.Column   = 4;
            obj.SensitivityInputsButton.Layout.Row      = 1;
            obj.SensitivityInputsButton.Text            = '...';
            obj.SensitivityInputsButton.ButtonPushedFcn = @(h,e)obj.onSensitivityInputButtonPushed();

            % Random seed configuration grid
            obj.SeedConfigurationGrid               = uigridlayout(obj.EditGrid);
            obj.SeedConfigurationGrid.ColumnWidth   = {2.00*obj.LabelLength, 2.00*obj.LabelLength, obj.LabelLength, '1x'};
            obj.SeedConfigurationGrid.RowHeight     = {obj.WidgetHeight};    % random seed
            obj.SeedConfigurationGrid.Layout.Row    = 3;
            obj.SeedConfigurationGrid.Layout.Column = 1;
            obj.SeedConfigurationGrid.Padding       = obj.WidgetPadding;
            obj.SeedConfigurationGrid.RowSpacing    = obj.WidgetHeightSpacing;
            obj.SeedConfigurationGrid.ColumnSpacing = 0;
            % Random seed configuration
            % checkbox
            obj.FixSeedCheckBox                 = uicheckbox(obj.SeedConfigurationGrid);
            obj.FixSeedCheckBox.Text            = "Fix seed for random number generation";
            obj.FixSeedCheckBox.Layout.Column   = [1,2];
            obj.FixSeedCheckBox.Layout.Row      = 1;
            obj.FixSeedCheckBox.Enable          = 'on';
            obj.FixSeedCheckBox.Value           = false;
            obj.FixSeedCheckBox.ValueChangedFcn = @(h,e)obj.onFixRandomSeedChange();
            % label
            obj.SeedLabel               = uilabel(obj.SeedConfigurationGrid);
            obj.SeedLabel.Text          = 'RNG Seed';
            obj.SeedLabel.Layout.Row    = 1;
            obj.SeedLabel.Layout.Column = 3;
            obj.SeedLabel.Enable        = 'off';
            % edit field
            obj.SeedEdit                       = uieditfield(obj.SeedConfigurationGrid,'numeric');
            obj.SeedEdit.Layout.Row            = 1;
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
                obj.ButtonHeight, ... % propagate value
                obj.ButtonHeight};    % duplicate row
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
            % duplicate row task table
            obj.DuplicateRowButton                 = uibutton(obj.TaskButtonGrid,'push');
            obj.DuplicateRowButton.Layout.Row      = 4;
            obj.DuplicateRowButton.Layout.Column   = 1;
            obj.DuplicateRowButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('copy_24.png');
            obj.DuplicateRowButton.Text            = '';
            obj.DuplicateRowButton.Tooltip         = 'Duplicate the selected row';
            obj.DuplicateRowButton.ButtonPushedFcn = @(h,e)obj.onDuplicateRowTaskTable();

            % task table
            obj.TaskTable                       = uitable(obj.TaskGrid, 'ColumnSortable', true);
            obj.TaskTable.Layout.Row            = 1;
            obj.TaskTable.Layout.Column         = 2;
            obj.TaskTable.Data                  = cell(0,4);
            obj.TaskTable.ColumnName            = {'Task', 'Samples Per Iteration', 'Iterations', 'Total Samples'};
            obj.TaskTable.ColumnFormat          = {'char','numeric','numeric','numeric'};
            obj.TaskTable.ColumnEditable        = [true,true,true,false];
            obj.TaskTable.ColumnWidth           = {'auto', 'auto', 'auto','auto'};
            obj.TaskTable.CellEditCallback      = @(h,e) obj.onTaskTableEdit(e);
            obj.TaskTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);
            s = uistyle;
            s.FontColor = [0.75, 0.75, 0.75];
            addStyle(obj.TaskTable, s, 'column', 4);

            % value propagation context menu
            obj.TaskTableContextMenu = uicontextmenu(obj.getUIFigure());
            obj.TaskTableMenu = uimenu(obj.TaskTableContextMenu);
            obj.TaskTableMenu.Label = sprintf('Select a value in the column ''%s'' or ''%s'' to propagate it to all tasks.',...
                obj.TaskTable.ColumnName{2}, obj.TaskTable.ColumnName{3});
            obj.TaskTableMenu.MenuSelectedFcn = @(h,e)obj.onPropagateSensitivityOutputValue();
            obj.TaskTable.ContextMenu = obj.TaskTableContextMenu;

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
                obj.ButtonHeight,... % edit
                obj.ButtonHeight,... % copy
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
            % edit Sobol index to plot
            obj.EditSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.EditSobolIndexButton.Layout.Row      = 2;
            obj.EditSobolIndexButton.Layout.Column   = 1;
            obj.EditSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('edit_24.png');
            obj.EditSobolIndexButton.Text            = '';
            obj.EditSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % copy Sobol index to plot
            obj.DuplicateSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.DuplicateSobolIndexButton.Layout.Row      = 3;
            obj.DuplicateSobolIndexButton.Layout.Column   = 1;
            obj.DuplicateSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('copy_24.png');
            obj.DuplicateSobolIndexButton.Text            = '';
            obj.DuplicateSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % remove Sobol index from plot
            obj.RemoveSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.RemoveSobolIndexButton.Layout.Row      = 4;
            obj.RemoveSobolIndexButton.Layout.Column   = 1;
            obj.RemoveSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveSobolIndexButton.Text            = '';
            obj.RemoveSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % move up Sobol index up
            obj.MoveUpSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.MoveUpSobolIndexButton.Layout.Row      = 5;
            obj.MoveUpSobolIndexButton.Layout.Column   = 1;
            obj.MoveUpSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('arrow_up_24.png');
            obj.MoveUpSobolIndexButton.Text            = '';
            obj.MoveUpSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % move up Sobol index down
            obj.MoveDownSobolIndexButton                 = uibutton(obj.SobolIndexButtonGrid,'push');
            obj.MoveDownSobolIndexButton.Layout.Row      = 6;
            obj.MoveDownSobolIndexButton.Layout.Column   = 1;
            obj.MoveDownSobolIndexButton.Icon            = QSPViewerNew.Resources.LoadResourcePath('arrow_down_24.png');
            obj.MoveDownSobolIndexButton.Text            = '';
            obj.MoveDownSobolIndexButton.ButtonPushedFcn = @(h,e)obj.onPlotTableButtonPress(h);
            % table
            obj.SobolIndexTable                       = uitable(obj.SobolIndexGrid, 'ColumnSortable', true);
            obj.SobolIndexTable.Layout.Row            = 1;
            obj.SobolIndexTable.Layout.Column         = 2;
            obj.SobolIndexTable.Data                  = cell(0,8);
            obj.SobolIndexTable.ColumnName            = {'Plot','Style','Input','Output','Type','Mode','Metric','Display'};
            obj.SobolIndexTable.ColumnFormat          = {obj.PlotNumber, obj.MarkerStyles, 'char', 'char', ...
                obj.Types, obj.Modes, obj.Metric, 'char'};
            obj.SobolIndexTable.ColumnEditable        = [true,true,false,false,true,true,true,true];
            obj.SobolIndexTable.ColumnWidth           = 'auto';
            obj.SobolIndexTable.SelectionHighlight    = 'off';
            obj.SobolIndexTable.CellEditCallback      = @(h,e) obj.onVisualizationTableEdit(h,e);
            obj.SobolIndexTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);

            % Option to show/hide convergence lines
            obj.PlotConvergenceLineCheckBox                 = uicheckbox(obj.PlotGrid);
            obj.PlotConvergenceLineCheckBox.Text            = "Hide termination indicator line in worst case convergence plots (requires metric 'max')";
            obj.PlotConvergenceLineCheckBox.Layout.Column   = [1,2];
            obj.PlotConvergenceLineCheckBox.Layout.Row      = 3;
            obj.PlotConvergenceLineCheckBox.ValueChangedFcn = @(h,e)obj.onHideConvergenceLineChange(e);
            obj.PlotConvergenceLineCheckBox.Enable          = 'off';

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
            obj.PlotItemsTable                       = uitable(obj.PlotItemsGrid, 'ColumnSortable', true);
            obj.PlotItemsTable.Layout.Row            = 1;
            obj.PlotItemsTable.Layout.Column         = 2;
            obj.PlotItemsTable.Data                  = cell(0,4);
            obj.PlotItemsTable.ColumnName            = {'Include','Color','Task','Description'};
            obj.PlotItemsTable.ColumnFormat          = {'logical','char','char'};
            obj.PlotItemsTable.ColumnEditable        = [true,false,false,true];
            obj.PlotItemsTable.ColumnWidth           = {'auto','auto','auto','auto'};
            obj.PlotItemsTable.CellEditCallback      = @(h,e) obj.onVisualizationTableEdit(h,e);
            obj.PlotItemsTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);

            % Table for managing iteration results
            obj.IterationsLabel               = uilabel(obj.PlotGrid);
            obj.IterationsLabel.Layout.Row    = 6;
            obj.IterationsLabel.Layout.Column = [1,2];
            obj.IterationsLabel.Text = 'Iterations: select a task';
            obj.IterationsLabel.FontWeight = 'bold';
            obj.IterationsTable                = uitable(obj.PlotGrid, 'ColumnSortable', true);
            obj.IterationsTable.Layout.Row     = 7;
            obj.IterationsTable.Layout.Column  = [1,2];
            obj.IterationsTable.Data           = {[],[],[]};
            obj.IterationsTable.ColumnName     = {'Maximum of maximal difference between Sobol indices', 'Samples'};
            obj.IterationsTable.ColumnFormat   = {'char','numeric'};
            obj.IterationsTable.ColumnEditable = [false,false];
            obj.IterationsTable.ColumnWidth    = {'auto','auto'};

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
            [statusOk, message] = obj.TemporaryGlobalSensitivityAnalysis.remove('gsaItem', DeleteIdx);
            if ~statusOk
                uialert(obj.getUIFigure(), message, 'Error');
                return;
            end
            obj.updateTaskTable();
            obj.SelectedRow.TaskTable = [0, 0];
            obj.TaskTable = obj.selectRow(obj.TaskTable, obj.SelectedRow.TaskTable(1), true);
            obj.IsDirty = true;
        end

        function onAddSensitivityOutput(obj)
            if isempty(obj.SensitivityOutputs)
                uialert(obj.getUIFigure(), ...
                    'At least one task must be defined in order to add a global sensitivity analysis item.',...
                    'Cannot Add');
                return;
            end
            [statusOk, message] = obj.TemporaryGlobalSensitivityAnalysis.add('gsaItem');
            if ~statusOk
                uialert(obj.getUIFigure(), message, 'Error');
                return;
            end
            obj.updateTaskTable();
            obj.IsDirty = true;
        end

        function onDuplicateRowTaskTable(obj)
            DuplicateIdx = obj.SelectedRow.TaskTable(1);
            if DuplicateIdx == 0
                uialert(obj.getUIFigure(), ...
                    ['Select a row to duplicate the corresponding ', ...
                    'global sensitivity analysis.'],'Selection required');
                return;
            end
            obj.TemporaryGlobalSensitivityAnalysis.duplicate(DuplicateIdx);
            obj.updateTaskTable();
            obj.SelectedRow.TaskTable = [0, 0];
            obj.IsDirty = true;
        end

        function onPropagateSensitivityOutputValue(obj)
            if isempty(obj.SensitivityOutputs) || ...
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
            if any(arrayfun(@(item) item.NumberSamples > 0, obj.GlobalSensitivityAnalysis.Item))
                staleMessage = sprintf(['Global sensitivity analysis results for sensitivity inputs ''%s'' already exist. ', ...
                    'If you change the sensitivity inputs to ''%s'', all existing results will be removed. Do you want to change ', ...
                    'the sensitivity inputs and remove existing results?'], obj.TemporaryGlobalSensitivityAnalysis.ParametersName, ...
                    obj.SensitivityInputsDropDown.Value);
                selection = uiconfirm(obj.getUIFigure, staleMessage, 'Remove results',...
                    'Options', {'Remove', 'Cancel'}, 'DefaultOption', 2, 'CancelOption',2, 'Icon', 'warning');
                if strcmp(selection, 'Cancel')
                    obj.SensitivityInputsDropDown.Value = obj.TemporaryGlobalSensitivityAnalysis.ParametersName;
                    return;
                else
                    for i = 1:numel(obj.TemporaryGlobalSensitivityAnalysis.Item)
                        obj.TemporaryGlobalSensitivityAnalysis.removeResultsFromItem(i);
                    end
                end
            end
            obj.TemporaryGlobalSensitivityAnalysis.ParametersName = obj.SensitivityInputsDropDown.Value;
            obj.IsDirty = true;
        end

        function onTableSelectionChange(obj, source, eventData)
            % Keep track of selected row in GSA tables
            if isempty(eventData.Indices) || ~isvector(eventData.Indices)
                return
            end
            if source == obj.TaskTable
                % Sensitivity output table
                obj.SelectedRow.TaskTable = eventData.Indices;

                % if one of the task cells is selected, bring up the dialog
                if size(obj.SelectedRow.TaskTable,1)==1 && ...
                        obj.SelectedRow.TaskTable(2)==1
                    selectedTaskNode = obj.getSelectionNode("Task");
                    if ~(selectedTaskNode == "" || isempty(selectedTaskNode))
                        obj.TemporaryGlobalSensitivityAnalysis.Item(obj.SelectedRow.TaskTable(1)).TaskName = ...
                            char(selectedTaskNode);
                        obj.updateTaskTable();
                        obj.IsDirty = true;
                    end
                end
            elseif source == obj.SobolIndexTable
                % Sobol index table for plotting.
                % The first index indicates the user-visible selected row.
                % The second index indicates tha actual selected row of the
                % table.
                obj.SelectedRow.PlotSobolIndexTable = eventData.Indices(1)*[1,1];
                obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), false);
                selectPlotItem(obj.GlobalSensitivityAnalysis, obj.SelectedRow.PlotSobolIndexTable(1));
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
                if strcmp(obj.SobolIndexTable.Data{eventData.Indices(1), 6}, 'bar plot')
                    obj.SobolIndexTable.ColumnFormat{2} = obj.MarkerStyles;
                else
                    obj.SobolIndexTable.ColumnFormat{2} = obj.LineStyles;
                end
                if strcmp(obj.SobolIndexTable.Data{eventData.Indices(1), 6}, 'time course')
                    obj.SobolIndexTable.ColumnFormat{7} = 'char';
                else
                    obj.SobolIndexTable.ColumnFormat{7} = obj.Metric;
                end
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
                    obj.updateValuePropagationContextMenuLabel();
                case 3 % Number of iterations
                    if eventData.NewData < 0 || ~isfinite(eventData.NewData)
                        uialert(obj.getUIFigure(),'Specify a non-negative number of iterations.','Invalid input');
                        obj.TaskTable.Data{rowIdx, colIdx} = eventData.PreviousData;
                        return;
                    end
                    item.IterationInfo(2) = ceil(eventData.NewData);
                    obj.TaskTable.Data{rowIdx, colIdx} = item.IterationInfo(2);
                    obj.updateValuePropagationContextMenuLabel();
            end

            [statusOk, message] = obj.TemporaryGlobalSensitivityAnalysis.updateItem(rowIdx, item);
            if ~statusOk
                uialert(obj.getUIFigure(), message, 'Error')
            end

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
                currentColor = obj.GlobalSensitivityAnalysis.Item(obj.SelectedRow.PlotItemsTable).Color;
                newColor = uisetcolor(currentColor);
                if isequal(newColor, currentColor)
                    return;
                end
                obj.GlobalSensitivityAnalysis.Item(obj.SelectedRow.PlotItemsTable).Color = newColor;
                stylesTable = obj.PlotItemsTable.StyleConfigurations;
                idx = vertcat(stylesTable.TargetIndex{:});
                updateIdx = find(idx(:,1)==obj.SelectedRow.PlotItemsTable,1);
                removeStyle(obj.PlotItemsTable, updateIdx);
                style = uistyle('BackgroundColor',newColor);
                addStyle(obj.PlotItemsTable,style,'cell',[obj.SelectedRow.PlotItemsTable,2]);
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
                obj.updateIterationsTable();
            else
                uialert(obj.getUIFigure(),'Specify a finite, non-nan value for the stopping criterion.','Select item');
            end
        end

        function lineSelectionCallback(obj, src)
            % Highlight row in SobolIndexTable that was clicked on in the
            % plots.
            tfSetHightlightInPlot = false;
            for tableIdx = 1:numel(obj.GlobalSensitivityAnalysis.PlotSobolIndex)
                if ismember(src, obj.GlobalSensitivityAnalysis.Plot2TableMap{tableIdx})
                    if ~obj.GlobalSensitivityAnalysis.PlotSobolIndex(tableIdx).Selected
                        obj.SelectedRow.PlotSobolIndexTable(1) = tableIdx;
                        obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), false);
                        selectPlotItem(obj.GlobalSensitivityAnalysis, obj.SelectedRow.PlotSobolIndexTable(1));
                        %                     s = uistyle('FontWeight', 'bold');
                        %                     addStyle(obj.SobolIndexTable, s, 'row', tableIdx);
                        tfSetHightlightInPlot = true;
                    end
                    break;
                end
            end
            if ~tfSetHightlightInPlot
                selectPlotItem(obj.GlobalSensitivityAnalysis, 0);
            end
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
        end

        function onVisualizationTableEdit(obj, source, eventData)
            indices = eventData.Indices;
            rowIdx = indices(1,1);
            colIdx = indices(1,2);
            if source == obj.SobolIndexTable
                fieldName = obj.SobolIndexTable.ColumnName{colIdx};
                if colIdx == 1
                    if ~strcmp(eventData.NewData, ' ')
                        idxSamePlot = find(ismember({obj.GlobalSensitivityAnalysis.PlotSobolIndex.Plot}, ...
                            eventData.NewData), 1);
                        if ~isempty(idxSamePlot)
                            obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).Mode = ...
                                obj.GlobalSensitivityAnalysis.PlotSobolIndex(idxSamePlot).Mode;
                        end
                    end
                    obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).Plot = eventData.NewData;
                elseif colIdx == 2
                    if strcmp(obj.SobolIndexTable.Data{rowIdx, 6}, 'bar plot')
                        styleIdx = 2;
                    else
                        styleIdx = 1;
                    end
                    obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).Style{styleIdx} = eventData.NewData;
                elseif colIdx == 6
                    if strcmp(obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).Plot, ' ')
                        idxSamePlot = rowIdx;
                    else
                        idxSamePlot = find(ismember({obj.GlobalSensitivityAnalysis.PlotSobolIndex.Plot}, ...
                            obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).Plot));
                    end
                    for i = idxSamePlot
                        obj.GlobalSensitivityAnalysis.PlotSobolIndex(i).Mode = eventData.NewData;
                    end
                else
                    obj.GlobalSensitivityAnalysis.PlotSobolIndex(rowIdx).(fieldName) = eventData.NewData;
                end
                tfConvergencePlot = ismember(obj.SobolIndexTable.Data(:, 6), 'convergence');
                if any(tfConvergencePlot) && ismember('max', obj.SobolIndexTable.Data(tfConvergencePlot, 7))
                    obj.PlotConvergenceLineCheckBox.Enable = 'on';
                else
                    obj.PlotConvergenceLineCheckBox.Enable = 'off';
                end
            elseif source == obj.PlotItemsTable
                fieldName = obj.PlotItemsTable.ColumnName{colIdx};
                obj.GlobalSensitivityAnalysis.Item(rowIdx).(fieldName) = eventData.NewData;
            end
            obj.updatePlotTables();
            drawnow;
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
        end

        function onHideConvergenceLineChange(obj, event)
            obj.GlobalSensitivityAnalysis.HideConvergenceLine = event.Value;
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
        end

        function inputOutputPlotSelectionCallback(obj, row, selections)
            % Edit sens. inputs/outputs in table row.
            obj.GlobalSensitivityAnalysis.PlotSobolIndex(row).Inputs = selections{1};
            obj.GlobalSensitivityAnalysis.PlotSobolIndex(row).Outputs = selections{2};

            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
        end

        function onPlotTableButtonPress(obj, src)
            if src == obj.NewSobolIndexButton

                [statusOk, message] = obj.GlobalSensitivityAnalysis.add('plotItem');

                if statusOk
                    row = numel(obj.GlobalSensitivityAnalysis.PlotSobolIndex);
                    options = {obj.GlobalSensitivityAnalysis.PlotInputs; obj.GlobalSensitivityAnalysis.PlotOutputs};
                    selections = {{}; {}};

                    modalWindow = QSPViewerNew.Widgets.MultiDataSelector("Select sensitivity inputs and outputs", ...
                        ["Sensitivity Inputs", "Sensitivity Outputs"], options, selections, @(selections)obj.inputOutputPlotSelectionCallback(row, selections));
                    modalWindow.open(obj.getUIFigure());
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
                end

            elseif src == obj.EditSobolIndexButton

                row = obj.SelectedRow.PlotSobolIndexTable(1);
                options = {obj.GlobalSensitivityAnalysis.PlotInputs; obj.GlobalSensitivityAnalysis.PlotOutputs};
                selections = {obj.GlobalSensitivityAnalysis.PlotSobolIndex(row).Inputs; obj.GlobalSensitivityAnalysis.PlotSobolIndex(row).Outputs};

                modalWindow = QSPViewerNew.Widgets.MultiDataSelector("Select sensitivity inputs and outputs", ...
                    ["Sensitivity Inputs", "Sensitivity Outputs"], options, selections, @(selections)obj.inputOutputPlotSelectionCallback(row, selections));
                modalWindow.open(obj.getUIFigure());
                statusOk = true;

                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
            elseif src == obj.DuplicateSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.duplicate(obj.SelectedRow.PlotSobolIndexTable(1));
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
            elseif src == obj.RemoveSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.remove('plotItem', obj.SelectedRow.PlotSobolIndexTable(1));
                if statusOk && obj.SelectedRow.PlotSobolIndexTable(1) == size(obj.SobolIndexTable.Data,1)
                    obj.SelectedRow.PlotSobolIndexTable = [0,0];
                    obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, 0, false);
                end
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
            elseif src == obj.MoveUpSobolIndexButton
                [statusOk, message] = obj.GlobalSensitivityAnalysis.moveUp(obj.SelectedRow.PlotSobolIndexTable(1));
                if statusOk
                    obj.SelectedRow.PlotSobolIndexTable(1) = obj.SelectedRow.PlotSobolIndexTable(1) - 1;
                    tfRenewTable = obj.SelectedRow.PlotSobolIndexTable(2) > 0;
                    if tfRenewTable
                        obj.SelectedRow.PlotSobolIndexTable(2) = 0;
                    end
                    obj.SobolIndexTable = obj.selectRow(obj.SobolIndexTable, obj.SelectedRow.PlotSobolIndexTable(1), tfRenewTable);
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
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
                    plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
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
            if numel(obj.GlobalSensitivityAnalysis.Item(selectedRow).Results) < 2
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

        function updateValuePropagationContextMenuLabel(obj)
            rowIdx = obj.SelectedRow.TaskTable(1);
            colIdx = obj.SelectedRow.TaskTable(2);
            if colIdx == 2
                colName = 'Samples per Iteration';
            elseif colIdx == 3
                colName = 'Iteration';
            else
                obj.TaskTableMenu.Label = sprintf('Select a value in the column ''%s'' or ''%s'' to propagate it to all tasks.',...
                    obj.TaskTable.ColumnName{2}, obj.TaskTable.ColumnName{3});
                return;
            end
            value = obj.TaskTable.Data{rowIdx, colIdx};
            obj.TaskTableMenu.Label = sprintf('Set column ''%s'' to selected value %g.', colName, value);
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
            succesfulSave = obj.saveBackEndInformation();
            if ~succesfulSave
                message = 'Unable to save configuration.';
                uialert(obj.getUIFigure, message, 'Run Failed', 'Icon', 'error');
                return
            end

            iterationsInfo = vertcat(obj.GlobalSensitivityAnalysis.Item.IterationInfo);
            if all(iterationsInfo(:,1).*iterationsInfo(:,2) == 0)
                message = 'Set number of samples and iteration to be added to a value greater than zero for at least one task.';
                uialert(obj.getUIFigure, message, 'Run Failed', 'Icon', 'info');
                return
            end

            [tfStaleItem, tfValidItem] = obj.GlobalSensitivityAnalysis.getStaleItemIndices();
            tfResultsOutOfDate = tfStaleItem | ~tfValidItem;
            if any(tfResultsOutOfDate)
                staleMessage = ['Running the sensitivity analysis requires removing stale results from', newline];
                for i = 1:numel(tfResultsOutOfDate)
                    if tfResultsOutOfDate(i)
                        staleMessage = sprintf('%s\n - %s', staleMessage, obj.GlobalSensitivityAnalysis.Item(i).TaskName);
                    end
                end
                selection = uiconfirm(obj.getUIFigure, staleMessage, 'Remove results',...
                    'Options', {'Remove', 'Cancel'}, 'DefaultOption', 2, 'CancelOption',2, 'Icon', 'warning');
                if strcmp(selection, 'Cancel')
                    return;
                else
                    for i = 1:numel(tfResultsOutOfDate)
                        if tfResultsOutOfDate(i)
                            obj.GlobalSensitivityAnalysis.removeResultsFromItem(i);
                        end
                    end
                end
            end

            % Open modal window for progress indication
            modalWindow = QSPViewerNew.Widgets.GlobalSensitivityAnalysisProgress(sprintf('Running %s', obj.GlobalSensitivityAnalysis.Name));
            modalWindow.open(obj.getUIFigure());
            onCleanupObj1 = onCleanup(@()delete(modalWindow));

            [StatusOK, Message] = run(obj.GlobalSensitivityAnalysis, ...
                @(tfReset, itemIdx, messages, samples, differences) ...
                obj.runProgressIndicator(modalWindow, tfReset, itemIdx, messages, samples, differences));
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            end
            modalWindow.customizeButton('Close', '', @()delete(modalWindow));
            waitfor(modalWindow);

        end

        function drawVisualization(obj)

            %DropDown Update
            obj.updatePlotConfig(obj.GlobalSensitivityAnalysis.SelectedPlotLayout);

            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);

        end

        function refreshVisualization(obj,axIndex)

            obj.updateIterationsTable();
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);

        end

        function updateIterationsTable(obj)
            % Update iterations table in plot panel

            if isempty(obj.TaskTable.Data)
                % No task available; no iterations to show
                obj.IterationsLabel.Text = 'No iterations available';
                obj.IterationsTable.Data = cell(0,2);
                return
            end
            % Check whose task's iteration should be shown
            if obj.SelectedRow.PlotItemsTable(1) == 0
                selectedRow = 1;
            else
                selectedRow = obj.SelectedRow.PlotItemsTable(1);
            end
            % Update label and data of table:
            obj.IterationsLabel.Text = ['Iterations: ', obj.GlobalSensitivityAnalysis.Item(selectedRow).TaskName];
            if isempty(obj.GlobalSensitivityAnalysis.Item(selectedRow).Results)
                obj.IterationsLabel.Text = [obj.IterationsLabel.Text, ...
                    ' (no iterations available)'];
                obj.IterationsTable.Data = cell(0,2);
            else
                [numSamples, maxDifferences] = obj.GlobalSensitivityAnalysis.getConvergenceStats(selectedRow);
                maxDifferences = arrayfun(@num2str, maxDifferences, 'UniformOutput', false);
                maxDifferences{1} = '-'; % the first difference is reported as NaN
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
            [StatusOK,Message,DuplicateFlag] = obj.TemporaryGlobalSensitivityAnalysis.validate(FlagRemoveInvalid);

            % check if it contains duplicate message
            if DuplicateFlag
                selection = uiconfirm(obj.getUIFigure, ...
                    sprintf("%s\nClick Proceed to Save if you want to continue with duplicates.", Message), ...
                    'Duplicate tasks', ...
                    'Icon', 'warning', ...
                    'Options', {'Proceed to save', 'Cancel'});
                if strcmp(selection, 'Cancel')
                    return;
                else
                    StatusOK = true;
                    Message = [];
                end
            end

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
            FlagRemoveInvalid = false;
            statusOk = validate(obj.GlobalSensitivityAnalysis, FlagRemoveInvalid);
            if ~statusOk
                selection = uiconfirm(obj.getUIFigure(), ...
                    'Removing invalid items will remove computed Sobol indices.','Remove invalid items',...
                    'Icon','warning');
                if strcmp(selection, 'Cancel')
                    return;
                end
                FlagRemoveInvalid = true;
                % Remove the invalid entries
                validate(obj.GlobalSensitivityAnalysis,FlagRemoveInvalid);
                obj.draw();
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.PlotSelectionCallback);
                obj.IsDirty = true;
            end
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
            % todopax.
%             obj.updateParallelButtonSession(obj.TemporaryGlobalSensitivityAnalysis.Session.UseParallel);
%             obj.updateGitButtonSession(obj.TemporaryGlobalSensitivityAnalysis.Session.AutoSaveGit);

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

        function updateSessionParallelOption(obj, parallelOption)
            if strcmp(parallelOption, 'off')
                obj.GlobalSensitivityAnalysis.Session.UseParallel = false;
            elseif strcmp(parallelOption, 'on')
                obj.GlobalSensitivityAnalysis.Session.UseParallel = true;
            end
            notifyOfChange(obj,obj.GlobalSensitivityAnalysis.Session)
        end

        function updateSessionGitOption(obj, gitOption)
            if strcmp(gitOption, 'off')
                obj.GlobalSensitivityAnalysis.Session.AutoSaveGit = false;
            elseif strcmp(gitOption, 'on')
                obj.GlobalSensitivityAnalysis.Session.AutoSaveGit = true;
            end
            notifyOfChange(obj,obj.GlobalSensitivityAnalysis.Session)
        end
    end

    methods (Access = private)

        function updateResultsDir(obj)
            obj.ResultFolderSelector.RelativePath = obj.TemporaryGlobalSensitivityAnalysis.ResultsFolder;
        end

        function updateGSAConfiguration(obj)
            % Update general settings for the Global Sensitivity Analysis
            % in the edit panel.

            if isempty(obj.TemporaryGlobalSensitivityAnalysis)
                return;
            end

            % Refresh Sensitivity Inputs
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis)
                parameters = obj.TemporaryGlobalSensitivityAnalysis.Settings.Parameters;
            end
            if ~isempty(parameters)
                paramNames = {parameters.Name};
                if isempty(obj.TemporaryGlobalSensitivityAnalysis.ParametersName) || ...
                        ~ismember(obj.TemporaryGlobalSensitivityAnalysis.ParametersName, ...
                        paramNames)
                    obj.TemporaryGlobalSensitivityAnalysis.ParametersName = ...
                        paramNames{1};
                    obj.SensitivityInputsValueLabel.Text = ...
                        paramNames{1};
                else
                    obj.SensitivityInputsValueLabel.Text = ...
                        obj.TemporaryGlobalSensitivityAnalysis.ParametersName;
                end
            else
                obj.TemporaryGlobalSensitivityAnalysis.ParametersName = '';
                obj.SensitivityInputsValueLabel.Text = '';
            end
        end

        function updatePlotTables(obj)
            if isempty(obj.GlobalSensitivityAnalysis)
                assert(false, "Internal error: missing temporary GSA object.");
                return
            end

            % Sobol indices table
            plot      = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Plot};
            style     = vertcat(obj.GlobalSensitivityAnalysis.PlotSobolIndex.Style);
            inputs    = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Inputs};
            inputs = cellfun(@(in) strjoin(in, ','), inputs, "UniformOutput", false);
            outputs    = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Outputs};
            outputs = cellfun(@(out) strjoin(out, ','), outputs, "UniformOutput", false);
            type      = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Type};
            mode      = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Mode};
            metric    = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Metric};
            if isempty(style)
                style = cell(0,1);
            else
                tfBarPlot = strcmp(mode, 'bar plot');
                style(tfBarPlot, 1) = style(tfBarPlot, 2);
            end
            style = style(:, 1);
            tfVariance = ismember(type, {'variance', 'unexpl. frac.'});
            inputs(tfVariance) = {'n/a'};
            tfTimeCourse = ismember(mode, {'time course'});
            metric(tfTimeCourse) = {'n/a'};
            display   = {obj.GlobalSensitivityAnalysis.PlotSobolIndex.Display};
            obj.SobolIndexTable.Data = [plot(:),style(:),inputs(:),outputs(:),type(:),mode(:),metric(:),display(:)];

            % Task selection table
            include         = {obj.GlobalSensitivityAnalysis.Item.Include};
            taskNames       = {obj.GlobalSensitivityAnalysis.Item.TaskName};
            taskColor       = {obj.GlobalSensitivityAnalysis.Item.Color};
            taskDescription = {obj.GlobalSensitivityAnalysis.Item.Description};
            colorPlaceholders = repmat({' '},numel(taskNames),1);
            Data = [include(:), colorPlaceholders, taskNames(:), taskDescription(:)];

            % Mark any invalid entries
            invalidIdx = [];
            if ~isempty(Data)
                % Task
                MatchIdx = find(~ismember(taskNames(:),obj.SensitivityOutputs(:)));
                for index = MatchIdx(:)'
                    Data{index,3} = QSP.makeInvalid(Data{index,3});
                    invalidIdx{end+1} = [index,3];
                end
            end
            obj.PlotItemsTable.Data = Data;

            removeStyle(obj.PlotItemsTable)
            for i = 1:numel(taskNames)
                style = uistyle('BackgroundColor', taskColor{i});
                addStyle(obj.PlotItemsTable,style,'cell',[i,2]);
            end

            for i = 1:length(invalidIdx)
                QSP.makeInvalidStyle(obj.PlotItemsTable, invalidIdx{i});
            end
        end

        function updateTaskTable(obj)

            % Find all available tasks (sensitivity outputs)
            ValidItemTasks = getValidSelectedTasks(obj.TemporaryGlobalSensitivityAnalysis.Settings,...
                {obj.TemporaryGlobalSensitivityAnalysis.Settings.Task.Name});
            if isempty(ValidItemTasks)
                obj.SensitivityOutputs = {};
            else
                obj.SensitivityOutputs = {ValidItemTasks.Name};
            end

            % Populate task table with task (sensitivity outputs)
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis.Item)

                iterationInfo         = vertcat(obj.TemporaryGlobalSensitivityAnalysis.Item.IterationInfo);
                existingNumberSamples = vertcat(obj.TemporaryGlobalSensitivityAnalysis.Item.NumberSamples);
                totalNumberSamples    = existingNumberSamples + prod(iterationInfo, 2);
                taskNames             = {obj.TemporaryGlobalSensitivityAnalysis.Item.TaskName}';
                samplesInfo           = arrayfun(@(i,j) sprintf('%d/%d', i, j), ...
                    existingNumberSamples, totalNumberSamples, ...
                    'UniformOutput', false);

                Data = [taskNames, num2cell(iterationInfo), samplesInfo];

                % Mark any invalid entries
                invalidIdx = [];
                if ~isempty(Data)
                    % Task
                    MatchIdx = find(~ismember(taskNames(:),obj.SensitivityOutputs(:)));
                    for index = MatchIdx(:)'
                        if isempty(Data{index,1})
                            Data{index,1} = 'Click to configure';
                        else
                            Data{index,1} = QSP.makeInvalid(Data{index,1});
                            invalidIdx{end+1} = [index,1];
                        end
                    end
                end
            else
                Data = cell(0,4);
            end

            %Reset the data
            obj.TaskTable.Data = Data;

            % add style to any invalid entries
            if ~isempty(obj.TemporaryGlobalSensitivityAnalysis.Item)
                for i = 1:length(invalidIdx)
                    QSP.makeInvalidStyle(obj.TaskTable, invalidIdx{i});
                end
            end

            % Dis-/enable drop down menu for sensitivity outputs if the are
            % empty/nonempty.
            if isempty(obj.SensitivityOutputs)
                obj.TaskTable.ColumnFormat{1}   = 'char';
                obj.TaskTable.ColumnEditable(1) = false;
            else
                obj.TaskTable.ColumnFormat{1}   = obj.SensitivityOutputs;
                obj.TaskTable.ColumnEditable(1) = true;
            end
        end

        function tbl = selectRow(~, tbl, rowIdx, resetSelection)
            % Helper method to manage row selection of tables.
            % PlotSobolIndexTable allows reordering of rows using buttons.
            % This causes the visually selected row to be different than
            % the selected row the uitable keeps track of. Clicking on a
            % row that uitable thinks is selected does not trigger the cell
            % selection callback. To sync the visual row selection with the
            % uitable's row selection, we need to replace the whole uitable
            % if necessary.
            if resetSelection && ~isempty(tbl)
                % Remove selection to force execution of selection callback
                % when the table is clicked on.
                tbl.Selection = [];
                % Reset selection type to prevent table cells to go into
                % edit mode when clicked on a single time after the
                % selection has been reset.
                selectionType = tbl.SelectionType;
                tbl.SelectionType = 'col';
                tbl.SelectionType = selectionType;
                drawnow;
            end
            % Add uistyle to indicate the selected rows
            removeStyle(tbl);
            if rowIdx > 0 && rowIdx <= size(tbl.Data, 1)
                alpha = 0.1;
                blue = [0,0.447,0.741];
                style = uistyle('BackgroundColor', blue*alpha + [1,1,1]*(1-alpha));
                addStyle(tbl, style, 'row', rowIdx);
            end
        end

        function selectedNode = getSelectionNode(obj, type)
            % get session node for this object
            currentNode = obj.TemporaryGlobalSensitivityAnalysis.TreeNode;
            sessionNode = currentNode.Parent;
            while ~strcmp(sessionNode.Tag, 'Session')
                sessionNode = sessionNode.Parent;
            end

            % get parent task node
            allChildrenTag = string({sessionNode.Children.Tag});
            buildingBlockNode = sessionNode.Children(allChildrenTag=="Building blocks");
            buildBlockChildrenTag = string({buildingBlockNode.Children.Tag});
            parentTypeNode = buildingBlockNode.Children(buildBlockChildrenTag==type);

            % launch tree selection node dialog for user's input
            if verLessThan('matlab','9.9')
                nodeSelDialog = QSPViewerNew.Widgets.TreeNodeSelectionModalDialog (obj, ...
                    parentTypeNode, ...
                    'ParentAppPosition', sessionNode.Parent.Parent.Parent.Parent.Parent.Position, ...
                    'DialogName', sprintf('Select %s node', parentTypeNode.Text), ...
                    'ModalOn', false, ...
                    'NodeType', "Other");
            else % Modal UI figures are supported >= 20b
                nodeSelDialog = QSPViewerNew.Widgets.TreeNodeSelectionModalDialog (obj, ...
                    parentTypeNode, ...
                    'ParentAppPosition', sessionNode.Parent.Parent.Parent.Parent.Parent.Position, ...
                    'DialogName', sprintf('Select %s node', parentTypeNode.Text), ...
                    'NodeType', "Other");
            end

            uiwait(nodeSelDialog.MainFigure);

            selectedNode = split(obj.SelectedNodePath, filesep);
            selectedNode  = selectedNode(1);
        end

        function tfStopRequested = runProgressIndicator(obj, modalWindow, tfReset, itemIdx, message, samples, data)
            % Usage: progress indicator is a modal window that is open
            % during the computation of GSA results. The modal window can
            % be reset (tfReset == true) to clear plots when switching from
            % on task item to another. The modal window can be updated
            % (tfReset == false) to show new messages and data-vs-samples
            % plots to indicate the progress in the computation.
            if tfReset
                modalWindow.reset(obj.GlobalSensitivityAnalysis.StoppingTolerance, ...
                    obj.GlobalSensitivityAnalysis.Item(itemIdx).Color);
            else
                modalWindow.update(message, samples, data);
                tfStopRequested = modalWindow.isStopRequested();
            end
        end
    end
end
