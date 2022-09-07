classdef SessionPane < QSPViewerNew.Application.ViewPane 
    %  SessionPane - A Class for the session settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.Session
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  1/9/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        Session = QSP.Session.empty()
        TemporarySession = QSP.Session.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        RootDirSelectorListener
        ObjectiveFunDirSelectorListener
        UDFSelectorListener
        PluginsSelectorListener
        AutoSaveFolderSelectListener
        GitFolderSelectListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterSubGrid                    matlab.ui.container.GridLayout
        RootDirSelector                 QSPViewerNew.Widgets.FolderSelector                
        ObjectiveFunDirSelector         QSPViewerNew.Widgets.FolderSelector
        UDFSelector                     QSPViewerNew.Widgets.FolderSelector
        PluginsSelector                     QSPViewerNew.Widgets.FolderSelector
        ParrallelGrid                   matlab.ui.container.GridLayout
        UseParallelToolboxCheckBox      matlab.ui.control.CheckBox
        AutosaveOptionsPanel            matlab.ui.container.Panel
        AutoSaveGrid                    matlab.ui.container.GridLayout
        ParallelOptionsPanel            matlab.ui.container.Panel
        AutoSaveFolderSelect            QSPViewerNew.Widgets.FolderSelector
        AutoSaveOptionsGrid             matlab.ui.container.GridLayout
        AutoSavePeriodically            matlab.ui.control.CheckBox
        AutoSaveBeforeRun               matlab.ui.control.CheckBox
        AutoSaveFreqLabel               matlab.ui.control.Label
        AutoSaveFreqEdit                matlab.ui.control.NumericEditField
        UseParallelToolboxLabel         matlab.ui.control.Label
        UseParallelToolboxDropDown      matlab.ui.control.DropDown
        GitOptionsPanel                 matlab.ui.container.Panel
        GitGrid                         matlab.ui.container.GridLayout
        EnableGitCheckBox               matlab.ui.control.CheckBox
        GitFolderSelect                 QSPViewerNew.Widgets.FolderSelector
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = SessionPane(varargin)
            obj = obj@QSPViewerNew.Application.ViewPane(varargin{:}{:},false);
            obj.create();
            obj.createListenersAndCallbacks();
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function create(obj)
            obj.OuterSubGrid = uigridlayout(obj.getEditGrid());
            obj.OuterSubGrid.Layout.Row = 3;
            obj.OuterSubGrid.Layout.Column = 1;
            obj.OuterSubGrid.Padding = obj.WidgetPadding;
            obj.OuterSubGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            obj.OuterSubGrid.ColumnSpacing = obj.WidgetHeightSpacing;
            obj.OuterSubGrid.ColumnWidth = {'1x'};
            obj.OuterSubGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight*4,obj.WidgetHeight*5,'1x'};
            
            % Create Objective Functions Directory
            obj.RootDirSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,1,1,' Root Directory:',true);
            
            %Objective Fcn Dir
            obj.ObjectiveFunDirSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,2,1,' Objective Functions Directory:');
            
            %UDF Fcn Dir
            obj.UDFSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,3,1,' User-defined Functions Directory:');
            
            %Plugins Dir
            obj.PluginsSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,4,1,' Plugins Directory:');
            
            %Create AutosaveOptionsPanel
            obj.ParallelOptionsPanel = uipanel(obj.OuterSubGrid);
            obj.ParallelOptionsPanel.Title = 'Parrallel Options';
            obj.ParallelOptionsPanel.Layout.Row = 5;
            obj.ParallelOptionsPanel.Layout.Column = 1;
            obj.ParallelOptionsPanel.BackgroundColor = obj.SubPanelColor;

            %Create Grid Layout for Parrallel
            obj.ParrallelGrid = uigridlayout(obj.ParallelOptionsPanel);
            obj.ParrallelGrid.RowHeight= {obj.WidgetHeight,obj.WidgetHeight,'1x'};  
            obj.ParrallelGrid.ColumnWidth = {obj.LabelLength,'1x'};
            obj.ParrallelGrid.Padding = obj.SubPanelPadding;
            obj.ParrallelGrid.ColumnSpacing = obj.SubPanelWidthSpacing;
            obj.ParrallelGrid.RowSpacing = obj.SubPanelHeightSpacing;
            
            % Create Parrallel checkbox
            obj.UseParallelToolboxCheckBox = uicheckbox(obj.ParrallelGrid);
            obj.UseParallelToolboxCheckBox.Text = 'Use Parallel Toolbox';
            obj.UseParallelToolboxCheckBox.Layout.Row = 1;
            obj.UseParallelToolboxCheckBox.Layout.Column = 1;
            
            %Parallel cluster label
            obj.UseParallelToolboxLabel = uilabel(obj.ParrallelGrid);
            obj.UseParallelToolboxLabel.Text = 'Use Parallel Toolbox';
            obj.UseParallelToolboxLabel.Layout.Row = 2;
            obj.UseParallelToolboxLabel.Layout.Column = 1;
            
            %Parallel cluster DropDown
            obj.UseParallelToolboxDropDown = uidropdown(obj.ParrallelGrid);
            obj.UseParallelToolboxDropDown.Layout.Row = 2;
            obj.UseParallelToolboxDropDown.Layout.Column = 2;
            obj.UseParallelToolboxDropDown.Items = {'Local','MATLAB Parallel Cloud'};
            
            %Create GitOptionsPanel
            obj.GitOptionsPanel = uipanel(obj.OuterSubGrid);
            obj.GitOptionsPanel.Title = 'Git Options';
            obj.GitOptionsPanel.Layout.Row = 6;
            obj.GitOptionsPanel.Layout.Column = 1;
            obj.GitOptionsPanel.BackgroundColor = obj.SubPanelColor;
            
            %Create Grid Layout for Git
            obj.GitGrid = uigridlayout(obj.GitOptionsPanel);
            obj.GitGrid.RowHeight= {obj.WidgetHeight,obj.WidgetHeight,'1x'};  
            obj.GitGrid.ColumnWidth = {'1x'};
            obj.GitGrid.Padding = obj.SubPanelPadding;
            obj.GitGrid.ColumnSpacing = obj.SubPanelWidthSpacing;
            obj.GitGrid.RowSpacing = obj.SubPanelHeightSpacing;
            
            % Create Git checkbox
            obj.EnableGitCheckBox = uicheckbox(obj.GitGrid);
            obj.EnableGitCheckBox.Text = 'Enable git';
            obj.EnableGitCheckBox.Layout.Row = 1;
            obj.EnableGitCheckBox.Layout.Column = 1;
            
            % Git Directory
            obj.GitFolderSelect = QSPViewerNew.Widgets.FolderSelector(obj.GitGrid,2,1,'Git repository Directory');
            
            % Create AutosaveOptionsPanel
            obj.AutosaveOptionsPanel = uipanel(obj.OuterSubGrid);
            obj.AutosaveOptionsPanel.Title = 'Autosave Options';
            obj.AutosaveOptionsPanel.Layout.Row = 6;
            obj.AutosaveOptionsPanel.Layout.Column = 1;
            obj.AutosaveOptionsPanel.BackgroundColor = obj.SubPanelColor;

            % Create Autosave grid layout
            obj.AutoSaveGrid = uigridlayout(obj.AutosaveOptionsPanel);
            obj.AutoSaveGrid.ColumnWidth = {'1x'};
            obj.AutoSaveGrid.RowHeight = {obj.WidgetHeight,'1x'};  
            obj.AutoSaveGrid.Padding = obj.SubPanelPadding;
            obj.AutoSaveGrid.ColumnSpacing = obj.SubPanelWidthSpacing;
            obj.AutoSaveGrid.RowSpacing = obj.SubPanelHeightSpacing;

            %AutoSaveDirectory
            obj.AutoSaveFolderSelect = QSPViewerNew.Widgets.FolderSelector(obj.AutoSaveGrid,1,1,'Autosave Directory');
            
            %AutsaveSubOptionsGrid
            obj.AutoSaveOptionsGrid = uigridlayout(obj.AutoSaveGrid);
            obj.AutoSaveOptionsGrid.ColumnWidth = {obj.DescriptionSize,obj.DescriptionSize,obj.LabelLength};
            obj.AutoSaveOptionsGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,'1x'};  
            obj.AutoSaveOptionsGrid.Padding = obj.WidgetPadding;
            obj.AutoSaveOptionsGrid.ColumnSpacing = obj.WidgetHeightSpacing;
            obj.AutoSaveOptionsGrid.RowSpacing = obj.WidgetWidthSpacing;
            obj.AutoSaveOptionsGrid.Layout.Row = 2;
            obj.AutoSaveOptionsGrid.Layout.Column = 1;
            
            %AutoSave periodically Checkbox
            obj.AutoSavePeriodically = uicheckbox(obj.AutoSaveOptionsGrid);
            obj.AutoSavePeriodically.Text = 'Autosave Periodically';
            obj.AutoSavePeriodically.Layout.Row = 1;
            obj.AutoSavePeriodically.Layout.Column = 1;
            
            %AutoSave periodically Checkbox
            obj.AutoSaveBeforeRun = uicheckbox(obj.AutoSaveOptionsGrid);
            obj.AutoSaveBeforeRun.Text = 'Before Run';
            obj.AutoSaveBeforeRun.Layout.Row = 2;
            obj.AutoSaveBeforeRun.Layout.Column = 1;
            
            %Autosave freq label
            obj.AutoSaveFreqLabel = uilabel(obj.AutoSaveOptionsGrid);
            obj.AutoSaveFreqLabel.Text = 'Autosave Frequency (min)';
            obj.AutoSaveFreqLabel.Layout.Row = 1;
            obj.AutoSaveFreqLabel.Layout.Column = 2;
            
            %Autosave freq edit
            obj.AutoSaveFreqEdit = uieditfield(obj.AutoSaveOptionsGrid,'numeric');
            obj.AutoSaveFreqEdit.Layout.Row = 1;
            obj.AutoSaveFreqEdit.Layout.Column = 3;
        end
        
        function createListenersAndCallbacks(obj)
            %If we have access to the value, we can create a callback.
            %Otherwise, we can listen the the widget and react when it
            %changes
            
            %Listeners
            obj.RootDirSelectorListener = addlistener(obj.RootDirSelector,'StateChanged',@(src,event) obj.onRootDirChange(event.Source.FullPath));
            obj.ObjectiveFunDirSelectorListener = addlistener(obj.ObjectiveFunDirSelector,'StateChanged',@(src,event) obj.onObjFunctionsChange(event.Source.RelativePath));
            obj.UDFSelectorListener = addlistener(obj.UDFSelector,'StateChanged',@(src,event) obj.onUDFChange(event.Source.RelativePath));
            obj.PluginsSelectorListener = addlistener(obj.PluginsSelector,'StateChanged',@(src,event) obj.onPluginsChange(event.Source.RelativePath));
            obj.AutoSaveFolderSelectListener = addlistener(obj.AutoSaveFolderSelect,'StateChanged',@(src,event) obj.onAutoSaveDirChange(event.Source.RelativePath));
            obj.GitFolderSelectListener = addlistener(obj.GitFolderSelect,'StateChanged',@(src,event) obj.onGitDirChange(event.Source.RelativePath));
            
            %Callbacks
            obj.UseParallelToolboxCheckBox.ValueChangedFcn = @(h,e) obj.onParallelCheckbox(e.Value);
            obj.AutoSavePeriodically.ValueChangedFcn = @(h,e) obj.onAutosaveTimerCheckbox(e.Value);
            obj.AutoSaveBeforeRun.ValueChangedFcn = @(h,e) obj.onAutoSaveBeforeRunChecked(e.Value);
            obj.AutoSaveFreqEdit.ValueChangedFcn = @(h,e) obj.onAutoSaveFrequencyEdited(e.Value);
            obj.UseParallelToolboxDropDown.ValueChangedFcn = @(h,e) obj.onParallelClusterPopup(e.Value);
            obj.EnableGitCheckBox.ValueChangedFcn = @(h,e) obj.onGitCheckbox(e.Value);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onRootDirChange(obj,newValue)
           obj.TemporarySession.RootDirectory = newValue;
           
           %Because the root directory changed, all other paths are
           %invalid.
           %We need to change the root directory for all others
           obj.ObjectiveFunDirSelector.RootDirectory = newValue;
           obj.UDFSelector.RootDirectory = newValue;
           obj.PluginsSelector.RootDirectory = newValue;
           obj.AutoSaveFolderSelect.RootDirectory = newValue;
           obj.IsDirty = true;
        end
        
        function onUDFChange(obj,newValue)
            obj.TemporarySession.removeUDF();
            obj.TemporarySession.RelativeUserDefinedFunctionsPath = newValue;
            obj.IsDirty = true;
        end
        
        function onObjFunctionsChange(obj,newValue)
            obj.TemporarySession.RelativeObjectiveFunctionsPath = newValue;
            obj.IsDirty = true;
        end
        
        function onPluginsChange(obj,newValue)
            obj.TemporarySession.RelativePluginsPath = newValue;
            obj.IsDirty = true;
        end
        
        function onParallelCheckbox(obj,newValue)
            obj.TemporarySession.UseParallel = newValue;
            obj.updateEnabled();
            obj.IsDirty = true;
        end
        
        function onAutosaveTimerCheckbox(obj,newValue)
            obj.TemporarySession.UseAutoSaveTimer = newValue;
            obj.updateEnabled();
            obj.IsDirty = true;
        end
        
        function onParallelClusterPopup(obj,newValue)
            obj.TemporarySession.ParallelCluster = newValue;
            obj.IsDirty = true;
        end
        
        function onAutoSaveFrequencyEdited(obj,newValue)
            obj.TemporarySession.AutoSaveFrequency = newValue;
            obj.IsDirty = true;
        end
        
        function onAutoSaveBeforeRunChecked(obj,newValue)
            obj.TemporarySession.AutoSaveBeforeRun = newValue;
            obj.IsDirty = true;
        end
        
        function onAutoSaveDirChange(obj,newValue)
            obj.TemporarySession.RelativeAutoSavePath = newValue;
            obj.IsDirty = true;
        end
        
        function onGitDirChange(obj,newValue)
            % check if it is a git dir
            [~,~,ext] = fileparts(newValue);
            if strcmp(ext,'.git')
                obj.TemporarySession.GitRepo = fullfile(obj.TemporarySession.RootDirectory, newValue);
            else
                uialert(obj.getUIFigure(), 'Git directories should be named ''.git''. Reverting back to previous git directory.', 'Invalid git directory');
                obj.GitFolderSelect.RelativePath = uix.utility.getRelativeFilePath(obj.TemporarySession.GitRepo, obj.TemporarySession.RootDirectory);
            end
            obj.IsDirty = true;
        end
        
        function onGitCheckbox(obj,newValue)
            obj.TemporarySession.AutoSaveGit = newValue;
            obj.IsDirty = true; 
        end
        
    end   
    
    methods(Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewSession(obj,NewSession)
            obj.Session = NewSession;
         
            obj.TemporarySession = copy(obj.Session);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
        function updateEnabled(obj)
            %Update the 'Enable' Property of items
            obj.UseParallelToolboxDropDown.Enable = obj.TemporarySession.UseParallel;
            obj.AutoSaveFreqEdit.Enable = obj.TemporarySession.UseAutoSaveTimer;
            
        end
        
    end
       
    methods(Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporarySession.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporarySession.Description= value;
            obj.IsDirty = true;
        end
        
        function [StatusOK] =  saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;     
            [StatusOK,Message] = obj.TemporarySession.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporarySession.updateLastSavedTime();
                
                %This creates an entirely new copy of the Session except
                %the name isnt copied
                obj.Session = copy(obj.TemporarySession,obj.Session);
                
                %We now need to notify the application to update the
                %session pointer to the new object created
                obj.notifyOfChange(obj.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save','modal');
            end
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporarySession)
            obj.TemporarySession = copy(obj.Session);
        end
        
        function draw(obj)
            %Draw the superclass Widgets values
            obj.updateDescriptionBox(obj.TemporarySession.Description);
            obj.updateNameBox(obj.TemporarySession.Name);
            obj.updateSummary(obj.TemporarySession.getSummary());
            
            %Draw the widgets for this class
            obj.RootDirSelector.RootDirectory = obj.TemporarySession.RootDirectory;
            obj.RootDirSelector.RelativePath = '';
            
            obj.ObjectiveFunDirSelector.RootDirectory = obj.TemporarySession.RootDirectory;
            obj.ObjectiveFunDirSelector.RelativePath = obj.TemporarySession.RelativeObjectiveFunctionsPath;
            
            obj.UDFSelector.RootDirectory = obj.TemporarySession.RootDirectory;
            obj.UDFSelector.RelativePath = obj.TemporarySession.RelativeUserDefinedFunctionsPath;
            
            obj.PluginsSelector.RootDirectory = obj.TemporarySession.RootDirectory;
            obj.PluginsSelector.RelativePath = obj.TemporarySession.RelativePluginsPath;
            
            obj.AutoSaveFolderSelect.RootDirectory = obj.TemporarySession.RootDirectory;
            obj.AutoSaveFolderSelect.RelativePath = obj.TemporarySession.RelativeAutoSavePath;
            
            obj.UseParallelToolboxCheckBox.Value = obj.TemporarySession.UseParallel;
            
            obj.AutoSavePeriodically.Value = obj.TemporarySession.UseAutoSaveTimer;
            
            obj.AutoSaveBeforeRun.Value = obj.TemporarySession.AutoSaveBeforeRun;
            
            obj.AutoSaveFreqEdit.Value = obj.TemporarySession.AutoSaveFrequency;
            
            obj.GitFolderSelect.RootDirectory = obj.TemporarySession.RootDirectory;
            obj.GitFolderSelect.RelativePath = uix.utility.getRelativeFilePath(obj.TemporarySession.GitRepo, obj.TemporarySession.RootDirectory);
            obj.EnableGitCheckBox.Value = obj.TemporarySession.AutoSaveGit;
            
            %Determine the users parallel options
            info = ver;
            if ismember('Parallel Computing Toolbox', {info.Name})
               obj.UseParallelToolboxDropDown.Items = parallel.clusterProfiles;
               obj.UseParallelToolboxCheckBox.Value = obj.TemporarySession.UseParallel;
               obj.UseParallelToolboxDropDown.Enable = 'on';
               obj.UseParallelToolboxCheckBox.Enable = 'on';
               obj.updateEnabled();
            else
               obj.UseParallelToolboxDropDown.Items = {};
               obj.UseParallelToolboxCheckBox.Value = 0;
               obj.UseParallelToolboxDropDown.Enable = 'off';
               obj.UseParallelToolboxCheckBox.Enable = 'off';
            end
                    
            obj.IsDirty = false;
            
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporarySession,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(~,StatusOK,Message)
            %Sessions do not need to be check for duplicates
        end
        
    end
end

