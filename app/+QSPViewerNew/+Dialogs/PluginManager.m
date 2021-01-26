classdef PluginManager < matlab.apps.AppBase
    %% Properties
    properties (SetObservable)
        % Plugins folder
        PluginFolder = ''
        
        % Display Flag
%         DisplayFlag (1, 1) logical = true
        TypeFilterValue (1,1) string = "all"
    end
    
    properties (Access=private)
        UIFigure                    matlab.ui.Figure
        PanelMain                   matlab.ui.container.Panel
        GridMain                    matlab.ui.container.GridLayout
        PluginFolderLabel           matlab.ui.control.Label
        PluginFolderTextArea        matlab.ui.control.TextArea
        BrowsePluginFolderButton    matlab.ui.control.Button
        FilterLabel                 matlab.ui.control.Label
        FilterDropDown              matlab.ui.control.DropDown
        FilterIcon                  matlab.ui.control.Image
        PluginTable                 matlab.ui.control.Table
        AddNewButton                matlab.ui.control.Button
        UpdateButton                matlab.ui.control.Button
    end
    
    properties (SetAccess=private, SetObservable, AbortSet)
        PluginTableData table
        PluginTableDisplayData table
        % Type of objects in the plugin table
        Types (:,1) string = "all"
    end
    
    properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % listener handle for PluginTableDisplayData property
        DisplayDataListener event.listener
        
