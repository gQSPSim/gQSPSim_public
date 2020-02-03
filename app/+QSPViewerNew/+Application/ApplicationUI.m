classdef ApplicationUI < matlab.apps.AppBase
    % ApplicationUI - this class will create the window for the UI. 
    % ---------------------------------------------------------------------
    % Instantiates the Application figure window
    %
    % Syntax:
    %           app = QSPViewerNew.Application.ApplicationUI
    %
    % This class inherits properties and methods from:
    %
    %       matlab.apps.AppBase 
    %
    % Properties
    %   Title- the title of the application to be displayed at the top of
    %   the window. this includes the current session
    %
    %   AppName - Name of the application
    %    
    %   Sessions - top level QSP.Session objects for each session that is loaded
    %
    %   Version - Version of the application
    %
    %   AllowMultipleSessions - indicates whether this app is
    %   single-session or multi-session [true|(false)] 
    %
    %   SelectionSessionIdx - The index of the selected Session
    %
    %   FileSpec - file type specification for load save (see doc
    %   uigetfile) [{'*.mat','MATLAB MAT File'}]
    %
    %   IsDirty - logical array inidicating which session files are dirty
    %
    %   SessionPaths - file paths of sessions currently loaded
    %
    %   SelectedSessionIdx - index of currently selected session
    %
    %   SessionNames (read-only) - filename and extension of sessions
    %   currently loaded, based on the SessionPaths property
    %
    %   NumSessions (read-only) - indicates number of sessions currently
    %   loaded, based on the SessionPaths property
    %
    %   RecentSessionPaths = cell.empty(0,1) %List of recent session files
    %
    %   LastFolder - The last folder to be accessed. 
    %
    %   ActivePane - The pane that is currently displayed
    % 
    %   IsConstructed - Is the application constructed[t or f]\
    %
    %   SelectedSessionName (Dependent) - Name of selected Session
    %
    %   SelectedSessionPath (Dependent) - Path of selected Session
    %
    %   NumSessions (Dependent) - Num of session loaded
    %
    %   SessionNames (Dependent) - Name of all sessions loaded
    %
    %   SelectedSession (Dependent) - Session that is currently loaded
    %
    %   SessionNode (Dependent) - Treenode of the currently selected
    %   session
    %   
    %
    %   
    %
    % Methods to create
    %
    % onExit()
    %
    %
    %   Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy 
    %   Revision: 1
    %   1/8/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Properties for handling sessions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties  
        Sessions = QSP.Session.empty(0,1)
        AppName
        Title
    end
    
    properties(Constant)
        Version = 'v1.0'
    end
    
    properties (SetAccess = private)
        AllowMultipleSessions = true;
        FileSpec 
        SelectedSessionIdx = double.empty(0,1)
        SessionPaths = cell.empty(0,1) 
        IsDirty = logical.empty(0,1) 
        RecentSessionPaths = cell.empty(0,1)
        LastFolder = pwd
        ActivePane  %= QSPViewerNew.Application.ViewPane.empty(0,1)
        IsConstructed = false;
    end
    
    properties (SetAccess = private, Dependent = true, AbortSet = true)
        SelectedSessionName
        SelectedSessionPath
        NumSessions
        SessionNames
        SelectedSession
        SessionNode
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % UI handle properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Access = public)
        %These components are created when the application is created
        UIFigure                 matlab.ui.Figure
        FileMenu                 matlab.ui.container.Menu
        NewCtrlNMenu             matlab.ui.container.Menu
        OpenCtrl0Menu            matlab.ui.container.Menu
        OpenRecentMenu           matlab.ui.container.Menu
        CloseMenu                matlab.ui.container.Menu
        SaveCtrlSMenu            matlab.ui.container.Menu
        SaveAsMenu               matlab.ui.container.Menu
        ExitCtrlQMenu            matlab.ui.container.Menu
        QSPMenu                  matlab.ui.container.Menu
        AddNewItemMenu           matlab.ui.container.Menu
        DatasetMenu              matlab.ui.container.Menu
        ParameterMenu            matlab.ui.container.Menu
        TaskMenu                 matlab.ui.container.Menu
        VirtualSubjectsMenu      matlab.ui.container.Menu
        AcceptanceCriteriaMenu   matlab.ui.container.Menu
        TargetStatisticsMenu     matlab.ui.container.Menu
        SimulationMenu           matlab.ui.container.Menu
        OptimizationMenu         matlab.ui.container.Menu
        CohortGenerationMenu     matlab.ui.container.Menu
        VirtualPopulationGenerationMenu  matlab.ui.container.Menu
        DeleteSelectedItemMenu   matlab.ui.container.Menu
        RestoreSelectedItemMenu  matlab.ui.container.Menu
        HelpMenu                 matlab.ui.container.Menu
        AboutMenu                matlab.ui.container.Menu
        GridLayout               matlab.ui.container.GridLayout
        SessionExplorerPanel     matlab.ui.container.Panel
        TreeRoot                 matlab.ui.container.Tree
        h = struct() %For widgets to store internal handles
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Constructors and Destructors 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)

        % Construct app
        function app = ApplicationUI
            % Create UIFigure and components
            app.AppName = ['gQSPsim ' app.Version];
            app.AllowMultipleSessions = true;
            app.FileSpec = {'*.qsp.mat','MATLAB QSP MAT File'};
            
            % Create the graphics objects
            app.create();

            % Register the app with App Designer
            app.IsConstructed = true;
            
            % Refresh the entire view
            app.refresh();
            app.redraw();
            app.redrawrecentfiles();
            
            if nargout == 0
                clear app
            end
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Methods to initilize application UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        % Create UIFigure and components
        function create(app)
            %for reference in callbacks
            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1005 864];
            app.UIFigure.Name = 'UI Figure';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create NewCtrlNMenu
            app.NewCtrlNMenu = uimenu(app.FileMenu);
            app.NewCtrlNMenu.Text = 'New...';
            app.NewCtrlNMenu.Accelerator = 'N';
            app.NewCtrlNMenu.MenuSelectedFcn = @app.onNew;
            

            % Create OpenCtrl0Menu
            app.OpenCtrl0Menu = uimenu(app.FileMenu);
            app.OpenCtrl0Menu.Text = 'Open...';
            app.OpenCtrl0Menu.MenuSelectedFcn = @app.onOpen;
            app.OpenCtrl0Menu.Accelerator = 'O';

            % Create OpenRecentMenu
            app.OpenRecentMenu = uimenu(app.FileMenu);
            app.OpenRecentMenu.Text = 'Open Recent';

            % Create CloseMenu
            app.CloseMenu = uimenu(app.FileMenu);
            app.CloseMenu.Separator = 'on';
            app.CloseMenu.Text = 'Close';
            app.CloseMenu.MenuSelectedFcn = @app.onClose;

            % Create SaveCtrlSMenu
            app.SaveCtrlSMenu = uimenu(app.FileMenu);
            app.SaveCtrlSMenu.Separator = 'on';
            app.SaveCtrlSMenu.Text = 'Save';
            app.SaveCtrlSMenu.MenuSelectedFcn = @app.onSave;
            app.SaveCtrlSMenu.Accelerator = 'S';

            % Create SaveAsMenu
            app.SaveAsMenu = uimenu(app.FileMenu);
            app.SaveAsMenu.Text = 'Save As...';
            app.SaveAsMenu.MenuSelectedFcn = @app.onSaveAs;

            % Create ExitCtrlQMenu
            app.ExitCtrlQMenu = uimenu(app.FileMenu);
            app.ExitCtrlQMenu.Separator = 'on';
            app.ExitCtrlQMenu.Text = 'Exit';
            app.ExitCtrlQMenu.MenuSelectedFcn = @app.onExit;
            app.ExitCtrlQMenu.Accelerator = 'Q';

            % Create QSPMenu
            app.QSPMenu = uimenu(app.UIFigure);
            app.QSPMenu.Text = 'QSP';

            % Create AddNewItemMenu
            app.AddNewItemMenu = uimenu(app.QSPMenu);
            app.AddNewItemMenu.Text = 'Add New Item';
            

            % Create DatasetMenu
            app.DatasetMenu = uimenu(app.AddNewItemMenu);
            app.DatasetMenu.Text = 'Dataset';
            app.DatasetMenu.MenuSelectedFcn = @(h,e) app.onAddItem('OptimizationData');

            % Create ParameterMenu
            app.ParameterMenu = uimenu(app.AddNewItemMenu);
            app.ParameterMenu.Text = 'Parameter';
            app.ParameterMenu.MenuSelectedFcn = @(h,e) app.onAddItem('Parameters');

            % Create TaskMenu
            app.TaskMenu = uimenu(app.AddNewItemMenu);
            app.TaskMenu.Text = 'Task';
            app.TaskMenu.MenuSelectedFcn =@(h,e) app.onAddItem('Task');

            % Create VirtualSubjectsMenu
            app.VirtualSubjectsMenu = uimenu(app.AddNewItemMenu);
            app.VirtualSubjectsMenu.Text = 'Virtual Subject(s)';
            app.VirtualSubjectsMenu.MenuSelectedFcn = @(h,e) app.onAddItem('VirtualPopulation');

            % Create AcceptanceCriteriaMenu
            app.AcceptanceCriteriaMenu = uimenu(app.AddNewItemMenu);
            app.AcceptanceCriteriaMenu.Text = 'Acceptance Criteria';
            app.AcceptanceCriteriaMenu.MenuSelectedFcn =@(h,e) app.onAddItem('VirtualPopulationData');

            % Create TargetStatisticsMenu
            app.TargetStatisticsMenu = uimenu(app.AddNewItemMenu);
            app.TargetStatisticsMenu.Text = 'Target Statistics ';
            app.TargetStatisticsMenu.MenuSelectedFcn =@(h,e) app.onAddItem('VirtualPopulationGenerationData');

            % Create SimulationMenu
            app.SimulationMenu = uimenu(app.AddNewItemMenu);
            app.SimulationMenu.Text = 'Simulation';
            app.SimulationMenu.MenuSelectedFcn = @(h,e) app.onAddItem('Simulation');
            % Create OptimizationMenu
            app.OptimizationMenu = uimenu(app.AddNewItemMenu);
            app.OptimizationMenu.Text = 'Optimization';
            app.OptimizationMenu.MenuSelectedFcn =@(h,e) app.onAddItem('Optimization');

            % Create CohortGenerationMenu
            app.CohortGenerationMenu = uimenu(app.AddNewItemMenu);
            app.CohortGenerationMenu.Text = 'Cohort Generation';
            app.CohortGenerationMenu.MenuSelectedFcn = @(h,e) app.onAddItem('CohortGeneration');

            % Create VirtualPopulationGenerationMenu
            app.VirtualPopulationGenerationMenu = uimenu(app.AddNewItemMenu);
            app.VirtualPopulationGenerationMenu.Text = 'Virtual Population Generation';
            app.VirtualPopulationGenerationMenu.MenuSelectedFcn = @(h,e) app.onAddItem('VirtualPopulationGeneration');
            
            % Create DeleteSelectedItemMenu
            app.DeleteSelectedItemMenu = uimenu(app.QSPMenu);
            app.DeleteSelectedItemMenu.Text = 'Delete Selected Item';
            app.DeleteSelectedItemMenu.MenuSelectedFcn =@(h,e) app.onAddItem('OptimizationData');

            % Create RestoreSelectedItemMenu
            app.RestoreSelectedItemMenu = uimenu(app.QSPMenu);
            app.RestoreSelectedItemMenu.Text = 'Restore Selected Item';
            app.RestoreSelectedItemMenu.MenuSelectedFcn =@(h,e) app.onAddItem('OptimizationData');

            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIFigure);
            app.HelpMenu.Text = 'Help';

            % Create AboutMenu
            app.AboutMenu = uimenu(app.HelpMenu);
            app.AboutMenu.Text = 'About';
            app.AboutMenu.MenuSelectedFcn = @app.onAbout;

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'4x', '10x'};
            app.GridLayout.RowHeight = {'1x'};

            % Create SessionExplorerPanel
            app.SessionExplorerPanel = uipanel(app.GridLayout);
            app.SessionExplorerPanel.Title = 'Session Explorer';
            app.SessionExplorerPanel.Layout.Row = 1;
            app.SessionExplorerPanel.Layout.Column = 1;

            % Create Tree
            app.TreeRoot = uitree(app.SessionExplorerPanel);
            app.TreeRoot.Position = [1 0 278 820];
            app.TreeRoot.Multiselect = 'on';
            app.TreeRoot.SelectionChangedFcn = @app.onTreeSelectionChanged;
            
            ItemTypes = {
            'Dataset',                          'OptimizationData'
            'Parameter',                        'Parameters'
            'Task',                             'Task'
            'Virtual Subject(s)',               'VirtualPopulation'    
            'Acceptance Criteria',              'VirtualPopulationData'
            'Target Statistics',                'VirtualPopulationGenerationData'
            'Simulation',                       'Simulation'
            'Optimization',                     'Optimization'
            'Cohort Generation',                'CohortGeneration'
            'Virtual Population Generation',    'VirtualPopulationGeneration'
            };
        
            for idx=1:size(ItemTypes,1)
                %Here we create the context menus for the tree, but we dont actually
                %assign them to any components because they havent been
                %created yet
                ThisItemType = strrep(ItemTypes{idx,1},'Settings: ','');
                app.h.TreeMenu.Branch.(ItemTypes{idx,2}) = uicontextmenu('Parent', app.UIFigure);
                uimenu(app.h.TreeMenu.Branch.(ItemTypes{idx,2}),...
                    'Label', ['Add new ' ThisItemType],...
                    'MenuSelectedFcn', @(h,e)app.onAddItem(ItemTypes{idx,2}));
                % For Leaves
                app.h.TreeMenu.Leaf.(ItemTypes{idx,2}) = uicontextmenu('Parent', app.UIFigure);
                uimenu(...
                   'Parent', app.h.TreeMenu.Leaf.(ItemTypes{idx,2}),...
                   'Text', ['Duplicate this ' ThisItemType],...
                   'MenuSelectedFcn', @app.onDuplicateItem);
                uimenu(...
                   'Parent', app.h.TreeMenu.Leaf.(ItemTypes{idx,2}),...
                   'Text', ['Delete this ' ThisItemType],...
                   'Separator', 'on',...
                   'MenuSelectedFcn', @app.onDeleteSelectedItem);
            end     
            
            %Session context menu
            app.h.TreeMenu.Branch.Session = uicontextmenu('Parent', app.UIFigure);
            uimenu(...
                'Parent', app.h.TreeMenu.Branch.Session,...
                'Text', 'Close',...
                'MenuSelectedFcn', @(h,e)onClose(app));
            app.h.TreeMenu.Branch.SessionSave = uimenu(...
                'Parent', app.h.TreeMenu.Branch.Session,...
                'Text', 'Save',...
                'Separator', 'on',...
                'MenuSelectedFcn', @(h,e)onSave(app));
            uimenu(...
                'Parent', app.h.TreeMenu.Branch.Session,...
                'Text', 'SaveAs',...
                'MenuSelectedFcn', @(h,e)onSaveAs(app));
            
            
            % For Deleted Items
            app.h.TreeMenu.Branch.Deleted = uicontextmenu('Parent', app.UIFigure);
            uimenu(...
                'Parent', app.h.TreeMenu.Branch.Deleted,...
                'Text', 'Empty Deleted Items',...
                'MenuSelectedFcn', @(h,e)onEmptyDeletedItems(app,true));
            app.h.TreeMenu.Leaf.Deleted = uicontextmenu('Parent', app.UIFigure);
            uimenu(...
                'Parent', app.h.TreeMenu.Leaf.Deleted,...
                'Text', 'Restore',...
                'MenuSelectedFcn', @(h,e)onRestoreItem(app));
            uimenu(...
                'Parent', app.h.TreeMenu.Leaf.Deleted,...
                'Text', 'Permanently Delete',...
                'Separator', 'on',...
                'MenuSelectedFcn', @(h,e)onEmptyDeletedItems(app,false));
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
            
            
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Callbacks for menu items and context menus
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onNew(app,~,~)
            %We are using multiple sessions so 
            if app.AllowMultipleSessions || app.promptToSave()
                app.createUntitledSession();
            end
        end
        
        function onOpen(app,~,~)
            disp("TODO: Open selected");
        end
        
        function onOpenRecentSelected(app,~,~)
            disp("TODO: Open Recent Selected");
        end
        
        function onClose(app,~,~)
            disp("TODO: Close Selected");
        end
        
        function onSave(app,~,~)
            disp("TODO: Save Selected")
        end
        
        function onSaveAs(app,~,~)
            disp("TODO: Save As Selected")
        end
        
        function onDeleteSelectedItem(app,~,~)
            disp("TODO: Delete Selected");
        end
        
        function onRestoreSelectedItem(app,~,~)
            disp("TODO: Restore Selected");
        end
        
        function onExit(app,~,~)
            disp("TODO: Selected");
        end
        
        function onAbout(app,~,~)
            disp("TODO: About Selected")
        end
        
        function onTreeSelectionChanged(app,handle,event)
            %handle is the root handle
            %event is the event data
            %We can selected mutliple nodes at once. Therefore we need to consider if SelectedNodes is a vector
            SelectedNodes = event.SelectedNodes;
            Root = handle;

            if length(SelectedNodes)>1
                %multiselect
                %We dont do any updates other than drawing
                return
            end

            SelNode = SelectedNodes;
            ThisSessionNode = SelectedNodes;

            %Find which session is the parent of the current one
             while ~isempty(ThisSessionNode) && ThisSessionNode.Parent~=Root
                ThisSessionNode = ThisSessionNode.Parent;                
             end

            %Update which session is currently selected
             if isempty(ThisSessionNode)
                app.SelectedSessionIdx = [];
             else
                % update path to include drop the UDF for previous session
                % and include the UDF for current session
                app.SelectedSession.removeUDF();

                app.SelectedSessionIdx = find(ThisSessionNode == app.SessionNode);
                app.SelectedSession.addUDF();
             end

             app.refresh();

             %Disable interaction while we do what we have to do
            if ~isempty(SelNode) ...
                    && ~isempty(app.ActivePane) && isprop(app.ActivePane,'h') && isfield(app.ActivePane.h,'MainAxes')
                thisObj = SelNode.Value;
                if any(ismember(app.ActivePane.Selection,[1 3]))
                    % Call updateVisualizationView to disable Visualization button if invalid items                    
                    switch class(thisObj)
                        case {'QSP.Simulation','QSP.Optimization','QSP.VirtualPopulationGeneration','QSP.CohortGeneration'}
                            if app.ActivePane.Selection == 3
                                plotData(app.ActivePane);
                            end
                            updateVisualizationView(app.ActivePane);                                   
                    end                    
                end                
            end    
        end
         
        function onAddItem(app,ItemType)
            if ischar(ItemType)
                ThisObj = QSP.(ItemType)();
            elseif isobject(ItemType)
                ThisObj = ItemType;
                ItemType = strrep(class(ThisObj),'QSP.','');
            else
               error('Invalid ItemType'); 
            end
            
            % special case since vpop data has been renamed to acceptance
            % criteria
            
            if strcmp(ItemType, 'VirtualPopulationData')
                ItemName = 'Acceptance Criteria';
            elseif strcmp(ItemType, 'VirtualPopulationGenerationData')
                ItemName = 'Target Statistics';
            elseif strcmp(ItemType, 'VirtualPopulation')
                ItemName = 'Virtual Subjects';
            elseif strcmp(ItemType, 'OptimizationData')
                ItemName = 'Dataset';
            else
                ItemName = ItemType;
            end
            
            % Get the session
            ThisSession = app.SelectedSession;
            
            
            % Where does the item go?
            if isprop(ThisSession,ItemType)
                ParentObj = ThisSession;
            else
                ParentObj = ThisSession.Settings;
            end
            
            % What tree branch does this go under?
            ChildNodes = ParentObj.TreeNode.Children;
            ChildTypes = {ChildNodes.UserData};
            if any(strcmpi(ItemType,{'Simulation','Optimization','CohortGeneration','VirtualPopulationGeneration'}))
                ThisChildNode = ChildNodes(strcmpi(ChildTypes,'Functionalities'));
                ChildNodes = ThisChildNode.Children;
                ChildTypes = {ChildNodes.UserData};
            end
            
            ParentNode = ChildNodes(strcmp(ChildTypes,ItemType));
            
            % Create the new item
            NewName = ThisObj.Name;
            if isempty(NewName)
                NewName = ['New ' ItemName];
            end
            
            DisallowedNames = {ParentObj.(ItemType).Name};
            NewName = matlab.lang.makeUniqueStrings(NewName, DisallowedNames);
            ThisObj.Name = NewName;
            if isprop(ThisObj,'Settings')
                ThisObj.Settings = ThisSession.Settings;
            end
            if isprop(ThisObj,'Session')
                ThisObj.Session = ThisSession;
            end
            
            % Place the item and add the tree node
            if isscalar(ParentNode)
                ParentObj.(ItemType)(end+1) = ThisObj;
                app.createTree(ParentNode, ThisObj);
                ParentNode.expand();
            else
                error('Invalid tree parent');
            end
            
            % Mark the current session dirty
            app.markDirty();
            
            % Update the display
            app.refresh();
        end
        
        function onDuplicateItem(app,h,e)
            disp("TODO: Duplicate This item")
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Methods for interacting with the active sessions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden = true)
        
        function createUntitledSession(app)
            % Add a new session called 'untitled_x'
            % Clear existing sessions if needed
            if ~app.AllowMultipleSessions
                app.SessionPaths = cell.empty(0,1);
                %Save? 
            end
            
            % Call subclass method to create storage for the new session
            app.createNewSession();
            
            % Create the new session and select it
            NewName = matlab.lang.makeUniqueStrings('untitled',app.SessionNames);
            idxNew = app.NumSessions +1;
            app.SessionPaths{idxNew,1} = NewName;
            app.IsDirty(idxNew,1) = false;

            % remove UDF from selected session
            app.SelectedSession.removeUDF();
            app.SelectedSessionIdx = idxNew;
            
            app.redraw();
            app.refresh(); %Call refresh of the main app
        end
        
        function createNewSession(app,Session)
            % Was a session provided? If not, make a new one
            if nargin < 2
                Session = QSP.Session();
            end
            
            % Add the session to the tree
            Root = app.TreeRoot;
            app.createTree(Root, Session);


            %% Update the app state
            
            % Which session is this?
            newIdx = app.NumSessions + 1;

            % Add the session to the app
            app.Sessions(newIdx) = Session;

            % Start timer
            initializeTimer(Session);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Methods for drawing UI components dynamically
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected)
        
        function createTree(app, Parent, AllData)
            % Nodes that take children have the type of child as a string in the UserData
            % property. Nodes that are children and are movable have [] in UserData.
            % Get short name to call this function recursively
            thisFcn = @(Parent,Data) createTree(app, Parent, Data);

            % Loop on objects
            for idx = 1:numel(AllData)

                % Get current object
                Data = AllData(idx);

                % What type of object is this?
                Type = class(Data);

                % Switch on object type for the icon
                switch Type

                    case 'QSP.Session'

                        % Session node
                        hSession = app.i_addNode(Parent, Data, ...
                            'Session', 'folder_24.png',...
                             app.h.TreeMenu.Branch.Session, [], 'Session');
                        Data.TreeNode = hSession; %Store node in the object for cross-ref

                        % Settings node and children
                        hSettings = app.i_addNode(hSession, Data.Settings, ...
                            'Building blocks', 'settings_24.png',...
                            [], 'Settings', 'Building blocks for the session');
                        Data.Settings.TreeNode = hSettings; %Store node in the object for cross-ref

                        hTasks = app.i_addNode(hSettings, Data.Settings, ...
                            'Tasks', 'flask2.png',...
                            app.h.TreeMenu.Branch.Task, 'Task', 'Tasks');
                        thisFcn(hTasks, Data.Settings.Task);

                        hParameters = app.i_addNode(hSettings, Data.Settings, ...
                            'Parameters', 'param_edit_24.png',...
                            app.h.TreeMenu.Branch.Parameters, 'Parameters', 'Parameters');
                        thisFcn(hParameters, Data.Settings.Parameters);

                        hOptimData = app.i_addNode(hSettings, Data.Settings, ...
                            'Datasets', 'datatable_24.png',...
                            app.h.TreeMenu.Branch.OptimizationData, 'OptimizationData', 'Datasets');
                        thisFcn(hOptimData, Data.Settings.OptimizationData);


                        hVPopDatas = app.i_addNode(hSettings, Data.Settings, ...
                            'Acceptance Criteria', 'acceptance_criteria.png',...
                            app.h.TreeMenu.Branch.VirtualPopulationData, 'VirtualPopulationData', 'Acceptance Criteria');
                        thisFcn(hVPopDatas, Data.Settings.VirtualPopulationData);

                        hVPopGenDatas = app.i_addNode(hSettings, Data.Settings, ...
                            'Target Statistics', 'target_stats.png',...
                            app.h.TreeMenu.Branch.VirtualPopulationGenerationData, 'VirtualPopulationGenerationData', 'Target Statistics');
                        thisFcn(hVPopGenDatas, Data.Settings.VirtualPopulationGenerationData);


                        hVPops = app.i_addNode(hSettings, Data.Settings, ...
                            'Virtual Subject(s)', 'stickman3.png',...
                             app.h.TreeMenu.Branch.VirtualPopulation, 'VirtualPopulation', 'Virtual Subject(s)');
                        thisFcn(hVPops, Data.Settings.VirtualPopulation);

                        % Functionalities node and children
                        hFunctionalities = app.i_addNode(hSession, Data, ...
                            'Functionalities', 'settings_24.png',...
                            [], 'Functionalities', 'Functionalities for the session');

                        hSimulations = app.i_addNode(hFunctionalities, Data, ...
                            'Simulations', 'simbio_24.png',...
                            app.h.TreeMenu.Branch.Simulation, 'Simulation', 'Simulation');
                        thisFcn(hSimulations, Data.Simulation);

                        hOptims = app.i_addNode(hFunctionalities, Data, ...
                            'Optimizations', 'optim_24.png',...
                            app.h.TreeMenu.Branch.Optimization, 'Optimization', 'Optimization');
                        thisFcn(hOptims, Data.Optimization);

                        hCohortGen = app.i_addNode(hFunctionalities, Data, ...
                            'Virtual Cohort Generations', 'stickman-3.png',...   
                           app.h.TreeMenu.Branch.CohortGeneration, 'CohortGeneration', 'Cohort Generation');
                        thisFcn(hCohortGen, Data.CohortGeneration);

                        hVPopGens = app.i_addNode(hFunctionalities, Data, ...
                            'Virtual Population Generations', 'stickman-3-color.png',...
                            app.h.TreeMenu.Branch.VirtualPopulationGeneration, 'VirtualPopulationGeneration', 'Virtual Population Generation');
                        thisFcn(hVPopGens, Data.VirtualPopulationGeneration);

                        hDeleteds = app.i_addNode(hSession, Data, ...
                            'Deleted Items', 'trash_24.png',...
                            app.h.TreeMenu.Branch.Deleted, 'Deleted', 'Deleted Items');
                        thisFcn(hDeleteds, Data.Deleted);

                        % Expand Nodes
                        hSession.expand();
                        hSettings.expand();

                    case 'QSP.OptimizationData'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'datatable_24.png',...
                            app.h.TreeMenu.Leaf.OptimizationData, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Parameters'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'param_edit_24.png',...
                            app.h.TreeMenu.Leaf.Parameters, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Task'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'flask2.png',...
                            app.h.TreeMenu.Leaf.Task, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.VirtualPopulation'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'stickman3.png',...
                            app.h.TreeMenu.Leaf.VirtualPopulation, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref


                    case 'QSP.VirtualPopulationData'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'acceptance_criteria.png',...
                            app.h.TreeMenu.Leaf.VirtualPopulationData, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Simulation'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'simbio_24.png',...
                            app.h.TreeMenu.Leaf.Simulation, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Optimization'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'optim_24.png',...
                            app.h.TreeMenu.Leaf.Optimization, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.CohortGeneration'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'stickman-3.png',...
                            app.h.TreeMenu.Leaf.CohortGeneration, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref            

                    case 'QSP.VirtualPopulationGeneration'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'stickman-3-color.png',...
                            app.h.TreeMenu.Leaf.VirtualPopulationGeneration, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.VirtualPopulationGenerationData'
                        hNode = app.i_addNode(Parent, Data, Data.Name, 'target_stats.png',...
                            app.h.TreeMenu.Leaf.VirtualPopulationGeneration, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    otherwise

                        % Skip this node
                        warning('QSPViewer:App:createTree:UnhandledType',...
                            'Unhandled object type for tree: %s. Skipping.', Type);
                        continue

                end %switch
                if isa(Parent,'matlab.ui.container.TreeNode') && strcmp(Parent.Text,'Deleted Items')
                    hNode.UIContextMenu = app.h.TreeMenu.Leaf.Deleted;
                end
            end %for
       end %function
       
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %methods for toggling interactivity and updating the view
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected)
        
        function redraw(app)
            % Get some criteria on selection and whether it's dirty
            SelectionNotEmpty = ~isempty(app.SessionNames) && ~isempty(app.SelectedSessionIdx);
            SelectionIsDirty = SelectionNotEmpty && any(app.IsDirty(app.SelectedSessionIdx));
            
            % Update title bar
            if SelectionNotEmpty
                CurrentFile = app.SessionNames{app.SelectedSessionIdx};
            else
                CurrentFile = '';
            end
            if SelectionIsDirty
                StarStr = ' *';
            else
                StarStr = '';
            end
            app.Title = sprintf('%s - %s%s', app.AppName, CurrentFile, StarStr);
            
            % Enable File->Save only if selection is dirty
            set(app.SaveCtrlSMenu,'Enable',app.tf2onoff(SelectionIsDirty))
            
            % Enable File->SaveAs and File->Close only if selection is made
            set([app.SaveAsMenu, app.CloseMenu],...
                'Enable',app.tf2onoff(SelectionNotEmpty)); 
        end
        
        function markDirty(app)
            %TODO: markDirty
        end
        
        function refresh(app)
           if ~app.IsConstructed
              return
           end
            
           % What is selected?
            SelNode = app.TreeRoot.SelectedNodes; %Nodes
            sIdx = app.SelectedSessionIdx; %index
            
            IsOneSessionSelected = isscalar(sIdx);
            IsSelectedSessionDirty = isequal(app.IsDirty(app.SelectedSessionIdx), true);


            if isscalar(SelNode) && isequal(SelNode.UserData,[])
                if strcmp(SelNode.Parent.UserData,'Deleted')
                    IsNodeRestorable = true;
                    IsNodeRemovable = false;
                else
                    IsNodeRestorable = false;
                    IsNodeRemovable = true;
                end
            else
                IsNodeRestorable = false;
                IsNodeRemovable = false;
            end
            
            set(app.AddNewItemMenu,'Enable',app.tf2onoff(IsOneSessionSelected));
            set(app.DeleteSelectedItemMenu,'Enable',app.tf2onoff(IsNodeRemovable));
            set(app.RestoreSelectedItemMenu,'Enable',app.tf2onoff(IsNodeRestorable));

            % Enable/disable Save on tree context menu for session branch
            % Only do this if the session is dirty
            set(app.SaveCtrlSMenu,'Enable',app.tf2onoff(IsSelectedSessionDirty))
            
            
            % Update each session node in the tree
            for idx=1:app.NumSessions
    
                % Get the session name for this node
                ThisRawName = app.SessionNames{idx};
                ThisName = ThisRawName;

                % Add dirty flag if needed
                if app.IsDirty(idx)
                    ThisName = strcat(ThisName, ' *');
                end
                setSessionName(app.Sessions(idx),ThisRawName);
            end
        end
        
        function redrawrecentfiles(app)
            
        end
       
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Static Methods 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Static)
        
       function answer = tf2onoff(TorF)
            if TorF ==true
                answer =  'on';
            else
                answer = 'off';
            end
        end
        
       function hNode = i_addNode(Parent, Data, Name, Icon, CMenu, PaneType, Tooltip)
        % Create the node
        hNode = uitreenode(...
            'Parent', Parent,...
            'NodeData', Data,...
            'Text', Name,...
            'UserData',PaneType,...
            'Icon',uix.utility.findIcon(Icon));
        hNode.ContextMenu = CMenu;
        end %function
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Get/Set Methods 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function value = get.SessionNames(app)
            [~,value,ext] = cellfun(@fileparts, app.SessionPaths,...
                'UniformOutput', false);
            value = strcat(value,ext);
        end
        
        function value = get.LastFolder(app)
            % If the LastFolder doesn't exist, update it
            if ~exist(app.LastFolder,'dir')
                app.LastFolder = pwd;
            end
            value = app.LastFolder;
        end
        
        function value = get.SelectedSessionPath(app)
            % Grab the session object for the selected session
            sIdx = app.SelectedSessionIdx;
            if isempty(sIdx) || isempty(app.SessionPaths)
                value = '';
            else
                value = app.SessionPaths{app.SelectedSessionIdx};
            end
        end
        
        function value = get.SelectedSessionName(app)
            % Grab the session object for the selected session
            sIdx = app.SelectedSessionIdx;
            if isempty(sIdx) || isempty(app.SessionPaths)
                value = '';
            else
                value = app.SessionNames{app.SelectedSessionIdx};
            end
        end
        
        function value = get.NumSessions(app)
            value = numel(app.SessionPaths);
        end
        
        function value = get.SelectedSessionIdx(app)
            ns = app.NumSessions;
            if ns==0
                value = double.empty(0,1);
            elseif app.SelectedSessionIdx > ns
                value = ns;
            else
                value = app.SelectedSessionIdx;
            end
        end
        
        function set.SelectedSessionIdx(app,value)
            if isempty(value)
                app.SelectedSessionIdx = double.empty(0,1);
            else
                validateattributes(value, {'double'},...
                    {'scalar','positive','integer','<=',app.NumSessions}) %TODO and Discuss
                app.SelectedSessionIdx = value;
            end
            app.redraw()
        end
        
        function set.SessionPaths(app,value)
            if isempty(value)
                app.SessionPaths = cell.empty(0,1);
            else
                app.SessionPaths = value;
            end
            app.redraw()
        end
        
        function value = get.SelectedSession(app)
            % Grab the session object for the selected session
            value = app.Sessions(app.SelectedSessionIdx);
        end
        
        function set.SelectedSession(app,value)
            % Grab the session object for the selected session
            app.Sessions(app.SelectedSessionIdx) = value;
        end
        
        function value = get.SessionNode(app)
            if isempty(app.Sessions)
                value = matlab.ui.container.TreeNode;
            else
                value = [app.Sessions.TreeNode];
            end
        end
       
    end
    
end