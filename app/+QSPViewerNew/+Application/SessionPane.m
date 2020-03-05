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
        AutoSaveFolderSelectListener
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterSubGrid                    matlab.ui.container.GridLayout
        RootDirSelector                 QSPViewerNew.Widgets.FolderSelector                
        ObjectiveFunDirSelector         QSPViewerNew.Widgets.FolderSelector
        UDFSelector                     QSPViewerNew.Widgets.FolderSelector
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
            obj.OuterSubGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight,obj.WidgetHeight*4,obj.WidgetHeight*5,'1x'};
            
            % Create Objective Functions Directory
            obj.RootDirSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,1,1,' Root Directory:');
            
            %Objective Fcn Dir
            obj.ObjectiveFunDirSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,2,1,' Objective Functions Directory:');
            
            %Objective Fcn Dir
            obj.UDFSelector = QSPViewerNew.Widgets.FolderSelector(obj.OuterSubGrid,3,1,' User-defined Functions Directory:');
            
            %Create AutosaveOptionsPanel
            obj.ParallelOptionsPanel = uipanel(obj.OuterSubGrid);
            obj.ParallelOptionsPanel.Title = 'Parrallel Options';
            obj.ParallelOptionsPanel.Layout.Row = 4;
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
            
            % Create AutosaveOptionsPanel
            obj.AutosaveOptionsPanel = uipanel(obj.OuterSubGrid);
            obj.AutosaveOptionsPanel.Title = 'Autosave Options';
            obj.AutosaveOptionsPanel.Layout.Row = 5;
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
            obj.AutoSaveOptionsGrid.ColumnWidth = {obj.LabelLength,obj.LabelLength,obj.LabelLength};
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
            obj.AutoSaveBeforeRun.Text = 'Autosave Before Run';
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
            obj.RootDirSelectorListener = addlistener(obj.RootDirSelector,'StateChanged',@(src,event) obj.onRootDirChange(event.Source.getRelativePath()));
            obj.ObjectiveFunDirSelectorListener = addlistener(obj.ObjectiveFunDirSelector,'StateChanged',@(src,event) obj.onObjFunctionsChange(event.Source.getRelativePath()));
            obj.UDFSelectorListener = addlistener(obj.UDFSelector,'StateChanged',@(src,event) obj.onUDFChange(event.Source.getRelativePath()));
            obj.AutoSaveFolderSelectListener = addlistener(obj.AutoSaveFolderSelect,'StateChanged',@(src,event) obj.onAutoSaveDirChange(event.Source.getRelativePath()));
            
            %Callbacks
            obj.UseParallelToolboxCheckBox.ValueChangedFcn = @(h,e) obj.onParallelCheckbox(e.Value);
            obj.AutoSavePeriodically.ValueChangedFcn = @(h,e) obj.onAutosaveTimerCheckbox(e.Value);
            obj.AutoSaveBeforeRun.ValueChangedFcn = @(h,e) obj.onAutoSaveBeforeRunChecked(e.Value);
            obj.AutoSaveFreqEdit.ValueChangedFcn = @(h,e) obj.onAutoSaveFrequencyEdited(e.Value);
            obj.UseParallelToolboxDropDown.ValueChangedFcn = @(h,e) obj.onParallelClusterPopup(e.Value);
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
           obj.ObjectiveFunDirSelector.setRootDirectory(newValue);
           obj.UDFSelector.setRootDirectory(newValue);
           obj.AutoSaveFolderSelect.setRootDirectory(newValue);
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
        
        function onParallelCheckbox(obj,newValue)
            obj.TemporarySession.UseParallel = newValue;
            obj.IsDirty = true;
        end
        
        function onAutosaveTimerCheckbox(obj,newValue)
            obj.TemporarySession.UseParallel = newValue;
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
    end   
    
    methods(Access = public) 
        
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
        
    end
       
    methods(Access = public)
        
        function NotifyOfChangeInName(obj,value,previousName,newName);
            obj.TemporarySession.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporarySession.Description= value;
            obj.IsDirty = true;
        end
        
        function saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporarySession.validate(FlagRemoveInvalid);          
            
            if StatusOK
                obj.TemporarySession.updateLastSavedTime();
                previousName = obj.TemporarySession.Name;
                newName = obj.Session.Name;
                
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
            obj.updateDescriptionBox(obj.Session.Description);
            obj.updateNameBox(obj.Session.Name);
            obj.updateSummary(obj.Session.getSummary());
            
            %Draw the widgets for this class
            obj.RootDirSelector.setRelativePath(obj.Session.RootDirectory);
            
            obj.ObjectiveFunDirSelector.setRelativePath(obj.Session.RelativeObjectiveFunctionsPath);
            obj.ObjectiveFunDirSelector.setRootDirectory(obj.Session.RootDirectory);
            
            obj.UDFSelector.setRelativePath(obj.Session.RelativeUserDefinedFunctionsPath);
            obj.UDFSelector.setRootDirectory(obj.Session.RootDirectory);
            
            obj.AutoSaveFolderSelect.setRelativePath(obj.Session.RelativeAutoSavePath);
            obj.AutoSaveFolderSelect.setRootDirectory(obj.Session.RootDirectory);
            
            obj.UseParallelToolboxCheckBox.Value = obj.Session.UseParallel;

            obj.AutoSavePeriodically.Value = obj.Session.UseAutoSaveTimer;
            
            obj.AutoSaveBeforeRun.Value = obj.Session.AutoSaveBeforeRun;
            
            obj.AutoSaveFreqEdit.Value = obj.Session.AutoSaveFrequency;
            
            %Determine the users parallel options
            info = ver;
            if ismember('Parallel Computing Toolbox', {info.Name})
               obj.UseParallelToolboxDropDown.Items = parallel.clusterProfiles;
               obj.UseParallelToolboxCheckBox.Value = obj.Session.UseParallel;
               obj.UseParallelToolboxDropDown.Enable = 'on';
               obj.UseParallelToolboxCheckBox.Enable = 'on';
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
        end
        
    end
end

