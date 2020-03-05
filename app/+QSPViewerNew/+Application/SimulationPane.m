classdef SimulationPane < QSPViewerNew.Application.ViewPane
    %  SimulationPane - A Class for the Virtual Population Generation Data Pane view. This is the
    %  'viewer' counterpart to the 'model' class
    %  QSP.Simulation
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  3/2/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        Simulation = QSP.Simulation.empty()
        TemporarySimulation = QSP.Simulation.empty()
        IsDirty = false
    end
    
    properties (Access=private)
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
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        ResultFolderListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        SimulationEditGrid          matlab.ui.container.GridLayout
        ResultFolderSelector        QSPViewerNew.Widgets.FolderSelector
        DatasetGrid                 matlab.ui.container.GridLayout
        DatasetDropDown             matlab.ui.control.DropDown
        DatasetLabel                matlab.ui.control.Label
        GroupColumnGrid             matlab.ui.container.GridLayout
        GroupColumnDropDown         matlab.ui.control.DropDown
        GroupColumnLabel            matlab.ui.control.Label
        SimItemLabelGrid            matlab.ui.container.GridLayout
        SimItemLabel                matlab.ui.control.Label
        SimItemGrid                 matlab.ui.container.GridLayout
        SimButtonGrid               matlab.ui.container.GridLayout
        NewButton                   matlab.ui.control.Button
        RemoveButton                matlab.ui.control.Button
        SimItemsTable               matlab.ui.control.Table
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = SimulationPane(varargin)
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
            obj.DatasetGrid.ColumnWidth = {obj.LabelLength,'1x'};
            obj.DatasetGrid.RowHeight = {obj.WidgetHeight};
            obj.DatasetGrid.Layout.Row = 2;
            obj.DatasetGrid.Layout.Column = 1;
            obj.DatasetGrid.Padding = [0,0,0,0];
            obj.DatasetGrid.RowSpacing = 0;
            obj.DatasetGrid.ColumnSpacing = 0;
            
            obj.DatasetDropDown = uidropdown(obj.DatasetGrid);
            obj.DatasetDropDown.Layout.Column = 2;
            obj.DatasetDropDown.Layout.Row = 1;
            obj.DatasetDropDown.Items = {'wide','tall'};
            obj.DatasetDropDown.ValueChangedFcn = @(h,e)obj.onDatasetChange();
            
            obj.DatasetLabel = uilabel(obj.DatasetGrid);
            obj.DatasetLabel.Layout.Column = 1;
            obj.DatasetLabel.Layout.Row = 1;
            obj.DatasetLabel.Text = ' Dataset';
            
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
            obj.SimButtonGrid.RowHeight = {obj.ButtonHeight,obj.ButtonHeight};
            obj.SimButtonGrid.Layout.Row = 1;
            obj.SimButtonGrid.Layout.Column = 1;
            obj.SimButtonGrid.Padding = [0,0,0,0];
            obj.SimButtonGrid.RowSpacing = 0;
            obj.SimButtonGrid.ColumnSpacing = 0;
            
            
            % New Button
           obj.NewButton = uibutton(obj.SimButtonGrid,'push');
           obj.NewButton.Layout.Row = 1;
           obj.NewButton.Layout.Column = 1;
           obj.NewButton.Icon = '+QSPViewerNew\+Resources\add_24.png';
           obj.NewButton.Text = '';
           obj.NewButton.ButtonPushedFcn = @(h,e)obj.onAddSimItem();
            
            %Remove Button
           obj.RemoveButton = uibutton(obj.SimButtonGrid,'push');
           obj.RemoveButton.Layout.Row = 2;
           obj.RemoveButton.Layout.Column = 1;
           obj.RemoveButton.Icon = '+QSPViewerNew\+Resources\delete_24.png';
           obj.RemoveButton.Text = '';
           obj.RemoveButton.ButtonPushedFcn = @(h,e)obj.onRemoveSimItem();
           
           %Table 
           obj.SimItemsTable = uitable(obj.SimItemGrid);
           obj.SimItemsTable.Layout.Row = 1;
           obj.SimItemsTable.Layout.Column = 2;
           obj.SimItemsTable.Data = {};
           obj.SimItemsTable.ColumnName = {'Task','Virtual Subject(s)','Virtual Subject Group to Simulate', 'Available Groups in Virtual Subjects'};
           obj.SimItemsTable.ColumnFormat = {obj.TaskPopupTableItems,obj.VPopPopupTableItems,'char','char'};
           obj.SimItemsTable.ColumnEditable = [true,true,true,true];
           obj.SimItemsTable.CellEditCallback = @(h,e) obj.onTableSelectionEdit(e);
           obj.SimItemsTable.CellSelectionCallback = @(h,e) obj.onTableSelectionChange(e);
        end
        
        function createListenersAndCallbacks(obj)
            obj.ResultFolderListener = addlistener(obj.ResultFolderSelector,'StateChanged',@(src,event) obj.onResultsPath(event.Source.getRelativePath()));
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onRemoveSimItem(obj)
            DeleteIdx = obj.SelectedRow;
            if DeleteIdx <= numel(obj.TemporarySession.Item)
                 obj.TemporarySession.Item(DeleteIdx) = [];
            end
            obj.updateItemsTable(obj);
            obj.IsDirty = true;
        end
        
        function onAddSimItem(obj)
            if ~isempty(vObj.TaskPopupTableItems)
                    NewTaskVPop = QSP.TaskVirtualPopulation;
                    NewTaskVPop.TaskName = obj.TaskPopupTableItems{1};
                    NewTaskVPop.VPopName = obj.VPopPopupTableItems{1};
                    NewTaskVPop.Group = '';
                    obj.TemporarySession.Item(end+1) = NewTaskVPop;
                else
                    hDlg = uialert(obj.getUIFigure(),'At least one task must be defined in order to add a simulation item.','Cannot Add');
                    uiwait(hDlg);
            end
            obj.updateItemsTable(obj);
            obj.IsDirty = true;
        end
        
        function onDatasetChange(obj)
            obj.TemporarySimulation.DatasetName = obj.DatasetDropDown.Value;
            %First update the dataset information
            obj.updateDataset();
            %update the Group column next, because it is dependent. 
            obj.updateGroupColumn();
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
            obj.SelectedRow = eventData.Indices(1);
            obj.IsDirty = true;
        end
        
        function onTableSelectionEdit(obj,eventData)
            Indices = eventData.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            obj.SelectedRow = RowIdx;
            
            % Update entry
            HasChanged = false;
            if ColIdx == 1
                if ~isequal(obj.TemporarySimulation.Item(RowIdx).TaskName,eventData.NewData)
                    HasChanged = true;                    
                end
                obj.TemporarySimulation.Item(RowIdx).TaskName = eventData.NewDataNewData;
            elseif ColIdx == 3 % Group
                if ~isequal(obj.TemporarySimulation.Item(RowIdx).VPopName,eventData.NewData)
                    HasChanged = true;                    
                end
                obj.TemporarySimulation.Item(RowIdx).Group = eventData.NewData;                
            elseif ColIdx == 2 % Vpop
                if ~isequal(obj.TemporarySimulation.Item(RowIdx).VPopName,eventData.NewData)
                    HasChanged = true;                    
                end
                obj.TemporarySimulation.Item(RowIdx).VPopName = eventData.NewData;                
            end
            % Clear the MAT file name
            if HasChanged
                obj.TemporarySimulation.Item(RowIdx).MATFileName = '';
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
        
    end
    
    methods (Access = public) 
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewSimulation(obj,NewSimulation)
            obj.Simulation = NewSimulation;
            obj.TemporarySimulation = copy(obj.Simulation);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
        function runModel(obj)
            [StatusOK,Message,~] = run(obj.Simulation);
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            end
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
        
        function saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporarySimulation.validate(FlagRemoveInvalid);          
            
            if StatusOK
                obj.TemporarySimulation.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.Simulation = copy(obj.TemporarySimulation,obj.Simulation);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.TemporarySimulation.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporarySimulation)
            obj.TemporarySimulation = copy(obj.Simulation);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporarySimulation.Description);
            obj.updateNameBox(obj.TemporarySimulation.Name);
            obj.updateSummary(obj.TemporarySimulation.getSummary());
            
            obj.ResultFolderSelector.setRootDirectory(obj.TemporarySimulation.Session.RootDirectory);
            obj.updateResultsDir();
            obj.updateDataset();
            obj.updateGroupColumn();
            obj.updateSimulationTable();
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporarySimulation,FlagRemoveInvalid);
            obj.draw()
        end
        
    end
    
    methods (Access = private)
        
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
                
                obj.DatasetDropDown.Items = obj.DatasetPopupItemsWithInvalid;
                obj.DatasetDropDown.Value = obj.DatasetPopupItemsWithInvalid{Value};
            else
                obj.DatasetDropDown.Items = obj.DatasetPopupItemsWithInvalid;
                obj.DatasetDropDown.Value = obj.DatasetPopupItemsWithInvalid{1};
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
            obj.ResultFolderSelector.setRelativePath(obj.TemporarySimulation.SimResultsFolderName);
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
                obj.TaskPopupTableItems = {};
            end

            %% Refresh VPopPopupTableItems
            if ~isempty(obj.TemporarySimulation)
                ValidItemVPops = getValidSelectedVPops(obj.TemporarySimulation.Settings,{obj.TemporarySimulation.Settings.VirtualPopulation.Name});    
                if ~isempty(ValidItemVPops)
                    obj.VPopPopupTableItems = [{obj.TemporarySimulation.NullVPop} {ValidItemVPops.Name}];        
                else
                    obj.VPopPopupTableItems = {obj.TemporarySimulation.NullVPop};
                end
            else
                obj.VPopPopupTableItems = {};
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
                if ~isempty(Data)
                    % Task
                    MatchIdx = find(~ismember(TaskNames(:),obj.TaskPopupTableItems(:)));
                    for index = MatchIdx(:)'
                        Data{index,1} = QSP.makeInvalid(Data{index,1});
                    end        
                    % VPop
                    MatchIdx = find(~ismember(VPopNames(:),obj.VPopPopupTableItems(:)));
                    for index = MatchIdx(:)'
                        Data{index,2} = QSP.makeInvalid(Data{index,2});
                    end
                end
            else
                Data = {};
            end
            
            
            %First, reset the data
            obj.SimItemsTable.Data = Data;
            
            %Then, reset the pop up options
            obj.SimItemsTable.ColumnFormat = {obj.TaskPopupTableItems,obj.VPopPopupTableItems,'char','char'};
        end
        
        
    end
        
end

