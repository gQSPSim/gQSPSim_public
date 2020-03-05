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

    % TODO: Methods to create
    %
    % onExit()
    %
    %
    %   Copyright 2020 The MathWorks, Inc.
    %    
    
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
        FileSpec ={'*.mat','MATLAB MAT File'}
        SelectedSessionIdx = double.empty(0,1)
        SessionPaths = cell.empty(0,1) 
        IsDirty = logical.empty(0,1) 
        RecentSessionPaths = cell.empty(0,1)
        LastFolder = pwd
        ActivePane
        Panes
        IsConstructed = false;
        Type
        TypeStr
    end
    
    properties (SetAccess = private, Dependent = true, AbortSet = true)
        SelectedSessionName
        SelectedSessionPath
        NumSessions
        SessionNames
        SelectedSession
        SessionNode
        PaneTypes
    end
    
    properties (Access = private)
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
        TreeMenu                 
        OpenRecentMenuArray 
    end
    
    methods (Access = public)
        
        function app = ApplicationUI
            app.AppName = ['gQSPsim ' app.Version];
            app.FileSpec = {'*.qsp.mat','MATLAB QSP MAT File'};
            
            % Create the graphics objects
            app.create();

            % Register the app with App Designer
            app.IsConstructed = true;
            
            
            %Save the type of the  for use in preferences
            app.Type = class(app);
            app.TypeStr = matlab.lang.makeValidName(app.Type);
            
            %Get the previous file locations from preferences
            app.LastFolder = getpref(app.TypeStr,'LastFolder',app.LastFolder);
            app.RecentSessionPaths = getpref(app.TypeStr,'RecentSessionPaths',app.RecentSessionPaths);
            
            % Validate each recent file, and remove any invalid files
            idxOk = cellfun(@(x)exist(x,'file'),app.RecentSessionPaths);
            app.RecentSessionPaths(~idxOk) = [];
            
            %Draw the recent files to the menu
            app.redrawRecentFiles();
            
            % Refresh the entire view
            app.refresh();
            
            if nargout == 0
                clear app
            end
        end
        
        function delete(app)
            %Upon deletion, save the recent sessions and last folder to use
            %in the next instance of the application
            setpref(app.TypeStr, 'LastFolder', app.LastFolder)
            setpref(app.TypeStr, 'RecentSessionPaths', app.RecentSessionPaths)
        end
        
    end
    
    methods (Access = private)
        
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
                app.TreeMenu.Branch.(ItemTypes{idx,2}) = uicontextmenu('Parent', app.UIFigure);
                uimenu(app.TreeMenu.Branch.(ItemTypes{idx,2}),...
                    'Label', ['Add new ' ThisItemType],...
                    'MenuSelectedFcn', @(h,e)app.onAddItem(ItemTypes{idx,2}));
                % For Leaves
                app.TreeMenu.Leaf.(ItemTypes{idx,2}) = uicontextmenu('Parent', app.UIFigure);
                uimenu(...
                   'Parent', app.TreeMenu.Leaf.(ItemTypes{idx,2}),...
                   'Text', ['Duplicate this ' ThisItemType],...
                   'MenuSelectedFcn', @app.onDuplicateItem);
                uimenu(...
                   'Parent', app.TreeMenu.Leaf.(ItemTypes{idx,2}),...
                   'Text', ['Delete this ' ThisItemType],...
                   'Separator', 'on',...
                   'MenuSelectedFcn', @app.onDeleteSelectedItem);
            end     
            
            %Session context menu
            app.TreeMenu.Branch.Session = uicontextmenu('Parent', app.UIFigure);
            uimenu(...
                'Parent', app.TreeMenu.Branch.Session,...
                'Text', 'Close',...
                'MenuSelectedFcn', @(h,e)onClose(app));
            app.TreeMenu.Branch.SessionSave = uimenu(...
                'Parent', app.TreeMenu.Branch.Session,...
                'Text', 'Save',...
                'Separator', 'on',...
                'MenuSelectedFcn', @(h,e)onSave(app));
            uimenu(...
                'Parent', app.TreeMenu.Branch.Session,...
                'Text', 'SaveAs',...
                'MenuSelectedFcn', @(h,e)onSaveAs(app));
            
            
            % For Deleted Items
            app.TreeMenu.Branch.Deleted = uicontextmenu('Parent', app.UIFigure);
            uimenu(...
                'Parent', app.TreeMenu.Branch.Deleted,...
                'Text', 'Empty Deleted Items',...
                'MenuSelectedFcn', @(h,e)onEmptyDeletedItems(app,true));
            app.TreeMenu.Leaf.Deleted = uicontextmenu('Parent', app.UIFigure);
            uimenu(...
                'Parent', app.TreeMenu.Leaf.Deleted,...
                'Text', 'Restore',...
                'MenuSelectedFcn', @(h,e)onRestoreItem(app));
            uimenu(...
                'Parent', app.TreeMenu.Leaf.Deleted,...
                'Text', 'Permanently Delete',...
                'Separator', 'on',...
                'MenuSelectedFcn', @(h,e)onEmptyDeletedItems(app,false));
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
        
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
                             app.TreeMenu.Branch.Session, [], 'Session');
                        Data.TreeNode = hSession; %Store node in the object for cross-ref

                        % Settings node and children
                        hSettings = app.i_addNode(hSession, Data.Settings, ...
                            'Building blocks', 'settings_24.png',...
                            [], 'Settings', 'Building blocks for the session');
                        Data.Settings.TreeNode = hSettings; %Store node in the object for cross-ref

                        hTasks = app.i_addNode(hSettings, Data.Settings, ...
                            'Tasks', 'flask2.png',...
                            app.TreeMenu.Branch.Task, 'Task', 'Tasks');
                        thisFcn(hTasks, Data.Settings.Task);

                        hParameters = app.i_addNode(hSettings, Data.Settings, ...
                            'Parameters', 'param_edit_24.png',...
                            app.TreeMenu.Branch.Parameters, 'Parameters', 'Parameters');
                        thisFcn(hParameters, Data.Settings.Parameters);

                        hOptimData = app.i_addNode(hSettings, Data.Settings, ...
                            'Datasets', 'datatable_24.png',...
                            app.TreeMenu.Branch.OptimizationData, 'OptimizationData', 'Datasets');
                        thisFcn(hOptimData, Data.Settings.OptimizationData);


                        hVPopDatas = app.i_addNode(hSettings, Data.Settings, ...
                            'Acceptance Criteria', 'acceptance_criteria.png',...
                            app.TreeMenu.Branch.VirtualPopulationData, 'VirtualPopulationData', 'Acceptance Criteria');
                        thisFcn(hVPopDatas, Data.Settings.VirtualPopulationData);

                        hVPopGenDatas = app.i_addNode(hSettings, Data.Settings, ...
                            'Target Statistics', 'target_stats.png',...
                            app.TreeMenu.Branch.VirtualPopulationGenerationData, 'VirtualPopulationGenerationData', 'Target Statistics');
                        thisFcn(hVPopGenDatas, Data.Settings.VirtualPopulationGenerationData);


                        hVPops = app.i_addNode(hSettings, Data.Settings, ...
                            'Virtual Subject(s)', 'stickman3.png',...
                             app.TreeMenu.Branch.VirtualPopulation, 'VirtualPopulation', 'Virtual Subject(s)');
                        thisFcn(hVPops, Data.Settings.VirtualPopulation);

                        % Functionalities node and children
                        hFunctionalities = app.i_addNode(hSession, Data, ...
                            'Functionalities', 'settings_24.png',...
                            [], 'Functionalities', 'Functionalities for the session');

                        hSimulations = app.i_addNode(hFunctionalities, Data, ...
                            'Simulations', 'simbio_24.png',...
                            app.TreeMenu.Branch.Simulation, 'Simulation', 'Simulation');
                        thisFcn(hSimulations, Data.Simulation);

                        hOptims = app.i_addNode(hFunctionalities, Data, ...
                            'Optimizations', 'optim_24.png',...
                            app.TreeMenu.Branch.Optimization, 'Optimization', 'Optimization');
                        thisFcn(hOptims, Data.Optimization);

                        hCohortGen = app.i_addNode(hFunctionalities, Data, ...
                            'Virtual Cohort Generations', 'stickman-3.png',...   
                           app.TreeMenu.Branch.CohortGeneration, 'CohortGeneration', 'Cohort Generation');
                        thisFcn(hCohortGen, Data.CohortGeneration);

                        hVPopGens = app.i_addNode(hFunctionalities, Data, ...
                            'Virtual Population Generations', 'stickman-3-color.png',...
                            app.TreeMenu.Branch.VirtualPopulationGeneration, 'VirtualPopulationGeneration', 'Virtual Population Generation');
                        thisFcn(hVPopGens, Data.VirtualPopulationGeneration);

                        hDeleteds = app.i_addNode(hSession, Data, ...
                            'Deleted Items', 'trash_24.png',...
                            app.TreeMenu.Branch.Deleted, 'Deleted', 'Deleted Items');
                        thisFcn(hDeleteds, Data.Deleted);

                        % Expand Nodes
                        hSession.expand();
                        hSettings.expand();

                    case 'QSP.OptimizationData'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'datatable_24.png',...
                            app.TreeMenu.Leaf.OptimizationData, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Parameters'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'param_edit_24.png',...
                            app.TreeMenu.Leaf.Parameters, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Task'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'flask2.png',...
                            app.TreeMenu.Leaf.Task, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.VirtualPopulation'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'stickman3.png',...
                            app.TreeMenu.Leaf.VirtualPopulation, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref


                    case 'QSP.VirtualPopulationData'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'acceptance_criteria.png',...
                            app.TreeMenu.Leaf.VirtualPopulationData, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Simulation'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'simbio_24.png',...
                            app.TreeMenu.Leaf.Simulation, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.Optimization'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'optim_24.png',...
                            app.TreeMenu.Leaf.Optimization, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.CohortGeneration'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'stickman-3.png',...
                            app.TreeMenu.Leaf.CohortGeneration, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref            

                    case 'QSP.VirtualPopulationGeneration'

                        hNode = app.i_addNode(Parent, Data, Data.Name, 'stickman-3-color.png',...
                            app.TreeMenu.Leaf.VirtualPopulationGeneration, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    case 'QSP.VirtualPopulationGenerationData'
                        hNode = app.i_addNode(Parent, Data, Data.Name, 'target_stats.png',...
                            app.TreeMenu.Leaf.VirtualPopulationGeneration, [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref

                    otherwise

                        % Skip this node
                        warning('QSPViewer:App:createTree:UnhandledType',...
                            'Unhandled object type for tree: %s. Skipping.', Type);
                        continue

                end %switch
                if isa(Parent,'matlab.ui.container.TreeNode') && strcmp(Parent.Text,'Deleted Items')
                    hNode.UIContextMenu = app.TreeMenu.Leaf.Deleted;
                end
            end %for
       end %function
        
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    %Callbacks for menu items and context menus
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    methods (Access = private)
        
        function onNew(app,~,~)
            %We are using multiple sessions so 
            if app.AllowMultipleSessions || app.promptToSave()
                app.createUntitledSession();
            end
            
            app.refresh();
        end
        
        function onOpen(app,~,~)
            %Here we will determine the file path of the folder to call.
            [FileName,PathName] = uigetfile(app.FileSpec,'Open File', app.LastFolder,'MultiSelect','on');

            %Determine what type of output was provided
            outputType = class(FileName);
            
            %Determine if the output was invalid
            
            switch outputType
                case 'double'
                    %The user canceled. Do Nothing
                case 'char'
                    %The user selected a single path
                    app.LastFolder = PathName;
                    fullFilePath = fullfile(PathName,FileName);
                    app.loadSessionFromPath(fullFilePath);
                case 'cell'
                    %The user selected multiple files
                    app.LastFolder = PathName;
                    for fileIndex = 1:length(FileName)
                        fullFilePath = fullfile(PathName,FileName{fileIndex});
                        app.loadSessionFromPath(fullFilePath);
                    end
            end
            
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
            app.UIFigure.Pointer = 'watch';
            drawnow();
            %First we determine the session that is selected
            %We can select mutliple nodes at once. Therefore we need to consider if SelectedNodes is a vector
            SelectedNodes = event.SelectedNodes;
            Root = handle;

            %We only make changes if a single node is selected
            if length(SelectedNodes)==1
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


                 %TODO We need to update the visualization plots

                 %Now that we have the correct session, we can work with the
                 app.refresh();
                 app.UIFigure.Pointer = 'arrow';
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
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    % Methods for interacting with the active sessions
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    methods (Access = private)
        
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
            app.SessionPaths{idxNew} = NewName;
            app.IsDirty(idxNew) = false;

            % remove UDF from selected session
            app.SelectedSession.removeUDF();
            app.SelectedSessionIdx = idxNew;
            
        end
        
        function createNewSession(app,Session)
            % Was a session provided? If not, make a new one
            if nargin < 2
                Session = QSP.Session();
            end
            
            % Add the session to the tree
            Root = app.TreeRoot;
            app.createTree(Root, Session);


            % % Update the app state
            
            % Which session is this?
            newIdx = app.NumSessions + 1;
            
            % Add the session to the app
            app.Sessions(newIdx) = Session;

            % Start timer
            initializeTimer(Session);
        end
        
        function loadSessionFromPath(app, fullFilePath)  
            % Loads a session file from disk found at fullFilePath.
            
            sessionStatus = app.verifyValidSessionFilePath(fullFilePath);
            StatusOk = true;
            if sessionStatus
                %Try to load the session
                try
                   loadedSession = load(fullFilePath, 'Session');
                catch err
                    StatusOk = false;
                    Message = sprintf('The file %s could not be loaded:\n%s', fullFilePath, err.message);
                end

                %Verify that the Session file has the correct atrributes
                try
                    validateattributes(loadedSession.Session, {'QSP.Session'}, {'scalar'});
                catch err
                     StatusOk =false;
                     Message = sprintf(['The file %s did not contain a valid '...
                        'Session object:\n%s'], fullFilePath, err.message);
                end

                %Check if the file is supposed to be removed
                if StatusOk && loadedSession.Session.toRemove
                   StatusOk = false;
                   Message = sprintf(['The file %s did not contain a valid '...
                        'Session object:\n%s'], fullFilePath, err.message);
                end

                %If any of the above failed, we exit and disply why
                if StatusOk == false
                    uialert(app.UIFigure, Message, 'Invalid File')
                else
                    %We have verified the session path, now verify the root
                    %directory
                    [status,newFilePath] = app.getValidSessionRootDirectory(loadedSession.Session.RootDirectory);

                    %If the status is false, we cannot find a valid root. Abandon
                    %call
                    if status
                        %Copy the sessionobject, then add it the application
                        Session = copy(loadedSession.Session);
                        loadedSession.Session.RootDirectory = newFilePath;
                        app.createNewSession(Session);

                        %Edit the app properties to reflect a new loaded session was
                        %added
                        idxNew = app.NumSessions + 1;
                        app.SessionPaths{idxNew} = fullFilePath;
                        app.IsDirty(idxNew) = false;
                        app.SelectedSessionIdx = idxNew;
                        app.addRecentSessionPath(fullFilePath);

                    end
                end
            end
            app.refresh();
        end
        
        function status = verifyValidSessionFilePath(app, fullFilePath)
            % This status function checks whether the filepath provided is valid
            %If not, it will try to find a valid session path
            %If the user cannot find a valid session path, the output is
            %false
            status = true;
           
           if ~exist(fullFilePath,'file')
                Message = sprintf('The specified file does not exist: \n%s',fullFilePath);
                uialert(app.UIFigure,Message,'Invalid File');
                status =false;
            end
            
            %Check that the file isnt already loaded
            if ismember(fullFilePath, app.SessionPaths)
                Message = sprintf('The specified file is already open: \n%s',fullFilePath);
                uialert(app.UIFigure,Message,'Invalid File');
                status = false;
            end
        end
       
        function [status,newFilePath] = getValidSessionRootDirectory(app,filePath)
            %Check if a directory exists. If not, find a valid one.
            existence = exist(filePath,'dir');
            
            %Check if the directory exists
            if existence
                
                %If the directory exists, we set the output values
                status =true;
                newFilePath = filePath;
            else
                questionResult = uiconfirm(app.UIFigure,'Session root directory is invalid. Select a new root directory?',...
                    'Select root directory','Options', {'Yes','Cancel'}, 'Icon', 'question');

                %If they they would like to add a new root directory
                if strcmp(questionResult,'Yes')
                    rootDir = uigetdir('Select valid session root directory');

                    %If the new root directory is valid
                    if rootDir ~= 0
                         status =true;
                         newFilePath = rootDir;
                    else 
                        status =false;
                        newFilePath = '';
                        uialert(app.UIFigure,'The newly selected root directory was not valid','Invalid Directory');
                    end
                else
                    %They chose not to select a new file. 
                    status = false;
                    newFilePath = '';
                end
            end     
        end
        
        function addRecentSessionPath(app,newPath)
            %Check if the new location is already listed
            isInRecent  = ismember(app.RecentSessionPaths,newPath);
            app.RecentSessionPaths(isInRecent) = [];
            
            %Add the File to the top of the list
            app.RecentSessionPaths = vertcat(newPath,app.RecentSessionPaths);
            
            %Crop the 9 most recent entries;
            app.RecentSessionPaths(9:end) = [];
            
            %redraw this context menu
            app.redrawRecentFiles()
        end
        
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    % Methods for drawing UI components.
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    methods (Access = public)
       
       function disableInteraction(app)
           app.TreeRoot.Enable = 'off';
           app.FileMenu.Enable = 'off';
           app.QSPMenu.Enable = 'off';
       end
       
       function enableInteraction(app)
           app.TreeRoot.Enable = 'on';
           app.FileMenu.Enable = 'on';
           app.QSPMenu.Enable = 'on';
       end
       
       function changeInBackEnd(app,newSession)
           %1.Replace the current Session with the newSession
           app.Sessions(app.SelectedSessionIdx) = newSession;
           
           %2. It must update the tree to reflect all the new values from
           %the session
           app.updateTreeData(app.TreeRoot.Children(app.SelectedSessionIdx),newSession,'Session')
           
           app.refresh();
        end
       
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %
    %methods for toggling interactivity and updating the view
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %
    methods (Access = private)
        
        function markDirty(app)
            %TODO: markDirty
        end
        
        function refresh(app)
            %This method refreshes the view of the screen
            if app.IsConstructed
                %Update the names displayed in the tree
                app.updateTreeNames();

                %Update the file menu
                app.updateFileMenu();

                %Update the title of the application
                app.updateAppTitle();

                %Update the current shown frame
                app.updatePane();
                
                drawnow();
            end
        end
        
        function redrawRecentFiles(app)
            % Construct menu items for each path in RecentSessionPaths. 
            
            % Delete the old menus
            delete(app.OpenRecentMenuArray);            
            
            for idx = 1:numel(app.RecentSessionPaths)
                app.OpenRecentMenuArray(idx) = uimenu(app.OpenRecentMenu);
                set(app.OpenRecentMenuArray(idx), 'Text', app.RecentSessionPaths{idx});
                set(app.OpenRecentMenuArray(idx), 'MenuSelectedFcn', @(h, filePath) app.loadSessionFromPath(app.RecentSessionPaths{idx}));                
            end
            
            %If there are no menus to show, remove the option
            if isempty(app.RecentSessionPaths)
                app.OpenRecentMenu.Enable = 'off';
            else
                app.OpenRecentMenu.Enable = 'on';
            end 
        end
        
        function updateFileMenu(app)
            %This will update the file menu interactivity based on the current state of the application 
            
            %Find the current Node
            SelNode = app.TreeRoot.SelectedNodes; %Nodes
            sIdx = app.SelectedSessionIdx; %index          
            
            %Determine if the Node is deleted and update this menu
            if isscalar(SelNode) && isequal(SelNode.UserData,[])
                if strcmp(SelNode.Parent.UserData,'Deleted')
                    IsNodeRestorableTF = true;
                    IsNodeRemovableTF = false;
                else
                    IsNodeRestorableTF = false;
                    IsNodeRemovableTF = true;
                end
            else
                IsNodeRestorableTF = false;
                IsNodeRemovableTF = false;
            end
            set(app.DeleteSelectedItemMenu,'Enable',app.tf2onoff(IsNodeRemovableTF));
            set(app.RestoreSelectedItemMenu,'Enable',app.tf2onoff(IsNodeRestorableTF));
            
            %Determine if a new item can be added
            IsOneSessionSelectedTF = isscalar(sIdx);
            set(app.AddNewItemMenu,'Enable',app.tf2onoff(IsOneSessionSelectedTF));
              
            %Determine if the file is new and should be saved as or saved
            SelectionNotEmpty = ~isempty(app.SessionNames) && ~isempty(app.SelectedSessionIdx);
            SelectionIsDirty = SelectionNotEmpty && any(app.IsDirty(app.SelectedSessionIdx));
            set(app.SaveCtrlSMenu,'Enable',app.tf2onoff(SelectionIsDirty));
            set([app.SaveAsMenu, app.CloseMenu],...
                'Enable',app.tf2onoff(SelectionNotEmpty)); 
            
            
        end
        
        function updateAppTitle(app)
            % Update title bar
            
            SelectionNotEmptyTF = ~isempty(app.SessionNames) && ~isempty(app.SelectedSessionIdx);
            SelectionIsDirtyTF = SelectionNotEmptyTF && any(app.IsDirty(app.SelectedSessionIdx));
            if SelectionNotEmptyTF
                CurrentFile = app.SessionNames{app.SelectedSessionIdx};
            else
                CurrentFile = '';
            end
            if SelectionIsDirtyTF
                StarStr = ' *';
            else
                StarStr = '';
            end
            app.Title = sprintf('%s - %s%s', app.AppName, CurrentFile, StarStr);
            app.UIFigure.Name = app.Title;
            
        end
        
        function updatePane(app)
            %Find the currently selected Node
            NodeSelected = app.TreeRoot.SelectedNodes; %Nodes       
            %Determine if the Node will launch a Pane
            LaunchPaneTF = ~isempty(NodeSelected) && isempty(NodeSelected.UserData);

            %If we shouldnt launch a pane and there is currently a pane,
            %close it
            if ~LaunchPaneTF && ~isempty(app.ActivePane)
                app.ActivePane.hideThisPane();
                app.ActivePane = [];
            elseif LaunchPaneTF  
                %Determine if the pane type has already been loaded
                PaneType = app.GetPaneClassFromQSPClass(class(NodeSelected.NodeData));
                idxPane = app.PaneTypes(strcmp(app.PaneTypes,PaneType));
                if isempty(idxPane)
                    %Launch a new Panewith the data provided
                    app.launchNewPane(NodeSelected.NodeData);
                else
                    %Launch a pane that already exists with the new data
                    app.launchOldPane(NodeSelected.NodeData);
                end
            end
        end
        
        function launchNewPane(app,NodeData)
            %Inputs that the pane API should require in the constructor
            classInputs = {app.GridLayout,1,2,app};
            
            %Need to hide old pane
            if ~isempty(app.ActivePane)
                app.ActivePane.hideThisPane();
                app.ActivePane = [];
            end
            
            %This switch determines the correct type of Pane and creates it
            %The default is that it is not shown
            %TODO: Address this switch statment to refactor
            switch class(NodeData)
                case 'QSP.Session'
                    app.ActivePane = QSPViewerNew.Application.SessionPane(classInputs);
                    app.ActivePane.attachNewSession(NodeData);
                case 'QSP.OptimizationData'
                    app.ActivePane = QSPViewerNew.Application.OptimizationDataPane(classInputs);
                    app.ActivePane.attachNewOptimizationData(NodeData);
                case 'QSP.Parameters'
                    app.ActivePane = QSPViewerNew.Application.ParametersPane(classInputs);
                    app.ActivePane.attachNewParameters(NodeData);
                case 'QSP.Task'
                    app.ActivePane = QSPViewerNew.Application.TaskPane(classInputs);
                    app.ActivePane.attachNewTask(NodeData);
                case 'QSP.VirtualPopulation'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationPane(classInputs);
                    app.ActivePane.attachNewVirtualPopulation(NodeData);
                case 'QSP.VirtualPopulationData'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationDataPane(classInputs);
                    app.ActivePane.attachNewVirtPopData(NodeData);
                case 'QSP.Simulation'
	                app.ActivePane = QSPViewerNew.Application.SimulationPane(classInputs);	
                    app.ActivePane.attachNewSimulation(NodeData);
                case 'QSP.Optimization'
                    %app.ActivePane = QSPViewerNew.Application.OptimizationPane(app.GridLayout);
                    disp("TODO: Create a QSPViewerNew.Application.OptimizationPane class to launch");
                case 'QSP.CohortGeneration'
                    %app.ActivePane = QSPViewerNew.Application.CohortGenerationPane(app.GridLayout);
                    disp("TODO: Create a QSPViewerNew.Application.CohortGenerationPane class to launch");
                case 'QSP.VirtualPopulationGeneration'
                    %app.ActivePane = QSPViewerNew.Application.VirtualPopulationGenerationPane(app.GridLayout);
                    disp("TODO: Create a QSPViewerNew.Application.VirtualPopulationGenerationPane class to launch");
                case 'QSP.VirtualPopulationGenerationData'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationGenerationDataPane(classInputs);
                    app.ActivePane.attachNewVirtPopGenData(NodeData);
            end
            if ~isempty(app.ActivePane)
                %Now take the pane and display it.
                app.Panes = horzcat(app.ActivePane);
                app.ActivePane.showThisPane();
            end
        end
        
        function launchOldPane(app,NodeData)
            %Find the index of the correct pane type
            PaneType = app.GetPaneClassFromQSPClass(class(NodeData));
            idxPane = find(strcmp(PaneType,app.PaneTypes),1);
            
            if app.ActivePane~=app.Panes(idxPane)
                %The pane shown is not correct, we need to change it.
                app.ActivePane.hideThisPane();
                app.ActivePane = app.Panes(idxPane);
            elseif isempty(app.ActivePane)
                %There is no pane shown
                app.ActivePane = app.Panes(idxPane);
            end
            
            switch PaneType
                case 'QSPViewerNew.Application.SessionPane'
                    app.ActivePane.attachNewSession(NodeData);
                case 'QSPViewerNew.Application.TaskPane'
                    app.ActivePane.attachNewTask(NodeData);
                case 'QSPViewerNew.Application.ParametersPane'
                    app.ActivePane.attachNewParameters(NodeData);
                case 'QSPViewerNew.Application.OptimizationDataPane'
                    app.ActivePane.attachNewOptimizationData(NodeData);
                case 'QSPViewerNew.Application.VirualPopulationDataPane'
                    app.ActivePane.attachNewVirtPop(NodeData);
                case 'QSPViewerNew.Application.VirualPopulationPane'
                    app.ActivePane.attachNewVirtPopData(NodeData);
                case 'QSPViewerNew.Application.VirualPopulationGenerationDataPane'
                    app.ActivePane.attachNewVirtPopGenData(NodeData);
                case 'QSPViewerNew.Application.SimulationPane'
                    app.ActivePane.attachNewSimulation(NodeData);
            end
            
            app.ActivePane.showThisPane();
        end
        
        function updateTreeData(app,Tree,NewData,type)
            %1. Update the Node information
            Tree.NodeData = NewData;
            
            %2. Determine what type of Node this is.
            % We have to pass the type of the children because the node userdata types are
            % often the same between different types of nodes
            switch type
                case 'Session'
                    %If a session, we must check settings,functionalties,
                    %and deleted item
                    app.updateTreeData(Tree.Children(1),NewData.Settings,'BuildingBlocks')
                    app.updateTreeData(Tree.Children(2),NewData,'Functionalities')
                    app.updateTreeData(Tree.Children(3),NewData.Deleted,'Deleted')
                    
                    %If we are updating the session, we need to update the
                    %name
                    app.setCurrentSessionDirty()
                    
                case 'Building Blocks'
                    %Iterate through the 5 Subcategories
                    app.updateTreeData(Tree.Children(1),NewData,'TaskGroup')
                    app.updateTreeData(Tree.Children(2),NewData,'ParameterGroup')
                    app.updateTreeData(Tree.Children(3),NewData,'OptimizationDataGroup')
                    app.updateTreeData(Tree.Children(4),NewData,'VirtualPopulationDataGroup')
                    app.updateTreeData(Tree.Children(5),NewData,'VirtualPopulationGenerationDataGroup')
                    
                case 'TaskGroup'
                    for idx = 1:numel(NewData.Task)
                        app.updateTreeData(Tree.Children(idx),NewData.Task(idx),'Task')
                    end
                case 'ParameterGroup'
                    for idx = 1:numel(NewData.Parameters)
                        app.updateTreeData(Tree.Children(idx),NewData.Parameters(idx),'Parameters')
                    end
                case 'OptimizationDataGroup'
                    for idx = 1:numel(NewData.OptimizationData)
                        app.updateTreeData(Tree.Children(idx),NewData.OptimizationData(idx),'OptimizationData')
                    end
                case 'VirtualPopulationDataGroup'
                     for idx = 1:numel(NewData.VirtualPopulationData)
                        app.updateTreeData(Tree.Children(idx),NewData.VirtualPopulationData(idx),'VirtualPopulationData')
                    end
                case 'VirtualPopulationGenerationDataGroup'
                     for idx = 1:numel(NewData.VirtualPopulationGenerationData)
                        app.updateTreeData(Tree.Children(idx),NewData.VirtualPopulationGenerationData(idx),'VirtualPopulationGenerationData')
                     end      
                case 'Simulation'
                    Tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'Optimization'
                    Tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'CohortGeneration'
                    Tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'VirtualPopulationGeneration'
                    Tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
            end 
        end
        
        function updateTreeNames(app)
            % Update the title of each session to reflect if its dirty
            for idx=1:app.NumSessions

                % Get the session name for this node
                ThisRawName = app.SessionNames{idx};
                ThisName = ThisRawName;

                % Add dirty flag if needed
                if app.IsDirty(idx)
                    ThisName = strcat(ThisName, ' *');
                end

                %Update the Node
                app.SessionNode(idx).Text = ThisName;

                %Assign the new name
                setSessionName(app.Sessions(idx),ThisRawName);
            end
            
            %Update the selected node's name in the tree based on the
            %name,unless it is a session
            SelNode = app.TreeRoot.SelectedNodes;
            checkScalerTF = isscalar(SelNode) && isscalar(SelNode.NodeData);
            checkTypeTF =~isempty(SelNode) && isprop(SelNode.NodeData,'Name') && ~strcmp(SelNode.NodeData.Name, SelNode.Text) && ...
            ~strcmpi(class(SelNode.NodeData),'QSP.Session'); %We dont want to update the name for a session
            if checkScalerTF && checkTypeTF
                SelNode.Text = SelNode.NodeData.Name;
            end
        end
       
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    %Static Methods 
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
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
       
       function PaneClass = GetPaneClassFromQSPClass(QSPClass)
            %This method takes a QSP class and returns what type of pane it
            %launches
            switch QSPClass
                case 'QSP.Session'
                    PaneClass = 'QSPViewerNew.Application.SessionPane';
                case 'QSP.OptimizationData'
                   PaneClass = 'QSPViewerNew.Application.OptimizationDataPane';
                case 'QSP.Parameters'
                   PaneClass = 'QSPViewerNew.Application.ParametersPane';
                case 'QSP.Task'
                   PaneClass = 'QSPViewerNew.Application.TaskPane';
                case 'QSP.VirtualPopulation'
                    PaneClass = 'QSPViewerNew.Application.VirtualPopulationPane';
                case 'QSP.VirtualPopulationData'
                    PaneClass = 'QSPViewerNew.Application.VirtualPopulationDataPane';
                case 'QSP.Simulation'
                    PaneClass = 'QSPViewerNew.Application.SimulationPane';
                case 'QSP.Optimization'
                    PaneClass = 'QSPViewerNew.Application.OptimizationPane';
                case 'QSP.CohortGeneration'
                    PaneClass = 'QSPViewerNew.Application.CohortGenerationPane';
                case 'QSP.VirtualPopulationGeneration'
                    PaneClass = 'QSPViewerNew.Application.VirtualPopulationGenerationPane';
                case 'QSP.VirtualPopulationGenerationData'
                    PaneClass = 'QSPViewerNew.Application.VirtualPopulationGenerationDataPane';
            end
        end
        
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    %Get/Set Methods 
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
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
        end
        
        function set.SessionPaths(app,value)
            if isempty(value)
                app.SessionPaths = cell.empty(0,1);
            else
                app.SessionPaths = value;
            end
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
        
        function value = get.PaneTypes(app)
            value = cell(size(app.Panes));
            for idx = 1:numel(app.Panes)
                value{idx} = class(app.Panes);
            end
        end
        
        function setCurrentSessionDirty(app)
            app.IsDirty(app.SelectedSessionIdx) = true;
        end
        
        function setCurrentSessionClean(app)
            app.IsDirty(app.SelectedSessionIdx) = true;
        end
        
        function value = getUIFigure(app)
            value = app.UIFigure;
        end
        
    end
    
end
