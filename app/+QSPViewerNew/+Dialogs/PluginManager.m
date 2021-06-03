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
        GridMain                    matlab.ui.container.GridLayout
        SessionLabel                matlab.ui.control.Label
        SessionDropDown             matlab.ui.control.DropDown
        PluginFolderLabel           matlab.ui.control.Label
        PluginFolderTextArea        matlab.ui.control.Label
        FilterLabel                 matlab.ui.control.Label
        FilterDropDown              matlab.ui.control.DropDown
        PluginTable                 matlab.ui.control.Table
        AddNewButton                matlab.ui.control.Button
        UpdateButton                matlab.ui.control.Button
        RunDependencyButton         matlab.ui.control.Button
        DependencyCheckbox          matlab.ui.control.CheckBox
        DependencySummaryPanel      matlab.ui.container.Panel
        DependencySummaryGrid       matlab.ui.container.GridLayout
        DependencySummaryArea       QSPViewerNew.Widgets.Summary
    end
    
    properties (SetAccess=private, SetObservable, AbortSet)
        PluginTableData table
        PluginTableDisplayData table
        % Type of objects in the plugin table
        Types (:,1) string = "all"
    end
    
    properties (Hidden, SetAccess = private, Transient, NonCopyable)
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
                
                app.PluginFolderTextArea.Text = '';
                
                app.PluginTableData = app.getPlugins('');
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
                    app.PluginFolderLabel.Text = sprintf("%s\n%s\n%s","Plugin Folder:", ...
                        "(present within or same as", ...
                        "root directory)");
                else
                    app.PluginFolderLabel.Text = sprintf("%s\n%s\n%s\n%s","Plugin Folder:", ...
                        "(not present within root directory.",...
                        "Edit value under corresponding",...
                        "session node in main app.)");
                end
            end
            % Update plugin table
            app.updatePluginTableData();
            
            % Update Types drop-down
            app.Types = ["all"; unique(app.PluginTableData.Type)];
            
            % Update plugin table for display
            app.updateDisplayDataPluginTable();
            
            % update dependency report area
            app.DependencySummaryArea.Information = {'Summary of Dependency folders','';...
                 'Summary of Dependency files','';...
                 'Summary of Dependencies for each plugin', ''};
        end
    end
    %% Private methods
    methods(Access=private)
        
        function createComponents(app)
            % Create a parent figure
            app.UIFigure = uifigure('Name', 'Plugin Manager', 'Visible', 'off');
            app.UIFigure.Position(3:4) = [1200, 750];
            typeStr = matlab.lang.makeValidName(class(app));
            app.UIFigure.Position = getpref(typeStr,'Position',app.UIFigure.Position);
            
            % Create the main grid
            app.GridMain = uigridlayout(app.UIFigure);
            app.GridMain.ColumnWidth = {'1x','0.4x','0.4x','0.6x','1x','1x','1.4x'};
            app.GridMain.RowHeight = {'fit',60,'fit','fit','fit','fit'};
            
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
            app.PluginFolderTextArea.Layout.Column = [2, length(app.GridMain.ColumnWidth)];
            
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
            app.AddNewButton.Layout.Column = [3, 4];
            app.AddNewButton.Text = "Add new plugin";
            app.AddNewButton.ButtonPushedFcn = @(s,e) app.onAddButtonPushed(s,e);
            
            % Create Update button
            app.UpdateButton = uibutton(app.GridMain, 'push');
            app.UpdateButton.Layout.Row = 5;
            app.UpdateButton.Layout.Column = 5;
            app.UpdateButton.Text = "Update";
            app.UpdateButton.ButtonPushedFcn = @(s,e) app.onUpdateButtonPushed(s,e);
            
            % Create Run Dependency button
            app.RunDependencyButton = uibutton(app.GridMain, 'push');
            app.RunDependencyButton.Layout.Row = 5;
            app.RunDependencyButton.Layout.Column = 6;
            app.RunDependencyButton.Text = "Run Dependency";
            app.RunDependencyButton.ButtonPushedFcn = @(s,e) app.onRunDependencyButtonPushed(s,e);
            
            % create panel for dependency panel
            app.DependencySummaryPanel = uipanel(app.GridMain, ...
                'Title', 'Summary Report of Dependencies outside Session root directory (Click Run Dependency to populate report)');
            app.DependencySummaryPanel.Layout.Row = 6;
            app.DependencySummaryPanel.Layout.Column = [1, length(app.GridMain.ColumnWidth)];
            
            % create grid for dependency grid
            app.DependencySummaryGrid = uigridlayout(app.DependencySummaryPanel, [1 1]);
            
            % create textbox for showing dependency report
            app.DependencySummaryArea = QSPViewerNew.Widgets.Summary(app.DependencySummaryGrid,...
                1,1,...
                {'Summary of Dependency folders','';...
                 'Summary of Dependency files','';...
                 'Summary of Dependencies for each plugin', ''});
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
            % Populate table with plugin data
            app.update();
            
        end
        
        function pluginTableDisplayData = filterTableBasedonValue(app)
            if strcmp(app.TypeFilterValue, "all")
                pluginTableDisplayData = app.PluginTableData;
            elseif ~isempty(app.TypeFilterValue) && app.TypeFilterValue~=""
                filterstr = app.TypeFilterValue;
                rowContainingFilter = app.PluginTableData.Type==filterstr;
                pluginTableDisplayData = app.PluginTableData(rowContainingFilter,:);
            else
                pluginTableDisplayData = app.PluginTableData(ismissing(app.PluginTableData.Type),:);
            end
        end
        
        function updatePluginTableData(app)
            if ~isempty(app.SelectedSession)
                pluginTable = app.getPlugins(app.SelectedSession.PluginsDirectory);
                app.PluginTableData = pluginTable;
            end
        end
        
        function [dependencyFiles, dependencyValues] = getDependencyValues(app)
            % run dependency only if plugin table is not empty
            pluginTable = app.PluginTableData;
            dependencyColumn = false(height(pluginTable),1);
            dependencyFiles = cell(height(pluginTable), 2);
            if ~isempty(pluginTable)
                % create progress dialog because this takes time
                d = uiprogressdlg(app.UIFigure,'Title','Running dependency analysis',...
                    'Indeterminate', 'on', 'Cancelable', 'on');
                
                % Run dependency
                
                for i = 1:height(pluginTable)
                    % Check for Cancel button press
                    if d.CancelRequested
                        break;
                    end
                    [fList,~] = matlab.codetools.requiredFilesAndProducts(pluginTable.File(i));
                    tf = app.isPathinRootDirectory(string(fList)',app.SelectedSession.RootDirectory);
                    if all(tf)
                        dependencyColumn(i) = true;
                    end
                    
                    dependencyFiles{i,1} = char(pluginTable.File(i));
                    dependencyFiles{i,2} = fList(~tf)';
                end
                dependencyValues(dependencyColumn) = "Yes" ;
                dependencyValues(~dependencyColumn) = "No" ;
            else
                dependencyValues = logical.empty();
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
        
        function onRunDependencyButtonPushed(app,~,~)
            if ~isempty(app.PluginTableData)
                [dependencyFiles, dependencyValues] = getDependencyValues(app);
                app.PluginTableData.("All Dependencies within root directory") = dependencyValues';
                
                dependencySummaryFiles = vertcat(dependencyFiles{:,2});
                dependencySummaryFiles = unique(dependencySummaryFiles);
                [dependencySummaryFolders,~,~] = fileparts(dependencySummaryFiles);
                if ~iscell(dependencySummaryFolders)
                    dependencySummaryFolders = {dependencySummaryFolders};
                end
                dependencySummaryFolders = unique(dependencySummaryFolders);
                
                report = {'Summary of Dependency folders', dependencySummaryFolders; ...
                    'Summary of Dependency files', dependencySummaryFiles; ...
                    'Summary of Dependencies for each plugin', ''};
                isnotemptyPluginDep = cellfun(@(x) ~isempty(x), (dependencyFiles(:,2)));
                dependencyFiles = dependencyFiles(isnotemptyPluginDep,:);
                report(4:3+size(dependencyFiles,1),1) = dependencyFiles(:,1);
                report(4:3+size(dependencyFiles,1),2) = dependencyFiles(:,2);
                
                app.DependencySummaryArea.Information = report;
            end
        end
        
        function onFilterValueChanged(app,~,~)
            app.TypeFilterValue = app.FilterDropDown.Value;
            app.updateDisplayDataPluginTable();
        end
        
        function onAddButtonPushed(app,~,~)
            app.addFile();
        end
    end
    
    %% Protected methods
    methods(Access=protected)
        
        function attachListeners(app)
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
        
        function updateDisplayDataPluginTable(app)
            if ~isempty(app.PluginTableData)
                pluginTableDisplayData = filterTableBasedonValue(app);
                
                % remove full file path for 'File' column while display
                [~,name,~] = arrayfun(@(x) fileparts(x), pluginTableDisplayData.File);
                pluginTableDisplayData.File = strcat(name, '.m');
            else
                pluginTableDisplayData = app.PluginTableData;
            end
            pluginTableDisplayData = removevars(pluginTableDisplayData, 'FunctionHandle');
            
            if all(ismissing(pluginTableDisplayData.("All Dependencies within root directory")))
                pluginTableDisplayData = removevars(pluginTableDisplayData, 'All Dependencies within root directory');
            end
            
            app.PluginTableDisplayData = pluginTableDisplayData;
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
                pluginTable = table('Size',[length(pluginFiles) 6],...
                    'VariableTypes',{'string','string','string','string','cell','string'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle','All Dependencies within root directory'});
                
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
                pluginTable = table('Size',[0 6],...
                    'VariableTypes',{'string','string','string','string','function_handle','string'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle','All Dependencies within root directory'});
            end
        end
        
        function tf = isPathinRootDirectory(path, rootDir)
            allFiles = dir(fullfile(rootDir, '**'));
            allFiles = [rootDir; fullfile(string({allFiles.folder}), string({allFiles.name}))'];
            tf = matches(path, allFiles);
        end
        
    end

%% Get/Set methods
methods
    function set.Sessions(app, value)
        app.Sessions = value;
        app.update();
    end
    
    function set.PluginTableData(app, value)
        app.PluginTableData = value;
        app.updateDisplayDataPluginTable();
    end
end
end
