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
            if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.DatasetDataColumn)
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
            
% %             TODO Codee taken from a edit field callback. IT makes no sense
% %              TypeCol = find(strcmp(VPopHeader,'Type'));
% % 
% %             obj.bShowTraces(1:obj.MaxNumPlots) = false; % default off
% %             obj.bShowQuantiles(1:obj.MaxNumPlots) = true; % default on
% %             obj.bShowMean(1:obj.MaxNumPlots) = true; % default on
% %             obj.bShowMedian(1:obj.MaxNumPlots) = false; % default off
% %             obj.bShowSD(1:obj.MaxNumPlots) = false; % default off, unless Type = MEAN_STD
% % 
% %             if ~isempty(TypeCol)
% %                 ThisType = VPopData(:,TypeCol);
% %                 if any(strcmp(ThisType,'MEAN_STD')) % If MEAN_STD, then show SD
% %                     obj.bShowSD(1:obj.MaxNumPlots) = true;
% %                 end
% %             end
% % 
% %             Update context menu - since defaults are the same, okay to use first
% %             value and assign to rest
% %             set(obj.h.ContextMenuTraces,'Checked',uix.utility.tf2onoff(obj.bShowTraces(1)));
% %             set(obj.h.ContextMenuQuantiles,'Checked',uix.utility.tf2onoff(obj.bShowQuantiles(1)));
% %             set(obj.h.ContextMenuMean,'Checked',uix.utility.tf2onoff(obj.bShowMean(1)));
% %             set(obj.h.ContextMenuMedian,'Checked',uix.utility.tf2onoff(obj.bShowMedian(1)));
% %             set(obj.h.ContextMenuSD,'Checked',uix.utility.tf2onoff(obj.bShowSD(1)));

            
          
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
                GroupIDs = obj.DatasetData(:,MatchIdx);
                if iscell(GroupIDs)
                    try
                        GroupIDs = cell2mat(GroupIDs);
                    catch
                        uialert(obj.getUIFigure,'Invalid group ID column selected. Only numeric values are allowed','Warning')
                        return
                    end

                end
                GroupIDs = unique(GroupIDs);
                obj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
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
                GroupIDs = {obj.TemporaryVirtualPopulationGeneration.Item.GroupID};
                RunToSteadyState = false(size(TaskNames));

                for index = 1:numel(TaskNames)
                    MatchIdx = strcmpi(TaskNames{index},{obj.TemporaryVirtualPopulationGeneration.Settings.Task.Name});
                    if any(MatchIdx)
                        RunToSteadyState(index) = obj.TemporaryVirtualPopulationGeneration.Settings.Task(MatchIdx).RunToSteadyState;
                    end
                end
                
                Data = [TaskNames(:) GroupIDs(:) num2cell(RunToSteadyState(:))];
                if ~isempty(Data)
                    for index = 1:numel(TaskNames)
                        ThisTask = getValidSelectedTasks(obj.TemporaryVirtualPopulationGeneration.Settings,TaskNames{index});
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
            
            if ~isempty(obj.TemporaryVirtualPopulationGeneration) && ~isempty(obj.DatasetHeader) && ~isempty(obj.DatasetData)
                MatchIdx = strcmp(obj.DatasetHeader,obj.TemporaryVirtualPopulationGeneration.GroupName);
                GroupIDs = obj.DatasetData(:,MatchIdx);
                if iscell(GroupIDs)
                    GroupIDs = cell2mat(GroupIDs);        
                end    
                GroupIDs = unique(GroupIDs);
                obj.GroupIDPopupTableItems = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
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
        
    end
        
end




