classdef PluginManager < matlab.apps.AppBase
    %% Properties
    properties (SetObservable)
        % QSP Sessions
        Sessions = QSP.Session.empty(0,1)
        
        % value to filter type
        TypeFilterValue (1,1) string = "all"
        
        % Session selected
        SelectedSession = QSP.Session.empty(0,1)
    end
    
    properties (Access=private)
        UIFigure                    matlab.ui.Figure
        PanelMain                   matlab.ui.container.Panel
        GridMain                    matlab.ui.container.GridLayout
        SessionLabel                matlab.ui.control.Label
        SessionDropDown             matlab.ui.control.DropDown
        PluginFolderLabel           matlab.ui.control.Label
        PluginFolderTextArea        matlab.ui.control.Label
        PathStatusIcon              matlab.ui.control.Image
        FilterLabel                 matlab.ui.control.Label
        FilterDropDown              matlab.ui.control.DropDown
        PluginTable                 matlab.ui.control.Table
        AddNewButton                matlab.ui.control.Button
        UpdateButton                matlab.ui.control.Button
        DependencyCheckbox          matlab.ui.control.CheckBox
    end
    
    properties (SetAccess=private, SetObservable, AbortSet)
        PluginTableData table
        PluginTableDisplayData table
        % Type of objects in the plugin table
        Types (:,1) string = "all"
    end
    
    properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % listener handle for Sessions property
        SessionsListener event.listener
        
        % listener handle for PluginTableDisplayData property
        DisplayDataListener event.listener
        
        % listener handle for SelectedSession property
        SelectedSessionListener event.listener
        
        % listener handle for Types property
        TypesListener event.listener
        
        % listener handle for Type Filter value property
        TypeFilterListener event.listener
    end %properties
    
    %% Constructor/Destructor
    methods
        
        % Construct app
        function app = PluginManager()
            if verLessThan('matlab','9.9')
                runningApp  = [];
            else
                runningApp = getRunningApp(app);
            end
            
            % Check for running plugin manager app
            if isempty(runningApp)
                
                % Create UIFigure and components
                createComponents(app)
                
                % Register the app with App Designer
                registerApp(app, app.UIFigure)
                
                % Attach listeners
                app.attachListeners();
                
            else
                % Focus the running plugin manager app
                figure(runningApp.UIFigure)
                
                app = runningApp;
            end
            
            if nargout == 0
                clear app
            end
        end % constructor
        
        % Code that executes before app deletion
        function delete(app)
            if isvalid(app.UIFigure)
                typeStr = matlab.lang.makeValidName(class(app));
                setpref(typeStr,'Position',app.UIFigure.Position);
            end
            
            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end % destructor
        
    end
    
    %% Public
    methods
        function addFile(~)
            % prompt user for type of input to autofill template
            [indx,~] = listdlg('ListString',QSPViewerNew.Application.ApplicationUI.ItemTypes(:,1),...
                'SelectionMode', 'single', ...
                'PromptString', {'Please select an input type',...
                'for plugin'});
            if ~isempty(indx)
                inputType = QSPViewerNew.Application.ApplicationUI.ItemTypes{indx,2};
                
                editorService = com.mathworks.mlservices.MLEditorServices; %#ok<JAPIMATHWORKS>
                editorApplication = editorService.getEditorApplication();
                
                % Template
                line1 = "function myPlugin(obj)";
                line2 = "% myPlugin";
                line3 = "% Syntax:";
                line4 = "%       myPlugin(obj)";
                line5 = "% Description:";
                line6 = sprintf("%%           This plugin is for %s objects",inputType);
                line7 = "% Inputs:";
                line8 = sprintf("%%       QSP.%s", inputType);
                line9 = "% Author:";
                line10 = "end";
                
                editorApplication.newEditor( sprintf('%s\n%s\n\n%s\n%s\n\n%s\n%s\n\n%s\n%s\n\n%s\n\n\n\n%s\n', ...
                    line1,line2,line3,line4,line5,line6,line7,line8,line9,line10) );
            end
        end
        
        function update(app)
            % update selected session drop-down
            if isempty(app.Sessions)
                app.SessionDropDown.Items = "";
                app.SelectedSession = QSP.Session.empty(0,1);
                
                 app.PathStatusIcon.Visible = 'off';
                
                app.PluginFolderTextArea.Text = '';
                
                app.DependencyCheckbox.Value = 0;
                
                app.PluginTableData = table.empty();
            else
                app.SessionDropDown.Items = {app.Sessions.SessionName};
                app.SessionDropDown.ItemsData = vertcat(app.Sessions);
                if isempty(app.SelectedSession) || ~ismember(app.SelectedSession, app.SessionDropDown.ItemsData)
                    app.SelectedSession = app.Sessions(1);
                end
                app.SessionDropDown.Value = app.SelectedSession;
                
                % update plugin folder text area
                app.PluginFolderTextArea.Text = app.SelectedSession.PluginsDirectory;
                if ~exist(app.SelectedSession.PluginsDirectory, 'dir')
                    app.PluginFolderTextArea.FontColor = 'r';
                else
                    app.PluginFolderTextArea.FontColor = 'k';
                end
                
                if app.isPathinRootDirectory(app.SelectedSession.PluginsDirectory, app.SelectedSession.RootDirectory)
                    app.PathStatusIcon.ImageSource = QSPViewerNew.Resources.LoadResourcePath('confirm_24.png');
                    app.PathStatusIcon.Tooltip = "Plugin directory present within root directory";
                else
                    app.PathStatusIcon.ImageSource = QSPViewerNew.Resources.LoadResourcePath('warning_24.png');
                    app.PathStatusIcon.Tooltip = sprintf(['Plugin directory  not present within root directory.', ...
                        'To change it, select corresponding Session in main app, then ',...
                        'Edit, then Plugins Directory']);
                end
                app.PathStatusIcon.Visible = 'on';
                
                % Update plugin table
                app.updatePluginTableData();
                
                % Update Types drop-down
                app.Types = ["all"; unique(app.PluginTableData.Type)];
                
                % Update plugin table
                app.filterTableBasedonValue();
            end
        end
    end
    %% Private methods
    methods(Access=private)
        
        function createComponents(app)
            ButtonSize = 30;
            
            % Create a parent figure
            app.UIFigure = uifigure('Name', 'Plugin Manager', 'Visible', 'off');
            app.UIFigure.Position(3:4) = [1200, 500];
            typeStr = matlab.lang.makeValidName(class(app));
            app.UIFigure.Position = getpref(typeStr,'Position',app.UIFigure.Position);
            
            % Create the main grid
            app.GridMain = uigridlayout(app.UIFigure);
            app.GridMain.ColumnWidth = {'1x',ButtonSize,'0.7x','1x','1x','0.7x','1.3x'};
            app.GridMain.RowHeight = {'1x','1x','1x','fit','1x'};
            
            % Create Session edit field
            app.SessionLabel = uilabel(app.GridMain, 'Text', 'Session:');
            app.SessionLabel.Layout.Row = 1;
            app.SessionLabel.Layout.Column = 1;
            
            % Create Filter edit field
            app.SessionDropDown = uidropdown(app.GridMain, 'Items', "");
            app.SessionDropDown.Layout.Row = 1;
            app.SessionDropDown.Layout.Column = [2, 5];
            app.SessionDropDown.ValueChangedFcn = @(s,e) app.onSelSessionValueChanged(s,e);
            
            % Create label for plugin folder text area
            app.PluginFolderLabel = uilabel(app.GridMain, 'Text', 'Plugin Folder:');
            app.PluginFolderLabel.Layout.Row = 2;
            app.PluginFolderLabel.Layout.Column = 1;
            
            % Create text area for plugin folder
            app.PluginFolderTextArea = uilabel(app.GridMain, 'Text', '');
            app.PluginFolderTextArea.Layout.Row = 2;
            app.PluginFolderTextArea.Layout.Column = [3, length(app.GridMain.ColumnWidth)];
            
            % Create a status symbol icon to check if plugin folder is
            % present within root directory
            app.PathStatusIcon = uiimage(app.GridMain);
            app.PathStatusIcon.Layout.Row = 2;
            app.PathStatusIcon.Layout.Column = 2;
            app.PathStatusIcon.Visible = 'off';
            
            % Create Filter edit field
            app.FilterLabel = uilabel(app.GridMain, 'Text', 'Search  (Type):');
            app.FilterLabel.Layout.Row = 3;
            app.FilterLabel.Layout.Column = 1;
            
            % Create Filter edit field
            app.FilterDropDown = uidropdown(app.GridMain, 'Items', app.Types, 'Value', "all");
            app.FilterDropDown.Layout.Row = 3;
            app.FilterDropDown.Layout.Column = [2, 3];
            app.FilterDropDown.ValueChangedFcn = @(s,e) app.onFilterValueChanged(s,e);
            
            % Create PluginTable
            app.PluginTable = uitable(app.GridMain, 'ColumnSortable', true);
            app.PluginTable.Layout.Row = 4;
            app.PluginTable.Layout.Column = [1, length(app.GridMain.ColumnWidth)];
            
            % Create Add new button
            app.AddNewButton = uibutton(app.GridMain, 'push');
            app.AddNewButton.Layout.Row = 5;
            app.AddNewButton.Layout.Column = 4;
            app.AddNewButton.Text = "Add New";
            app.AddNewButton.ButtonPushedFcn = @(s,e) app.onAddButtonPushed(s,e);
            
            % Create Update button
            app.UpdateButton = uibutton(app.GridMain, 'push');
            app.UpdateButton.Layout.Row = 5;
            app.UpdateButton.Layout.Column = 5;
            app.UpdateButton.Text = "Update";
            app.UpdateButton.ButtonPushedFcn = @(s,e) app.onUpdateButtonPushed(s,e);
            
            % create checkbox for dependencies
            app.DependencyCheckbox = uicheckbox(app.GridMain, ...
                'Text', 'Show dependency analysis');
            app.DependencyCheckbox.Layout.Row = 3;
            app.DependencyCheckbox.Layout.Column = 7;
            app.DependencyCheckbox.ValueChangedFcn = @(s, e) app.onDependencyValueChanged(s,e);
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
            % Populate table with plugin data
            app.update();
            
        end
        
        function filterTableBasedonValue(app)
            if ~isempty(app.PluginTableData)
                if strcmp(app.TypeFilterValue, "all")
                    pluginTableDisplayData = app.PluginTableData;
                elseif ~isempty(app.TypeFilterValue) && app.TypeFilterValue~=""
                    filterstr = app.TypeFilterValue;
                    rowContainingFilter = app.PluginTableData.Type==filterstr;
                    pluginTableDisplayData = app.PluginTableData(rowContainingFilter,:);
                else
                    pluginTableDisplayData = app.PluginTableData(ismissing(app.PluginTableData.Type),:);
                end
                % remove function handle for display
                app.PluginTableDisplayData = removevars(pluginTableDisplayData, 'FunctionHandle');
                
                % remove full file path for 'File' column while display
                [~,name,~] = arrayfun(@(x) fileparts(x), app.PluginTableDisplayData.File);
                app.PluginTableDisplayData.File = strcat(name, '.m');
            else
                app.PluginTableDisplayData = removevars(app.PluginTableData, 'FunctionHandle');
            end
        end
        
        function updatePluginTableData(app)
            if ~isempty(app.SelectedSession)
                pluginTable = app.getPlugins(app.SelectedSession.PluginsDirectory);
                app.PluginTableData = pluginTable;
            end
        end
        
    end
    
    %% Callback methods
    methods(Access=private)
        
        function onSelSessionValueChanged(app,~,~)
            app.SelectedSession = app.SessionDropDown.Value;
        end
        
        function onUpdateButtonPushed(app,~,~)
            app.update();
            
            % throw a warning if plugin table is empty
            if isempty(app.PluginTableData)
                uialert(app.UIFigure, ['Please change plugin directory (from main app under Session objects Edit page)',...
                    ' or ensure appropriate Input types are entered in plugin files (use template provided by "Add New" button).'], ...
                    'No plugin files found', 'Icon', 'warning');
            end
        end
        
        function onBrowsePluginFolderButtonPushed(app,~,~)
            selpath = uigetdir(pwd, 'Select Plugin source folder');
            figure(app.UIFigure);
            if selpath
                app.PluginFolder = selpath;
            end
        end
        
        function onFilterValueChanged(app,~,~)
            app.TypeFilterValue = app.FilterDropDown.Value;
            app.filterTableBasedonValue();
        end
        
        function onAddButtonPushed(app,~,~)
            app.addFile();
        end
        
        function onDependencyValueChanged(app,~,~)
            if app.DependencyCheckbox.Value
                % run dependency only if plugin table is not empty
                if ~isempty(app.PluginTableData)
                    % create progress dialog because this takes time
                    d = uiprogressdlg(app.UIFigure,'Title','Running dependency analysis',...
                        'Indeterminate', 'on', 'Cancelable', 'on');
                    
                    % Run dependency
                    dependencyColumn = false(1,height(app.PluginTableData));
                    for i = 1:height(app.PluginTableData)
                        % Check for Cancel button press
                        if d.CancelRequested
                            break
                        end
                        [fList,~] = matlab.codetools.requiredFilesAndProducts(app.PluginTableData.File(i));
                        tf = app.isPathinRootDirectory(string(fList)',app.SelectedSession.RootDirectory);
                        if all(tf)
                            dependencyColumn(i) = true;
                        end
                    end
                    app.PluginTableDisplayData.("All Dependencies within root directory") = dependencyColumn';
                    
                    close(d);
                end
            else
                if any(matches(string(app.PluginTableDisplayData.Properties.VariableNames), ...
                        "All Dependencies within root directory"))
                    app.PluginTableDisplayData = removevars(app.PluginTableDisplayData, 'All Dependencies within root directory');
                end
            end
        end
    end
    
    %% Protected methods
    methods(Access=protected)
        
        function attachListeners(app)
            % Attach listener to SelectedSession property to update table
            app.SessionsListener = addlistener(app, 'Sessions', ...
                'PostSet', @(h,e) update(app));
            
            % Attach listener to display data property to update table
            app.DisplayDataListener = addlistener(app, 'PluginTableDisplayData', ...
                'PostSet', @(h,e)updateDisplayDataPluginTable(app,h,e));
            
            % Attach listener to SelectedSession property to update table
            app.SelectedSessionListener = addlistener(app, 'SelectedSession', ...
                'PostSet', @(h,e) update(app));
            
            % Attach listener to Types property to update table
            app.TypesListener = addlistener(app, 'Types', ...
                'PostSet', @(h,e) updateDropDownlist(app,h,e));
            
            % Attach listener to filter value to update table
            app.TypeFilterListener = addlistener(app, 'TypeFilterValue', ...
                'PostSet', @(h,e) filterTableBasedonValue(app));
        end
        
    end
    
    %% Listener methods
    methods(Access=private)
        
        function updateDisplayDataPluginTable(app,~,~)
            app.PluginTable.Data = app.PluginTableDisplayData;
            if verLessThan('matlab','9.9')
                app.PluginTable.ColumnWidth = 'auto';
            else
                app.PluginTable.ColumnWidth = '1x';
            end
            
        end
        
        function updateDropDownlist(app,~,~)
            % remove missing types
            app.Types(ismissing(app.Types)) = "";
            app.Types = unique(app.Types);
            app.FilterDropDown.Items = app.Types;
        end
        
    end
    
    %%
    methods(Static)
        function pluginTable = getPlugins(pluginFolder)
            if ~isempty(pluginFolder) && exist(pluginFolder, 'dir')
                pluginFiles = dir(fullfile(pluginFolder, '*.m'));
                
                % Initialize plugin table
                pluginTable = table('Size',[length(pluginFiles) 5],...
                    'VariableTypes',{'string','string','string','string','cell'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
                
                for i = 1:length(pluginFiles)
                    fileloc = fullfile(pluginFolder, pluginFiles(i).name);
                    fID = fopen(fileloc, 'r');
                    fileData = fread(fID);
                    fclose(fID);
                    
                    % Name column
                    chardata = char(fileData');
                    data = splitlines(string(chardata));
                    pluginTable.Name(i) = extractBefore(pluginFiles(i).name, '.m');
                    
                    % File column
                    pluginTable.File(i) = fileloc;
                    
                    % Type column
                    typeLineIdx = find(contains(data, 'Inputs'))+1;
                    if ~isempty(typeLineIdx)
                        inputType =  strtrim(split(data(typeLineIdx)));
                        inputType = split(inputType(2),'.');
                        if ~isempty(inputType) && inputType(end) ~= ""
                            pluginTable.Type(i) = inputType(end);
                        end
                    end
                    
                    % Description column
                    descriptionLineIdx = find(contains(data, 'Description'))+1;
                    if ~isempty(descriptionLineIdx)
                        description = strtrim(extractAfter(data(descriptionLineIdx), '%'));
                        if ~isempty(description) && description ~= ""
                            pluginTable.Description(i) = description;
                        end
                    end
                    
                    % Function handle column
                    currentDir = pwd;
                    cd(pluginFolder);
                    try
                        pluginTable.FunctionHandle{i} = str2func(pluginTable.Name(i));
                    catch ME
                        warning(ME.message);
                    end
                    cd(currentDir);
                end
                
                % remove rows that do not contain valid functionalities
                allTypes = unique(pluginTable.Type);
                isValidFunc = ismember(allTypes, QSPViewerNew.Application.ApplicationUI.ItemTypes(:,2));
                pluginTable(matches(pluginTable.Type, allTypes(~isValidFunc)),:) = [];
                pluginTable(ismissing(pluginTable.Type),:) = [];
            else
                pluginTable = table('Size',[0 5],...
                    'VariableTypes',{'string','string','string','string','function_handle'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
            end
        end
        
        function tf = isPathinRootDirectory(path, rootDir)
            allFiles = dir(fullfile(rootDir, '**'));
            allFiles = fullfile(string({allFiles.folder}), string({allFiles.name}))';
            tf = matches(path, allFiles);
        end
    end
    
end