%         % listener handle for DisplayFlag property
%         DisplayFlagListener event.listener
        
        % listener handle for PluginFolder property
        PluginFolderListener event.listener
        
        % listener handle for Types property
        TypesListener event.listener
        
        % listener handle for Type Filter value property
        TypeFilterListener event.listener
    end %properties
    
    %% Constructor/Destructor
    methods
        
        % Construct app
        function app = PluginManager(varargin)
            runningApp = getRunningApp(app);

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
            
            if nargin==1
                displayFlag = varargin{1};
                if ~displayFlag
                    app.UIFigure.Visible = 'off';
                end
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
            % add M file with template
            codeGenerator = vision.internal.calibration.tool.MCodeGenerator;
            codeGenerator.addLine('function myPlugin(obj)');
            codeGenerator.addLine('% myPlugin');
            codeGenerator.addLine('%');
            codeGenerator.addLine('% Syntax:');
            codeGenerator.addLine('%       myPlugin(obj)');
            codeGenerator.addLine('%');
            codeGenerator.addLine('% Description:');
            codeGenerator.addLine('%           Generate a new plugin file');
            codeGenerator.addLine('%');
            codeGenerator.addLine('% Inputs:');
            codeGenerator.addLine('%       QSP.App object');
            codeGenerator.addLine('%');
            codeGenerator.addLine('% Author:');
            codeGenerator.addLine('');
            codeGenerator.addLine('');
            codeGenerator.addLine('');
            codeGenerator.addLine('end');
            
            % open a new M file with above contents
            content = codeGenerator.CodeString;
            editorDoc = matlab.desktop.editor.newDocument(content);
            editorDoc.smartIndentContents;
            editorDoc.goToLine(1);
        end
        
        function update(app)
            % update plugin folder text area
            app.PluginFolderTextArea.Value = app.PluginFolder;
            if ~exist(app.PluginFolder, 'dir')
                app.PluginFolderTextArea.FontColor = 'r';
            else
                app.PluginFolderTextArea.FontColor = 'k';
            end
            
            % Update plugin table 
            app.updatePluginTableData();
            
            % Update Types drop-down
            additionalTypes = setdiff(unique(app.PluginTableData.Type), app.Types);
            if ~isempty(additionalTypes)
                app.Types = [app.Types; additionalTypes];
            end
            
            % Update plugin table 
            app.filterTableBasedonValue();
        end
    end
    %% Private methods
    methods(Access=private)
        
        function createComponents(app)
            ButtonSize = 30;
            
            % Create a parent figure
            app.UIFigure = uifigure('Name', 'Plugin Manager', 'Visible', 'off');
            app.UIFigure.Position(3:4) = [1000, 420];
            typeStr = matlab.lang.makeValidName(class(app));
            app.UIFigure.Position = getpref(typeStr,'Position',app.UIFigure.Position);
            
            % Create the main grid
            app.GridMain = uigridlayout(app.UIFigure);
            app.GridMain.ColumnWidth = {'1x','1x',ButtonSize,'1x','1x',ButtonSize,'1x','1x'};
            app.GridMain.RowHeight = {'1x','1x','fit','1x'};
            
            % Create label for plugin folder text area
            app.PluginFolderLabel = uilabel(app.GridMain, 'Text', 'Plugin Folder:',...
                'WordWrap', 'on');
            app.PluginFolderLabel.Layout.Row = 1;
            app.PluginFolderLabel.Layout.Column = 1;
            
            % Create text area for plugin folder
            app.PluginFolderTextArea = uitextarea(app.GridMain, ...
                'Value', app.PluginFolder);
            app.PluginFolderTextArea.Layout.Row = 1;
            app.PluginFolderTextArea.Layout.Column = [2, 5];
            app.PluginFolderTextArea.Editable='off';
            
            % Create choose plugin folder button
            app.BrowsePluginFolderButton = uibutton(app.GridMain, 'push', ...
                'WordWrap', 'on');
            app.BrowsePluginFolderButton.Layout.Row = 1;
            app.BrowsePluginFolderButton.Layout.Column = 6;
            app.BrowsePluginFolderButton.Text = '';
            app.BrowsePluginFolderButton.Icon = QSPViewerNew.Resources.LoadResourcePath('folder_24.png');
            app.BrowsePluginFolderButton.ButtonPushedFcn = @(s,e) app.onBrowsePluginFolderButtonPushed(s,e);
            
            % Create Filter edit field
            app.FilterLabel = uilabel(app.GridMain, 'Text', 'Search  (Type):',...
                'WordWrap', 'on');
            app.FilterLabel.Layout.Row = 2;
            app.FilterLabel.Layout.Column = 1;
            
            % Create Filter edit field
            app.FilterDropDown = uidropdown(app.GridMain, 'Items', app.Types, 'Value', "all");
            app.FilterDropDown.Layout.Row = 2;
            app.FilterDropDown.Layout.Column = 2;
            app.FilterDropDown.ValueChangedFcn = @(s,e) app.onFilterValueChanged(s,e);
            
            % Create Filter icon
            app.FilterIcon = uiimage(app.GridMain);
            app.FilterIcon.ImageSource = QSPViewerNew.Resources.LoadResourcePath('filter_24.png');
            app.FilterIcon.Layout.Row = 2;
            app.FilterIcon.Layout.Column = 3;
            
            % Create PluginTable
            app.PluginTable = uitable(app.GridMain);
            app.PluginTable.Layout.Row = 3;
            app.PluginTable.Layout.Column = [1, length(app.GridMain.ColumnWidth)];
            
            % Create Add new button
            app.AddNewButton = uibutton(app.GridMain, 'push');
            app.AddNewButton.Layout.Row = 4;
            app.AddNewButton.Layout.Column = 4;
            app.AddNewButton.Text = "Add New";
            app.AddNewButton.ButtonPushedFcn = @(s,e) app.onAddButtonPushed(s,e);
            
            % Create Update button
            app.UpdateButton = uibutton(app.GridMain, 'push');
            app.UpdateButton.Layout.Row = 4;
            app.UpdateButton.Layout.Column = 5;
            app.UpdateButton.Text = "Update";
            app.UpdateButton.ButtonPushedFcn = @(s,e) app.onUpdateButtonPushed(s,e);
            
            % Populate table with plugin data
            app.updatePluginTableData;
            app.filterTableBasedonValue();
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
        end
        
        function filterTableBasedonValue(app)
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
            [~,name,~] = fileparts(app.PluginTableDisplayData.File);
            app.PluginTableDisplayData.File = strcat(name, '.m');
        end
        
        function updatePluginTableData(app)
            if ~isempty(app.PluginFolder) && exist(app.PluginFolder, 'dir')
                pluginFiles = dir(fullfile(app.PluginFolder, '*.m'));
                
                % Initialize plugin table
                pluginTable = table('Size',[length(pluginFiles) 5],...
                    'VariableTypes',{'string','string','string','string','cell'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
                
                for i = 1:length(pluginFiles)
                    fileloc = fullfile(app.PluginFolder, pluginFiles(i).name);
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
                        inputType =  strtrim(extractBetween(data(typeLineIdx), '%', 'object'));
                        inputType = split(inputType,'.');
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
                    cd(app.PluginFolder);
                    try
                        pluginTable.FunctionHandle{i} = str2func(pluginTable.Name(i));
                    catch ME
                        warning(ME.message);
                    end
                    cd(currentDir);
                end
            else
                pluginTable = table('Size',[0 5],...
                    'VariableTypes',{'string','string','string','string','function_handle'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
            end
            
            app.PluginTableData = pluginTable;
        end
        
%         function displayPluginManager(obj)
%             if obj.DisplayFlag
%                 if isvalid(obj.UIFigure)
%                     obj.UIFigure.Visible = 'on';
%                 else
%                     obj.create();
%                 end
%             else
%                 if isvalid(obj.UIFigure)
%                     obj.UIFigure.Visible = 'off';
%                 end
%             end
%         end
    end
    
    %% Callback methods
    methods(Access=private)
        
        function onUpdateButtonPushed(app,~,~)
            app.update();
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
    end
    
    %% Protected methods
    methods(Access=protected)
        
        function attachListeners(app)
            % Attach listener to display data property to update table
            app.DisplayDataListener = addlistener(app, 'PluginTableDisplayData', ...
                'PostSet', @(h,e)updateDisplayDataPluginTable(app,h,e));
            
%             % Attach listener to display data property to update graphics
%             app.DisplayFlagListener = addlistener(app, 'DisplayFlag', ...
%                 'PostSet', @(h,e)displayPluginManager(app));
            
            % Attach listener to plugin folder property to update table
            app.PluginFolderListener = addlistener(app, 'PluginFolder', ...
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
            app.PluginTable.ColumnWidth = '1x';
        end
        
        function updateDropDownlist(app,~,~)
            % remove missing types
            app.Types(ismissing(app.Types)) = "";
            app.Types = unique(app.Types);
            app.FilterDropDown.Items = app.Types;
        end
        
    end
    %% Get/Set methods
    methods
        
    end
    
end
