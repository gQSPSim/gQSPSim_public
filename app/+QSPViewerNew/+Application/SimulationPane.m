classdef SimulationPane < QSPViewerNew.Application.ViewPane
    %  SimulationPane - A Class for the Virtual Population Generation Data Pane view. This is the
    %  'viewer' counterpart to the 'model' class
    %  QSP.Simulation
    %
    %
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        Simulation = QSP.Simulation.empty()
        TemporarySimulation = QSP.Simulation.empty()
        IsDirty = false
    end

    properties (Access = private)
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}

        DatasetHeader = {}
        DatasetHeaderPopupItems = {'-'}
        DatasetHeaderPopupItemsWithInvalid = {'-'}

        TaskPopupTableItems = {'yellow','blue'}
        VPopPopupTableItems = {'yellow','blue'}

        PlotSpeciesAsInvalidTable = cell(0,2)
        PlotItemAsInvalidTable = cell(0,4)
        PlotDataAsInvalidTable = cell(0,2)
        PlotGroupAsInvalidTable = cell(0,3)

        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []
        PlotDataInvalidRowIndices = []
        PlotGroupInvalidRowIndices = []

        SelectedRow =0;
        SelectedCol=0;

        SelectedGroup
        SelectedData
        SelectedSimItem
        SelectedSpecies
        StaleFlag
        ValidFlag
    end

    properties
        SelectedNodePath
    end

    properties(Constant)
        ButtonWidth = 30;
        ButtonHeight = 30;
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
    properties(Access = private)
        SimulationEditGrid          matlab.ui.container.GridLayout
        ResultFolderSelector        QSPViewerNew.Widgets.FolderSelector
        DatasetGrid                 matlab.ui.container.GridLayout
        DatasetSelectionLabel       matlab.ui.control.Label
        DatasetLabel                matlab.ui.control.Label
        DatasetSelectionButton      matlab.ui.control.Button
        GroupColumnGrid             matlab.ui.container.GridLayout
        GroupColumnDropDown         matlab.ui.control.DropDown
        GroupColumnLabel            matlab.ui.control.Label
        SimItemLabelGrid            matlab.ui.container.GridLayout
        SimItemLabel                matlab.ui.control.Label
        SimItemGrid                 matlab.ui.container.GridLayout
        SimButtonGrid               matlab.ui.container.GridLayout
        NewButton                   matlab.ui.control.Button
        RemoveButton                matlab.ui.control.Button
        DuplicateButton             matlab.ui.control.Button
        SimItemsTable               matlab.ui.control.Table
        SimItemsTableContextMenu    matlab.ui.container.ContextMenu
        ApplyToAllMenu              matlab.ui.container.Menu
        SimulationVisualizationGrid matlab.ui.container.GridLayout
        SpeciesLabel                matlab.ui.control.Label
        SpeciesTable                matlab.ui.control.Table
        SimulationItemsLabel        matlab.ui.control.Label
        SimulationItemsTable        matlab.ui.control.Table
        DataLabel                   matlab.ui.control.Label
        DataTable                   matlab.ui.control.Table
        GroupLabel                  matlab.ui.control.Label
        GroupTable                  matlab.ui.control.Table
        PlotItemsTableContextMenu
        PlotGroupTableContextMenu
        PlotItemsTableMenu
        PlotGroupTableMenu
    end

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = SimulationPane(pvargs)
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
        end
    end

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function create(obj)
            %Edit Layout
            obj.SimulationEditGrid = uigridlayout(obj.getEditGrid());
            obj.SimulationEditGrid.ColumnWidth = {'1x'};
            obj.SimulationEditGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,'1x'};
            obj.SimulationEditGrid.Layout.Row = 3;
            obj.SimulationEditGrid.Layout.Column = 1;
            obj.SimulationEditGrid.Padding = obj.WidgetPadding;
            obj.SimulationEditGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.SimulationEditGrid.ColumnSpacing = obj.WidgetWidthSpacing;

            %Results Path selector
            obj.ResultFolderSelector = QSPViewerNew.Widgets.FolderSelector(obj.SimulationEditGrid,1,1,' Results Path');

            %Data set drop down
            obj.DatasetGrid = uigridlayout(obj.SimulationEditGrid);
            obj.DatasetGrid.ColumnWidth = {obj.LabelLength,'1x',obj.ButtonWidth};
            obj.DatasetGrid.RowHeight = {obj.WidgetHeight};
            obj.DatasetGrid.Layout.Row = 2;
            obj.DatasetGrid.Layout.Column = 1;
            obj.DatasetGrid.Padding = [0,0,0,0];
            obj.DatasetGrid.RowSpacing = 0;
            obj.DatasetGrid.ColumnSpacing = 0;

            %             obj.DatasetDropDown = uidropdown(obj.DatasetGrid);
            %             obj.DatasetDropDown.Layout.Column = 2;
            %             obj.DatasetDropDown.Layout.Row = 1;
            %             obj.DatasetDropDown.Items = {'wide','tall'};
            %             obj.DatasetDropDown.ValueChangedFcn = @(h,e)obj.onDatasetChange();
            %
            %             obj.DatasetLabel = uilabel(obj.DatasetGrid);
            %             obj.DatasetLabel.Layout.Column = 1;
            %             obj.DatasetLabel.Layout.Row = 1;
            %             obj.DatasetLabel.Text = ' Dataset';

            %Dataset Label
            obj.DatasetLabel = uilabel(obj.DatasetGrid);
            obj.DatasetLabel.Text = 'Dataset';
            obj.DatasetLabel.Layout.Row = 1;
            obj.DatasetLabel.Layout.Column = 1;

            %Dataset value level
            obj.DatasetSelectionLabel = uilabel(obj.DatasetGrid);
            obj.DatasetSelectionLabel.Layout.Row = 1;
            obj.DatasetSelectionLabel.Layout.Column = 2;

            %Datasets selection button
            obj.DatasetSelectionButton = uibutton(obj.DatasetGrid);
            obj.DatasetSelectionButton.Layout.Row = 1;
            obj.DatasetSelectionButton.Layout.Column = 3;
            obj.DatasetSelectionButton.Text = '...';

            %Group Column drop down
            obj.GroupColumnGrid = uigridlayout(obj.SimulationEditGrid);
            obj.GroupColumnGrid.ColumnWidth = {obj.LabelLength,'1x'};
            obj.GroupColumnGrid.RowHeight = {obj.WidgetHeight};
            obj.GroupColumnGrid.Layout.Row = 3;
            obj.GroupColumnGrid.Layout.Column = 1;
            obj.GroupColumnGrid.Padding = [0,0,0,0];
            obj.GroupColumnGrid.RowSpacing = 0;
            obj.GroupColumnGrid.ColumnSpacing = 0;

            obj.GroupColumnDropDown = uidropdown(obj.GroupColumnGrid);
            obj.GroupColumnDropDown.Layout.Column = 2;
            obj.GroupColumnDropDown.Layout.Row = 1;
            obj.GroupColumnDropDown.Items = {'wide','tall'};
            obj.GroupColumnDropDown.ValueChangedFcn = @(h,e)obj.onGroupColumnChange();

            obj.GroupColumnLabel = uilabel(obj.GroupColumnGrid);
            obj.GroupColumnLabel.Layout.Column = 1;
            obj.GroupColumnLabel.Layout.Row = 1;
            obj.GroupColumnLabel.Text = ' Group Column';

            %Simulation Items label
            obj.SimItemLabelGrid = uigridlayout(obj.SimulationEditGrid);
            obj.SimItemLabelGrid.ColumnWidth = {obj.LabelLength,'1x'};
            obj.SimItemLabelGrid.RowHeight = {obj.WidgetHeight};
            obj.SimItemLabelGrid.Layout.Row = 4;
            obj.SimItemLabelGrid.Layout.Column = 1;
            obj.SimItemLabelGrid.Padding = [0,0,0,0];
            obj.SimItemLabelGrid.RowSpacing = 0;
            obj.SimItemLabelGrid.ColumnSpacing = 0;

            obj.SimItemLabel = uilabel(obj.SimItemLabelGrid);
            obj.SimItemLabel.Layout.Column = 1;
            obj.SimItemLabel.Layout.Row = 1;
            obj.SimItemLabel.Text = ' Simulation Items';

            %Select Simulation Items
            obj.SimItemGrid = uigridlayout(obj.SimulationEditGrid);
            obj.SimItemGrid.ColumnWidth = {obj.ButtonWidth,'1x'};
            obj.SimItemGrid.Layout.Row = 5;
            obj.SimItemGrid.Layout.Column = 1;
            obj.SimItemGrid.Padding = [0,0,0,0];
            obj.SimItemGrid.RowSpacing = 0;
            obj.SimItemGrid.ColumnSpacing = 0;

            %Simulation Select Buttons Grid
            obj.SimButtonGrid = uigridlayout(obj.SimItemGrid);
            obj.SimButtonGrid.ColumnWidth = {'1x'};
            obj.SimButtonGrid.RowHeight = {obj.ButtonHeight,obj.ButtonHeight,obj.ButtonHeight};
            obj.SimButtonGrid.Layout.Row = 1;
            obj.SimButtonGrid.Layout.Column = 1;
            obj.SimButtonGrid.Padding = [0,0,0,0];
            obj.SimButtonGrid.RowSpacing = 2;
            obj.SimButtonGrid.ColumnSpacing = 2;

            % New Button
            obj.NewButton = uibutton(obj.SimButtonGrid,'push');
            obj.NewButton.Layout.Row = 1;
            obj.NewButton.Layout.Column = 1;
            obj.NewButton.Icon =QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.NewButton.Text = '';
            obj.NewButton.Tooltip = 'Add new row';
            obj.NewButton.ButtonPushedFcn = @(h,e)obj.onAddSimItem();

            %Remove Button
            obj.RemoveButton = uibutton(obj.SimButtonGrid,'push');
            obj.RemoveButton.Layout.Row = 2;
            obj.RemoveButton.Layout.Column = 1;
            obj.RemoveButton.Icon = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveButton.Text = '';
            obj.RemoveButton.Tooltip = 'Delete the highlighted row';
            obj.RemoveButton.ButtonPushedFcn = @(h,e)obj.onRemoveSimItem();

            % Duplicate Button
            obj.DuplicateButton = uibutton(obj.SimButtonGrid,'push');
            obj.DuplicateButton.Layout.Row = 3;
            obj.DuplicateButton.Layout.Column = 1;
            obj.DuplicateButton.Icon =QSPViewerNew.Resources.LoadResourcePath('copy_24.png');
            obj.DuplicateButton.Text = '';
            obj.DuplicateButton.Tooltip = 'Duplicate the highlighted row';
            obj.DuplicateButton.ButtonPushedFcn = @(h,e)obj.onDuplicateSimItem();

            %Table
            obj.SimItemsTable = uitable(obj.SimItemGrid, 'ColumnSortable', true);
            obj.SimItemsTable.Layout.Row = 1;
            obj.SimItemsTable.Layout.Column = 2;
            obj.SimItemsTable.Data = {};
            obj.SimItemsTable.ColumnName = {'Task','Virtual Subject(s)','Virtual Subject Group to Simulate', 'Available Groups in Virtual Subjects'};
            obj.SimItemsTable.ColumnFormat = {obj.TaskPopupTableItems,obj.VPopPopupTableItems,'char','char'};
            obj.SimItemsTable.ColumnEditable = [true,true,true,true];
            obj.SimItemsTable.CellEditCallback = @(h,e) obj.onTableSelectionEdit(e);
            obj.SimItemsTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(e);

            % create ApplytoAll context menu for sim items table
            if false % TODO
                obj.SimItemsTableContextMenu = uicontextmenu(obj.getUIFigure);
                obj.SimItemsTable.ContextMenu = obj.SimItemsTableContextMenu;
                obj.ApplyToAllMenu = uimenu(obj.SimItemsTableContextMenu, 'Label', "Apply to all");
                obj.ApplyToAllMenu.MenuSelectedFcn = @(h,e) obj.onApplyToAllSelected(h,e);
            end

            %VisualizationPanel Items
            obj.SimulationVisualizationGrid = uigridlayout(obj.getVisualizationGrid());
            obj.SimulationVisualizationGrid.Layout.Row = 2;
            obj.SimulationVisualizationGrid.Layout.Column = 1;
            obj.SimulationVisualizationGrid.RowHeight = {obj.WidgetHeight,'1x',obj.WidgetHeight,'1x',obj.WidgetHeight,'1x',obj.WidgetHeight,'1x'};
            obj.SimulationVisualizationGrid.ColumnWidth = {'1x'};

            %Species Label and Table;
            obj.SpeciesLabel = uilabel(obj.SimulationVisualizationGrid);
            obj.SpeciesLabel.Text = 'Species';
            obj.SpeciesLabel.Layout.Row = 1;
            obj.SpeciesLabel.Layout.Column = 1;
            obj.SpeciesLabel.FontWeight = 'bold';

            obj.SpeciesTable = uitable(obj.SimulationVisualizationGrid, 'ColumnSortable', true);
            obj.SpeciesTable.Layout.Row = 2;
            obj.SpeciesTable.Layout.Column = 1;
            obj.SpeciesTable.Data = {};
            obj.SpeciesTable.ColumnName = {'Plot','Style','Name', 'Display'};
            obj.SpeciesTable.CellEditCallback = @(h,e) obj.onSpeciesTableEdit(h,e);

            %SimulationItems Label and Table;
            obj.SimulationItemsLabel = uilabel(obj.SimulationVisualizationGrid);
            obj.SimulationItemsLabel.Text = 'Simulation Items';
            obj.SimulationItemsLabel.Layout.Row = 3;
            obj.SimulationItemsLabel.Layout.Column = 1;
            obj.SimulationItemsLabel.FontWeight = 'bold';

            obj.SimulationItemsTable = uitable(obj.SimulationVisualizationGrid, 'ColumnSortable', true);
            obj.SimulationItemsTable.Layout.Row = 4;
            obj.SimulationItemsTable.Layout.Column = 1;
            obj.SimulationItemsTable.Data = {};
            obj.SimulationItemsTable.ColumnName = {'Include','Color','Task', 'Virtual Subject(s)','Group','Display'};
            obj.SimulationItemsTable.CellEditCallback = @(h,e) obj.onSimItemsTableEdit(h,e);

            %Data Label and Table;
            obj.DataLabel = uilabel(obj.SimulationVisualizationGrid);
            obj.DataLabel.Text = 'Data';
            obj.DataLabel.Layout.Row = 5;
            obj.DataLabel.Layout.Column = 1;
            obj.DataLabel.FontWeight = 'bold';

            obj.DataTable = uitable(obj.SimulationVisualizationGrid, 'ColumnSortable', true);
            obj.DataTable.Layout.Row = 6;
            obj.DataTable.Layout.Column = 1;
            obj.DataTable.Data = {};
            obj.DataTable.ColumnName = {'Plot','Marker','Name', 'Display'};
            obj.DataTable.CellEditCallback = @(h,e) obj.onDataTableEdit(h,e);

            %Group Label and Table;
            obj.GroupLabel = uilabel(obj.SimulationVisualizationGrid);
            obj.GroupLabel.Text = 'Group (dataset)';
            obj.GroupLabel.Layout.Row = 7;
            obj.GroupLabel.Layout.Column = 1;
            obj.GroupLabel.FontWeight = 'bold';

            obj.GroupTable = uitable(obj.SimulationVisualizationGrid, 'ColumnSortable', true);
            obj.GroupTable.Layout.Row = 8;
            obj.GroupTable.Layout.Column = 1;
            obj.GroupTable.Data = {};
            obj.GroupTable.ColumnName = {'Include','Color','Name', 'Display'};
            obj.GroupTable.CellEditCallback = @(h,e) obj.onGroupTableEdit(h,e);
        end

        function createListenersAndCallbacks(obj)
            obj.ResultFolderListener = addlistener(obj.ResultFolderSelector,'StateChanged',@(src,event) obj.onResultsPath(event.Source.RelativePath));
            obj.DatasetSelectionButton.ButtonPushedFcn  =  @(h,e) obj.onEditDataset();
        end

    end

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function onEditDataset(obj)
            selection = obj.getSelectionNode("OptimizationData");
            if ~(isempty(selection) || selection=="")
                obj.TemporarySimulation.DatasetName = char(selection);
                obj.DatasetSelectionLabel.Text = selection;

                %First update the dataset information
                obj.updateDataset();
                %update the Group column next, because it is dependent.
                obj.updateGroupColumn();
                obj.IsDirty = true;
            end
        end

        function onRemoveSimItem(obj)
            DeleteIdx = obj.SelectedRow;
            if DeleteIdx~= 0 && DeleteIdx <= numel(obj.TemporarySimulation.Item)
                obj.TemporarySimulation.Item(DeleteIdx) = [];
            end
            obj.updateSimulationTable();
            obj.IsDirty = true;
        end

        function onAddSimItem(obj)
            if ~isempty(obj.TaskPopupTableItems)
                NewTaskVPop = QSP.TaskVirtualPopulation;
                NewTaskVPop.TaskName = '';
                NewTaskVPop.VPopName = obj.VPopPopupTableItems{1};
                NewTaskVPop.Group = '';
                obj.TemporarySimulation.Item(end+1) = NewTaskVPop;
            else
                uialert(obj.getUIFigure(),'At least one task must be defined in order to add a simulation item.','Cannot Add');
            end
            obj.updateSimulationTable();
            obj.IsDirty = true;
        end

        function onDuplicateSimItem(obj)
            DuplicateIdx = obj.SelectedRow;
            if DuplicateIdx ~= 0 && DuplicateIdx <= numel(obj.TemporarySimulation.Item)
                NewTaskVPop = QSP.TaskVirtualPopulation;
                NewTaskVPop.TaskName = obj.TemporarySimulation.Item(DuplicateIdx).TaskName;
                NewTaskVPop.VPopName = obj.TemporarySimulation.Item(DuplicateIdx).VPopName;
                NewTaskVPop.Group = obj.TemporarySimulation.Item(DuplicateIdx).Group;
                obj.TemporarySimulation.Item(end+1) = NewTaskVPop;
            end
            obj.updateSimulationTable();
            obj.IsDirty = true;
        end


        function onGroupColumnChange(obj)
            obj.TemporarySimulation.GroupName = obj.GroupColumnDropDown.Value;
            %First update the dataset information
            obj.updateDataset();
            %update the Group column next, because it is dependent.
            obj.updateGroupColumn();
            obj.IsDirty = true;
        end

        function onTableSelectionChange(obj,eventData)
            Indices = eventData.Indices;
            obj.SelectedRow = Indices(1);

            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);

            % if a task cell is selected
            if size(Indices,1)==1
                if ColIdx==1 % if task cell is selected
                    selectedTaskNode = obj.getSelectionNode("Task");
                    if ~(isempty(selectedTaskNode) || strcmp(selectedTaskNode, ""))
                        if ~isequal(obj.TemporarySimulation.Item(RowIdx).TaskName,selectedTaskNode)
                            obj.TemporarySimulation.Item(RowIdx).MATFileName = '';
                        end
                        obj.TemporarySimulation.Item(RowIdx).TaskName = char(selectedTaskNode);
                        obj.updateSimulationTable();
                    end
                elseif ColIdx==2 % if virtual subject cell is selected
                    selectedVpopNode = obj.getSelectionNode("VirtualPopulation");
                    if ~(isempty(selectedVpopNode) || strcmp(selectedVpopNode, ""))
                        if ~isequal(obj.TemporarySimulation.Item(RowIdx).VPopName,selectedVpopNode)
                            obj.TemporarySimulation.Item(RowIdx).MATFileName = '';
                        end
                        obj.TemporarySimulation.Item(RowIdx).VPopName = char(selectedVpopNode);
                        obj.updateSimulationTable();
                    end
                end
            end

            obj.IsDirty = true;
        end

        function onTableSelectionEdit(obj,eventData)
            Indices = eventData.Indices;
            if isempty(Indices)
                return;
            end

            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);

            obj.SelectedRow = Indices(1);
            obj.SelectedCol = Indices(:,2);

            % Update entry
            HasChanged = false;
            if ColIdx == 1
                if ~isequal(obj.TemporarySimulation.Item(RowIdx).TaskName,selectedTaskNode)
                    HasChanged = true;
                end
                obj.TemporarySimulation.Item(RowIdx).TaskName = selectedTaskNode;
            elseif ColIdx == 3 % Group
                if ~isequal(obj.TemporarySimulation.Item(RowIdx).Group,eventData.NewData)
                    HasChanged = true;
                end
                obj.TemporarySimulation.Item(RowIdx).Group = eventData.NewData;
            elseif ColIdx == 2 % Vpop
                if ~isequal(obj.TemporarySimulation.Item(RowIdx).VPopName,eventData.NewData)
                    HasChanged = true;
                end
                obj.TemporarySimulation.Item(RowIdx).VPopName = eventData.NewData;
            end
            if HasChanged
                obj.TemporarySimulation.Item(RowIdx).MATFileName = '';
            end

            obj.updateSimulationTable();
            obj.IsDirty = true;
        end

        function onApplyToAllSelected(obj,~,~)
            if numel(obj.SelectedCol)>1 || obj.SelectedCol==0 || ...
                    ~ismember(obj.SelectedRow, 1:length(obj.TemporarySimulation.Item)) ...
                    || ~ismember(obj.SelectedCol, [1, 2, 3])
                uialert(obj.getUIFigure, "Please make sure to select one valid editable cell before calling 'Apply to All'.", ...
                    'Invalid cell(s) selected', 'Icon', 'warning');
                return;
            end

            % Update entry
            if obj.SelectedCol == 1
                colName = "TaskName";
            elseif obj.SelectedCol == 2 % Group
                colName = "VPopName";
            elseif obj.SelectedCol == 3 % Vpop
                colName = "Group";
            end

            for rowIdx = 1:length(obj.TemporarySimulation.Item)
                if rowIdx == obj.SelectedRow
                    continue;
                end
                obj.TemporarySimulation.Item(rowIdx).(colName) = ...
                    obj.TemporarySimulation.Item(obj.SelectedRow).(colName);
                obj.TemporarySimulation.Item(rowIdx).MATFileName = '';
            end

            obj.updateSimulationTable();
            obj.IsDirty = true;
        end

        function onResultsPath(obj,eventData)
            %The backend for the simulation objects seems to have an issue
            %with '' even though other QSP objects can have '' as a
            %relative path for a directory. For simulation, we need to
            %change the value to a 0x1 instead of 0x0 char array.
            if isempty(eventData)
                obj.TemporarySimulation.SimResultsFolderName = char.empty(1,0);
            else
                obj.TemporarySimulation.SimResultsFolderName = eventData;
            end
            obj.IsDirty = true;
        end

        function onSpeciesTableEdit(obj,h,e)
            if iscell(h.ColumnFormat{e.Indices(2)}) && ~any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
            end

            %Determine if the change was valid
            if e.Indices(2)==4  || iscell(h.ColumnFormat{e.Indices(2)}) && any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                %The new value was already in the dropdown, so we can
                %continue
                obj.SelectedSpecies = e.Indices;
                ThisData = get(h,'Data');
                Indices = e.Indices;
                RowIdx = Indices(1);
                ColIdx = Indices(2);

                NewAxIdx = str2double(ThisData{RowIdx,1});
                if isnan(NewAxIdx)
                    NewAxIdx = [];
                end


                if ~isequal(obj.Simulation.PlotSpeciesTable,[ThisData(:,1) ThisData(:,2) ThisData(:,3)]) || ...
                        ColIdx == 1 || ColIdx == 2 || ColIdx == 4

                    if ~isempty(RowIdx) && ColIdx == 2
                        NewLineStyle = ThisData{RowIdx,2};
                        setSpeciesLineStyles(obj.Simulation,RowIdx,NewLineStyle);
                    end

                    obj.Simulation.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);

                    if ColIdx == 2
                        AxIndices = NewAxIdx;
                        if isempty(AxIndices)
                            AxIndices = 1:numel(obj.getPlotArray());
                        end
                        % Redraw legend
                        [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                            obj.Simulation,obj.getPlotArray(),obj.SpeciesGroup,obj.DatasetGroup,...
                            'AxIndices',AxIndices);
                        obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                        obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                        obj.updateLines();

                    elseif ColIdx == 4
                        % Display Name
                        AxIndices = NewAxIdx;
                        if isempty(AxIndices)
                            AxIndices = 1:numel(obj.getPlotArray());
                        end
                        % Redraw legend
                        [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                            obj.Simulation,obj.getPlotArray(),obj.SpeciesGroup,obj.DatasetGroup,...
                            'AxIndices',AxIndices);
                        obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                        obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                        obj.updateLines();

                    elseif ColIdx == 1
                        % Plot axes
                        sIdx = RowIdx;
                        OldAxIdx = find(~cellfun(@isempty,obj.SpeciesGroup(sIdx,:)),1,'first');

                        % If originally not plotted
                        if isempty(OldAxIdx) && ~isempty(NewAxIdx)
                            obj.SpeciesGroup{sIdx,NewAxIdx} = obj.SpeciesGroup{sIdx,1};
                            % Parent
                            obj.SpeciesGroup{sIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                        elseif ~isempty(OldAxIdx) && isempty(NewAxIdx)
                            obj.SpeciesGroup{sIdx,1} = obj.SpeciesGroup{sIdx,OldAxIdx};
                            % Un-parent
                            obj.SpeciesGroup{sIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                            if OldAxIdx ~= 1
                                obj.SpeciesGroup{sIdx,OldAxIdx} = [];
                            end
                        elseif ~isempty(OldAxIdx) && ~isempty(NewAxIdx)
                            obj.SpeciesGroup{sIdx,NewAxIdx} = obj.SpeciesGroup{sIdx,OldAxIdx};
                            % Re-parent
                            obj.SpeciesGroup{sIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                            if OldAxIdx ~= NewAxIdx
                                obj.SpeciesGroup{sIdx,OldAxIdx} = [];
                            end
                        end

                        % Update lines (line widths, marker sizes)
                        updateLines(obj);

                        AxIndices = [OldAxIdx,NewAxIdx];
                        AxIndices(isnan(AxIndices)) = [];

                        % Redraw legend
                        [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                            obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                            'AxIndices',AxIndices);
                        obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                        obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
                        obj.updateLegends();
                    end
                end
            else
                %invalid value, revert information
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
            end
            %We need to save this configuration
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end

        function onSimItemsTableEdit(obj,h,e)
            if iscell(h.ColumnFormat{e.Indices(2)}) && ~any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                %The new value was already in the dropdown, so we can
                %continue
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
            end

            % Temporarily disable column 1 to prevent quick clicking of
            % 'Include'
            OrigColumnEditable = get(h,'ColumnEditable');
            ColumnEditable = OrigColumnEditable;
            ColumnEditable(1) = false;
            set(h,'ColumnEditable',ColumnEditable);

            ThisData = get(h,'Data');
            obj.SelectedSpecies = e.Indices;
            if isempty(e.Indices)
                return;
            end
            obj.Simulation.PlotItemTable(obj.SelectedSpecies(1),obj.SelectedSpecies(2)) = ThisData(obj.SelectedSpecies(1),obj.SelectedSpecies(2));

            if obj.SelectedSpecies(1) == 6
                % Display name
                [obj.PlotArray,obj.AxesLegendChildren] = updatePlots(obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup);

            elseif obj.SelectedSpecies(2) == 1
                % Include

                % Don't overwrite the output
                updatePlots(obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'RedrawLegend',false);
            end

            % Enable column 1
            set(h,'ColumnEditable',OrigColumnEditable);
            %We need to save this configuration
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation

        end

        function onSimItemsTableSelect(obj,~,e)
            obj.SelectedSimItem = e.Indices;
        end

        function onDataTableEdit(obj,h,e)
            if iscell(h.ColumnFormat{e.Indices(2)}) && ~any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                %The new value was already in the dropdown, so we can
                %continue
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
            end

            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end

            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);

            NewAxIdx = str2double(ThisData{RowIdx,1});
            if isnan(NewAxIdx)
                NewAxIdx = [];
            end


            obj.Simulation.PlotDataTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);

            if ColIdx == 4
                % Display name
                AxIndices = NewAxIdx;
                if isempty(AxIndices)
                    AxIndices = 1:numel(obj.PlotArray);
                end
                % Redraw legend
                [UpdatedAxesLegend,~] = updatePlots(...
                    obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'AxIndices',AxIndices);
                obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);

            elseif ColIdx == 2
                % Style
                for dIdx = 1:size(obj.Simulation.PlotDataTable,1)
                    axIdx = str2double(obj.Simulation.PlotDataTable{dIdx,1});
                    if ~isnan(axIdx)
                        Ch = get(obj.DatasetGroup{dIdx,axIdx},'Children');
                        HasMarker = isprop(Ch,'Marker');
                        set(Ch(HasMarker),'Marker',obj.Simulation.PlotDataTable{dIdx,2});
                    end
                end

                AxIndices = NewAxIdx;
                if isempty(AxIndices)
                    AxIndices = 1:numel(obj.PlotArray);
                end
                % Redraw legend
                [UpdatedAxesLegend,~] = updatePlots(...
                    obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'AxIndices',AxIndices);
                obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);

            elseif ColIdx == 1

                dIdx = RowIdx;
                OldAxIdx = find(~cellfun(@isempty,obj.DatasetGroup(dIdx,:)),1,'first');

                % If originally not plotted
                if isempty(OldAxIdx) && ~isempty(NewAxIdx)
                    obj.DatasetGroup{dIdx,NewAxIdx} = obj.DatasetGroup{dIdx,1};
                    % Parent
                    obj.DatasetGroup{dIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                elseif ~isempty(OldAxIdx) && isempty(NewAxIdx)
                    obj.DatasetGroup{dIdx,1} = obj.DatasetGroup{dIdx,OldAxIdx};
                    % Un-parent
                    obj.DatasetGroup{dIdx,1}.Parent = matlab.graphics.GraphicsPlaceholder.empty();
                    if OldAxIdx ~= 1
                        obj.DatasetGroup{dIdx,OldAxIdx} = [];
                    end
                elseif ~isempty(OldAxIdx) && ~isempty(NewAxIdx)
                    obj.DatasetGroup{dIdx,NewAxIdx} = obj.DatasetGroup{dIdx,OldAxIdx};
                    % Re-parent
                    obj.DatasetGroup{dIdx,NewAxIdx}.Parent = obj.PlotArray(NewAxIdx);
                    if OldAxIdx ~= NewAxIdx
                        obj.DatasetGroup{dIdx,OldAxIdx} = [];
                    end
                end

                AxIndices = [OldAxIdx,NewAxIdx];
                AxIndices(isnan(AxIndices)) = [];

                % Redraw legend
                [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                    obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'AxIndices',AxIndices);
                obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
                obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);

            end
            %We need to save this configuration
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end

        function onGroupTableEdit(obj,h,e)
            if iscell(h.ColumnFormat{e.Indices(2)}) && ~any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                %The new value was already in the dropdown, so we can
                %continue
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
            end

            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end

            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);

            obj.Simulation.PlotGroupTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);

            if ColIdx == 4
                % Display name
                [obj.AxesLegend,obj.AxesLegendChildren] = updatePlots(obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup);

            elseif ColIdx == 1
                % Include

                % Don't overwrite the output
                updatePlots(obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'RedrawLegend',false);

            end
            %We need to save this configuration
            obj.VisDirty = true; %Same as notify(obj,'MarkDirty') in old implementation
        end

        function onGroupTableSelect(obj,~,e)
            obj.SelectedGroup = e.Indices;
        end

        function onPlotItemsTableContextMenu(~,~,~)
            %TODO when uisetcolor is supported or a workaround
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

        function attachNewSimulation(obj,NewSimulation)
            obj.Simulation = NewSimulation;
            obj.Simulation.PlotSettings = getSummary(obj.getPlotSettings());
            obj.TemporarySimulation = copy(obj.Simulation);


            for index = 1:obj.MaxNumPlots
                Summary = obj.Simulation.PlotSettings(index);
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
            [StatusOK, Message, ~] = run(obj.Simulation);

            if ~StatusOK
                notify(obj, "Alert", QSPViewerNew.Application.AlertEventData(Message));
            end

            % todopax this seems unnecessary.
            obj.deleteTemporary(); % this will delete the temporary and copy the simulation (the one run above) and copy it into the temporary.
            obj.draw(); % todopax need to figure out who does the run/draw. Maybe better in ViewPane.
        end

        function drawVisualization(obj)

            %DropDown Update
            obj.updatePlotConfig(obj.Simulation.SelectedPlotLayout);

            %Determine if the values are valid
            if ~isempty(obj.Simulation)
                % Check what items are stale or invalid
                [obj.StaleFlag,obj.ValidFlag] = getStaleItemIndices(obj.Simulation);
            end

            % Create context menu
            obj.redrawAxesContextMenu();
            obj.updateCM();
            obj.updateSpeciesTable();
            obj.updateSimItemsTable();
            [OptimHeader,OptimData] = updateDataTable(obj);
            obj.updateGroupTable(OptimHeader,OptimData);
            [obj.SpeciesGroup,obj.DatasetGroup,obj.AxesLegend,obj.AxesLegendChildren] = ...
                plotSimulation(obj.Simulation,obj.getPlotArray());
        end

        function refreshVisualization(obj,axIndex)

            obj.redrawAxesContextMenu();
            obj.updateCM();
            obj.updateSpeciesTable();
            obj.updateSimItemsTable();
            [OptimHeader,OptimData] = updateDataTable(obj);
            obj.updateGroupTable(OptimHeader,OptimData);

            if ~isempty(axIndex)
                [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                    obj.Simulation,obj.PlotArray,obj.SpeciesGroup,obj.DatasetGroup,...
                    'AxIndices',axIndex);
                obj.AxesLegend(axIndex) = UpdatedAxesLegend(axIndex);
                obj.AxesLegendChildren(axIndex) = UpdatedAxesLegendChildren(axIndex);
            end

        end

        function UpdateBackendPlotSettings(obj)
            obj.Simulation.PlotSettings = getSummary(obj.getPlotSettings());
        end

    end

    methods (Access = public)

        function NotifyOfChangeInName(obj,value)
            obj.TemporarySimulation.Name = value;
            obj.IsDirty = true;
        end

        function NotifyOfChangeInDescription(obj,value)
            obj.TemporarySimulation.Description= value;
            obj.IsDirty = true;
        end

        function NotifyOfChangeInPlotConfig(obj,value)
            obj.Simulation.SelectedPlotLayout = value;
            obj.updatePlotConfig(value);
        end

        function [StatusOK] = saveBackEndInformation(obj)

            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporarySimulation.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);

            if StatusOK
                obj.TemporarySimulation.updateLastSavedTime();

                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.Simulation = copy(obj.TemporarySimulation,obj.Simulation);

                %We now need to notify the application
                obj.notifyOfChange(obj.TemporarySimulation.Session);

