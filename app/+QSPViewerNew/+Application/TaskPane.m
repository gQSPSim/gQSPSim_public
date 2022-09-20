classdef TaskPane < QSPViewerNew.Application.ViewPane 
    %  TaskPane - A Class for the session settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.Task
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  2/14/20
    % ---------------------------------------------------------------------
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        Task = QSP.Task.empty()
        TemporaryTask = QSP.Task.empty();
        IsDirty;
        LastPath = pwd
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = private)
        VariantstoActivateListener
        DosestoIncludeListener
        RulestoDeactivateListener
        ReactionstoDeactivatexListener
        SpeciestoIncludeListener
        ProjectFileListener
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterTaskGrid               matlab.ui.container.GridLayout
        ModelGrid                   matlab.ui.container.GridLayout
        ModelLabel                  matlab.ui.control.Label
        ModelDropDown               matlab.ui.control.DropDown
        ProjectFileSelector         QSPViewerNew.Widgets.FileSelector
        ListBoxGrid                 matlab.ui.container.GridLayout
        VariantstoActivateDoubleBox QSPViewerNew.Widgets.DoubleSelectBox
        DosestoIncludeDoubleBox     QSPViewerNew.Widgets.DoubleSelectBox
        RulestoDeactivateDoubleBox  QSPViewerNew.Widgets.DoubleSelectBox
        ReactionstoDeactivateDoubleBox    QSPViewerNew.Widgets.DoubleSelectBox
        SettingsPanel               matlab.ui.container.Panel
        SettingsGrid                matlab.ui.container.GridLayout
        OutputTimesEdit             matlab.ui.control.EditField
        MaxWallClockEdit            matlab.ui.control.NumericEditField
        TimetoSteadyStateEdit       matlab.ui.control.NumericEditField
        TimetoSteadyStateLabel      matlab.ui.control.Label
        RuntoSteadyStateCheckBox    matlab.ui.control.CheckBox
        MaxWallClockLabel           matlab.ui.control.Label
        OutputTimesLabel            matlab.ui.control.Label
        AbsToleranceLabel           matlab.ui.control.Label
        AbsToleranceEdit            matlab.ui.control.NumericEditField
        RelToleranceLabel           matlab.ui.control.Label
        RelToleranceEdit            matlab.ui.control.NumericEditField
        SpeciestoIncludeDoubleBox   QSPViewerNew.Widgets.DoubleSelectBox
    end
        
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods              
        function obj = TaskPane(pvargs)
            arguments
                pvargs.Parent (1,1) matlab.ui.container.GridLayout
                pvargs.layoutrow (1,1) double = 1
                pvargs.layoutcolumn (1,1) double = 1
                pvargs.parentApp
                pvargs.HasVisualization (1,1) logical = false
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
            obj.OuterTaskGrid = uigridlayout(obj.getEditGrid());
            obj.OuterTaskGrid.ColumnWidth = {'1x'};
            obj.OuterTaskGrid.RowHeight = {obj.WidgetHeight, obj.WidgetHeight, '1x'};
            obj.OuterTaskGrid.Layout.Row = 3;
            obj.OuterTaskGrid.Layout.Column = 1;
            obj.OuterTaskGrid.Padding = obj.WidgetPadding;
            obj.OuterTaskGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.OuterTaskGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            % Create DropDown Grid
            obj.ModelGrid = uigridlayout(obj.OuterTaskGrid);
            obj.ModelGrid.ColumnWidth = {100, '1x'};
            obj.ModelGrid.RowHeight = {'1x'};
            obj.ModelGrid.Layout.Row = 2;
            obj.ModelGrid.Layout.Column = 1;
            obj.ModelGrid.Padding = obj.WidgetPadding;

            % Create Dropdown Label
            obj.ModelLabel = uilabel(obj.ModelGrid);
            obj.ModelLabel.Layout.Row = 1;
            obj.ModelLabel.Layout.Column = 1;
            obj.ModelLabel.Text = ' Model';

            % Create DropDown
            obj.ModelDropDown = uidropdown(obj.ModelGrid);
            obj.ModelDropDown.Layout.Row = 1;
            obj.ModelDropDown.Layout.Column = 2;

            % Create Project select
            obj.ProjectFileSelector = QSPViewerNew.Widgets.FileSelector(obj.OuterTaskGrid,1,1,' Project');
            obj.ProjectFileSelector.setFileExtension('.sbproj');

            % Create SecondaryGrid
            obj.ListBoxGrid = uigridlayout(obj.OuterTaskGrid);
            obj.ListBoxGrid.ColumnWidth = {'1x', '1x', '1x'};
            obj.ListBoxGrid.RowHeight = {'1x', '1x'};
            obj.ListBoxGrid.Layout.Row = 3;
            obj.ListBoxGrid.Layout.Column = 1;

            % Create VariantstoActivate DoubleSelectBox
            obj.VariantstoActivateDoubleBox = QSPViewerNew.Widgets.DoubleSelectBox(obj.ListBoxGrid,1,1,'Variants to Activate');

            % Create DosestoInclude DoubleSelectBox
            obj.DosestoIncludeDoubleBox = QSPViewerNew.Widgets.DoubleSelectBox(obj.ListBoxGrid,1,2,'Doses to Include');

            % Create RulestoDeactivate DoubleSelectBox
            obj.RulestoDeactivateDoubleBox = QSPViewerNew.Widgets.DoubleSelectBox(obj.ListBoxGrid,2,1,'Rules to Deactivate');

            % Create ReactionstoDeactivate DoubleSelectBox
            obj.ReactionstoDeactivateDoubleBox = QSPViewerNew.Widgets.DoubleSelectBox(obj.ListBoxGrid,2,2,'Reactions to Deactivate');
            
            % Create SpeciestoIncludePanel
            obj.SpeciestoIncludeDoubleBox = QSPViewerNew.Widgets.DoubleSelectBox(obj.ListBoxGrid,1,3,'Species to Include');

            % Create SettingsPanel
            obj.SettingsPanel = uipanel(obj.ListBoxGrid);
            obj.SettingsPanel.TitlePosition = 'centertop';
            obj.SettingsPanel.Title = 'Settings';
            obj.SettingsPanel.Layout.Row = 2;
            obj.SettingsPanel.Layout.Column = 3;

            % Create GridLayout5
            obj.SettingsGrid = uigridlayout(obj.SettingsPanel);
            obj.SettingsGrid.ColumnWidth = {'1x'};
            obj.SettingsGrid.RowHeight = {obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, obj.WidgetHeight, '1x'};
            obj.SettingsGrid.Padding = obj.WidgetPadding;
            obj.SettingsGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.SettingsGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            obj.SettingsGrid.Scrollable = true;
            
            % Create OutputTimesLabel
            obj.OutputTimesLabel = uilabel(obj.SettingsGrid);
            obj.OutputTimesLabel.Layout.Row = 1;
            obj.OutputTimesLabel.Layout.Column = 1;
            obj.OutputTimesLabel.Text = 'Output Times';
            
            % Create OutputTimesEdit
            obj.OutputTimesEdit = uieditfield(obj.SettingsGrid, 'text');
            obj.OutputTimesEdit.Layout.Row = 2;
            obj.OutputTimesEdit.Layout.Column = 1;
            
            % Create MaxWallClocksecLabel
            obj.MaxWallClockLabel = uilabel(obj.SettingsGrid);
            obj.MaxWallClockLabel.Layout.Row = 3;
            obj.MaxWallClockLabel.Layout.Column = 1;
            obj.MaxWallClockLabel.Text = 'Max Wall Clock (sec):';

            % Create MaxWallClockEdit
            obj.MaxWallClockEdit = uieditfield(obj.SettingsGrid, 'numeric');
            obj.MaxWallClockEdit.Layout.Row = 4;
            obj.MaxWallClockEdit.Layout.Column = 1;
            
            % Create MaxWallClocksecLabel
            obj.AbsToleranceLabel = uilabel(obj.SettingsGrid);
            obj.AbsToleranceLabel.Layout.Row = 5;
            obj.AbsToleranceLabel.Layout.Column = 1;
            obj.AbsToleranceLabel.Text = 'Absolute Tolerance:';

            % Create MaxWallClockEdit
            obj.AbsToleranceEdit = uieditfield(obj.SettingsGrid, 'numeric');
            obj.AbsToleranceEdit.Layout.Row = 6;
            obj.AbsToleranceEdit.Layout.Column = 1;
            
            % Create MaxWallClocksecLabel
            obj.RelToleranceLabel = uilabel(obj.SettingsGrid);
            obj.RelToleranceLabel.Layout.Row = 7;
            obj.RelToleranceLabel.Layout.Column = 1;
            obj.RelToleranceLabel.Text = 'Relative Tolerance:';

            % Create MaxWallClockEdit
            obj.RelToleranceEdit = uieditfield(obj.SettingsGrid, 'numeric');
            obj.RelToleranceEdit.Layout.Row = 8;
            obj.RelToleranceEdit.Layout.Column = 1;
            
            % Create TimetoSteadyStateLabel
            obj.TimetoSteadyStateLabel = uilabel(obj.SettingsGrid);
            obj.TimetoSteadyStateLabel.Layout.Row = 10;
            obj.TimetoSteadyStateLabel.Layout.Column = 1;
            obj.TimetoSteadyStateLabel.Text = 'Time to Steady State:';

            % Create TimetoSteadyStateEdit
            obj.TimetoSteadyStateEdit = uieditfield(obj.SettingsGrid, 'numeric');
            obj.TimetoSteadyStateEdit.Layout.Row = 11;
            obj.TimetoSteadyStateEdit.Layout.Column = 1;

            % Create RuntoSteadyStateCheckBox
            obj.RuntoSteadyStateCheckBox = uicheckbox(obj.SettingsGrid);
            obj.RuntoSteadyStateCheckBox.Text = 'Run to Steady State';
            obj.RuntoSteadyStateCheckBox.Layout.Row = 9;
            obj.RuntoSteadyStateCheckBox.Layout.Column = 1;
        end
        
        function createListenersAndCallbacks(obj)
            %Listeners
            obj.VariantstoActivateListener = addlistener(obj.VariantstoActivateDoubleBox,'StateChanged',@(src,event) obj.onVariantstoActivate(event.Source.getRightList()));
            obj.DosestoIncludeListener = addlistener(obj.DosestoIncludeDoubleBox,'StateChanged',@(src,event) obj.onDosestoInclude(event.Source.getRightList()));
            obj.RulestoDeactivateListener = addlistener(obj.RulestoDeactivateDoubleBox,'StateChanged',@(src,event) obj.onRulestoDeactivate(event.Source.getRightList()));
            obj.ReactionstoDeactivatexListener = addlistener(obj.ReactionstoDeactivateDoubleBox,'StateChanged',@(src,event) obj.onReactionstoDeactivate(event.Source.getRightList()));
            obj.SpeciestoIncludeListener = addlistener(obj.SpeciestoIncludeDoubleBox,'StateChanged',@(src,event) obj.onSpeciestoInclude(event.Source.getRightList()));
            obj.ProjectFileListener = addlistener(obj.ProjectFileSelector,'StateChanged',@(src,event) obj.onProjectFileSelector(event.Source.RelativePath));
            
            %Callbacks
            obj.OutputTimesEdit.ValueChangedFcn = @(h,e) obj.onOutputTimesEdit(e.Value);
            obj.MaxWallClockEdit.ValueChangedFcn = @(h,e) obj.onMaxWallClockEdit(e.Value);
            obj.AbsToleranceEdit.ValueChangedFcn = @(h,e) obj.onAbsToleranceEdit(e.Value);
            obj.RelToleranceEdit.ValueChangedFcn = @(h,e) obj.onRelToleranceEdit(e.Value);
            obj.TimetoSteadyStateEdit.ValueChangedFcn = @(h,e) obj.onTimetoSteadyStateEdit(e.Value);
            obj.RuntoSteadyStateCheckBox.ValueChangedFcn = @(h,e) obj.onRuntoSteadyStateCheckBox(e.Value);
            obj.ModelDropDown.ValueChangedFcn = @(h,e) obj.onModelDropDown(e.Value);

        end
        
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onVariantstoActivate(obj,NewData)
            obj.TemporaryTask.ActiveVariantNames  = NewData;
            obj.IsDirty = true;
        end
        
        function onDosestoInclude(obj,NewData)
            obj.TemporaryTask.ActiveDoseNames = NewData;
            obj.IsDirty = true;
        end
        
        function onRulestoDeactivate(obj,NewData)
            obj.TemporaryTask.InactiveRuleNames = NewData;
            obj.IsDirty = true;
        end
        
        function onReactionstoDeactivate(obj,NewData)
            obj.TemporaryTask.InactiveReactionNames = NewData;
            obj.IsDirty = true;
        end
        
        function onSpeciestoInclude(obj,NewData)
            obj.TemporaryTask.ActiveSpeciesNames = NewData;
            obj.IsDirty = true;
        end
        
        function onOutputTimesEdit(obj,NewData)
            obj.TemporaryTask.OutputTimesStr = NewData;
            obj.IsDirty = true;
        end
        
        function onMaxWallClockEdit(obj,NewData)
            obj.TemporaryTask.MaxWallClockTime = NewData;
            obj.IsDirty = true;
        end
        
        function onAbsToleranceEdit(obj,NewData)
            obj.TemporaryTask.AbsoluteTolerance = NewData;
            obj.IsDirty = true;
        end
        
        function onRelToleranceEdit(obj,NewData)
            obj.TemporaryTask.RelativeTolerance = NewData;
            obj.IsDirty = true;
        end
        
        function onTimetoSteadyStateEdit(obj,NewData)
            obj.TemporaryTask.TimeToSteadyState = NewData;
            obj.IsDirty = true;
        end
        
        function onRuntoSteadyStateCheckBox(obj,NewData)
            obj.TemporaryTask.RunToSteadyState = NewData;
            obj.TimetoSteadyStateEdit.Enable = NewData;
            obj.IsDirty = true;
            
        end
        
        function onProjectFileSelector(obj,NewData)
            if ~strcmp(obj.TemporaryTask.RelativeFilePath,NewData)
                obj.invalidProject();
                obj.TemporaryTask.RelativeFilePath = NewData;
                if exist(obj.TemporaryTask.FilePath,'file')==2
                    obj.modelChange(obj.TemporaryTask.ModelName,true);
                    obj.ModelDropDown.Items = {obj.TemporaryTask.getModelList()};
                end
                obj.IsDirty = true;
            end
        end
        
        
        
        function onModelDropDown(obj,NewValue)
            if ~strcmpi(NewValue,QSP.makeInvalid('-'))
                obj.modelChange(NewValue,true);
                obj.IsDirty = true;
            end
        end
        
    end
    
    methods (Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.Task.Settings.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewTask(obj,NewTask)
            obj.deleteTemporary();
            obj.Task = NewTask;
            obj.TemporaryTask = copy(obj.Task);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
                
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryTask.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryTask.Description= value;
            obj.IsDirty = true;
        end
                
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryTask.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);          
            
            if StatusOK
                obj.TemporaryTask.updateLastSavedTime();
                
                %This creates an entirely new copy of the Task except
                %the name isnt copied
                obj.Task = copy(obj.TemporaryTask,obj.Task);
                
                %We now need to notify the application to update the
                %Task pointer to the new object created
                obj.notifyOfChange(obj.Task.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryTask)
            obj.TemporaryTask = copy(obj.Task);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryTask.Description);
            obj.updateNameBox(obj.TemporaryTask.Name);
            obj.updateSummary(obj.TemporaryTask.getSummary());
            obj.ProjectFileSelector.RootDirectory = obj.TemporaryTask.Session.RootDirectory;
                
            % if right model is already loaded, just update UI
            if isequal(obj.ProjectFileSelector.RelativePath, obj.TemporaryTask.RelativeFilePath) && ...
                    isequal(obj.ModelDropDown.Value, obj.TemporaryTask.ModelName)
                obj.updateModelInfoUI();
            % if not, re-import model
            elseif exist(obj.TemporaryTask.FilePath,'file')==2
                obj.modelChange(obj.TemporaryTask.ModelName,true)
                obj.ProjectFileSelector.RelativePath = obj.TemporaryTask.RelativeFilePath;
                obj.ModelDropDown.Items = {obj.TemporaryTask.getModelList()};
            else
                obj.invalidProject()
            end
            
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryTask,FlagRemoveInvalid);
            obj.updateModelInfoUI();
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.Task.Session.Settings.Task;
            ixDup = find(strcmp( obj.TemporaryTask.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.Task)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
    end
    
    methods (Access = private)
        
        function modelChange(obj,newName,reimport)
            if reimport
                [StatusOK,Message] = importModel(obj.TemporaryTask,obj.TemporaryTask.FilePath,newName);
                if ~StatusOK
                    uialert(obj.getUIFigure,'Error on Import',Message)
                end
            end
            
            if ~isempty(obj.TemporaryTask.ModelObj) && ~isempty(obj.TemporaryTask.ModelObj.mObj)
                %get active variant names
                allVariantNames = get(obj.TemporaryTask.ModelObj.mObj.Variants, 'Name');
                if isempty(allVariantNames)
                    allVariantNames = {};
                end
                obj.TemporaryTask.ActiveVariantNames = allVariantNames(cell2mat(get(obj.TemporaryTask.ModelObj.mObj.Variants,'Active')));

                 % get inactive reactions from the model
                allReactionNames = obj.TemporaryTask.ReactionNames; 
                if isempty(allReactionNames)
                    allReactionNames = {};
                end
                obj.TemporaryTask.InactiveReactionNames = allReactionNames(~cell2mat(get(obj.TemporaryTask.ModelObj.mObj.Reactions,'Active')));

                % get inactive rules from model
                allRulesNames = obj.TemporaryTask.RuleNames;
                if isempty(allRulesNames)
                    allRulesNames = {};
                end
                obj.TemporaryTask.InactiveRuleNames = allRulesNames(~cell2mat(get(obj.TemporaryTask.ModelObj.mObj.Rules,'Active')));
            end
            
            obj.updateModelInfoUI();
        end
        
        function updateModelInfoUI(obj)
            %Draw the superclass Widgets values
            
            % %For each Box, we must import the left and right list
            
            % %
            obj.VariantstoActivateDoubleBox.setLeftListBox(obj.TemporaryTask.VariantNames);
            obj.VariantstoActivateDoubleBox.setRightListBox(obj.TemporaryTask.ActiveVariantNames);
            
            obj.DosestoIncludeDoubleBox.setLeftListBox(obj.TemporaryTask.DoseNames);
            obj.DosestoIncludeDoubleBox.setRightListBox(obj.TemporaryTask.ActiveDoseNames);
            
            obj.RulestoDeactivateDoubleBox.setLeftListBox(obj.TemporaryTask.RuleNames);
            obj.RulestoDeactivateDoubleBox.setRightListBox(obj.TemporaryTask.InactiveRuleNames);
            
            obj.ReactionstoDeactivateDoubleBox.setLeftListBox(obj.TemporaryTask.ReactionNames);
            obj.ReactionstoDeactivateDoubleBox.setRightListBox(obj.TemporaryTask.InactiveReactionNames);
            
            obj.SpeciestoIncludeDoubleBox.setLeftListBox(obj.TemporaryTask.SpeciesNames);
            obj.SpeciestoIncludeDoubleBox.setRightListBox(obj.TemporaryTask.ActiveSpeciesNames);
            
            %Settings
            obj.OutputTimesEdit.Value = obj.Task.OutputTimesStr;
            obj.OutputTimesEdit.Enable = 'on';

            obj.MaxWallClockEdit.Value = obj.Task.MaxWallClockTime;
            obj.MaxWallClockEdit.Enable = 'on';
            
            obj.AbsToleranceEdit.Value = obj.Task.AbsoluteTolerance;
            obj.AbsToleranceEdit.Enable = 'on';
            obj.RelToleranceEdit.Value = obj.Task.RelativeTolerance;
            obj.RelToleranceEdit.Enable = 'on';
            
            obj.TimetoSteadyStateEdit.Value = obj.Task.TimeToSteadyState;
            obj.TimetoSteadyStateEdit.Enable ='on';
            
            %Time to steady state checkbox. IF off, disable the edit field
            obj.RuntoSteadyStateCheckBox.Value = obj.Task.RunToSteadyState;
            if ~obj.Task.RunToSteadyState
                obj.TimetoSteadyStateEdit.Enable = 'off';
            else
                obj.TimetoSteadyStateEdit.Enable = 'on';
            end
            
        end
        
        function invalidProject(obj)
            obj.ModelDropDown.Items = {QSP.makeInvalid('-')};
            
            obj.VariantstoActivateDoubleBox.setRightListBox({});
            obj.VariantstoActivateDoubleBox.setLeftListBox({});
            
            obj.DosestoIncludeDoubleBox.setRightListBox({});
            obj.DosestoIncludeDoubleBox.setLeftListBox({});
            
            obj.RulestoDeactivateDoubleBox.setRightListBox({});
            obj.RulestoDeactivateDoubleBox.setLeftListBox({});
            
            obj.ReactionstoDeactivateDoubleBox.setRightListBox({});
            obj.ReactionstoDeactivateDoubleBox.setLeftListBox({});
            
            obj.SpeciestoIncludeDoubleBox.setRightListBox({});
            obj.SpeciestoIncludeDoubleBox.setLeftListBox({});
            
            %Settings
            obj.OutputTimesEdit.Value = '';
            obj.OutputTimesEdit.Enable = 'off';

            obj.MaxWallClockEdit.Value = 0;
            obj.MaxWallClockEdit.Enable = 'off';
            
            obj.TimetoSteadyStateEdit.Value =0;
            obj.TimetoSteadyStateEdit.Enable ='off';
            
            obj.RuntoSteadyStateCheckBox.Value = 0;
            obj.TimetoSteadyStateEdit.Enable = 'off';
        end
    end
end

