classdef PluginManager < handle
    %% Properties
    properties (SetObservable)
        % Plugins folder
        PluginFolder = ''
        
        % Display Flag
        DisplayFlag (1, 1) logical = true
    end
    
    properties
        UIFigure            matlab.ui.Figure
        PanelMain           matlab.ui.container.Panel
        GridMain            matlab.ui.container.GridLayout
        FilterLabel         matlab.ui.control.Label
        FilterDropDown      matlab.ui.control.DropDown
        FilterIcon          matlab.ui.control.Image
        PluginTable         matlab.ui.control.Table
        AddNewButton        matlab.ui.control.Button
        UpdateButton        matlab.ui.control.Button
        ChoosePluginFolder  matlab.ui.control.Button
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
        
        % listener handle for DisplayFlag property
        DisplayFlagListener event.listener
        
        % listener handle for PluginFolder property
        PluginFolderListener event.listener
        
        % listener handle for Types property
        TypesListener event.listener
    end %properties
    %% Constructor
    methods
        
        function obj = PluginManager(varargin)
            if nargin > 1
                obj.PluginFolder = varargin{1};
                obj.DisplayFlag = varargin{2};
            elseif nargin == 1
                obj.PluginFolder = varargin{1};
            end
            obj.attachListeners();
            obj.create();
            obj.updateTable();
        end
        
    end  % constructor
    
    %% Public methods
    methods
        
        function create(obj)
            ButtonSize = 30;
            
            % Create a parent figure
            obj.UIFigure = uifigure('Name', 'Plugin Manager', 'Visible', 'off');
            obj.UIFigure.Position(3:4) = [1000, 420];
            typeStr = matlab.lang.makeValidName(class(obj));
            obj.UIFigure.Position = getpref(typeStr,'Position',obj.UIFigure.Position);
            obj.UIFigure.CloseRequestFcn = @(s,e) obj.closePluginManager;
            
            % Create the main grid
            obj.GridMain = uigridlayout(obj.UIFigure);
            obj.GridMain.ColumnWidth = {'1x','1x',ButtonSize,'1x','1x','1x',ButtonSize,'1x','1x'};
            obj.GridMain.RowHeight = {'1x','fit','1x'};
            
            % Create Filter edit field
            obj.FilterLabel = uilabel(obj.GridMain, 'Text', 'Search  (Type):',...
                'WordWrap', 'on');
            obj.FilterLabel.Layout.Row = 1;
            obj.FilterLabel.Layout.Column = 1;
            
            % Create Filter edit field
            obj.FilterDropDown = uidropdown(obj.GridMain, 'Items', obj.Types, 'Value', "all");
            obj.FilterDropDown.Layout.Row = 1;
            obj.FilterDropDown.Layout.Column = 2;
            obj.FilterDropDown.ValueChangedFcn = @(s,e) obj.FilterTableBasedonValue;
            
            % Create Filter icon
            obj.FilterIcon = uiimage(obj.GridMain);
            obj.FilterIcon.ImageSource = QSPViewerNew.Resources.LoadResourcePath('filter_24.png');
            obj.FilterIcon.Layout.Row = 1;
            obj.FilterIcon.Layout.Column = 3;
            
            % Create PluginTable
            obj.PluginTable = uitable(obj.GridMain);
            obj.PluginTable.Layout.Row = 2;
            obj.PluginTable.Layout.Column = [1, length(obj.GridMain.ColumnWidth)];
            
            % Create choose plugin folder button
            obj.ChoosePluginFolder = uibutton(obj.GridMain, 'push', ...
                'WordWrap', 'on');
            obj.ChoosePluginFolder.Layout.Row = 3;
            obj.ChoosePluginFolder.Layout.Column = 4;
            obj.ChoosePluginFolder.Text = "Choose Plugin folder";
            obj.ChoosePluginFolder.ButtonPushedFcn = @(s,e) obj.choosePluginFolder;
            
            % Create Add new button
            obj.AddNewButton = uibutton(obj.GridMain, 'push');
            obj.AddNewButton.Layout.Row = 3;
            obj.AddNewButton.Layout.Column = 5;
            obj.AddNewButton.Text = "Add New";
            obj.AddNewButton.ButtonPushedFcn = @(s,e) obj.addFile;
            
            % Create Update button
            obj.UpdateButton = uibutton(obj.GridMain, 'push');
            obj.UpdateButton.Layout.Row = 3;
            obj.UpdateButton.Layout.Column = 6;
            obj.UpdateButton.Text = "Update";
            obj.UpdateButton.ButtonPushedFcn = @(s,e) obj.updateFile;
            
            % Populate table with plugin data
            obj.FilterTableBasedonValue();
            
            if obj.DisplayFlag
                obj.UIFigure.Visible = 'on';
            end
        end
        
        function updateTable(obj,~,~)
            if ~isempty(obj.PluginFolder)
                pluginFiles = dir(fullfile(obj.PluginFolder, '*.m'));
                
                % Initialize plugin table
                pluginTable = table('Size',[length(pluginFiles) 5],...
                    'VariableTypes',{'string','string','string','string','cell'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
                
                for i = 1:length(pluginFiles)
                    fileloc = fullfile(obj.PluginFolder, pluginFiles(i).name);
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
                    cd(obj.PluginFolder);
                    pluginTable.FunctionHandle{i} = str2func(pluginTable.Name(i));
                    cd(currentDir);
                end
            else
                pluginTable = table('Size',[0 5],...
                    'VariableTypes',{'string','string','string','string','function_handle'},...
                    'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
            end
            
            obj.PluginTableData = pluginTable;
            additionalTypes = setdiff(unique(pluginTable.Type), obj.Types);
            if ~isempty(additionalTypes)
                obj.Types = [obj.Types; additionalTypes];
            end
            obj.FilterTableBasedonValue();
        end
        
        function choosePluginFolder(obj)
            selpath = uigetdir;
            drawnow;
            obj.UIFigure;
            if selpath
                obj.PluginFolder = selpath;
            end
        end
        
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
            codeGenerator.addLine('%       QSPViewer.App object');
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
        
        function updateFile(obj)
            obj.updateTable();
        end
        
        function FilterTableBasedonValue(obj)
            if strcmp(obj.FilterDropDown.Value, "all")
                obj.PluginTableDisplayData = obj.PluginTableData;
            elseif ~isempty(obj.FilterDropDown.Value)
                filterstr = obj.FilterDropDown.Value;
%                 rowContainingFilter = contains(obj.PluginTableData.Type, filterstr, 'IgnoreCase', true);
                rowContainingFilter = obj.PluginTableData.Type==filterstr;
                obj.PluginTableDisplayData = obj.PluginTableData(rowContainingFilter,:);
            else
                obj.PluginTableDisplayData = obj.PluginTableData(ismissing(obj.PluginTableData.Type),:);
            end
        end
        
        function updateDisplayDataPluginTable(obj)
            obj.PluginTableDisplayData = removevars(obj.PluginTableDisplayData, 'FunctionHandle');
            obj.PluginTable.Data = obj.PluginTableDisplayData;
            obj.PluginTable.ColumnWidth = {'1x', '1x', '1x', '1x'};
        end
        
        function displayPluginManager(obj)
            if obj.DisplayFlag
                if isvalid(obj.UIFigure)
                    obj.UIFigure.Visible = 'on';
                else
                    obj.create();
                end
            else
                if isvalid(obj.UIFigure)
                    obj.UIFigure.Visible = 'off';
                end
            end
        end
        
        function updateDropDownlist(obj)
            % remove missing types
            obj.Types(ismissing(obj.Types)) = "";
            obj.Types = unique(obj.Types);
            obj.FilterDropDown.Items = obj.Types;
        end
        
        function closePluginManager(obj)
            typeStr = matlab.lang.makeValidName(class(obj));
            setpref(typeStr,'Position',obj.UIFigure.Position);
            
            delete(obj.UIFigure);
        end
        
    end
    
    %% Private methods
    methods(Access=protected)
        
        function attachListeners(obj)
            % Attach listener to display data property to update table
            obj.DisplayDataListener = addlistener(obj, 'PluginTableDisplayData', ...
                'PostSet', @(h,e)updateDisplayDataPluginTable(obj));
            
            % Attach listener to display data property to update graphics
            obj.DisplayFlagListener = addlistener(obj, 'DisplayFlag', ...
                'PostSet', @(h,e)displayPluginManager(obj));
            
            % Attach listener to plugin folder property to update table
            obj.PluginFolderListener = addlistener(obj, 'PluginFolder', ...
                'PostSet', @(h,e) updateTable(obj));
            
            % Attach listener to Types property to update table
            obj.TypesListener = addlistener(obj, 'Types', ...
                'PostSet', @(h,e) updateDropDownlist(obj));
        end
        
    end
    
end
