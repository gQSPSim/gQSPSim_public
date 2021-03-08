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
                'Global Sensitivity Analysis',      'GlobalSensitivityAnalysis'
                };
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
        WindowButtonDownCallbacks = {};
        WindowButtonUpCallbacks = {};
        LoggerDialog QSPViewerNew.Dialogs.LoggerDialog
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
        GlobalSensitivityAnalysisMenu    matlab.ui.container.Menu
        DeleteSelectedItemMenu   matlab.ui.container.Menu
        RestoreSelectedItemMenu  matlab.ui.container.Menu
        ToolsMenu                matlab.ui.container.Menu
        LoggerMenu               matlab.ui.container.Menu
        HelpMenu                 matlab.ui.container.Menu
        AboutMenu                matlab.ui.container.Menu
        FlexGridLayout           QSPViewerNew.Widgets.GridFlex
        SessionExplorerPanel     matlab.ui.container.Panel
        SessionExplorerGrid      matlab.ui.container.GridLayout
        TreeRoot                 matlab.ui.container.Tree
        TreeMenu                 
        OpenRecentMenuArray      
    end
    
     properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % listener handle for Sessions property
        SessionsListener
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
            setpref(app.TypeStr,'Position',app.UIFigure.Position)
            
             % close logger dialog if open
            if isvalid(app.LoggerDialog)
                delete(app.LoggerDialog)
            end
            
            %Delete UI
            delete(app.UIFigure)
        end
        
    end
    
    methods (Access = private)
        
        function create(app)
            %for reference in callbacks
            %Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1005 864];
            app.UIFigure.Name = 'UI Figure';
            app.UIFigure.WindowButtonUpFcn = @(h,e) app.executeCallbackArray(app.WindowButtonUpCallbacks,h,e);
            app.UIFigure.WindowButtonDownFcn = @(h,e) app.executeCallbackArray(app.WindowButtonDownCallbacks,h,e);
            app.UIFigure.CloseRequestFcn = @app.onExit;
            
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
            app.CloseMenu.MenuSelectedFcn = @(h,e) app.onClose([]);
            
            % Create SaveCtrlSMenu
            app.SaveCtrlSMenu = uimenu(app.FileMenu);
            app.SaveCtrlSMenu.Separator = 'on';
            app.SaveCtrlSMenu.Text = 'Save';
            app.SaveCtrlSMenu.MenuSelectedFcn = @(h,e) app.onSave([]);
            app.SaveCtrlSMenu.Accelerator = 'S';
            
            % Create SaveAsMenu
            app.SaveAsMenu = uimenu(app.FileMenu);
            app.SaveAsMenu.Text = 'Save As...';
            app.SaveAsMenu.MenuSelectedFcn = @(h,e) app.onSaveAs([]);
            
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
            app.DatasetMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'OptimizationData');
            
            % Create ParameterMenu
            app.ParameterMenu = uimenu(app.AddNewItemMenu);
            app.ParameterMenu.Text = 'Parameter';
            app.ParameterMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'Parameters');
            
            % Create TaskMenu
            app.TaskMenu = uimenu(app.AddNewItemMenu);
            app.TaskMenu.Text = 'Task';
            app.TaskMenu.MenuSelectedFcn =@(h,e) app.onAddItem([],'Task');
            
            % Create VirtualSubjectsMenu
            app.VirtualSubjectsMenu = uimenu(app.AddNewItemMenu);
            app.VirtualSubjectsMenu.Text = 'Virtual Subject(s)';
            app.VirtualSubjectsMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'VirtualPopulation');
            
            % Create AcceptanceCriteriaMenu
            app.AcceptanceCriteriaMenu = uimenu(app.AddNewItemMenu);
            app.AcceptanceCriteriaMenu.Text = 'Acceptance Criteria';
            app.AcceptanceCriteriaMenu.MenuSelectedFcn =@(h,e) app.onAddItem([],'VirtualPopulationData');
            
            % Create TargetStatisticsMenu
            app.TargetStatisticsMenu = uimenu(app.AddNewItemMenu);
            app.TargetStatisticsMenu.Text = 'Target Statistics ';
            app.TargetStatisticsMenu.MenuSelectedFcn =@(h,e) app.onAddItem([],'VirtualPopulationGenerationData');
            
            % Create SimulationMenu
            app.SimulationMenu = uimenu(app.AddNewItemMenu);
            app.SimulationMenu.Text = 'Simulation';
            app.SimulationMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'Simulation');

            % Create OptimizationMenu
            app.OptimizationMenu = uimenu(app.AddNewItemMenu);
            app.OptimizationMenu.Text = 'Optimization';
            app.OptimizationMenu.MenuSelectedFcn =@(h,e) app.onAddItem([],'Optimization');
            
            % Create CohortGenerationMenu
            app.CohortGenerationMenu = uimenu(app.AddNewItemMenu);
            app.CohortGenerationMenu.Text = 'Cohort Generation';
            app.CohortGenerationMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'CohortGeneration');
            
            % Create VirtualPopulationGenerationMenu
            app.VirtualPopulationGenerationMenu = uimenu(app.AddNewItemMenu);
            app.VirtualPopulationGenerationMenu.Text = 'Virtual Population Generation';
            app.VirtualPopulationGenerationMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'VirtualPopulationGeneration');
            
            % Create GlobalSensitivityAnalysisMenu
            app.GlobalSensitivityAnalysisMenu = uimenu(app.AddNewItemMenu);
            app.GlobalSensitivityAnalysisMenu.Text = 'Global Sensitivity Analysis';
            app.GlobalSensitivityAnalysisMenu.MenuSelectedFcn = @(h,e) app.onAddItem([],'GlobalSensitivityAnalysis');
            
            % Create DeleteSelectedItemMenu
            app.DeleteSelectedItemMenu = uimenu(app.QSPMenu);
            app.DeleteSelectedItemMenu.Text = 'Delete Selected Item';
            app.DeleteSelectedItemMenu.MenuSelectedFcn =@(h,e) app.onDeleteSelectedItem([],[]);
            
            % Create RestoreSelectedItemMenu
            app.RestoreSelectedItemMenu = uimenu(app.QSPMenu);
            app.RestoreSelectedItemMenu.Text = 'Restore Selected Item';
            app.RestoreSelectedItemMenu.MenuSelectedFcn =@(h,e) app.onRestoreSelectedItem([],[]);
            
            % Create Tools menu
            app.ToolsMenu = uimenu(app.UIFigure);
            app.ToolsMenu.Text = 'Tools';
            
            % Create logger menu
            app.LoggerMenu = uimenu(app.ToolsMenu);
            app.LoggerMenu.Text = 'Logger';
            app.LoggerMenu.MenuSelectedFcn = @(h, e) app.onOpenLogger;
            
            % Create HelpMenu
            app.HelpMenu = uimenu(app.UIFigure);
            app.HelpMenu.Text = 'Help';
            
            % Create AboutMenu
            app.AboutMenu = uimenu(app.HelpMenu);
            app.AboutMenu.Text = 'About';
            app.AboutMenu.MenuSelectedFcn = @app.onAbout;
            
            % Create GridLayout
            app.FlexGridLayout = QSPViewerNew.Widgets.GridFlex(app.UIFigure);
            app.FlexGridLayout.getGridHandle();
            app.addWindowDownCallback(app.FlexGridLayout.getButtonDownCallback());
            app.addWindowUpCallback(app.FlexGridLayout.getButtonUpCallback());
            
            % Create SessionExplorerPanel
            app.SessionExplorerPanel = uipanel(app.FlexGridLayout.getGridHandle());
            app.SessionExplorerPanel.Title = 'Session Explorer';
            app.SessionExplorerPanel.Layout.Row = 1;
            app.SessionExplorerPanel.Layout.Column = 1;
            
            %Create TreeGrid
            app.SessionExplorerGrid = uigridlayout(app.SessionExplorerPanel);
            app.SessionExplorerGrid.ColumnWidth = {'1x'};
            app.SessionExplorerGrid.RowHeight = {'1x'};
            
            % Create Tree
            app.TreeRoot = uitree(app.SessionExplorerGrid);
            app.TreeRoot.Multiselect = 'on';
            app.TreeRoot.SelectionChangedFcn = @app.onTreeSelectionChanged;
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
        
        function createTree(app, parent, allData)
            % Nodes that take children have the type of child as a string in the UserData
            % property. Nodes that are children and are movable have [] in UserData.
            % Get short name to call this function recursively
            thisFcn = @(Parent,Data) createTree(app, Parent, Data);
            
            % Loop on objects
            for idx = 1:numel(allData)
                
                % Get current object
                Data = allData(idx);
                
                % What type of object is this?
                TypeTemp = class(Data);
                
                % Switch on object type for the icon
                switch TypeTemp
                    
                    case 'QSP.Session'
                        
                        % Session node
                        hSession = app.createNode(parent, Data, ...
                            'Session', QSPViewerNew.Resources.LoadResourcePath('folder_24.png'),...
                            'Session', [], 'Session');
                        Data.TreeNode = hSession; %Store node in the object for cross-ref
                        hSession.Tag = 'Session';
                        
                        % Settings node and children
                        hSettings = app.createNode(hSession, Data.Settings, ...
                            'Building blocks', QSPViewerNew.Resources.LoadResourcePath('settings_24.png'),...
                            [], 'Settings', 'Building blocks for the session');
                        Data.Settings.TreeNode = hSettings; %Store node in the object for cross-ref
                        hSettings.Tag = 'Building blocks';
                        
                        hTasks = app.createNode(hSettings, Data.Settings, ...
                            'Tasks', QSPViewerNew.Resources.LoadResourcePath('flask2.png'),...
                            'Task', 'Task', 'Tasks');
                        thisFcn(hTasks, Data.Settings.Task);
                        hTasks.Tag = 'Task';
                        
                        hParameters = app.createNode(hSettings, Data.Settings, ...
                            'Parameters', QSPViewerNew.Resources.LoadResourcePath('param_edit_24.png'),...
                            'Parameter', 'Parameters', 'Parameters');
                        thisFcn(hParameters, Data.Settings.Parameters);
                        hParameters.Tag = 'Parameters';
                        
                        hOptimData = app.createNode(hSettings, Data.Settings, ...
                            'Datasets', QSPViewerNew.Resources.LoadResourcePath('datatable_24.png'),...
                            'Dataset', 'OptimizationData', 'Datasets');
                        thisFcn(hOptimData, Data.Settings.OptimizationData);
                        hOptimData.Tag = 'OptimizationData';
                        
                        
                        hVPopDatas = app.createNode(hSettings, Data.Settings, ...
                            'Acceptance Criteria', QSPViewerNew.Resources.LoadResourcePath('acceptance_criteria.png'),...
                            'Acceptance Criteria', 'VirtualPopulationData', 'Acceptance Criteria');
                        thisFcn(hVPopDatas, Data.Settings.VirtualPopulationData);
                        hVPopDatas.Tag = 'VirtualPopulationData';
                        
                        hVPopGenDatas = app.createNode(hSettings, Data.Settings, ...
                            'Target Statistics', QSPViewerNew.Resources.LoadResourcePath('target_stats.png'),...
                            'Target Statistics', 'VirtualPopulationGenerationData', 'Target Statistics');
                        thisFcn(hVPopGenDatas, Data.Settings.VirtualPopulationGenerationData);
                        hVPopGenDatas.Tag = 'VirtualPopulationGenerationData';
                        
                        
                        hVPops = app.createNode(hSettings, Data.Settings, ...
                            'Virtual Subject(s)', QSPViewerNew.Resources.LoadResourcePath('stickman3.png'),...
                            'Virtual Subject(s)', 'VirtualPopulation', 'Virtual Subject(s)');
                        thisFcn(hVPops, Data.Settings.VirtualPopulation);
                        hVPops.Tag = 'VirtualPopulation';
                        
                        % Functionalities node and children
                        hFunctionalities = app.createNode(hSession, Data, ...
                            'Functionalities', QSPViewerNew.Resources.LoadResourcePath('settings_24.png'),...
                            [], 'Functionalities', 'Functionalities for the session');
                        hFunctionalities.Tag = 'Functionalities';
                        
                        hSimulations = app.createNode(hFunctionalities, Data, ...
                            'Simulations', QSPViewerNew.Resources.LoadResourcePath('simbio_24.png'),...
                            'Simulation', 'Simulation', 'Simulation');
                        thisFcn(hSimulations, Data.Simulation);
                        hSimulations.Tag = 'Simulation';
                        
                        hOptims = app.createNode(hFunctionalities, Data, ...
                            'Optimizations', QSPViewerNew.Resources.LoadResourcePath('optim_24.png'),...
                            'Optimization', 'Optimization', 'Optimization');
                        thisFcn(hOptims, Data.Optimization);
                        hOptims.Tag = 'Optimization';
                        
                        hCohortGen = app.createNode(hFunctionalities, Data, ...
                            'Virtual Cohort Generations', QSPViewerNew.Resources.LoadResourcePath('stickman-3.png'),...
                            'Cohort Generation', 'CohortGeneration', 'Cohort Generation');
                        thisFcn(hCohortGen, Data.CohortGeneration);
                        hCohortGen.Tag = 'CohortGeneration';
                        
                        hVPopGens = app.createNode(hFunctionalities, Data, ...
                            'Virtual Population Generations', QSPViewerNew.Resources.LoadResourcePath('stickman-3-color.png'),...
                            'Virtual Population Generation', 'VirtualPopulationGeneration', 'Virtual Population Generation');
                        thisFcn(hVPopGens, Data.VirtualPopulationGeneration);
                        hVPopGens.Tag = 'VirtualPopulationGeneration';
                        
                        hGSA = app.createNode(hFunctionalities, Data, ...
                            'Global Sensitivity Analyses', QSPViewerNew.Resources.LoadResourcePath('sensitivity.png'),...
                            'Global Sensitivity Analysis', 'GlobalSensitivityAnalysis', 'Global Sensitivity Analysis');
                        thisFcn(hGSA, Data.GlobalSensitivityAnalysis);
                        hGSA.Tag = 'GlobalSensitivityAnalysis';                                                
                        
                        hDeleteds = app.createNode(hSession, Data, ...
                            'Deleted Items', QSPViewerNew.Resources.LoadResourcePath('trash_24.png'),...
                            'Deleted Items', 'Deleted', 'Deleted Items');
                        thisFcn(hDeleteds, Data.Deleted);
                        hDeleteds.Tag = 'Deleted Items';
                        
                        % Expand Nodes
                        hSession.expand();
                        hSettings.expand();
                        
                    case 'QSP.OptimizationData'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('datatable_24.png'),...
                            'Dataset', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.Parameters'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('param_edit_24.png'),...
                            'Parameter', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.Task'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('flask2.png'),...
                            'Task', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.VirtualPopulation'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('stickman3.png'),...
                            'Virtual Subject(s)', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                        
                    case 'QSP.VirtualPopulationData'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('acceptance_criteria.png'),...
                            'Acceptance Criteria', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.Simulation'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('simbio_24.png'),...
                            'Simulation', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.Optimization'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('optim_24.png'),...
                            'Optimization', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.CohortGeneration'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('stickman-3.png'),...
                            'Cohort Generation', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.VirtualPopulationGeneration'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('stickman-3-color.png'),...
                            'Virtual Population Generation', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.VirtualPopulationGenerationData'

                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('target_stats.png'),...
                            'Target Statistics', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref
                        
                    case 'QSP.GlobalSensitivityAnalysis'
                        
                        hNode = app.createNode(parent, Data, Data.Name, QSPViewerNew.Resources.LoadResourcePath('sensitivity.png'),...
                            'Global Sensitivity Analysis', [], '');
                        Data.TreeNode = hNode; %Store node in the object for cross-ref                        

                    otherwise
                        
                        % Skip this node
                        warning('QSPViewer:App:createTree:UnhandledType',...
                            'Unhandled object type for tree: %s. Skipping.', TypeTemp);
                        continue
                        
                end %switch
                
                if isa(parent,'matlab.ui.container.TreeNode') && strcmp(parent.Text,'Deleted Items')
                    app.createContextMenu(hNode,'Deleted')
                end
            end %for
        end %function
        
        function createContextMenu(app,Node,Type)
            %Determine if this ContextMenu is from QSP
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
                'Global Sensitivity Analysis',      'GlobalSensitivityAnalysis'
                };
            Index = find(strcmpi(Type,ItemTypes(:,1)));
            
            %If the Node is from a QSP class
            if ~isempty(Index)
                ThisItemType = ItemTypes{Index,2};
                
                %If it is an instance of a QSP Class
                if ~isempty(Node.UserData)
                    CM = uicontextmenu('Parent',app.UIFigure);
                    uimenu('Parent',CM,'Label', ['Add new ' ThisItemType],...
                        'MenuSelectedFcn', @(h,e)app.onAddItem(h.Parent.UserData.Parent.Parent.NodeData,ThisItemType));
                    
                    %Not an Instance, just a type
                else
                    CM = uicontextmenu('Parent',app.UIFigure);
                    uimenu(...
                        'Parent', CM,...
                        'Text', ['Duplicate this ' ThisItemType],...
                        'MenuSelectedFcn', @(h,e) app.onDuplicateItem(h.Parent.UserData.Parent.Parent.Parent.NodeData,h.Parent.UserData));
                    uimenu(...
                        'Parent', CM,...
                        'Text', ['Delete this ' ThisItemType],...
                        'Separator', 'on',...
                        'MenuSelectedFcn', @(h,e) app.onDeleteSelectedItem(h.Parent.UserData.Parent.Parent.Parent.NodeData,h.Parent.UserData));
                end
            else
                switch Type
                    
                    %For a session Node
                    case 'Session'
                        CM = uicontextmenu('Parent',app.UIFigure);
                        uimenu(...
                            'Parent', CM,...
                            'Text', 'Close',...
                            'MenuSelectedFcn', @(h,e) app.onClose(h.Parent.UserData.NodeData));
                        uimenu(...
                            'Parent', CM,...
                            'Text', 'Save',...
                            'Separator', 'on',...
                            'MenuSelectedFcn', @(h,e) app.onSave(h.Parent.UserData.NodeData));
                        uimenu(...
                            'Parent', CM,...
                            'Text', 'Save As',...
                            'MenuSelectedFcn', @(h,e) app.onSaveAs(h.Parent.UserData.NodeData));
                        
                        %For the trash node
                    case 'Deleted Items'
                        CM = uicontextmenu('Parent', app.UIFigure);
                        uimenu(...
                            'Parent',CM,...
                            'Text', 'Empty Deleted Items',...
                            'MenuSelectedFcn', @(h,e) app.onEmptyDeletedItems([],[],true));
                        
                        %for items under the trash nose
                    case 'Deleted'
                        CM = uicontextmenu('Parent', app.UIFigure);
                        uimenu(...
                            'Parent', CM,...
                            'Text', 'Restore',...
                            'MenuSelectedFcn', @(h,e) app.onRestoreSelectedItem(h.Parent.UserData,h.Parent.UserData.Parent.Parent.NodeData));
                        uimenu(...
                            'Parent', CM,...
                            'Text', 'Permanently Delete',...
                            'Separator', 'on',...
                            'MenuSelectedFcn', @(h,e) app.onEmptyDeletedItems(h.Parent.UserData,h.Parent.UserData.Parent.Parent.NodeData,false));
                end
            end
            
            %Attach menu to widgets and attach widget to context menu
            Node.ContextMenu = CM;
            CM.UserData = Node;
        end
        
        function hNode = createNode(app,Parent, Data, Name, Icon, CMenu, PaneType, ~)
           % Create the node
           hNode = uitreenode(...
               'Parent', Parent,...
               'NodeData', Data,...
               'Text', Name,...
               'UserData',PaneType,...
               'Icon',Icon);
           if ~isempty(CMenu)
               app.createContextMenu(hNode,CMenu);
           end
       end 
        
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    %Callbacks for menu items and context menus
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    methods (Access = private)
        
        function onNew(app,~,~)
            %We are using multiple sessions so 
            if app.AllowMultipleSessions || app.promptToSave(1)
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
        
        function onClose(app,activeSession)
            if ~isempty(activeSession)
                
                %Need to find the session index
                SessionIdx = find(strcmp(activeSession.SessionName,{app.Sessions.SessionName}));
            else
                SessionIdx = app.SelectedSessionIdx;
            end
            
            if app.IsDirty(SessionIdx)
                app.savePromptBeforeClose(SessionIdx);
            else
                app.closeSession(SessionIdx);
            end
        end
        
        function onSave(app,activeSession)
            if ~isempty(activeSession)
                
                %Need to find the session index
                Idx = find(strcmp(activeSession.SessionName,{app.Sessions.SessionName}));
            else
                Idx = app.SelectedSessionIdx;
            end
            
            StatusTF = app.saveSession(Idx,false);
            if StatusTF
                app.markClean(activeSession);
            end
        end
        
        function onSaveAs(app,activeSession)
            if ~isempty(activeSession)
                
                %Need to find the session index
                Idx = find(strcmp(activeSession.Name,{app.Sessions.Name}));
            else
                Idx = app.SelectedSessionIdx;
            end
            StatusTF = app.saveSession(Idx,true);
            if StatusTF
                app.markClean(activeSession);
            end
        end
        
        function onDeleteSelectedItem(app,activeSession,activeNode)
            if isempty(activeSession)
                activeSession = app.SelectedSession;
            end
            
            if isempty(activeNode)
                activeNode = app.TreeRoot.SelectedNodes;
            end
            
            app.deleteNode(activeNode,activeSession)
            app.markDirty(activeSession);
        end
        
        function onRestoreSelectedItem(app,activeNode,activeSession)
            if isempty(activeSession)
                activeSession = app.SelectedSession;
            end
            
            if isempty(activeNode)
                activeNode = app.TreeRoot.SelectedNodes;
            end
            
            app.restoreNode(activeNode,activeSession)
            app.markDirty(activeSession);
        end
        
        function onExit(app,~,~)
            CancelTF = false;
            while ~CancelTF && (~isempty(app.Sessions))
                if app.IsDirty(1)
                    CancelTF = app.savePromptBeforeClose(1);
                else
                    app.closeSession(1)
                end
            end
            
            if ~CancelTF
                app.delete();
            end
                
        end
        
        function onAbout(app,~,~)
           Message = {'gQSPsim version 1.0', ...
               '', ...
               'http://www.github.com/feigelman/gQSPsim', ...
               '', ...
               'Authors:', ...
               '', ...
               'Justin Feigelman (feigelman.justin@gene.com)', ...
               'Iraj Hosseini (hosseini.iraj@gene.com)', ...
               'Anita Gajjala (agajjala@mathworks.com)'};
           uialert(app.UIFigure,Message,'About','Icon','');
        end
        
        function onTreeSelectionChanged(app,handle,event)
            app.UIFigure.Pointer = 'watch';
            drawnow limitrate;
            
            %First we determine the session that is selected
            %We can select mutliple nodes at once. Therefore we need to consider if SelectedNodes is a vector
            SelectedNodes = event.SelectedNodes;
            Root = handle;

            %We only make changes if a single node is selected
            if length(SelectedNodes)==1
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
                 
                 %Now that we have the correct session, we can work
                 app.refresh();
                 app.UIFigure.Pointer = 'arrow';
            end
        end    
         
        function onAddItem(app,thisSession,itemType)
            if isempty(thisSession)
                thisSession = app.SelectedSession;
            end
            
            %itemType can be a QSP item or just the type as a char
            % This enables adding a blank or complete item to the tree
            if ischar(itemType)
                ThisObj = QSP.(itemType)();
            elseif isobject(itemType)
                ThisObj = itemType;
                itemType = strrep(class(ThisObj),'QSP.','');
            else
               error('Invalid ItemType'); 
            end
            
            % special case since vpop data has been renamed to acceptance
            % criteria
            if strcmp(itemType, 'VirtualPopulationData')
                ItemName = 'Acceptance Criteria';
            elseif strcmp(itemType, 'VirtualPopulationGenerationData')
                ItemName = 'Target Statistics';
            elseif strcmp(itemType, 'VirtualPopulation')
                ItemName = 'Virtual Subjects';
            elseif strcmp(itemType, 'OptimizationData')
                ItemName = 'Dataset';
            else
                ItemName = itemType;
            end
                     
            % Where does the item go?
            if isprop(thisSession,itemType)
                ParentObj = thisSession;
            else
                ParentObj = thisSession.Settings;
            end
            
            % What tree branch does this go under?
            ChildNodes = ParentObj.TreeNode.Children;
            ChildTypes = {ChildNodes.UserData};
            if any(strcmpi(itemType,{'Simulation','Optimization','CohortGeneration',...
                    'VirtualPopulationGeneration','GlobalSensitivityAnalysis'}))
                ThisChildNode = ChildNodes(strcmpi(ChildTypes,'Functionalities'));
                ChildNodes = ThisChildNode.Children;
                ChildTypes = {ChildNodes.UserData};
            end
            
            ParentNode = ChildNodes(strcmp(ChildTypes,itemType));
            
            % Create the new item
            NewName = ThisObj.Name;
            if isempty(NewName)
                NewName = ['New ' ItemName];
            end
            
            DisallowedNames = {ParentObj.(itemType).Name};
            NewName = matlab.lang.makeUniqueStrings(NewName, DisallowedNames);
            ThisObj.Name = NewName;
            
            %Determine the session associated
            if isprop(ThisObj,'Settings')
                ThisObj.Settings = thisSession.Settings;
            end
            if isprop(ThisObj,'Session')
                ThisObj.Session = thisSession;
            end
            
            % Place the item and add the tree node
            if isscalar(ParentNode)
                ParentObj.(itemType)(end+1) = ThisObj;
                app.createTree(ParentNode, ThisObj);
                ParentNode.expand();
            else
                error('Invalid tree parent');
            end
            
            % Mark the current session dirty
            app.markDirty(thisSession);
            
            % Update the display
            app.updateTreeNames();
            
            %Update the file menu
            app.updateFileMenu();
            
            %Update the title of the application
            app.updateAppTitle();
            
            % log to logger
            loggerObj = QSPViewerNew.Widgets.Logger(thisSession.LoggerName);
            loggerObj.write(ParentNode.Text, itemType, "MESSAGE", 'added item')
        end
        
        function onDuplicateItem(app,activeSession,activeNode)
            if isempty(activeSession)
                activeSession = app.SelectedSession;
            end
            
            if isempty(activeNode)
                activeNode = app.TreeRoot.SelectedNodes;
            end
            
            app.duplicateNode(activeNode,activeSession)
            app.markDirty(activeSession);
        end
       
        function onEmptyDeletedItems(app,activeNode,activeSession,deleteAllTF)
            if deleteAllTF
                TreeRoots = app.SelectedSession.TreeNode.Children;
                ChildTags = {TreeRoots.Tag};
                Deleted = TreeRoots(strcmpi(ChildTags,'Deleted Items'));
                app.permDelete(Deleted.Children,app.SelectedSession)
            else
                if isempty(activeSession)
                    activeSession = app.SelectedSession;
                end
                
                if isempty(activeNode)
                    activeNode = app.TreeRoot.SelectedNodes;
                end
                app.permDelete(activeNode,activeSession)
            end
            app.markDirty(activeSession);
        end
        
        function onOpenLogger(app)
            try
                app.LoggerDialog = QSPViewerNew.Dialogs.LoggerDialog;
                app.LoggerDialog.Sessions = app.Sessions;
            catch ME
                uialert(app.UIFigure, ME.message, 'Error opening logger dialog');
            end
        end
        
        function updateLoggerSessions(app,~,~)
            if isvalid(app.LoggerDialog)
                app.LoggerDialog.Sessions = app.Sessions;
            end
        end
       
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    % Methods for interacting with the active sessions
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %%
    methods (Access = private)
        
        function StatusTF = saveSession(app,sessionIdx,saveAsTF)
            %Retrieve session info
            Session = app.Sessions(sessionIdx);
            IsSessionDirty = app.IsDirty(sessionIdx);
            OldSessionPath = app.SessionPaths{sessionIdx};
            StatusTF = false;
            
            %Get a valid file location to start in
            ThisFile = OldSessionPath;
            IsNewFile = ~exist(ThisFile,'file');
            
            %ValidName. File must be of type QSP.mat
            ValidFileType = length(ThisFile)>8 && strcmpi(ThisFile(end-6:end),'qsp.mat');
            
            if isempty(fileparts(ThisFile))
                ThisFile = fullfile(app.LastFolder,ThisFile);
            end
            
            % Do we need to prompt for a filename?
            PutFileSuccess = true;
            if saveAsTF || IsNewFile || ~ValidFileType
                
                % Need special handling for non-PC
                [PathName,FileName] = fileparts(ThisFile);
                FileName = regexp(FileName,'\.','split');
                if iscell(FileName)
                    FileName = FileName{1};
                end
                ThisFile = fullfile(PathName,FileName);
                
                %Get file location using UI
                [FileName,PathName,FilterIndex] = uiputfile(app.FileSpec, ...
                    'Save as',ThisFile);
                
                %If uiputfile was a success
                if ~isequal(FileName,0)
                    
                    %get file extension
                    if iscell(app.FileSpec)
                        FileExt = app.FileSpec{FilterIndex,1};
                    else
                        FileExt = app.FileSpec;
                    end
                    
                    % If it's missing the full FileExt (i.e. on Mac/Linux)
                    if isempty(regexp(FileName,FileExt,'once'))
                        FileName = regexp(FileName,'\.','split');
                        if iscell(FileName)
                            FileName = FileName{1};
                        end
                        if ~isempty(FileExt)
                            FileExt = FileExt(2:end);
                        end
                        FileName = [FileName,FileExt];
                    end
                    
                    ThisFile = fullfile(PathName,FileName);
                    app.LastFolder = PathName;
                else
                    PutFileSuccess = false;
                end
            end
            
            % Try save. If it returns ok, then update ui states.
            % Otherwise, return.
            if PutFileSuccess
                app.SessionPaths{sessionIdx} = ThisFile;
                app.IsDirty(sessionIdx) = false;
                if  app.saveSessionToFile(Session,ThisFile)
                    app.addRecentSessionPath(ThisFile);
                    app.refresh();
                    StatusTF = true;
                else
                    app.IsDirty(sessionIdx) = IsSessionDirty;
                    app.SessionPaths{sessionIdx} = CurrentSessionPath;
                end
            end
            
        end
        
        function StatusTF = saveSessionToFile(app,session,filePath)
           StatusTF = true;
           try
               s.Session = session; 
               save(filePath,'-struct','s');
           catch err
               StatusTF = false;
               Message = sprintf('The file %s could not be saved:\n%s',filePath, err.message);
               uialert(app.UIFigure,Message,'Save File');
           end
        end
        
        function createUntitledSession(app)
            % Add a new session called 'untitled_x'
            % Clear existing sessions if needed
            if ~app.AllowMultipleSessions
                app.SessionPaths = cell.empty(0,1);
            end
            
            % Call subclass method to create storage for the new session
            app.createNewSession();
            
            % Create the new session and select it
            NewName = matlab.lang.makeUniqueStrings('untitled',app.SessionNames);
            idxNew = app.NumSessions +1;
            app.SessionPaths{idxNew} = NewName;
            app.IsDirty(idxNew) = true;

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
                        loadedSession.Session.RootDirectory = newFilePath;
                        Session = copy(loadedSession.Session);
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
        
        function closeSession(app,sessionIdx)
            % Delete timer
            deleteTimer(app.Sessions(sessionIdx));
            
            % remove the session's UDF from the path
            app.Sessions(sessionIdx).removeUDF();
            
            % Delete the session's tree node
            delete(app.Sessions(sessionIdx).TreeNode);
            
            % Remove the session object
            app.Sessions(sessionIdx) = [];
            
            %Update paths and dirtyTF
            app.SessionPaths(sessionIdx) = [];
            app.IsDirty(sessionIdx) = [];
            
            %Update selected session
            app.SelectedSessionIdx = [];
            
            %update app
            app.refresh();
        end
        
        function CancelTF = savePromptBeforeClose(app,sessionIdx) 
            %Ask user if they would like to save
            Prompt = sprintf('Save changes to %s?', app.SessionNames{sessionIdx});
            Result = uiconfirm(app.UIFigure,Prompt,'Save Changes','Options',{'Yes','No','Cancel'},'DefaultOption','Cancel');
            
            CancelTF = false;
            switch Result
                case 'Yes'
                    SaveOK = app.saveSession(sessionIdx,false);
                    if SaveOK
                        app.closeSession(sessionIdx);
                    else
                        CancelTF = true;
                    end
                case 'No'
                    app.closeSession(sessionIdx);
                case 'Cancel'
                    CancelTF = true;
            end
                    
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
        
        function changeInBackEnd(app,newObject)
            %This function is for other classes to provide a new session to
            %be added to session and corresponding tree
            switch class(newObject)
                
                %We have a new backend object to attach to the tree.
                case 'QSP.Session'
                    %1.Replace the current Session with the newSession
                    app.Sessions(app.SelectedSessionIdx) = newObject;
                    
                    %2. It must update the tree to reflect all the new values from
                    %the session
                    app.updateTreeData(app.TreeRoot.Children(app.SelectedSessionIdx),newObject,'Session')
                    
                    app.refresh();
                case 'QSP.VirtualPopulation'
                    NewVirtualPopulation = newObject;
                    for idx = 1:numel(NewVirtualPopulation)
                        app.onAddItem(NewVirtualPopulation(idx).Session,NewVirtualPopulation(idx))
                    end
                case 'QSP.Parameters'
                    NewParameters = newObject;
                    for idx = 1:numel(NewParameters)
                        app.onAddItem(NewParameters(idx).Session,NewParameters(idx))
                    end
                otherwise
                    error('QSP object is not supported for adding to tree')
            end
        end
        
        %The following 4 functions are required because uiaxes in R2020a do
        %not support buttonDown and buttonUp callbacks. Use these functions
        %to add your callback to the list of callbacks executed on
        %buttondown and buttonup.
        function addWindowDownCallback(app,functionHandle)
            app.WindowButtonDownCallbacks{end+1} = functionHandle;
        end
        
        function removeWindowDownCallback(app,functionHandle)
            %Need to use loop because == does not support function handles, need
            %to use isequal
            for i = 1:length(app.WindowButtonDownCallbacks)
                if isequal(app.WindowButtonDownCallbacks{i},functionHandle)
                    app.WindowButtonDownCallbacks(i) = [];
                    break
                end
            end
        end
        
        function addWindowUpCallback(app,functionHandle)
            app.WindowButtonUpCallbacks{end+1} = functionHandle;
        end
        
        function removeWindowUpCallback(app,functionHandle)
            %Need to use loop because == does not support function handles, need
            %to use isequal
            for i = 1:length(app.WindowButtonUpCallbacks)
                if isequal(app.WindowButtonUpCallbacks{i},functionHandle)
                    app.WindowButtonUpCallbacks(i) = [];
                    break
                end
            end
        end
        
    end
    
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %
    %methods for toggling interactivity and updating the view
    % %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %% %
    methods (Access = private)
        
        function markDirty(app,session)
            %This function can take an empty Session, a session index, or a
            %session object
            
            if isempty(session)
                app.IsDirty(app.SelectedSessionIdx) = true;
            elseif isnumeric(session)
                app.IsDirty(session) = true;
            else
                app.IsDirty(strcmp(session.SessionName,{app.Sessions.SessionName})) = true;
                %Provided session, need to find index
            end
        end
        
        function markClean(app,session)
            %This function can take an empty Session, a session index, or a
            %session object
            
            if isempty(session)
                app.IsDirty(app.SelectedSessionIdx) = false;
            elseif isnumeric(session)
                app.IsDirty(session) = false;
            else
                app.IsDirty(strcmp(session.SessionName,{app.Sessions.SessionName})) = false;
                %Provided session, need to find index
            end
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
                    
                    %Sessions have blank UserData but cannot be
                    %removed/restored
                elseif strcmp(SelNode.Tag,'Session')
                    IsNodeRestorableTF = false;
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
            
            %Update context menus
            %Iterate through each session
            for SessionIdx = 1:numel(app.Sessions)
                TempSession = app.Sessions(SessionIdx);
                SaveContextMenu = TempSession.TreeNode.ContextMenu.Children(2);
                SaveContextMenu.Enable = app.IsDirty(SessionIdx);
            end
            
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
            NodeSelected = app.TreeRoot.SelectedNodes;
            
            %Determine if the Node will launch a Pane
            LaunchPaneTF = ~isempty(NodeSelected) && isempty(NodeSelected.UserData);

            %If we shouldnt launch a pane and there is currently a pane,
            %close it
            if ~LaunchPaneTF && ~isempty(app.ActivePane)
                app.ActivePane.hideThisPane();
                app.ActivePane = [];
            elseif LaunchPaneTF  
                %Determine if the pane type has already been loaded
                PaneType = app.getPaneClassFromQSPClass(class(NodeSelected.NodeData));
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
        
        function launchNewPane(app,nodeData)
            %Inputs that the pane API should require in the constructor
            classInputs = {app.FlexGridLayout.getGridHandle(),1,3,app};
            
            %Need to hide old pane
            if ~isempty(app.ActivePane)
                app.ActivePane.hideThisPane();
                app.ActivePane = [];
            end
            
            %This switch determines the correct type of Pane and creates it
            %The default is that it is not shown
            %TODO: Address this switch statment to refactor
            switch class(nodeData)
                case 'QSP.Session'
                    app.ActivePane = QSPViewerNew.Application.SessionPane(classInputs);
                    app.ActivePane.attachNewSession(nodeData);
                case 'QSP.OptimizationData'
                    app.ActivePane = QSPViewerNew.Application.OptimizationDataPane(classInputs);
                    app.ActivePane.attachNewOptimizationData(nodeData);
                case 'QSP.Parameters'
                    app.ActivePane = QSPViewerNew.Application.ParametersPane(classInputs);
                    app.ActivePane.attachNewParameters(nodeData);
                case 'QSP.Task'
                    app.ActivePane = QSPViewerNew.Application.TaskPane(classInputs);
                    app.ActivePane.attachNewTask(nodeData);
                case 'QSP.VirtualPopulation'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationPane(classInputs);
                    app.ActivePane.attachNewVirtualPopulation(nodeData);
                case 'QSP.VirtualPopulationData'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationDataPane(classInputs);
                    app.ActivePane.attachNewVirtPopData(nodeData);
                case 'QSP.Simulation'
	                app.ActivePane = QSPViewerNew.Application.SimulationPane(classInputs);	
                    app.ActivePane.attachNewSimulation(nodeData);
                case 'QSP.Optimization'
                    app.ActivePane = QSPViewerNew.Application.OptimizationPane(classInputs);
                    app.ActivePane.attachNewOptimization(nodeData);
                case 'QSP.CohortGeneration'
                    app.ActivePane = QSPViewerNew.Application.CohortGenerationPane(classInputs);
                    app.ActivePane.attachNewCohortGeneration(nodeData);
                case 'QSP.VirtualPopulationGeneration'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationGenerationPane(classInputs);
                    app.ActivePane.attachNewVirtualPopulationGeneration(nodeData);
                case 'QSP.VirtualPopulationGenerationData'
                    app.ActivePane = QSPViewerNew.Application.VirtualPopulationGenerationDataPane(classInputs);
                    app.ActivePane.attachNewVirtPopGenData(nodeData);
                case 'QSP.GlobalSensitivityAnalysis'
                    app.ActivePane = QSPViewerNew.Application.GlobalSensitivityAnalysisPane(classInputs);
                    app.ActivePane.attachNewGlobalSensitivityAnalysis(nodeData);                    
                    
            end
            if ~isempty(app.ActivePane)
                %Now take the pane and display it.
                app.Panes = [app.Panes, app.ActivePane];
                app.ActivePane.showThisPane();
            end
        end
        
        function launchOldPane(app,nodeData)
            %Find the index of the correct pane type
            PaneType = app.getPaneClassFromQSPClass(class(nodeData));
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
                    app.ActivePane.attachNewSession(nodeData);
                case 'QSPViewerNew.Application.TaskPane'
                    app.ActivePane.attachNewTask(nodeData);
                case 'QSPViewerNew.Application.ParametersPane'
                    app.ActivePane.attachNewParameters(nodeData);
                case 'QSPViewerNew.Application.OptimizationDataPane'
                    app.ActivePane.attachNewOptimizationData(nodeData);
                case 'QSPViewerNew.Application.VirtualPopulationDataPane'
                    app.ActivePane.attachNewVirtPopData(nodeData);
                case 'QSPViewerNew.Application.VirtualPopulationPane'
                    app.ActivePane.attachNewVirtualPopulation(nodeData);
                case 'QSPViewerNew.Application.VirtualPopulationGenerationDataPane'
                    app.ActivePane.attachNewVirtPopGenData(nodeData);
                case 'QSPViewerNew.Application.SimulationPane'
                    app.ActivePane.attachNewSimulation(nodeData);
                case 'QSPViewerNew.Application.OptimizationPane'
                    app.ActivePane.attachNewOptimization(nodeData);
                case 'QSPViewerNew.Application.CohortGenerationPane'
                    app.ActivePane.attachNewCohortGeneration(nodeData);
                case 'QSPViewerNew.Application.VirtualPopulationGenerationPane'
                    app.ActivePane.attachNewVirtualPopulationGeneration(nodeData);
                case 'QSPViewerNew.Application.GlobalSensitivityAnalysisPane'
                    app.ActivePane.attachNewGlobalSensitivityAnalysis(nodeData);
            end
            
            app.ActivePane.showThisPane();
        end
        
        function updateTreeData(app,tree,newData,type)
            %1. Update the Node information
            tree.NodeData = newData;
            
            %2. Determine what type of Node this is.
            % We have to pass the type of the children because the node userdata types are
            % often the same between different types of nodes
            switch type
                case 'Session'
                    %If a session, we must check settings,functionalties,
                    %and deleted item
                    app.updateTreeData(tree.Children(1),newData.Settings,'BuildingBlocks')
                    app.updateTreeData(tree.Children(2),newData,'Functionalities')
                    app.updateTreeData(tree.Children(3),newData.Deleted,'Deleted')
                    
                    %If we are updating the session, we need to update the
                    %name
                    app.setCurrentSessionDirty()
                    
                case 'Building Blocks'
                    %Iterate through the 5 Subcategories
                    app.updateTreeData(tree.Children(1),newData,'TaskGroup')
                    app.updateTreeData(tree.Children(2),newData,'ParameterGroup')
                    app.updateTreeData(tree.Children(3),newData,'OptimizationDataGroup')
                    app.updateTreeData(tree.Children(4),newData,'VirtualPopulationDataGroup')
                    app.updateTreeData(tree.Children(5),newData,'VirtualPopulationGenerationDataGroup')
                    
                case 'TaskGroup'
                    for idx = 1:numel(newData.Task)
                        app.updateTreeData(tree.Children(idx),newData.Task(idx),'Task')
                    end
                case 'ParameterGroup'
                    for idx = 1:numel(newData.Parameters)
                        app.updateTreeData(tree.Children(idx),newData.Parameters(idx),'Parameters')
                    end
                case 'OptimizationDataGroup'
                    for idx = 1:numel(newData.OptimizationData)
                        app.updateTreeData(tree.Children(idx),newData.OptimizationData(idx),'OptimizationData')
                    end
                case 'VirtualPopulationDataGroup'
                     for idx = 1:numel(newData.VirtualPopulationData)
                        app.updateTreeData(tree.Children(idx),newData.VirtualPopulationData(idx),'VirtualPopulationData')
                    end
                case 'VirtualPopulationGenerationDataGroup'
                     for idx = 1:numel(newData.VirtualPopulationGenerationData)
                        app.updateTreeData(tree.Children(idx),newData.VirtualPopulationGenerationData(idx),'VirtualPopulationGenerationData')
                     end      
                case 'Simulation'
                    tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'Optimization'
                    tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'CohortGeneration'
                    tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'VirtualPopulationGeneration'
                    tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);
                case 'GlobalSensitivityAnalysis'
                    tree.NodeData.Session = app.Sessions(app.SelectedSessionIdx);                    
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
                updateLoggerName(app.Sessions(idx));
                updateLoggerSessions(app);
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
        
        function restoreNode(app,node,session)
            try
            % What is the data object?
            ThisObj = node.NodeData;
            
            % What type of item?
            ItemType = strrep(class(ThisObj), 'QSP.', '');
            
            % Where does the item go?
            if isprop(session,ItemType)
                ParentObj = session;
                SuperParentArray = ParentObj.TreeNode.Children;
                ChildTags = {SuperParentArray.Tag};
                SuperParent = SuperParentArray(strcmpi(ChildTags,'Functionalities'));
                ParentArray = SuperParent.Children;
                
            else
                ParentObj = session.Settings;
                ParentArray = ParentObj.TreeNode.Children;
            end
            
            ParentArrayTypes = {ParentArray.Tag};
            ParentNode = ParentArray(strcmp(ParentArrayTypes,ItemType));
            
            % check for duplicate names
            if any(strcmp(ThisObj.Name,{ParentObj.(ItemType).Name} ))
                uialert(app.UIFigure,'Cannot restore deleted item because its name is identical to an existing item.','Restore');
            end
            
            % Move the object from deleted to the new parent
            ParentObj.(ItemType)(end+1) = ThisObj;
            MatchIdx = false(size(session.Deleted));
            for idx = 1:numel(session.Deleted)
                MatchIdx(idx) = session.Deleted(idx)==ThisObj;
            end
            session.Deleted( MatchIdx ) = [];
            
            % Update the name to include the timestamp
            TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
            
            % Strip out date
            SplitName = regexp(ThisObj.Name,'\(\d\d-\D\D\D-\d\d\d\d_\d\d-\d\d-\d\d\)','split');
            if ~isempty(SplitName) && iscell(SplitName)
                SplitName = SplitName{1}; % Take first
            end
            ThisObj.Name = strtrim(SplitName);
            
            ThisObj.Name = sprintf('%s (%s)',ThisObj.Name,TimeStamp);
            
            % Update the tree
            node.Parent = ParentNode;
            ParentNode.expand();
            
            % Change context menu
            node.UIContextMenu = app.TreeMenu.Leaf.(ItemType);
            
            % Update the display
            app.refresh();
            app.markDirty(session);
            catch ME
                ThisSession = node.NodeData.Session;
                loggerObj = QSPViewerNew.Widgets.Logger(ThisSession.LoggerName);
                loggerObj.write(node.Text, ItemType ,ME)
            end
        end
        
        function duplicateNode(app,Node,~) 

            % What type of item?
            ParentNode = Node.Parent;
            ItemType = ParentNode.Tag;
            
            % What are the data object and its parent?
            ParentObj = ParentNode.NodeData;
            
            ThisObj = Node.NodeData;
            
            % Create the duplicate item
            DisallowedNames = {ParentObj.(ItemType).Name};
            NewName = matlab.lang.makeUniqueStrings(ThisObj.Name, DisallowedNames);
            ThisObj = ThisObj.copy();
            ThisObj.Name = NewName;
            ThisObj.clearData();
            
            % Place the item and add the tree node
            if isscalar(ParentNode)
                ParentObj.(ItemType)(end+1) = ThisObj;
                app.createTree(ParentNode, ThisObj);
                ParentNode.expand();
            else
                error('Invalid tree parent');
            end
            
            % Mark the current session dirty
            ThisSession = Node.NodeData.Session;
            app.markDirty(ThisSession);
            
            % Update the display
            app.refresh();
            
            % update log
            loggerObj = QSPViewerNew.Widgets.Logger(ThisSession.LoggerName);
            loggerObj.write(Node.Text, ItemType, "INFO", 'duplicated item')
        end
        
        function deleteNode(app,Node,session)

            % What type of item?
            PackageContents = strsplit(class(Node.NodeData),'.');
            ItemType = PackageContents{end};
            
            % Where is the Deleted Items node?
            hDeletedNode = session.TreeNode.Children(3);
            
            % What are the data object and its parent?
            ThisObj = Node.NodeData;
            ParentObj = Node.Parent.NodeData;
            
            % Move the object from its parent to deleted
            session.Deleted(end+1) = ThisObj;
            ParentObj.(ItemType)( ParentObj.(ItemType)==ThisObj ) = [];
            Node.Parent = hDeletedNode;
            app.TreeRoot.SelectedNodes = Node;
            
            % Change context menu
            app.createContextMenu(Node,'Deleted')
            
            app.SelectedSessionIdx = []; % switch to summary view
            
            hDeletedNode.expand();
            
            % Mark the current session dirty
            app.markDirty(session);
                        
            % Update the display
            app.refresh();
            
            % update log
            loggerObj = QSPViewerNew.Widgets.Logger(ThisObj.Session.LoggerName);
            loggerObj.write(Node.Text, ItemType, "WARNING", 'deleted item')
        end
        
        function permDelete(app,nodes,session)
            %Determine node names
            NodeNames = {nodes.Text};
            
            % Confirm with user they would like to delete all
            Messages = cellfun(@(x) sprintf('Permanently delete "%s"?', x),NodeNames,'UniformOutput',false);
            Result = uiconfirm(app.UIFigure,Messages,'Delete','Options', {'Delete','Cancel'});
            
            if strcmpi(Result,'Delete')
                for Nodeidx = 1:numel(nodes)
                    % Delete the selected item
                    ThisNode = nodes(Nodeidx);
                    ThisObj = ThisNode.NodeData;
                    
                     % update log
                     % What type of item?
                     itemType = split(class(ThisObj), '.');
                     loggerObj = QSPViewerNew.Widgets.Logger(session.LoggerName);
                     loggerObj.write(ThisNode.Text, itemType{end}, "DEBUG", 'permanently deleted item')
                    
                    %Find the node in the deleted array
                    MatchIdx = false(size(session.Deleted));
                    for idx = 1:numel(session.Deleted)
                        MatchIdx(idx) = session.Deleted(idx)==ThisObj;
                    end
                    
                    % Remove from deleted items in the session
                    session.Deleted( MatchIdx ) = [];

                    % Now delete tree node
                    delete(ThisNode);
                    
                    % Mark the current session dirty
                    app.markDirty(session);
                    
                end
                
                % Update the display
                app.refresh();
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
        
       function PaneClass = getPaneClassFromQSPClass(QSPClass)
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
                case 'QSP.GlobalSensitivityAnalysis'
                    PaneClass = 'QSPViewerNew.Application.GlobalSensitivityAnalysisPane';
            end
       end
       
       function executeCallbackArray(functionArray,h,e)
           for i = 1:length(functionArray)
               feval(functionArray{i},h,e)
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
        
        function set.Sessions(app,value)
            app.Sessions = value;
            app.updateLoggerSessions();
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
            value = arrayfun(@class, app.Panes, 'UniformOutput', false); 
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
