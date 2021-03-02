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
        LogfileText         matlab.ui.control.TextArea
        SearchLabel         matlab.ui.control.Label
        SearchDropDown      matlab.ui.control.DropDown
        SearchEditField     matlab.ui.control.EditField
        LoggerTable         matlab.ui.control.Table        
    end
    
    properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % logger object message listeners
        MessageListener (:,1) event.listener
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
                app.LogfileText.Value = '';
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
                app.LogfileText.Value = app.SelectedSession.LoggerFile;
                if ~exist(app.SelectedSession.LoggerFile, 'file')
                    app.LogfileText.FontColor = 'r';
                else
                    app.LogfileText.FontColor = 'k';
                end
                
                % update logger table
                logObj = app.SelectedSession.LoggerObj;
                app.LoggerTableData = logObj.MessageTable;
                
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
            app.GridMain.ColumnWidth = {'0.5x','1x','3x'};
            app.GridMain.RowHeight = {'1x','1x','1x','fit'};
            
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
            app.LogfileText = uitextarea(app.GridMain, 'Value', '');
            app.LogfileText.Layout.Row = 2;
            app.LogfileText.Layout.Column = [2, length(app.GridMain.ColumnWidth)];
            app.LogfileText.Editable = 'off';
            app.LogfileText.BackgroundColor = [0.94, 0.94, 0.94];
            
            % Create Search label
            app.SearchLabel = uilabel(app.GridMain, 'Text', 'Search:');
            app.SearchLabel.Layout.Row = 3;
            app.SearchLabel.Layout.Column = 1;
            
            % Create Search dropdown
            app.SearchDropDown = uidropdown(app.GridMain, 'Items', "all");
            app.SearchDropDown.Layout.Row = 3;
            app.SearchDropDown.Layout.Column = 2;
            app.SearchDropDown.ValueChangedFcn = @(s,e) app.onFilterValueChanged(s,e);
            
            % Create Search string edit field
            app.SearchEditField = uieditfield(app.GridMain);
            app.SearchEditField.Layout.Row = 3;
            app.SearchEditField.Layout.Column = 3;
            app.SearchEditField.ValueChangedFcn = @(s,e) app.onFilterValueChanged(s,e);
            
            % Create Logger Table
            app.LoggerTable = uitable(app.GridMain, 'ColumnSortable', true);
            app.LoggerTable.Layout.Row = 4;
            app.LoggerTable.Layout.Column = [1, length(app.GridMain.ColumnWidth)];
            
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
                searchStr = app.SearchEditField.Value;
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
            end
            
            % update logger table
            app.LoggerTable.Data = loggerT;
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
        
        function onFilterValueChanged(app,~,~)
            app.update();
        end
        
    end
    
    %% Protected methods
    methods(Access=protected)
        
        function attachListeners(app)
            for i = 1:length(app.Sessions)
                % Attach listener to every session's logger object to update logger table
                app.MessageListener(i) = event.listener(app.Sessions(i).LoggerObj, ...
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