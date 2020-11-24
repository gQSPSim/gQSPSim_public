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
        
        SelectedRow = struct('GSAItemsTable', 0, ...
                             'PlotItemsTable', 0);
                         
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
        RNGSeedLabel                matlab.ui.control.Label
        RNGSeedEdit                 matlab.ui.control.NumericEditField
        SensitivityInputsDropDown   matlab.ui.control.DropDown
        SensitivityInputsLabel      matlab.ui.control.Label
        GSAItemLabel                matlab.ui.control.Label
        GSAItemGrid                 matlab.ui.container.GridLayout
        GSAItemButtonGrid           matlab.ui.container.GridLayout
        NewButton                   matlab.ui.control.Button
        RemoveButton                matlab.ui.control.Button
        GSAItemsTable               matlab.ui.control.Table
        
        PlotGrid                    matlab.ui.container.GridLayout
        PlotModeLabel               matlab.ui.control.Label
        PlotModeDropDown            matlab.ui.control.DropDown
        FirstOrderLabel             matlab.ui.control.Label
        FirstOrderTable             matlab.ui.control.Table
        TotalOrderLabel             matlab.ui.control.Label
        TotalOrderTable             matlab.ui.control.Table
        PlotItemsGrid               matlab.ui.container.GridLayout
        SelectColorGrid             matlab.ui.container.GridLayout
        SelectColorButton           matlab.ui.control.Button
        PlotItemsLabel              matlab.ui.control.Label
        PlotItemsTable              matlab.ui.control.Table
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
            % Edit layout
            obj.EditGrid = uigridlayout(obj.getEditGrid());
            obj.EditGrid.ColumnWidth = {'1x'};
            obj.EditGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,'1x'};
            obj.EditGrid.Layout.Row = 3;
            obj.EditGrid.Layout.Column = 1;
            obj.EditGrid.Padding = obj.WidgetPadding;
            obj.EditGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.EditGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            % Results path selector
            obj.ResultFolderSelector = QSPViewerNew.Widgets.FolderSelector(obj.EditGrid,1,1,'Results Path');
            
            % Sampling configuration grid
            % ---------------------------
            % Sampling method       [         Sobol ]   [ ] Fix seed for random number generation
            % Add number of samples [          1000 ]   RNG Seed          [                 100 ]
            obj.SamplingConfigurationGrid = uigridlayout(obj.EditGrid);
            obj.SamplingConfigurationGrid.ColumnWidth = {1.5*obj.LabelLength,'1x',1.25*obj.LabelLength,'1x'};
            obj.SamplingConfigurationGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight};
            obj.SamplingConfigurationGrid.Layout.Row = [2,4];
            obj.SamplingConfigurationGrid.Layout.Column = 1;
            obj.SamplingConfigurationGrid.Padding = obj.WidgetPadding;
            obj.SamplingConfigurationGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.SamplingConfigurationGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            % Number of samples label
            obj.NumberSamplesLabel = uilabel(obj.SamplingConfigurationGrid);
            obj.NumberSamplesLabel.Layout.Column = 1;
            obj.NumberSamplesLabel.Layout.Row = 1;
            obj.NumberSamplesLabel.Text = 'Add number of samples';

            % Number of samples numeric edit field
            obj.NumberSamplesEditField = uieditfield(obj.SamplingConfigurationGrid, 'numeric');
            obj.NumberSamplesEditField.Layout.Column = 2;
            obj.NumberSamplesEditField.Layout.Row = 1;
            obj.NumberSamplesEditField.Limits = [0,Inf];
            obj.NumberSamplesEditField.RoundFractionalValues = true;
            obj.NumberSamplesEditField.ValueChangedFcn = @(h,e)obj.onNumberSamplesChange();            
            
            % Number of iterations label
            obj.NumberIterationsLabel = uilabel(obj.SamplingConfigurationGrid);
            obj.NumberIterationsLabel.Layout.Column = 3;
            obj.NumberIterationsLabel.Layout.Row = 1;
            obj.NumberIterationsLabel.Text = 'Number of iterations';

            % Number of iterations edit field
            obj.NumberIterationsEditField = uieditfield(obj.SamplingConfigurationGrid, 'numeric');
            obj.NumberIterationsEditField.Layout.Column = 4;
            obj.NumberIterationsEditField.Layout.Row = 1;
            obj.NumberIterationsEditField.Limits = [1,Inf];
            obj.NumberIterationsEditField.RoundFractionalValues = true;
            obj.NumberIterationsEditField.ValueChangedFcn = @(h,e)obj.onNumberIterationsChange();            

            % FixSeed checkbox
            obj.FixSeedCheckBox = uicheckbox(obj.SamplingConfigurationGrid);
            obj.FixSeedCheckBox.Text = "Fix seed for random number generation";
            obj.FixSeedCheckBox.Layout.Column = [1,2];
            obj.FixSeedCheckBox.Layout.Row = 2;
            obj.FixSeedCheckBox.Visible = 'off';
            obj.FixSeedCheckBox.Enable = 'on';
            obj.FixSeedCheckBox.Value = false;
            obj.FixSeedCheckBox.ValueChangedFcn = @(h,e)obj.onFixRandomSeedChange();
            
            % RNG seed label
            obj.RNGSeedLabel = uilabel(obj.SamplingConfigurationGrid);
            obj.RNGSeedLabel.Text = 'RNG Seed';
            obj.RNGSeedLabel.Layout.Row = 2;
            obj.RNGSeedLabel.Layout.Column = 3;
            obj.RNGSeedLabel.Visible = 'off';
            obj.RNGSeedLabel.Enable = 'off';
            
            % RNG Seed numeric edit field
            obj.RNGSeedEdit = uieditfield(obj.SamplingConfigurationGrid,'numeric');
            obj.RNGSeedEdit.Layout.Row = 2;
            obj.RNGSeedEdit.Layout.Column = 4;
            obj.RNGSeedEdit.Limits = [0,Inf];
            obj.RNGSeedEdit.RoundFractionalValues = true;
            obj.RNGSeedEdit.Visible  = 'off';
            obj.RNGSeedEdit.Enable  = 'off';
            
            % Sensitivity inputs label
            obj.SensitivityInputsLabel = uilabel(obj.SamplingConfigurationGrid);
            obj.SensitivityInputsLabel.Layout.Column = 1;
            obj.SensitivityInputsLabel.Layout.Row = 3;
            obj.SensitivityInputsLabel.Text = 'Sensitivity inputs';
            
            % Sensitivity inputs drop down
            obj.SensitivityInputsDropDown = uidropdown(obj.SamplingConfigurationGrid);
            obj.SensitivityInputsDropDown.Layout.Column = [2,4];
            obj.SensitivityInputsDropDown.Layout.Row = 3;
            obj.SensitivityInputsDropDown.Items = {'foo', 'bar'};
            obj.SensitivityInputsDropDown.ValueChangedFcn = @(h,e)obj.onSensitivityInputChange();            
            
            % Global sensitivity analysis items label
            obj.GSAItemLabel = uilabel(obj.EditGrid);
            obj.GSAItemLabel.Layout.Row = 5;
            obj.GSAItemLabel.Layout.Column = 1;
            obj.GSAItemLabel.Text = 'Global Sensitivity Analysis Items';
            obj.GSAItemLabel.FontWeight = 'bold';
            
            % Select global sensitivity analysis items
            obj.GSAItemGrid = uigridlayout(obj.EditGrid);
            obj.GSAItemGrid.ColumnWidth = {obj.ButtonWidth,'1x'};
            obj.GSAItemGrid.RowHeight = {'1x'};
            obj.GSAItemGrid.Layout.Row = 6;
            obj.GSAItemGrid.Layout.Column = 1;
            obj.GSAItemGrid.Padding = [0,0,0,0];
            obj.GSAItemGrid.RowSpacing = 0;
            obj.GSAItemGrid.ColumnSpacing = 0;
            
            % Global sensitivity analysis item select buttons grid
            obj.GSAItemButtonGrid = uigridlayout(obj.GSAItemGrid);
            obj.GSAItemButtonGrid.ColumnWidth = {'1x'};
            obj.GSAItemButtonGrid.RowHeight = {obj.ButtonHeight,obj.ButtonHeight};
            obj.GSAItemButtonGrid.Layout.Row = 1;
            obj.GSAItemButtonGrid.Layout.Column = 1;
            obj.GSAItemButtonGrid.Padding = [0,0,0,0];
            obj.GSAItemButtonGrid.RowSpacing = 0;
            obj.GSAItemButtonGrid.ColumnSpacing = 0;
            
            % New/add button
            obj.NewButton = uibutton(obj.GSAItemButtonGrid,'push');
            obj.NewButton.Layout.Row = 1;
            obj.NewButton.Layout.Column = 1;
            obj.NewButton.Icon = QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.NewButton.Text = '';
            obj.NewButton.ButtonPushedFcn = @(h,e)obj.onAddGSAItem();
            
            % Remove button
            obj.RemoveButton = uibutton(obj.GSAItemButtonGrid,'push');
            obj.RemoveButton.Layout.Row = 2;
            obj.RemoveButton.Layout.Column = 1;
            obj.RemoveButton.Icon = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveButton.Text = '';
            obj.RemoveButton.ButtonPushedFcn = @(h,e)obj.onRemoveGSAItem();
           
            % Items table 
            obj.GSAItemsTable = uitable(obj.GSAItemGrid);
            obj.GSAItemsTable.Layout.Row = 1;
            obj.GSAItemsTable.Layout.Column = 2;
            obj.GSAItemsTable.Data = {[],[],[],[]};
            obj.GSAItemsTable.ColumnName = {'Include','Task','Number of Samples'};
            obj.GSAItemsTable.ColumnFormat = {'logical',obj.TaskPopupTableItems,'numeric'};
            obj.GSAItemsTable.ColumnEditable = [true,true,false];
            obj.GSAItemsTable.ColumnWidth = {'fit', 'auto', 'fit'};
            obj.GSAItemsTable.CellEditCallback = @(h,e) obj.onGSAItemsTableSelectionEdit(e);
            obj.GSAItemsTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);
           
            %VisualizationPanel Items
            obj.PlotGrid = uigridlayout(obj.getVisualizationGrid());
            obj.PlotGrid.Layout.Row = 2;
            obj.PlotGrid.Layout.Column = 1;
            obj.PlotGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,'1x',obj.WidgetHeight,'1x',obj.WidgetHeight,'1x',0};
            obj.PlotGrid.ColumnWidth = {obj.LabelLength,'1x'};
            
            % Sampling method label
            obj.PlotModeLabel = uilabel(obj.PlotGrid);
            obj.PlotModeLabel.Layout.Column = 1;
            obj.PlotModeLabel.Layout.Row = 1;
            obj.PlotModeLabel.Text = 'Mode';

            % Sampling method drop down
            obj.PlotModeDropDown = uidropdown(obj.PlotGrid);
            obj.PlotModeDropDown.Layout.Column = 2;
            obj.PlotModeDropDown.Layout.Row = 1;
            obj.PlotModeDropDown.Items = {'Time course','Bar plot (mean)','Bar plot (median)','Bar plot (max)','Bar plot (min)'};
            obj.PlotModeDropDown.ValueChangedFcn = @(h,e)obj.onVisualizationModeChange();
            
            % Input/output table label for first order indices
            obj.FirstOrderLabel = uilabel(obj.PlotGrid);
            obj.FirstOrderLabel.Layout.Row = 2;
            obj.FirstOrderLabel.Layout.Column = [1,2];
            obj.FirstOrderLabel.Text = 'First order Sobol indices';
            obj.FirstOrderLabel.FontWeight = 'bold';
            
            % Input/output table for first order indices
            obj.FirstOrderTable = uitable(obj.PlotGrid);
            obj.FirstOrderTable.Layout.Row = 3;
            obj.FirstOrderTable.Layout.Column = [1,2];
            obj.FirstOrderTable.Data = cell(0,5);
            obj.FirstOrderTable.ColumnName = {'Plot','Line style','Input','Output','Display'};
            obj.FirstOrderTable.ColumnFormat = {obj.PlotNumber,obj.LineStyles,'char','char','char'};
            obj.FirstOrderTable.ColumnEditable = [true,true,true,true,true];
            obj.FirstOrderTable.ColumnWidth = '1x';
            obj.FirstOrderTable.CellEditCallback = @(h,e) obj.onVisualizationTableSelectionEdit(h,e);

            % Input/output table label for total order indices
            obj.TotalOrderLabel = uilabel(obj.PlotGrid);
            obj.TotalOrderLabel.Layout.Row = 4;
            obj.TotalOrderLabel.Layout.Column = [1,2];
            obj.TotalOrderLabel.Text = 'Total order Sobol indices';
            obj.TotalOrderLabel.FontWeight = 'bold';
            
            % Input/output table for total order indices
            obj.TotalOrderTable = uitable(obj.PlotGrid);
            obj.TotalOrderTable.Layout.Row = 5;
            obj.TotalOrderTable.Layout.Column = [1,2];
            obj.TotalOrderTable.Data = cell(0,5);
            obj.TotalOrderTable.ColumnName = {'Plot','Line style','Input','Output','Display'};
            obj.TotalOrderTable.ColumnFormat = {obj.PlotNumber,obj.LineStyles,'char', 'char','char'};
            obj.TotalOrderTable.ColumnEditable = [true,true,true,true,true];
            obj.TotalOrderTable.ColumnWidth = '1x';
            obj.TotalOrderTable.CellEditCallback = @(h,e) obj.onVisualizationTableSelectionEdit(h,e);
            
            % Task selection label for visualization
            obj.PlotItemsLabel = uilabel(obj.PlotGrid);
            obj.PlotItemsLabel.Layout.Row = 6;
            obj.PlotItemsLabel.Layout.Column = [1,2];
            obj.PlotItemsLabel.Text = 'Task selection';
            obj.PlotItemsLabel.FontWeight = 'bold';
            
            % Select global sensitivity analysis items
            obj.PlotItemsGrid = uigridlayout(obj.PlotGrid);
            obj.PlotItemsGrid.ColumnWidth = {obj.ButtonWidth,'1x'};
            obj.PlotItemsGrid.RowHeight = {'1x'};
            obj.PlotItemsGrid.Layout.Row = 7;
            obj.PlotItemsGrid.Layout.Column = [1,2];
            obj.PlotItemsGrid.Padding = [0,0,0,0];
            obj.PlotItemsGrid.RowSpacing = 0;
            obj.PlotItemsGrid.ColumnSpacing = 0;
            
            % Color selection button grid
            obj.SelectColorGrid = uigridlayout(obj.PlotItemsGrid);
            obj.SelectColorGrid.ColumnWidth = {'1x'};
            obj.SelectColorGrid.RowHeight = {obj.ButtonHeight};
            obj.SelectColorGrid.Layout.Row = 1;
            obj.SelectColorGrid.Layout.Column = 1;
            obj.SelectColorGrid.Padding = [0,0,0,0];
            obj.SelectColorGrid.RowSpacing = 0;
            obj.SelectColorGrid.ColumnSpacing = 0;
            
            % Color selection button
            obj.SelectColorButton = uibutton(obj.SelectColorGrid,'push');
            obj.SelectColorButton.Layout.Row = 1;
            obj.SelectColorButton.Layout.Column = 1;
            obj.SelectColorButton.Icon = QSPViewerNew.Resources.LoadResourcePath('fillColor_24.png');
            obj.SelectColorButton.Text = '';
            obj.SelectColorButton.ButtonPushedFcn = @(h,e)obj.setPlotItemColor();
            
            % Task selection table for visualization
            obj.PlotItemsTable = uitable(obj.PlotItemsGrid);
            obj.PlotItemsTable.Layout.Row = 1;
            obj.PlotItemsTable.Layout.Column = 2;
            obj.PlotItemsTable.Data = cell(0,4);
            obj.PlotItemsTable.ColumnName = {'Include','Color','Task','Description'};
            obj.PlotItemsTable.ColumnFormat = {'logical','char','char'};
            obj.PlotItemsTable.ColumnEditable = [true,false,false,true];
            obj.PlotItemsTable.ColumnWidth = {'fit','fit','auto','auto'};
            obj.PlotItemsTable.CellEditCallback = @(h,e) obj.onVisualizationTableSelectionEdit(h,e);
            obj.PlotItemsTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(h,e);
            

        end
        
        function createListenersAndCallbacks(obj)
            obj.ResultFolderListener = addlistener(obj.ResultFolderSelector,'StateChanged',@(src,event) obj.onResultsPath(event.Source.getRelativePath()));
        end
        
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onRemoveGSAItem(obj)
            DeleteIdx = obj.SelectedRow.GSAItemsTable;
            if DeleteIdx~= 0 && DeleteIdx <= numel(obj.TemporaryGlobalSensitivityAnalysis.Item)
                 obj.TemporaryGlobalSensitivityAnalysis.removeItem(DeleteIdx);
            end
            obj.updateGSAItemTable();
            obj.IsDirty = true;
        end
        
        function onAddGSAItem(obj)
            if isempty(obj.TaskPopupTableItems)
                uialert(obj.getUIFigure(),'At least one task and one parameter set must be defined in order to add a global sensitivity analysis item.','Cannot Add');
            end
            NewItem = obj.TemporaryGlobalSensitivityAnalysis.ItemTemplate;
            existingTaskNames = {obj.TemporaryGlobalSensitivityAnalysis.Item.TaskName};
            tfTaskExists = ismember(obj.TaskPopupTableItems, existingTaskNames);
            if all(tfTaskExists)
                uialert(obj.getUIFigure(),'All tasks are already selected. Add more tasks to add them to this sensitivity analysis','Cannot Add');
            end
            nonExistingTaskNames = obj.TaskPopupTableItems(~tfTaskExists);
            NewItem.TaskName = nonExistingTaskNames{1};
            ItemColors = getItemColors(obj.TemporaryGlobalSensitivityAnalysis.Session,...
                numel(obj.TemporaryGlobalSensitivityAnalysis.Item)+1);
            NewItem.Color = ItemColors(end,:);
            NewItem.Description = '';
            obj.TemporaryGlobalSensitivityAnalysis.addItem(NewItem);
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
                obj.TemporaryGlobalSensitivityAnalysis.RandomSeed = obj.RNGSeedEdit.Value;
                obj.RNGSeedLabel.Enable = 'on';
                obj.RNGSeedEdit.Enable  = 'on';
            else
                obj.TemporaryGlobalSensitivityAnalysis.RandomSeed = [];
                obj.RNGSeedLabel.Enable = 'off';
                obj.RNGSeedEdit.Enable  = 'off';
            end
        end
        
        function onSensitivityInputChange(obj)
            obj.TemporaryGlobalSensitivityAnalysis.setParametersName(obj.SensitivityInputsDropDown.Value);
            suggestedSamples = max([1000, 10^numel(obj.TemporaryGlobalSensitivityAnalysis.PlotInputs), ...
                obj.TemporaryGlobalSensitivityAnalysis.NumberSamples]);
            obj.TemporaryGlobalSensitivityAnalysis.NumberSamples = suggestedSamples;
            obj.NumberSamplesEditField.Value = suggestedSamples;
            obj.IsDirty = true;
        end
        
        function onTableSelectionChange(obj,source,eventData)
            if source == obj.GSAItemsTable
                obj.SelectedRow.GSAItemsTable = eventData.Indices(1);
            else
                obj.SelectedRow.PlotItemsTable = eventData.Indices(1);
            end
            obj.IsDirty = true;
        end
        
        function onGSAItemsTableSelectionEdit(obj,eventData)
            Indices = eventData.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            obj.SelectedRow.GSAItemsTable = RowIdx;
            
            % Update entry if necessary:
            % Map table column header/index to field name in 
            % GlobalSensitivityAnalysis.Item property.
            ColumnToItemProperty = {'Include','TaskName','ParametersName'};
            item = obj.TemporaryGlobalSensitivityAnalysis.Item(RowIdx);
            if ~isequal(item.(ColumnToItemProperty{ColIdx}),eventData.NewData)
                item.(ColumnToItemProperty{ColIdx}) = eventData.NewData;                
                item.MATFileName = '';
                item.NumberSamples = 0;
                obj.TemporaryGlobalSensitivityAnalysis.updateItemTable(RowIdx, item);
            end
            
            obj.updateGSAItemTable();
            obj.IsDirty = true;
        end
        
        function onResultsPath(obj,eventData)
            %The backend for the simulation objects seems to have an issue
            %with '' even though other QSP objects can have '' as a
            %relative path for a directory. For simulation, we need to
            %change the value to a 0x1 instead of 0x0 char array.
            if isempty(eventData)
                obj.TemporaryGlobalSensitivityAnalysis.ResultsFolderName = char.empty(1,0);
            else
                obj.TemporaryGlobalSensitivityAnalysis.ResultsFolderName = eventData;
            end
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
                plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
            end
        end
        
        function onVisualizationTableSelectionEdit(obj, source, eventData)
            indices = eventData.Indices;
            rowIdx = indices(1,1);
            colIdx = indices(1,2);
            if source == obj.FirstOrderTable
                obj.GlobalSensitivityAnalysis.PlotFirstOrderInfo(rowIdx, [1,2,3]) = source.Data(rowIdx, [1,2,5]);
            elseif source == obj.TotalOrderTable
                obj.GlobalSensitivityAnalysis.PlotTotalOrderInfo(rowIdx, [1,2,3]) = source.Data(rowIdx, [1,2,5]);
            else
                if colIdx == 1
                    obj.GlobalSensitivityAnalysis.Item(rowIdx).Include = eventData.NewData;
                else
                    obj.GlobalSensitivityAnalysis.Item(rowIdx).Description = eventData.NewData;
                end
            end
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
        end
        
        function onVisualizationModeChange(obj)
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
        end
        
    end
    
    methods (Access = public) 

        function Value = getRootDirectory(obj)
            Value = obj.Simulation.Session.RootDirectory;
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
%             obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());
            
        end
        
        function refreshVisualization(obj,axIndex)
                        
            obj.updateGSAItemTable();
            obj.updatePlotTables();
            plotSobolIndices(obj.GlobalSensitivityAnalysis,obj.getPlotArray(),obj.getPlotMode());

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
            obj.ResultFolderSelector.setRootDirectory(obj.TemporaryGlobalSensitivityAnalysis.Session.RootDirectory);
            
            obj.updateGSAConfiguration();
            obj.updateGSAItemTable();
            obj.updatePlotTables();
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
            obj.ResultFolderSelector.setRelativePath(obj.TemporaryGlobalSensitivityAnalysis.ResultsFolderName);
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
            if isempty(obj.TemporaryGlobalSensitivityAnalysis)
                assert(false, "Internal error: missing temporary GSA object.");
                return
            end
            
            info = obj.TemporaryGlobalSensitivityAnalysis.getPlotInformation();
            
            obj.FirstOrderTable.Data = [info.FirstOrderInfo(:,1:2),info.InputsOutputs,info.FirstOrderInfo(:,3)];
            obj.TotalOrderTable.Data = [info.TotalOrderInfo(:,1:2),info.InputsOutputs,info.TotalOrderInfo(:,3)];
            if isempty(obj.FirstOrderTable.Data)
                obj.TotalOrderTable.ColumnWidth = '1x';
                obj.FirstOrderTable.ColumnWidth = '1x';
            else
                obj.TotalOrderTable.ColumnWidth = {'fit','fit','auto','auto','auto'};
                obj.FirstOrderTable.ColumnWidth = {'fit','fit','auto','auto','auto'};
            end
            
            include         = {obj.TemporaryGlobalSensitivityAnalysis.Item.Include};
            taskNames       = {obj.TemporaryGlobalSensitivityAnalysis.Item.TaskName};
            taskColor       = {obj.TemporaryGlobalSensitivityAnalysis.Item.Color};
            taskDescription = {obj.TemporaryGlobalSensitivityAnalysis.Item.Description};
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
            obj.GSAItemsTable.Data = Data;
            s = uistyle('Fontcolor', [0.75,0.75,0.75]);
            addStyle(obj.GSAItemsTable,s,'column',3)
            
            %Then, reset the pop up options.
            %New uitable API cannot handle empty lists for table dropdowns.
            %Instead, we need to set the format to char.
            [columnFormat,editableTF] = obj.replaceEmptyDropdowns();
            obj.GSAItemsTable.ColumnFormat = columnFormat;
            obj.GSAItemsTable.ColumnEditable = editableTF;
        end
        
        function [columnFormat,editableTF] = replaceEmptyDropdowns(obj)
            columnFormat = {'logical',obj.TaskPopupTableItems,'numeric'};
            editableTF = [true,true,false];
            if isempty(columnFormat{2})
                columnFormat{2} = 'char';
                editableTF(2) = false;
            end
        end
        
        function mode = getPlotMode(obj)
           [~, mode] = ismember(obj.PlotModeDropDown.Value,obj.PlotModeDropDown.Items);
        end
        
    end
end

