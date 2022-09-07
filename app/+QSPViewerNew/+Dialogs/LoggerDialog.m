classdef LoggerDialog < matlab.apps.AppBase
    
    %% Properties
    properties
        % QSP Sessions
        Sessions = QSP.Session.empty(0,1)
        
        % Session selected
        SelectedSession = QSP.Session.empty(0,1)
        
        % Logger Table
        LoggerTableData table
    end
    
    properties (Access=private)
        UIFigure            matlab.ui.Figure                  
        GridMain            matlab.ui.container.GridLayout
        SessionLabel        matlab.ui.control.Label
        SessionDropDown     matlab.ui.control.DropDown
        LogfileLabel        matlab.ui.control.Label
        LogfileText         matlab.ui.control.Label
        OpenButton          matlab.ui.control.Button
        SearchLabel         matlab.ui.control.Label
        SearchDropDown      matlab.ui.control.DropDown
        SearchEditField     matlab.ui.control.EditField
        SearchColumnDropDown matlab.ui.control.DropDown
        GridLoggerTable     matlab.ui.container.GridLayout
        AddNoteButton       matlab.ui.control.Button
        LoggerTable         matlab.ui.control.Table        
    end
    
    properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % logger object message listeners
        MessageListener (:,1) event.listener
    end
    
    properties(Constant)
        ButtonSize      = 30
    end
    
     %% Constructor/Destructor
    methods
        
        % Construct app
        function app = LoggerDialog()
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
        function update(app)
            if isempty(app.Sessions)
                app.SessionDropDown.Items = "";
                app.LogfileText.Text = '';
                app.SearchDropDown.Items = "all";
                app.SelectedSession = QSP.Session.empty(0,1);
                app.LoggerTable.Data = table.empty();
            else
                % update Session dropdown names
                app.SessionDropDown.Items = {app.Sessions.SessionName};
                app.SessionDropDown.ItemsData = vertcat(app.Sessions);
                if ~isempty(app.SelectedSession)
                    selSessionIdx = app.SelectedSession.SessionName==string(app.SessionDropDown.Items);
                    if any(selSessionIdx)
                        app.SelectedSession = app.Sessions(selSessionIdx);
                    else
                        app.SelectedSession = app.Sessions(1);
                    end
                else
                    app.SelectedSession = app.Sessions(1);
                end
                app.SessionDropDown.Value = app.SelectedSession;
                
                % update logfile text area
                app.LogfileText.Text = strcat("(root dir) \", app.SelectedSession.RelativeLoggerFilePath);
                if ~exist(app.SelectedSession.LoggerFile, 'file')
                    app.LogfileText.FontColor = 'r';
                else
                    app.LogfileText.FontColor = 'k';
                end
                
                % update logger table
                loggerObj = QSPViewerNew.Widgets.Logger(app.SelectedSession.LoggerName);
                app.LoggerTableData = loggerObj.MessageTable;
                
                if ~isempty(app.LoggerTableData)
                    app.SearchDropDown.Items = ["all", string(app.LoggerTableData.Properties.VariableNames)];
                else
                    app.SearchDropDown.Items = "all";
                end
                
                if verLessThan('matlab','9.9')
                    app.LoggerTable.ColumnWidth = 'auto';
                else
                    app.LoggerTable.ColumnWidth = '1x';
                end
            end
        end
    end
    
    %% Private methods
    methods(Access=private)
        function createComponents(app)
            % Create a parent figure
            app.UIFigure = uifigure('Name', 'Logger Dialog', 'Visible', 'off');
            app.UIFigure.Position(3:4) = [800, 450];
            typeStr = matlab.lang.makeValidName(class(app));
            app.UIFigure.Position = getpref(typeStr,'Position',app.UIFigure.Position);
            
            % Create the main grid
            app.GridMain = uigridlayout(app.UIFigure);
            app.GridMain.ColumnWidth = {'0.5x','1x','2.5x',app.ButtonSize};
            app.GridMain.RowHeight = {'fit','fit','fit','1x'};
            
            % Create Session label
            app.SessionLabel = uilabel(app.GridMain, 'Text', 'Session:');
            app.SessionLabel.Layout.Row = 1;
            app.SessionLabel.Layout.Column = 1;
            
            % Create Filter edit field
            app.SessionDropDown = uidropdown(app.GridMain, 'Items', "");
            app.SessionDropDown.Layout.Row = 1;
            app.SessionDropDown.Layout.Column = [2, length(app.GridMain.ColumnWidth)];
            app.SessionDropDown.ValueChangedFcn = @(s,e) app.onSelSessionValueChanged(s,e);
            
            % Create log file label
            app.LogfileLabel = uilabel(app.GridMain, 'Text', 'Log file:');
            app.LogfileLabel.Layout.Row = 2;
            app.LogfileLabel.Layout.Column = 1;
            
            % Create text area for plugin folder
            app.LogfileText = uilabel(app.GridMain, 'Text', '');
            app.LogfileText.Layout.Row = 2;
            app.LogfileText.Layout.Column = [2, 3];
            
            % create button to open log file in MATLAB editor
            app.OpenButton = uibutton(app.GridMain, 'push');
            app.OpenButton.Layout.Row = 2;
            app.OpenButton.Layout.Column = 4;
            app.OpenButton.Icon = QSPViewerNew.Resources.LoadResourcePath('openDocument_24.png');
            app.OpenButton.ButtonPushedFcn = @app.onOpenLogfile;
            app.OpenButton.Text = '';
            app.OpenButton.Tooltip = {'Click to open logfile'};
            
            % Create Search label
            app.SearchLabel = uilabel(app.GridMain, 'Text', 'Search:');
            app.SearchLabel.Layout.Row = 3;
            app.SearchLabel.Layout.Column = 1;
            
            % Create Search dropdown
            app.SearchDropDown = uidropdown(app.GridMain, 'Items', "all");
            app.SearchDropDown.Layout.Row = 3;
            app.SearchDropDown.Layout.Column = 2;
            app.SearchDropDown.ValueChangedFcn = @(s,e) app.onSearchDropdownChanged(s,e);
            
            % Create Search string edit field
            app.SearchEditField = uieditfield(app.GridMain);
            app.SearchEditField.Layout.Row = 3;
            app.SearchEditField.Layout.Column = [3, 4];
            app.SearchEditField.ValueChangedFcn = @(s,e) app.onFilterValueChanged(s,e);
            
            % Create search drop-down for column-specific items
            app.SearchColumnDropDown = uidropdown(app.GridMain, 'Items', "all");
            app.SearchColumnDropDown.Layout.Row = 3;
            app.SearchColumnDropDown.Layout.Column = [3, 4];
            app.SearchColumnDropDown.ValueChangedFcn = @(s,e) app.onFilterValueChanged(s,e);
            app.SearchColumnDropDown.Visible = 'off';
            
            % Create gridlayout for Logger table
            app.GridLoggerTable = uigridlayout(app.GridMain);
            app.GridLoggerTable.Layout.Row = 4;
            app.GridLoggerTable.Layout.Column = [1, length(app.GridMain.ColumnWidth)];
            app.GridLoggerTable.ColumnWidth = {app.ButtonSize,'1x'};
            app.GridLoggerTable.RowHeight = {app.ButtonSize,'1x'};
            
            % Create Addnote button
            app.AddNoteButton = uibutton(app.GridLoggerTable, 'push');
            app.AddNoteButton.Layout.Row = 1;
            app.AddNoteButton.Layout.Column = 1;
            app.AddNoteButton.Icon = QSPViewerNew.Resources.LoadResourcePath('messageAdd_16.png');
            app.AddNoteButton.ButtonPushedFcn = @app.onAddNote;
            app.AddNoteButton.Text = '';
            app.AddNoteButton.Tooltip = {'Click to add a note'};
            
            % Create Logger Table
            app.LoggerTable = uitable(app.GridLoggerTable, 'ColumnSortable', true);
            app.LoggerTable.Layout.Row = [1,2];
            app.LoggerTable.Layout.Column = 2;
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
            % Populate table with plugin data
            app.update();
        end
        
        function updateLoggerDisplayData(app)
            loggerT = app.LoggerTableData;
            if ~isempty(loggerT)
                loggerT.Level = string(loggerT.Level);
                
                % filter based on strings
                if strcmp(app.SearchEditField.Visible, 'on')
                    searchStr = app.SearchEditField.Value;
                else
                    searchStr = app.SearchColumnDropDown.Value;
                end
                
                if ~isempty(searchStr) || searchStr~=""
                    rowContainingFilter = false(height(loggerT),1);
                    if app.SearchDropDown.Value=="all"
                        % go through all columns
                        varnames = string(loggerT.Properties.VariableNames);
                        for i = 1:length(varnames)
                            rowContainingFilter = rowContainingFilter | ...
                                contains(string(app.LoggerTableData.(varnames(i))), searchStr, 'IgnoreCase', true);
                        end
                    else
                        rowContainingFilter = rowContainingFilter | ...
                            contains(string(app.LoggerTableData.(app.SearchDropDown.Value)), searchStr, 'IgnoreCase', true);
                    end
                    loggerT = loggerT(rowContainingFilter,:);
                end
                
                loggerT = sortrows(loggerT, 1, 'descend');
            end
            
            % update logger table
            app.LoggerTable.Data = loggerT;
            app.LoggerTable.RowName = [];
            app.addStylingTable();
        end
        
        function addStylingTable(app)
            % add styling
            loggerT = app.LoggerTable.Data;
            if ~isempty(loggerT)
                errorRowsIdx = loggerT.Level=="ERROR";
                warningRowsIdx = loggerT.Level=="WARNING";
                infoRowsIdx = loggerT.Level=="INFO";
                msgRowsIdx = loggerT.Level=="MESSAGE";
                debugRowsIdx = loggerT.Level=="DEBUG";
                
                s = uistyle;
                s.BackgroundColor = '#FFA09E'; % light red
                if any(errorRowsIdx)
                    addStyle(app.LoggerTable, s, 'row', find(errorRowsIdx));
                end
                
                s.BackgroundColor = '#FFFFB8'; % light yellow
                if any(warningRowsIdx)
                    addStyle(app.LoggerTable, s, 'row', find(warningRowsIdx));
                end
                
                s.BackgroundColor = '#A3D8FF'; % lavendar
                if any(infoRowsIdx)
                    addStyle(app.LoggerTable, s, 'row', find(infoRowsIdx));
                end
                
                s.BackgroundColor = '#92F0B0'; % light blue
                if any(msgRowsIdx)
                    addStyle(app.LoggerTable, s, 'row', find(msgRowsIdx));
                end
                
                s.BackgroundColor = '#FFDDAB'; % light gray
                if any(debugRowsIdx)
                    addStyle(app.LoggerTable, s, 'row', find(debugRowsIdx));
                end
            end
        end
    end
    
    %% Callback methods
    methods (Access=private)
        
        function onSelSessionValueChanged(app,~,~)
            app.SelectedSession = app.SessionDropDown.Value;
            app.update();
        end
        
        function onSearchDropdownChanged(app,~,~)
            columnSearch = app.SearchDropDown.Value;
            loggerT = app.LoggerTableData;
            
            if strcmp(columnSearch, "Level") || strcmp(columnSearch, "Name") || ...
                    strcmp(columnSearch, "Type")
                app.SearchColumnDropDown.Items = [""; unique(string(loggerT.(columnSearch)))];
                app.SearchColumnDropDown.Visible = 'on';
                app.SearchEditField.Visible = 'off';
            else
                app.SearchColumnDropDown.Visible = 'off';
                app.SearchEditField.Visible = 'on';
            end
            app.update();
        end
        
        function onFilterValueChanged(app,~,~)
            app.update();
        end
        
        function onOpenLogfile(app,~,~)
            if ~isempty(app.SelectedSession)
                edit(app.SelectedSession.LoggerFile);
            end
        end
        
        function onAddNote(app,~,~)
            % launch dialog to accept inputs
            prompt = {'Enter Name:', 'Enter Note:'};
            dlgtitle = 'Input';
            dims = [1 50];
            answer = inputdlg(prompt,dlgtitle,dims);
            
            if ~isempty(answer)
                loggerObj = QSPViewerNew.Widgets.Logger(app.SelectedSession.LoggerName);
                loggerObj.write(answer{1}, "Note", "INFO", answer{2});
            end
        end
        
    end
    
    %% Protected methods
    methods(Access=protected)
        
        function attachListeners(app)
            for i = 1:length(app.Sessions)
                % Attach listener to every session's logger object to update logger table
                loggerObj = QSPViewerNew.Widgets.Logger(app.Sessions(i).LoggerName);
                
                app.MessageListener(i) = event.listener(loggerObj, ...
                    "MessageReceived", @(src,evt)update(app) );
            end
        end
    end
    
    %% Get/Set methods
    methods
        function set.Sessions(app, value)
            app.Sessions = value;
            app.attachListeners();
            app.update();
        end
        
        function set.LoggerTableData(app, value)
            app.LoggerTableData = value;
            app.updateLoggerDisplayData();
        end
    end
end