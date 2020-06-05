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
        SpeciesGroup
        DatasetGroup
        AxesLegend
        AxesLegendChildren
        
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
        
        DatasetHeader = {}
        PrunedDatasetHeader = {};
        DatasetData = {};
        
        ParametersHeader = {} 
        ParametersData = {} 
        
        FixRNGSeed = false
        RNGSeed = 100
        
        ObjectiveFunctions = {'defaultObj'}
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
            obj.ParametersTable = uitable(obj.EditLayout);
            obj.ParametersTable.Layout.Row = 5;
            obj.ParametersTable.Layout.Column = 1;
            obj.ParametersTable.ColumnEditable = false;
            
        end
        
        function createListenersAndCallbacks(obj)
        %Listeners
        obj.ResultsPathListener = addlistener(obj.ResultsPath,'StateChanged',@(src,event) obj.onEditResultsPath(event.Source.getRelativePath()));
        
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

    end
    
    methods (Access = public) 
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewOptimization(obj,NewOptimization)
            obj.Optimization = NewOptimization;
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
            [StatusOK,Message,~] = run(obj.Optimization);
            if ~StatusOK
                uialert(obj.getUIFigure,Message,'Run Failed');
            end
        end
        
        function drawVisualization(obj)
            
            %DropDown Update
            obj.updatePlotConfig(obj.Optimization.SelectedPlotLayout);
            
            %Determine if the values are valid
            if ~isempty(obj.Optimization)
                % Check what items are stale or invalid
                [~,~] = getStaleItemIndices(obj.Optimization);  
            end
            
            %Set flags for determing what to display
            if ~isempty(obj.Optimization)
                obj.Optimization.bShowTraces = obj.bShowTraces;
                obj.Optimization.bShowQuantiles = obj.bShowQuantiles;
                obj.Optimization.bShowMean = obj.bShowMean;
                obj.Optimization.bShowMedian = obj.bShowMedian;
                obj.Optimization.bShowSD = obj.bShowSD;
            end
            
          
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
        
        function saveVisualizationView(obj)
            %TODO
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
    end
    
    methods (Access = private)
        
        function redrawResultsPath(obj)
            obj.ResultsPath.setRootDirectory(obj.TemporaryOptimization.Session.RootDirectory);
            obj.ResultsPath.setRelativePath(obj.TemporaryOptimization.OptimResultsFolderName);
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
            
            if ~isempty(obj.TemporaryOptimization) && ~isempty(obj.TemporaryOptimization.DatasetName) && ~isempty(obj.TemporaryOptimization.Settings.OptimizationData)
                Names = {obj.TemporaryOptimization.Settings.OptimizationData.Name};
                MatchIdx = strcmpi(Names,obj.TemporaryOptimization.DatasetName);

                if any(MatchIdx)
                    dobj = obj.TemporaryOptimization.Settings.OptimizationData(MatchIdx);

                    DestDatasetType = 'wide';
                    [~,~,OptimHeader,OptimData] = importData(dobj,dobj.FilePath,DestDatasetType);
                else
                    OptimHeader = {};
                    OptimData = {};
                end
            else
                OptimHeader = {};
                OptimData = {};
            end
            obj.DatasetHeader = OptimHeader;
            obj.PrunedDatasetHeader = setdiff(OptimHeader,{'Time','Group'}); 
            obj.DatasetData = OptimData;
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
            else
                obj.GroupIDPopupTableItems = {};
            end
            
            obj.OptimizationTable.setEditable([true true false]);
            obj.OptimizationTable.setName({'Task','Group','Run To Steady State'});
            obj.OptimizationTable.setFormat({obj.TaskPopupTableItems(:)',obj.GroupIDPopupTableItems(:)','char'});
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
            
            obj.SpeciesDataTable.setEditable([true true false true true]);
            obj.SpeciesDataTable.setName({'Data (y)','Species (x)','# Tasks per Species','y=f(x)','ObjectiveFcn'});
            obj.SpeciesDataTable.setFormat({obj.PrunedDatasetHeader(:)',obj.SpeciesPopupTableItems(:)','numeric','char',obj.ObjectiveFunctions(:)'});
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
            
            obj.SpeciesInitialTable.setEditable([true true true]);
            obj.SpeciesInitialTable.setName({'Species (y)','Data (x)','y=f(x)'});
            obj.SpeciesInitialTable.setFormat({obj.SpeciesPopupTableItems(:)',obj.PrunedDatasetHeader(:)','char'});
            obj.SpeciesInitialTable.setData(Data)
            
        end
    end
        
end