%                 notify(obj, "StateChange", QSPViewerNew.Application.ChangeData(obj.TemporarySimulation));

            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end

        end

        function removeInvalidVisualization(obj)
            % Remove invalid indices
            if ~isempty(obj.PlotSpeciesInvalidRowIndices)
                obj.Simulation.PlotSpeciesTable(obj.PlotSpeciesInvalidRowIndices,:) = [];
                obj.PlotSpeciesAsInvalidTable(obj.PlotSpeciesInvalidRowIndices) = [];
                obj.PlotSpeciesInvalidRowIndices = [];
            end

            if ~isempty(obj.PlotItemInvalidRowIndices)
                obj.Simulation.PlotItemTable(obj.PlotItemInvalidRowIndices,:) = [];
                obj.PlotItemAsInvalidTable(obj.PlotItemInvalidRowIndices,:) = [];
                obj.PlotItemInvalidRowIndices = [];
            end

            if ~isempty(obj.PlotDataInvalidRowIndices)
                obj.Simulation.PlotDataTable(obj.PlotDataInvalidRowIndices,:) = [];
                obj.PlotDataAsInvalidTable(obj.PlotDataInvalidRowIndices,:) = [];
                obj.PlotDataInvalidRowIndices = [];
            end

            if ~isempty(obj.PlotGroupInvalidRowIndices)
                obj.Simulation.PlotGroupTable(obj.PlotGroupInvalidRowIndices,:) = [];
                obj.PlotGroupAsInvalidTable(obj.PlotGroupInvalidRowIndices,:) = [];
                obj.PlotGroupInvalidRowIndices = [];
            end

            % Update
            obj.updateCM();
            obj.updateSpeciesTable();
            obj.updateSimItemsTable();
            [OptimHeader,OptimData] = obj.updateDataTable();
            obj.updateGroupTable(OptimHeader,OptimData);
        end

        function deleteTemporary(obj)
            delete(obj.TemporarySimulation)
            obj.TemporarySimulation = copy(obj.Simulation);
        end

        function draw(obj)
            obj.updateDescriptionBox(obj.TemporarySimulation.Description);
            obj.updateNameBox(obj.TemporarySimulation.Name);
            obj.updateSummary(obj.TemporarySimulation.getSummary());

            obj.updateResultsDir();
            obj.ResultFolderSelector.RootDirectory = obj.TemporarySimulation.Session.RootDirectory;

            obj.updateDataset();
            obj.updateGroupColumn();
            obj.updateSimulationTable();
            % TODOpax. these need to go away.
%             obj.updateParallelButtonSession(obj.TemporarySimulation.Session.UseParallel);
%             obj.updateGitButtonSession(obj.TemporarySimulation.Session.AutoSaveGit);
            obj.IsDirty = false;
        end

        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporarySimulation,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end

        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.Simulation.Session.Simulation;
            ixDup = find(strcmp( obj.TemporarySimulation.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.Simulation)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end

        function [ValidTF] = isValid(obj)
            [~,Valid] = getStaleItemIndices(obj.Simulation);
            ValidTF = all(Valid);
        end

        function BackEnd = getBackEnd(obj)
            BackEnd = obj.Simulation;
        end

        function updateSessionParallelOption(obj, parallelOption)
            if strcmp(parallelOption, 'off')
                obj.Simulation.Session.UseParallel = false;
            elseif strcmp(parallelOption, 'on')
                obj.Simulation.Session.UseParallel = true;
            end
            notifyOfChange(obj,obj.Simulation.Session)
        end

        % This should go away.
        function updateSessionGitOption(obj, gitOption)
            error("This should go away.");
            if strcmp(gitOption, 'off')
                obj.Simulation.Session.AutoSaveGit = false;
            elseif strcmp(gitOption, 'on')
                obj.Simulation.Session.AutoSaveGit = true;
            end
            notifyOfChange(obj,obj.Simulation.Session)
        end
    end

    methods (Access = private)

        function updateCM(obj)
            %Set Context Menus;
            obj.PlotItemsTableContextMenu = uicontextmenu(ancestor(obj.SimulationEditGrid,'figure'));
            obj.PlotItemsTableMenu = uimenu(obj.PlotItemsTableContextMenu);
            obj.PlotItemsTableMenu.Label = 'Set Color';
            obj.PlotItemsTableMenu.Tag = 'PlotItemsCM';
            obj.PlotItemsTableMenu.MenuSelectedFcn = @(h,e)onPlotItemsTableContextMenu(obj,h,e);
            obj.SimulationItemsTable.ContextMenu = obj.PlotItemsTableContextMenu;

            obj.PlotGroupTableContextMenu = uicontextmenu(ancestor(obj.SimulationEditGrid,'figure'));
            obj.PlotGroupTableMenu = uimenu(obj.PlotGroupTableContextMenu);
            obj.PlotGroupTableMenu.Label = 'Set Color';
            obj.PlotGroupTableMenu.Tag = 'PlotGroupCM';
            obj.PlotGroupTableMenu.MenuSelectedFcn = @(h,e)onPlotItemsTableContextMenu(obj,h,e);
            obj.GroupTable.ContextMenu =  obj.PlotGroupTableContextMenu;
            % Create context menu
        end

        function updateDataset(obj)
            OptimHeader = {};

            if ~isempty(obj.TemporarySimulation)
                ThisRawList = {obj.TemporarySimulation.Settings.OptimizationData.Name};

                ThisList = vertcat('Unspecified',ThisRawList(:));
                Selection = obj.TemporarySimulation.DatasetName;
                if isempty(Selection)
                    Selection = 'Unspecified';
                end

                % Force as invalid if validate fails
                MatchIdx = find(strcmpi(ThisRawList,Selection));

                if any(MatchIdx)
                    [ThisStatusOk,~,OptimHeader] = validate(obj.TemporarySimulation.Settings.OptimizationData(MatchIdx));
                    ForceMarkAsInvalid = ~ThisStatusOk;
                else
                    ForceMarkAsInvalid = false;
                end

                [FullListWithInvalids,FullList,~] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
            else
                FullList = {'-'};
                FullListWithInvalids = {QSP.makeInvalid('-')};
            end
            obj.DatasetPopupItems = FullList;
            obj.DatasetPopupItemsWithInvalid = FullListWithInvalids;

            if ~isempty(obj.TemporarySimulation)
                if isempty(obj.TemporarySimulation.DatasetName)
                    ThisSelection = 'Unspecified';
                else
                    ThisSelection = obj.TemporarySimulation.DatasetName;
                end
                [~,Value] = ismember(ThisSelection,obj.DatasetPopupItems);

                obj.DatasetSelectionLabel.Text = obj.DatasetPopupItemsWithInvalid{Value};
            else
                obj.DatasetSelectionLabel.Text = obj.DatasetPopupItemsWithInvalid{1};
            end

            obj.DatasetHeader = OptimHeader;
        end

        function updateGroupColumn(obj)
            if ~isempty(obj.TemporarySimulation)
                if isempty(obj.TemporarySimulation.DatasetName) || strcmpi(obj.TemporarySimulation.DatasetName,'Unspecified')
                    ThisList = vertcat('Unspecified',obj.DatasetHeader(:));
                else
                    ThisList = obj.DatasetHeader;
                end

                GroupSelection = obj.TemporarySimulation.GroupName;
                [FullGroupListWithInvalids,FullGroupList,GroupValue] = QSP.highlightInvalids(ThisList,GroupSelection);
            else
                FullGroupList = {'-'};
                FullGroupListWithInvalids = {QSP.makeInvalid('-')};

                GroupValue = 1;
            end
            obj.DatasetHeaderPopupItems = FullGroupList;
            obj.DatasetHeaderPopupItemsWithInvalid = FullGroupListWithInvalids;

            obj.GroupColumnDropDown.Items = obj.DatasetHeaderPopupItemsWithInvalid;
            obj.GroupColumnDropDown.Value = obj.DatasetHeaderPopupItemsWithInvalid{GroupValue};
        end

        function updateResultsDir(obj)
            obj.ResultFolderSelector.RelativePath = obj.TemporarySimulation.SimResultsFolderName;
        end

        function updateSimulationTable(obj)

            %Find the correct set of values for the in-table popup menus
            if ~isempty(obj.TemporarySimulation)
                ValidItemTasks = getValidSelectedTasks(obj.TemporarySimulation.Settings,{obj.TemporarySimulation.Settings.Task.Name});
                if ~isempty(ValidItemTasks)
                    obj.TaskPopupTableItems = {ValidItemTasks.Name};
                else
                    obj.TaskPopupTableItems = {};
                end
            else
                obj.TaskPopupTableItems = 'char';
            end

            % % Refresh VPopPopupTableItems
            if ~isempty(obj.TemporarySimulation)
                ValidItemVPops = getValidSelectedVPops(obj.TemporarySimulation.Settings,{obj.TemporarySimulation.Settings.VirtualPopulation.Name});
                if ~isempty(ValidItemVPops)
                    obj.VPopPopupTableItems = [{obj.TemporarySimulation.NullVPop} {ValidItemVPops.Name}];
                else
                    obj.VPopPopupTableItems = {obj.TemporarySimulation.NullVPop};
                end
            else
                obj.VPopPopupTableItems = 'char';
            end


            %Find the correct Data to be stored
            if ~isempty(obj.TemporarySimulation)
                TaskNames = {obj.TemporarySimulation.Item.TaskName};
                VPopNames = {obj.TemporarySimulation.Item.VPopName};
                Groups = {obj.TemporarySimulation.Item.Group};
                AvailableGroups = cell(1,length(obj.TemporarySimulation.Item));
                for k=1:length(obj.TemporarySimulation.Item)
                    WithName = obj.TemporarySimulation.Settings.getVpopWithName(obj.TemporarySimulation.Item(k).VPopName);
                    if isempty(WithName)
                        AvailableGroups{k} = 'N/A';
                    else
                        AvailableGroups{k} = WithName.Groups;
                    end
                end
                Data = [TaskNames(:) VPopNames(:) Groups(:) AvailableGroups(:) ];

                % Mark any invalid entries
                invalidIdx = []; % store invalid indices to create uistyle in table
                if ~isempty(Data)
                    % Task
                    MatchIdx = find(~ismember(TaskNames(:),obj.TaskPopupTableItems(:)));
                    for index = MatchIdx(:)'
                        if isempty(Data{index,1})
                            Data{index,1} = 'Click to configure';
                        else
                            Data{index,1} = QSP.makeInvalid(Data{index,1});
                            invalidIdx{end+1} = [index,1];
                        end
                    end
                    % VPop
                    MatchIdx = find(~ismember(VPopNames(:),obj.VPopPopupTableItems(:)));
                    for index = MatchIdx(:)'
                        Data{index,2} = QSP.makeInvalid(Data{index,2});
                        invalidIdx{end+1} = [index,2];
                    end
                end
            else
                Data = {};
            end


            %First, reset the data
            obj.SimItemsTable.Data = Data;

            %Then, reset the pop up options.
            %New uitable API cannot handle empty lists for table dropdowns.
            %Instead, we need to set the format to char.
            [columnFormat,editableTF] = obj.replaceEmptyDropdowns();
            obj.SimItemsTable.ColumnFormat = columnFormat;
            obj.SimItemsTable.ColumnEditable = editableTF;

            % Add style to any invalid entries
            removeStyle(obj.SimItemsTable);
            for i = 1:length(invalidIdx)
                QSP.makeInvalidStyle(obj.SimItemsTable, invalidIdx{i});
            end
        end

        function [columnFormat,editableTF] = replaceEmptyDropdowns(obj)
            columnFormat = {[],[],'char','char'};
            editableTF = [false,false,true,true];
            %             if isempty(columnFormat{1})
            %                 columnFormat{1} = 'char';
            %                 editableTF(1) = false;
            %             end
            if isempty(columnFormat{2})
                columnFormat{2} = 'char';
                editableTF(2) = false;
            end
        end

        function updateSpeciesTable(obj)
            AxesOptions = obj.getAxesOptions();
            if ~isempty(obj.Simulation)
                ItemTaskNames = {obj.Simulation.Item.TaskName};
                SpeciesNames = getSpeciesFromValidSelectedTasks(obj.Simulation.Settings,ItemTaskNames);
                InvalidIndices = ~ismember(SpeciesNames,obj.Simulation.PlotSpeciesTable(:,3));

                if isempty(obj.Simulation.PlotSpeciesTable)
                    % If empty, populate, but first update line styles
                    obj.Simulation.PlotSpeciesTable = cell(numel(SpeciesNames),4);
                    updateSpeciesLineStyles(obj.Simulation);

                    obj.Simulation.PlotSpeciesTable(:,1) = {' '};
                    obj.Simulation.PlotSpeciesTable(:,2) = obj.Simulation.SpeciesLineStyles(:);
                    obj.Simulation.PlotSpeciesTable(:,3) = SpeciesNames;
                    obj.Simulation.PlotSpeciesTable(:,4) = SpeciesNames;

                    obj.PlotSpeciesAsInvalidTable = obj.Simulation.PlotSpeciesTable;
                    obj.PlotSpeciesInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(SpeciesNames),4);
                    NewPlotTable(:,1) = {' '};
                    NewPlotTable(:,2) = {'-'};
                    NewPlotTable(:,3) = SpeciesNames;
                    NewPlotTable(:,4) = SpeciesNames;

                    % Adjust size if from an old saved session
                    if size(obj.Simulation.PlotSpeciesTable,2) == 2
                        obj.Simulation.PlotSpeciesTable(:,3) = obj.Simulation.PlotSpeciesTable(:,2);
                        obj.Simulation.PlotSpeciesTable(:,2) = {'-'};
                    end
                    if size(obj.Simulation.PlotSpeciesTable,2) == 3
                        obj.Simulation.PlotSpeciesTable(:,4) = obj.Simulation.PlotSpeciesTable(:,3);
                        obj.Simulation.PlotSpeciesTable(:,2) = {'-'};
                    end
                    % Update Table
                    KeyColumn = 3;
                    [obj.Simulation.PlotSpeciesTable,obj.PlotSpeciesAsInvalidTable,obj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.Simulation.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);
                    % Update line styles
                    updateSpeciesLineStyles(obj.Simulation);
                end
                obj.SpeciesTable.Data = obj.PlotSpeciesAsInvalidTable;
                obj.SpeciesTable.ColumnName = {'Plot','Style','Name','Display'};
                obj.SpeciesTable.ColumnFormat = {AxesOptions',obj.Simulation.Settings.LineStyleMap,'char','char'};
                obj.SpeciesTable.ColumnEditable = [true,true,false,true];
            else
                obj.SpeciesTable.Data = cell(0,4);
                obj.SpeciesTable.ColumnName = {'Plot','Style','Name','Display'};
                obj.SpeciesTable.ColumnFormat = {AxesOptions,'char','char','char'};
                obj.SpeciesTable.ColumnEditable = [true,true,false,true];
            end
        end

        function updateSimItemsTable(obj)
            if ~isempty(obj.Simulation)
                [obj.StaleFlag,obj.ValidFlag] = getStaleItemIndices(obj.Simulation);
                InvalidItemIndices = ~obj.ValidFlag;
                TaskNames = {obj.Simulation.Item.TaskName};
                VPopNames = {obj.Simulation.Item.VPopName};
                Groups    = {obj.Simulation.Item.Group};
                % If empty, populate
                if isempty(obj.Simulation.PlotItemTable)

                    if any(InvalidItemIndices)
                        % Then, prune
                        TaskNames(InvalidItemIndices) = [];
                        VPopNames(InvalidItemIndices) = [];
                    end

                    obj.Simulation.PlotItemTable = cell(numel(TaskNames),6);
                    obj.Simulation.PlotItemTable(:,1) = {false};
                    obj.Simulation.PlotItemTable(:,3) = TaskNames;
                    obj.Simulation.PlotItemTable(:,4) = VPopNames;
                    obj.Simulation.PlotItemTable(:,5) = Groups;
                    obj.Simulation.PlotItemTable(:,6) = cellfun(@(x,y)sprintf('%s - %s',x,y),TaskNames,VPopNames,'UniformOutput',false);

                    % Update the item colors
                    ItemColors = getItemColors(obj.Simulation.Session,numel(TaskNames));
                    obj.Simulation.PlotItemTable(:,2) = num2cell(ItemColors,2);

                    obj.PlotItemAsInvalidTable = obj.Simulation.PlotItemTable;
                    obj.PlotItemInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(TaskNames),4);
                    NewPlotTable(:,1) = {false};
                    NewPlotTable(:,3) = TaskNames;
                    NewPlotTable(:,4) = VPopNames;
                    NewPlotTable(:,5) = Groups;
                    NewPlotTable(:,6) = cellfun(@(x,y)sprintf('%s - %s',x,y),TaskNames,VPopNames,'UniformOutput',false);

                    NewColors = getItemColors(obj.Simulation.Session,numel(TaskNames));
                    NewPlotTable(:,2) = num2cell(NewColors,2);

                    if size(obj.Simulation.PlotItemTable,2) == 5
                        obj.Simulation.PlotItemTable(:,6) = cellfun(@(x,y)sprintf('%s - %s',x,y),obj.Simulation.PlotItemTable(:,3),obj.Simulation.PlotItemTable(:,4),'UniformOutput',false);
                    end

                    % Update Table
                    KeyColumn = [3 4 5];
                    [obj.Simulation.PlotItemTable,obj.PlotItemAsInvalidTable,obj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.Simulation.PlotItemTable,NewPlotTable,InvalidItemIndices,KeyColumn);
                end

                % Check which results files are invalid
                ResultsDir = fullfile(obj.Simulation.Session.RootDirectory,obj.Simulation.SimResultsFolderName);


                TableData = obj.PlotItemAsInvalidTable;

                % Update Colors column
                % Items table
                if any(obj.StaleFlag)
                    ThisLabel = 'Simulation Items (Items are not up-to-date)';
                else
                    ThisLabel = 'Simulation Items';
                end

                %Remove colors from table.
                for rowIndex = 1:1:size(obj.Simulation.PlotItemTable,1)
                    TableData{rowIndex,2} = '';
                end

                obj.SimulationItemsLabel.Text = ThisLabel;
                obj.SimulationItemsTable.Data = TableData;
                obj.SimulationItemsTable.ColumnName = {'Include','Color','Task','Virtual Subject(s)','Group','Display'};
                obj.SimulationItemsTable.ColumnFormat = {'logical','char','char','char','numeric','char'};
                obj.SimulationItemsTable.ColumnEditable = [true,false,false,false,false,true];

                % Only make the "valids" missing. Leave the invalids as is
                if ~isempty(TableData)
                    TaskNames = {obj.Simulation.Item.TaskName};
                    VPopNames = {obj.Simulation.Item.VPopName};
                    Groups = {obj.Simulation.Item.Group};

                    for index = 1:size(obj.Simulation.PlotItemTable,1)
                        % Check to see if this row is invalid. If it is not invalid,
                        % check to see if we need to mark the corresponding file as missing
                        if ~ismember(obj.PlotItemInvalidRowIndices,index)
                            ThisTaskName = obj.Simulation.PlotItemTable{index,3};
                            ThisVPopName = obj.Simulation.PlotItemTable{index,4};
                            ThisGroup = obj.Simulation.PlotItemTable{index,5};
                            MatchIdx = strcmp(ThisTaskName,TaskNames) & strcmp(ThisVPopName,VPopNames) & strcmp(ThisGroup, Groups);
                            if any(MatchIdx)
                                ThisFileName = obj.Simulation.Item(MatchIdx).MATFileName;
                                % Mark results file as missing
                                if ~isequal(exist(fullfile(ResultsDir,ThisFileName),'file'),2)
                                    QSP.makeItalicizedNew(obj.SimulationItemsTable, [index,3]);
                                    QSP.makeItalicizedNew(obj.SimulationItemsTable, [index,4]);
                                end
                            end %if
                        end %if
                    end %for
                end %if

                % Set cell color
                for index = 1:size(TableData,1)
                    ThisColor = obj.Simulation.PlotItemTable{index,2};
                    if ~isempty(ThisColor)
                        Temp = uistyle('BackgroundColor',ThisColor);
                        addStyle(obj.SimulationItemsTable,Temp,'cell',[index,2])
                    end
                end
            else
                obj.SimulationItemsTable.Data = cell(0,6);
                obj.SimulationItemsTable.ColumnName = {'Include','Color','Task','Virtual Subject(s)','Group','Display'};
                obj.SimulationItemsTable.ColumnFormat = {'logical','char','char','char','numeric','char'};
                obj.SimulationItemsTable.ColumnEditable = [true,false,false,false,false,true];
            end
        end

        function [OptimHeader,OptimData] = updateDataTable(obj)
            OptimHeader = {};
            OptimData = {};
            AxesOptions = obj.getAxesOptions();

            % DatasetHeaderPopupItems corresponds to header in DatasetName
            if ~isempty(obj.Simulation) && ~isempty(obj.Simulation.DatasetName)
                Names = {obj.Simulation.Settings.OptimizationData.Name};
                MatchIdx = strcmpi(Names,obj.Simulation.DatasetName);

                if any(MatchIdx)
                    dObj = obj.Simulation.Settings.OptimizationData(MatchIdx);

                    DestDatasetType = 'wide';
                    [StatusOk,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
                    if StatusOk
                        % Prune to remove Time, Group, etc.
                        TempDatasetHeaderPopupItems = setdiff(OptimHeader,{'Time','Group'});
                    else
                        TempDatasetHeaderPopupItems = {};
                    end
                else
                    TempDatasetHeaderPopupItems = {};
                end

                % Adjust size if from an old saved session
                if size(obj.Simulation.PlotDataTable,2) == 2
                    obj.Simulation.PlotDataTable(:,3) = obj.Simulation.PlotDataTable(:,2);
                    obj.Simulation.PlotDataTable(:,2) = {'*'};
                end
                if size(obj.Simulation.PlotDataTable,2) == 3
                    obj.Simulation.PlotDataTable(:,4) = obj.Simulation.PlotDataTable(:,3);
                end

                InvalidIndices = ~ismember(TempDatasetHeaderPopupItems,obj.Simulation.PlotDataTable(:,3));

                % If empty, populate
                if isempty(obj.Simulation.PlotDataTable)
                    obj.Simulation.PlotDataTable = cell(numel(TempDatasetHeaderPopupItems),4);
                    obj.Simulation.PlotDataTable(:,1) = {' '};
                    obj.Simulation.PlotDataTable(:,2) = {'*'};
                    obj.Simulation.PlotDataTable(:,3) = TempDatasetHeaderPopupItems;
                    obj.Simulation.PlotDataTable(:,4) = TempDatasetHeaderPopupItems;

                    obj.PlotDataAsInvalidTable = obj.Simulation.PlotDataTable;
                    obj.PlotDataInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(TempDatasetHeaderPopupItems),4);
                    NewPlotTable(:,1) = {' '};
                    NewPlotTable(:,2) = {'*'};
                    NewPlotTable(:,3) = TempDatasetHeaderPopupItems;
                    NewPlotTable(:,4) = TempDatasetHeaderPopupItems;

                    % Update Table
                    KeyColumn = 3;
                    [obj.Simulation.PlotDataTable,obj.PlotDataAsInvalidTable,obj.PlotDataInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.Simulation.PlotDataTable,NewPlotTable,InvalidIndices,KeyColumn);
                end

                obj.DataTable.Data = obj.PlotDataAsInvalidTable;
                obj.DataTable.ColumnName = {'Plot','Marker','Name','Display'};
                obj.DataTable.ColumnFormat = {AxesOptions',obj.Simulation.Settings.LineMarkerMap,'char','char'};
                obj.DataTable.ColumnEditable = [true,true,false,true];
            else
                % Dataset table
                obj.DataTable.Data = cell(0,4);
                obj.DataTable.ColumnName = {'Plot','Marker','Name','Display'};
                obj.DataTable.ColumnFormat = {AxesOptions',obj.Simulation.Settings.LineMarkerMap,'char','char'};
                obj.DataTable.ColumnEditable = [true,true,false,true];
            end

        end

        function updateGroupTable(obj,OptimHeader,OptimData)
            if ~isempty(obj.Simulation) && ~isempty(OptimData)
                MatchIdx = strcmp(OptimHeader,obj.Simulation.GroupName);
                GroupIDs = OptimData(:,MatchIdx);
                if iscell(GroupIDs)
                    GroupIDs = cell2mat(GroupIDs);
                end
                GroupIDs = unique(GroupIDs);
                GroupIDNames = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);

                InvalidIndices = ~ismember(GroupIDNames,obj.Simulation.PlotGroupTable(:,3));

                % If empty, populate
                if isempty(obj.Simulation.PlotGroupTable)
                    obj.Simulation.PlotGroupTable = cell(numel(GroupIDNames),4);
                    obj.Simulation.PlotGroupTable(:,1) = {false};
                    obj.Simulation.PlotGroupTable(:,3) = GroupIDNames;
                    obj.Simulation.PlotGroupTable(:,4) = GroupIDNames;

                    % Update the group colors
                    GroupColors = getGroupColors(obj.Simulation.Session,numel(GroupIDNames));
                    obj.Simulation.PlotGroupTable(:,2) = num2cell(GroupColors,2);

                    obj.PlotGroupAsInvalidTable = obj.Simulation.PlotGroupTable;
                    obj.PlotGroupInvalidRowIndices = [];
                else
                    NewPlotTable = cell(numel(GroupIDNames),4);
                    NewPlotTable(:,1) = {false};
                    NewPlotTable(:,3) = GroupIDNames;
                    NewPlotTable(:,4) = GroupIDNames;

                    NewColors = getGroupColors(obj.Simulation.Session,numel(GroupIDNames));
                    NewPlotTable(:,2) = num2cell(NewColors,2);

                    % Update Table
                    KeyColumn = 3;
                    [obj.Simulation.PlotGroupTable,obj.PlotGroupAsInvalidTable,obj.PlotGroupInvalidRowIndices] = QSPViewer.updateVisualizationTable(obj.Simulation.PlotGroupTable,NewPlotTable,InvalidIndices,KeyColumn);

                end

                % Update Colors column
                TableData = obj.PlotGroupAsInvalidTable;
                %Remove color information from the cell
                for rowIndex = 1:size(obj.Simulation.PlotGroupTable,1)
                    TableData{rowIndex,2} = '';
                end

                obj.GroupTable.Data = TableData;
                obj.GroupTable.ColumnName ={'Include','Color','Name','Display'};
                obj.GroupTable.ColumnFormat = {'logical','char','char','char'};
                obj.GroupTable.ColumnEditable = [true,false,false,true];
                % Set cell color
                for index = 1:size(TableData,1)
                    ThisColor = obj.Simulation.PlotGroupTable{index,2};
                    if ~isempty(ThisColor)
                        if ischar(ThisColor) %html string
                            rgb = regexp(ThisColor, 'bgcolor="#(\w{2})(\w{2})(\w{2})', 'tokens');
                            rgb = rgb{1};
                            ThisColor = [hex2dec(rgb{1}), hex2dec(rgb{2}), hex2dec(rgb{3})]/255;

                        end
                        Temp = uistyle('BackgroundColor',ThisColor);
                        addStyle(obj.GroupTable,Temp,'cell',[index,2])
                    end
                end

            else
                obj.GroupTable.Data = cell(0,4);
                obj.GroupTable.ColumnName ={'Include','Color','Name','Display'};
                obj.GroupTable.ColumnFormat = {'logical','char','char','char'};
                obj.GroupTable.ColumnEditable = [true,false,false,true];
            end
        end
    end
end

