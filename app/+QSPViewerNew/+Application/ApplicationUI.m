classdef ApplicationUI < handle
    % ApplicationUI - This is the Controller class for the application.
    % In addition is manages the list of Sessions (the model) loaded in the 
    % application. In other words, this controller hangs on to the Model.
    
    %   Copyright 2020 The MathWorks, Inc.

    properties
        Sessions (1,:) QSP.Session = QSP.Session.empty(0,1)        
        Title
        SelectedNodePath (1,1) string
        ItemTypes cell
    end

    properties(Constant)
        AppName = "gQSPSim"
        Version = 'v1.0'
        buildingBlockTypes = {
            'Task',                             'Task'
            'Parameter',                        'Parameters'
            'Dataset',                          'OptimizationData'
            'Acceptance Criteria',              'VirtualPopulationData'
            'Target Statistics',                'VirtualPopulationGenerationData'
            'Virtual Subject(s)',               'VirtualPopulation'
            };
        
        functionalityTypes = {
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
        SessionPaths = cell.empty(0,1) % What is this? TODOpax
        IsDirty = logical.empty(0,1)
        RecentSessionPaths = cell.empty(0,1)
        LastFolder = pwd
        ActivePane % TODOpax remove this..
        Panes = cell.empty(0,1); % TODOpax remove this..
        IsConstructed = false; % TODOpax remove this..
        PreferencesGroupName (1,1) string  = "gQSPSim_preferences";
        Type % replaced with PreferencesGroupName
        TypeStr %todopax remove.
        WindowButtonDownCallbacks = {}; % TODOpax remove this
        WindowButtonUpCallbacks = {}; % TODOpax remove this
       
        OuterShell QSPViewerNew.Application.OuterShell_UIFigureBased
        ModelManagerDialog ModelManager
        LoggerDialog QSPViewerNew.Dialogs.LoggerDialog
    end

    properties (SetAccess = private, Dependent = true, AbortSet = true)
        SelectedSessionName
        SelectedSessionPath
        NumSessions %TODOpax remove
        SessionNames %TODOpax remove
        SelectedSession
        SessionNode % TODOpax remove
        PaneTypes %TODOpax remove
    end

    properties (Access = public)
        paneGridLayout (1,1) matlab.ui.container.GridLayout
        paneHolder     (1,1) struct
        
%         SessionExplorerPanel     matlab.ui.container.Panel
%         SessionExplorerGrid      matlab.ui.container.GridLayout
        TreeRoot                 matlab.ui.container.Tree %TODOpax remove this.. moved to OuterShell.
        TreeMenu
        OpenRecentMenuArray
    end

    properties (SetAccess = private, SetObservable, AbortSet)
        PluginManager QSPViewerNew.Dialogs.PluginManager
    end

    properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % listener handle for Sessions property
        SessionsListener

        % listener handle for PluginTableData property
        PluginTableDataListener event.listener
    end

    events
        NewSession
        Model_NewItemAdded
        Model_SessionClosed
    end

    methods (Access = public)

        function app = ApplicationUI

            app.Title = app.AppName + " " + app.Version;
            app.FileSpec = {'*.qsp.mat','MATLAB QSP MAT File'};
            app.PreferencesGroupName = "gQSPSim_preferences";
            app.ItemTypes = vertcat(app.buildingBlockTypes, app.functionalityTypes);

            % Construct the view. The app (i.e. controller) is supplied to the View
            % constructor for the purpose of connecting listeners. The app
            % should not (and is not) stored by the View.
            app.OuterShell = QSPViewerNew.Application.OuterShell_UIFigureBased(app.Title, app); 

            %Save the type of the app for use in preferences
            app.Type = class(app); %TODOpax this is not going to work well. We need to pick a name for the preferences and make sure we are backwards compatible. E.g., a name change for the class would break this.
            app.TypeStr = matlab.lang.makeValidName(app.Type);

            %Get the previous file locations from preferences
            app.LastFolder = getpref(app.TypeStr,'LastFolder',app.LastFolder);
            app.RecentSessionPaths = getpref(app.TypeStr,'RecentSessionPaths',app.RecentSessionPaths);

            % Validate each recent file, and remove any invalid files
            idxOk = cellfun(@(x)exist(x,'file'), app.RecentSessionPaths);
            app.RecentSessionPaths(~idxOk) = [];

            % Draw the recent files to the menu
            % TODOpax. app.redrawRecentFiles();

            % Refresh the entire view
            %TODOpax. app.refresh();
            
            % Listen to these events from the View.             
            addlistener(app.OuterShell, 'New_Request',       @(h,e)app.createNewSession);
            addlistener(app.OuterShell, 'AddTreeNode',       @(h,e)app.onAddItemNew(e));
            addlistener(app.OuterShell, 'OpenModelManager',  @(h,e)app.onOpenModelManager);
            addlistener(app.OuterShell, 'OpenPluginManager', @(h,e)app.onOpenPluginManager);
            addlistener(app.OuterShell, 'OpenLogger',        @(h,e)app.onOpenLogger);
            addlistener(app.OuterShell, 'Close_Request',     @(h,e)app.onClose(e));
            addlistener(app.OuterShell, 'Open_Request',      @(h,e)app.onOpen);
            addlistener(app.OuterShell, 'Exit_Request',      @(h,e)app.onExit);

            % load a session for rapid devel.
            %app.forDebuggingInit;
        end

        function forDebuggingInit(app, h, e)
            app.IsConstructed = true;

            app.loadSessionFromPath('tests/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD_pax.qsp.mat')
        end

        function delete(app)
            %Upon deletion, save the recent sessions and last folder to use
            %in the next instance of the application
            setpref(app.TypeStr, 'LastFolder', app.LastFolder)
            setpref(app.TypeStr, 'RecentSessionPaths', app.RecentSessionPaths)
            % TODOpax. Restore saving the window position. setpref(app.TypeStr, 'Position', app.UIFigure.Position)

            % close plugin manager if open
            if isvalid(app.PluginManager)
                delete(app.PluginManager)
            end

            % close logger dialog if open
            if isvalid(app.LoggerDialog)
                delete(app.LoggerDialog)
            end

            if isvalid(app.OuterShell)
                delete(app.OuterShell)
            end
        end
    end

    methods (Access = private)

        function createTree(app, parent, allData)

            error("ApplicationUI:createTree");

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
                        % create nodes for all except folder; folder nodes
                        % are created separately in createFolderNode
                        thisFcn(hDeleteds, Data.Deleted(arrayfun(@(x) ~isa(x, 'QSP.Folder'), Data.Deleted)));
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

                    case 'QSP.Folder'

                        hNode = app.createNode(parent, Data, Data.Name, ...
                            QSPViewerNew.Resources.LoadResourcePath('folder_24.png'),...
                            'Folder', 'Folder', '');
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

        % todo, move to OuterShell
        function createContextMenu(app,Node,Type)
            %Determine if this ContextMenu is from QSP
            Index = find(strcmpi(Type,app.ItemTypes(:,1)));

            %If the Node is from a QSP class
            if ~isempty(Index)
                ThisItemType = app.ItemTypes{Index,2};

                % If it is an instance of QSP.Folder
                if strcmp(Node.UserData,"Folder")
                    ParentItemObj = getParentItemNode(Node.NodeData, app.TreeRoot);
                    ParentItemType = ParentItemObj.UserData;

                    CM = uicontextmenu('Parent',app.UIFigure);
                    uimenu('Parent', CM,'Label', ['Add new ' ParentItemType],...
                        'MenuSelectedFcn', @(h,e)app.onAddItem(h.Parent.UserData,Node.NodeData.Session,ParentItemType));

                    uimenu('Parent', CM,'Label', 'Add new Folder', ...
                        'MenuSelectedFcn', @(h,e)app.onAddFolder(h.Parent.UserData,Node.NodeData.Session,true));

                    uimenu('Parent', CM,'Label', 'Move to ...', ...
                        'MenuSelectedFcn', @(h,e)app.onMoveFolder(h.Parent.UserData));

                    uimenu('Parent', CM,'Label', 'Rename', ...
                        'MenuSelectedFcn', @(h,e)app.onRenameFolder(h.Parent.UserData));

                    uimenu('Parent', CM,'Label', 'Delete', ...
                        'MenuSelectedFcn', @(h,e)app.onDeleteSelectedItem(h.Parent.UserData.NodeData.Session, h.Parent.UserData));

                    %If it is an instance of a QSP Class
                elseif ~isempty(Node.UserData)
                    CM = uicontextmenu('Parent',app.UIFigure);
                    uimenu('Parent',CM,'Label', ['Add new ' ThisItemType],...
                        'MenuSelectedFcn', @(h,e)app.onAddItem(h.Parent.UserData,h.Parent.UserData.Parent.Parent.NodeData,ThisItemType));

                    uimenu('Parent',CM,'Label', 'Add new Folder', ...
                        'MenuSelectedFcn', @(h,e)app.onAddFolder(h.Parent.UserData,h.Parent.UserData.Parent.Parent.NodeData,true));

                    %Not an Instance, just a type
                else
                    CM = uicontextmenu('Parent',app.UIFigure);
                    uimenu(...
                        'Parent', CM,...
                        'Text', ['Duplicate this ' ThisItemType],...
                        'MenuSelectedFcn', @(h,e) app.onDuplicateItem(h.Parent.UserData.NodeData.Session,h.Parent.UserData));
                    uimenu(...
                        'Parent', CM,...
                        'Text', ['Delete this ' ThisItemType],...
                        'Separator', 'on',...
                        'MenuSelectedFcn', @(h,e) app.onDeleteSelectedItem(h.Parent.UserData.NodeData.Session,h.Parent.UserData));
                    uimenu(...
                        'Parent', CM,...
                        'Text', 'Move to ...',...
                        'Separator', 'on',...
                        'MenuSelectedFcn', @(h,e) app.onMoveToSelectedItem(h,e), ...
                        'Enable', 'off');
                    %TODOpax'MenuSelectedFcn', @(h,e) app.onDeleteSelectedItem(h.Parent.UserData.Parent.Parent.Parent.NodeData,h.Parent.UserData));

                    Node.ContextMenu = CM;

                    pluginsDir = Node.Parent.Parent.Parent.NodeData.PluginsDirectory;
                    pluginTable = ...
                        QSPViewerNew.Dialogs.PluginManager.getPlugins(pluginsDir);
                    updateItemTypePluginMenus(app, ThisItemType, Node, pluginTable);
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
                            'MenuSelectedFcn', @(h,e) app.onRestoreSelectedItem(h.Parent.UserData,h.Parent.UserData.NodeData.Session));
                        uimenu(...
                            'Parent', CM,...
                            'Text', 'Permanently Delete',...
                            'Separator', 'on',...
                            'MenuSelectedFcn', @(h,e) app.onEmptyDeletedItems(h.Parent.UserData,h.Parent.UserData.NodeData.Session,false));
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

        function updateItemTypePluginMenus(app, thisItemType, Node, pluginTable)
            % Get runpluginMenu
            CM = Node.ContextMenu;

            % delete all current plugin menus
            allMenuTags = string({CM.Children.Tag});
            delete(CM.Children(allMenuTags=="plugin"))

            % Get plugins for this item
            thisItemPlugins = pluginTable(pluginTable.Type==thisItemType,:);
            thisItemPlugins = removevars(thisItemPlugins, 'All Dependencies within root directory');
            if ~isempty(thisItemPlugins)
                % Get most recently used plugins for this type
                defaultPluginTable = table.empty();
                mostRecentPlugins = getpref(app.TypeStr, strcat('recent', erase(thisItemType, " ")), defaultPluginTable);

                % Check if most recent plugins are part of
                % currently available plugins
                if ~isempty(mostRecentPlugins)
                    [~, ia] = setdiff(mostRecentPlugins.File, thisItemPlugins.File);
                    mostRecentPlugins(ia,:) = [];
                    thisItemAvailablePlugins = vertcat(mostRecentPlugins, thisItemPlugins);

                    % remove function handle column to get unique rows
                    [~, ia] = unique(thisItemAvailablePlugins.File, 'stable', 'rows');
                    thisItemAvailablePlugins = thisItemAvailablePlugins(ia,:);
                else
                    thisItemAvailablePlugins = thisItemPlugins ;
                end

                % create a menu for every plugin for the first five
                % plugins
                numPlugin = 5;
                numPlugin = min(numPlugin, height(thisItemAvailablePlugins));

                %                 delete(runpluginMenu.Children);
                for cntPlugin=1:numPlugin
                    m = uimenu(...
                        'Parent', CM,...
                        'Text', strcat("Run ", thisItemAvailablePlugins.Name(cntPlugin)),...
                        'MenuSelectedFcn', @(h,e) app.applyPlugin(Node, ...
                        thisItemAvailablePlugins(cntPlugin,:)), ...
                        'UserData', thisItemAvailablePlugins.File(cntPlugin), ...
                        'Tag', "plugin");
                    if cntPlugin==1
                        m.Separator = 'on';
                    end
                end

                % if more than 5 plugins, create, more options menu
                if height(thisItemAvailablePlugins)>numPlugin
                    uimenu(...
                        'Parent', CM,...
                        'Text', 'More plugins...',...
                        'MenuSelectedFcn', @(h,e) app.onOpenPluginListDialog(Node, thisItemAvailablePlugins), ...
                        'Tag', "plugin");
                end
            end
        end

    end

    methods (Access = private)

        function onNew(app,~,~)
            error("called ApplicationUI:onNew");

            %We are using multiple sessions so
            if app.AllowMultipleSessions || app.promptToSave(1)
                app.createUntitledSession();
            end

            app.refresh();

            % check if an instance of plugin  manager is
            % running
            if isvalid(app.PluginManager)
                app.PluginManager.Sessions = app.Sessions;
            else
                thisSession = app.Sessions(app.SelectedSessionIdx);
                pluginTable = ...
                    QSPViewerNew.Dialogs.PluginManager.getPlugins(thisSession.PluginsDirectory);
                updateAllPluginMenus(app, thisSession, pluginTable)
            end
        end

        function onOpen(app,~,~)
            % Allow the controller to call this ui utility. We could hide
            % this implemenation in a utility package but there is little
            % need for that overhead.
            [FileName, PathName] = uigetfile(app.FileSpec, 'Open File', app.LastFolder, 'MultiSelect', 'on');

            % If the user did not cancel
            if ~isequal(FileName, 0)

                switch class(FileName)
                    case 'char'
                        app.LastFolder = PathName;
                        fullFilePath = fullfile(PathName,FileName);
                        app.loadSessionFromPath(fullFilePath);
                    case 'cell'                        
                        app.LastFolder = PathName;
                        for fileIndex = 1:numel(FileName)
                            fullFilePath = fullfile(PathName,FileName{fileIndex});
                            app.loadSessionFromPath(fullFilePath);
                        end
                end
            end
        end

        function onClose(app, eventData)
            activeSession = eventData.Session;
            assert(~isempty(activeSession));

            sessionTF = activeSession == app.Sessions;            

            assert(sum(sessionTF) == 1);            

            app.closeSession(find(sessionTF));

            notify(app, "Model_SessionClosed", QSPViewerNew.Application.Session_EventData(activeSession));
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

        function onExit(app)            
            cancelTF = false;

            for i = 1:numel(app.Sessions)
                if app.IsDirty(i)
                    cancelTF = app.savePromptBeforeClose(i);
                    if cancelTF
                        break
                    end
                end
            end

            if ~cancelTF
                app.delete();
            end

%             while ~CancelTF && (~isempty(app.Sessions))
%                 if app.IsDirty(1)
%                     CancelTF = app.savePromptBeforeClose(1);
%                 else
%                     app.closeSession(1)
%                 end
%             end
% 
%             if ~CancelTF
%                 app.delete();
%             end
        end

        function onDeleteSelectedItem(app,activeSession,activeNode)
            if isempty(activeSession)
                activeSession = app.SelectedSession;
            end

            activeNodes = [activeNode; app.TreeRoot.SelectedNodes];
            activeNodes = unique(activeNodes);

            for i = 1:length(activeNodes)
                app.deleteNode(activeNodes(i),activeSession)
            end
            app.markDirty(activeSession);
        end

        function onRestoreSelectedItem(app,activeNode,activeSession)
            if isempty(activeSession)
                activeSession = app.SelectedSession;
            end

            activeNodes = [activeNode; app.TreeRoot.SelectedNodes];
            activeNodes = unique(activeNodes);

            for i = 1:length(activeNodes)
                app.restoreNode(activeNodes(i),activeSession)
            end
            app.markDirty(activeSession);
        end

        function onOpenModelManager(app,~,~)
            if ~isempty(app.SelectedSession)
                rootDir = app.SelectedSession.RootDirectory;
            else
                rootDir = [];
            end

            % singleton only
            if isempty(app.ModelManagerDialog) || ~isvalid(app.ModelManagerDialog)
                app.ModelManagerDialog = ModelManager(rootDir);
            end

        end

        function onAddItemNew(app, eventData)
            % ONADDITEMNEW Add a new item to the model. The parent session
            % and the type are provided in the eventData.
            newItemPrefix = "New ";

            session = eventData.Session;
            itemType = eventData.type;

            % The Model should provide a way to add to its structure, but
            % that does not appear to be the case right now so handle it
            % here at the expense of some technical debt. If the model were
            % to have this add functionality then it would be the one
            % notifying the controller (or the view) about the addition.
            % In addition, the model also does not support default names.
            % Rather than adding it in the Model deal with it here, but
            % that is more technical debt.
            buildingBlockType_TF = strcmp(itemType, app.buildingBlockTypes(:,2));
            functionalityType_TF = strcmp(itemType, app.functionalityTypes(:,2));

            if any(buildingBlockType_TF)
                newName = newItemPrefix + app.buildingBlockTypes(buildingBlockType_TF, 1);
                newIndex = sum(string({session.Settings.(itemType).Name}).contains(newName)) + 1;
                newName = newName + "_" + newIndex;                
                newItem = QSP.(itemType)('Name', char(newName));
                session.Settings.(itemType)(end+1) = newItem;
            elseif any(functionalityType_TF)
                newName = char(newItemPrefix + app.functionalityTypes(functionalityType_TF, 1));
                newIndex = sum(string({session.(itemType).Name}).contains(newName)) + 1;
                newName = newName + "_" + newIndex;
                newItem = QSP.(itemType)('Name', char(newName));
                session.(itemType)(end+1) = newItem;
            end

            % I would prefer if the session is not stored in the items but
            % a lot of code depends on this now.
            % TODOpax: remove this from the model.
            newItem.Session = session;

            notify(app, 'Model_NewItemAdded', QSPViewerNew.Application.NewItemAddedEventData(newItem, itemType)); % todopax would be nice if we don't need itemType
        end
        
        function onAddItem(app,~,thisSession,itemType)

            error('ApplicationUI:onAddItem called.');

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

            % TODOpax, need to version this.
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

            if isa(ParentNode.NodeData, 'QSP.Folder')
                if isempty(ParentNode.NodeData.Children)
                    ParentNode.NodeData.Children = ThisObj;
                else
                    ParentNode.NodeData.Children(end+1) = ThisObj;
                end
            end

            % update "Move to..." context menu
            updateMovetoContextMenu(app,ParentNode);

            % Mark the current session dirty
            app.markDirty(thisSession);

            % Update the display
            app.updateTreeNames();

            %Update the file menu
            app.updateFileMenu();

            %Update the title of the application
            app.updateAppTitle();
        end

        function ThisFolder = onAddFolder(app,ParentNode,thisSession,TfAcceptName)
            ThisFolder = QSP.Folder;
            if isa(ParentNode.NodeData, 'QSP.Folder')
                ThisFolder.Name = 'SubFolder';
                if isempty(ParentNode.NodeData.Children)
                    ParentNode.NodeData.Children = ThisFolder;
                else
                    ParentNode.NodeData.Children(end+1) = ThisFolder;
                end
                ThisFolder.OldParent = ThisFolder.Parent;
                ThisFolder.Parent = ParentNode.NodeData;
            else
                ThisFolder.OldParent = ThisFolder.Parent;
                ThisFolder.Parent = ParentNode.Text;
            end
            ThisFolder.Session = thisSession;

            if ~isempty(ParentNode.Children)
                allChildren = {ParentNode.Children.NodeData};
                allFoldersIdx = cellfun(@(x) isa(x, 'QSP.Folder'),allChildren );

                if any(allFoldersIdx)
                    allFolders = [allChildren{allFoldersIdx}];
                    DisallowedNames = {allFolders.Name};
                    NewName = matlab.lang.makeUniqueStrings(ThisFolder.Name, DisallowedNames);
                    ThisFolder.Name = NewName;
                end
            end

            % Place the item and add the tree node
            if isscalar(ParentNode)
                app.createTree(ParentNode, ThisFolder);
                ParentNode.expand();
            else
                error('Invalid tree parent');
            end

            % update "Move to..." context menu
            updateMovetoContextMenu(app,ParentNode);

            if TfAcceptName
                % get user input to name folder
                onRenameFolder(app, ThisFolder.TreeNode);
            end

            thisSession.Settings.Folder(end+1) = ThisFolder;

            % Mark the current session dirty
            app.markDirty(thisSession);

            % Update the display
            app.updateTreeNames();

            %Update the file menu
            app.updateFileMenu();

            %Update the title of the application
            app.updateAppTitle();

        end

        function onMoveFolder(app,thisNode)
            parentItemNode = getParentItemNode(thisNode.NodeData, app.TreeRoot);

            nodeSelDialog = QSPViewerNew.Widgets.TreeNodeSelectionModalDialog (app, ...
                parentItemNode, ...
                'ParentAppPosition', app.UIFigure.Position, ...
                'DialogName', 'Select node to move item(s) to', ...
                'CurrentFolder', string(thisNode.Text));

            uiwait(nodeSelDialog.MainFigure);

            selNode = app.SelectedNodePath;

            if selNode ~= ""
                allNodes = split(selNode, filesep);
                newParentNode = parentItemNode;
                for i = length(allNodes)-1:-1:1
                    childName = allNodes(i);
                    childNodeIdx = childName==string({newParentNode.Children.Text});
                    newParentNode = newParentNode.Children(childNodeIdx);
                end

                % assign all current selected nodes to new parent
                selNodes = [thisNode; app.TreeRoot.SelectedNodes];
                selNodes = unique(selNodes);
                for i = 1:length(selNodes)
                    if isa(selNodes(i).NodeData, class(thisNode.NodeData))
                        if isequal(getParentItemNode(selNodes(i).NodeData, app.TreeRoot), getParentItemNode(thisNode.NodeData, app.TreeRoot))
                            if ~isequal(newParentNode, thisNode)
                                selNodes(i).Parent = newParentNode;
                                if isa(newParentNode.NodeData, 'QSP.Folder') % if folder, assign the new children
                                    if isempty(newParentNode.NodeData.Children)
                                        newParentNode.NodeData.Children = selNodes(i).NodeData;
                                    else
                                        newParentNode.NodeData.Children(end+1) = selNodes(i).NodeData;
                                    end
                                    selNodes(i).NodeData.OldParent = selNodes(i).NodeData.Parent;
                                    selNodes(i).NodeData.Parent = newParentNode.NodeData;
                                else
                                    selNodes(i).NodeData.Parent = newParentNode.Text;
                                end
                                expand(newParentNode);
                            end
                        end
                    end
                end
            end
        end

        function onRenameFolder(app, node)
            prompt = {'Enter new name'};
            dlgtitle = 'Folder Name';
            dims = [1 50];
            definput = {node.Text};
            answer = inputdlg(prompt, dlgtitle, dims, definput);
            if ~isempty(answer)
                % check if the name is same as other folders for this
                % itemtype
                parentNode = node.Parent;

                allChildren = {parentNode.Children.NodeData};
                allFoldersIdx = cellfun(@(x) isa(x, 'QSP.Folder'), allChildren );

                allFolders = [allChildren{allFoldersIdx}];
                DisallowedNames = string({allFolders.Name});
                DisallowedNames(DisallowedNames==node.Text) = [];
                if any(ismember(answer{1}, DisallowedNames))
                    msg = sprintf("A folder already exists with the name %s. Please specify another name.", answer{1});
                    uialert(app.UIFigure, msg, ...
                        "Inavlid file name");
                else
                    node.Text = answer{1};
                    node.NodeData.Name = answer{1};
                end
            end
            % log to logger
            loggerObj = QSPViewerNew.Widgets.Logger(thisSession.LoggerName);
            loggerObj.write(ParentNode.Text, itemType, "MESSAGE", 'added item')
        end

        function onDuplicateItem(app,activeSession,activeNode)
            if isempty(activeSession)
                activeSession = app.SelectedSession;
            end

            activeNodes = [activeNode; app.TreeRoot.SelectedNodes];
            activeNodes = unique(activeNodes);

            for i = 1:length(activeNodes)
                app.duplicateNode(activeNodes(i),activeSession)
            end

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

        function onMoveToSelectedItem(app,h,~)

            currentNode = h.Parent.UserData;
            allItemTypeTags = {'Task'; 'Parameters'; 'OptimizationData'; 'VirtualPopulationData'; ...
                'VirtualPopulationGenerationData'; 'VirtualPopulation'; 'Simulation'; 'Optimization'; ...
                'CohortGeneration'; 'VirtualPopulationGeneration'; 'GlobalSensitivityAnalysis'};
            parentNode = currentNode;
            while ~ismember(parentNode.Tag, allItemTypeTags)
                parentNode = parentNode.Parent;
            end

            nodeSelDialog = QSPViewerNew.Widgets.TreeNodeSelectionModalDialog (app, ...
                parentNode, ...
                'ParentAppPosition', app.UIFigure.Position, ...
                'DialogName', 'Select node to move item(s) to');

            uiwait(nodeSelDialog.MainFigure);

            selNode = app.SelectedNodePath;
            allNodes = split(selNode, filesep);
            newParentNode = parentNode;
            for i = length(allNodes)-1:-1:1
                childName = allNodes(i);
                childNodeIdx = childName==string({newParentNode.Children.Text});
                newParentNode = newParentNode.Children(childNodeIdx);
            end

            % assign all current selected nodes to new parent
            selNodes = [currentNode; app.TreeRoot.SelectedNodes];
            selNodes = unique(selNodes);
            for i = 1:length(selNodes)
                if isa(selNodes(i).NodeData, class(currentNode.NodeData)) % move all nodes of same type
                    selNodes(i).Parent = newParentNode;
                    if isa(newParentNode.NodeData, 'QSP.Folder') % if folder, assign the new children
                        if isempty(newParentNode.NodeData.Children)
                            newParentNode.NodeData.Children = selNodes(i).NodeData;
                        else
                            newParentNode.NodeData.Children(end+1) = selNodes(i).NodeData;
                        end
                    end
                end
            end
            expand(newParentNode);
            app.markDirty(currentNode.NodeData.Session);
        end

        function onOpenPluginManager(app)
            try
                app.PluginManager = QSPViewerNew.Dialogs.PluginManager;
                app.PluginManager.Sessions = app.Sessions;

                % Attach listener to plugin table property to update context
                % menus
                app.PluginTableDataListener = addlistener(app.PluginManager, 'PluginTableData', ...
                    'PostSet', @(h,e) onPluginTableChanged(app));

            catch ME
                uialert(app.UIFigure, ME.message, 'Error opening plugin manager');
            end
        end

        function onPluginTableChanged(app)
            if ~isempty(app.PluginManager.SelectedSession)
                updateAllPluginMenus(app, app.PluginManager.SelectedSession, ...
                    app.PluginManager.PluginTableData)
            end
        end

        function updateAllPluginMenus(app, Session, pluginTable)
            %Determine if this ContextMenu is from QSP
            allTreeNodes = vertcat(Session.TreeNode);
            allTopTreenodes = vertcat(allTreeNodes.Children);
            allItemTypes = vertcat(allTopTreenodes.Children);

            for i = 1:length(allItemTypes)
                for thisItemTypeIdx = 1:length(allItemTypes(i).Children)
                    thisItemNode = allItemTypes(i).Children(thisItemTypeIdx);
                    thisItemTypeClass = split(class(thisItemNode.NodeData),'.');
                    thisItemTypeClass = string(thisItemTypeClass(end));
                    typeIdx = cellfun(@(x) thisItemTypeClass==string(x), app.ItemTypes(:,2));
                    type = app.ItemTypes{typeIdx,1};
                    app.updateItemTypePluginMenus(type, thisItemNode, pluginTable);
                end
            end
        end

        function onOpenPluginListDialog(app, Node, thisItemAvailablePlugins)
            [indx,tf] = listdlg('ListString', thisItemAvailablePlugins.Name,...
                'SelectionMode', 'single', ...
                'OKString', 'Apply', ...
                'PromptString', 'Select a plugin to run.');

            if tf
                applyPlugin(app, Node, thisItemAvailablePlugins(indx,:));
            end
        end

        function applyPlugin(app, Node, plugin)
            % Get most recently used plugins for this type and
            % add current plugin to list
            defaultPluginTable = table('Size',[0 5],...
                'VariableTypes',{'string','string','string','string','cell'},...
                'VariableNames',{'Name','Type','File','Description','FunctionHandle'});
            mostRecentPlugins = getpref(app.TypeStr, strcat('recent', strtrim(plugin.Type)), defaultPluginTable);
            mostRecentPlugins = [plugin; mostRecentPlugins];

            % remove function handle column to get unique rows
            [~, ia] = unique(mostRecentPlugins.File, 'stable', 'rows');
            mostRecentPlugins = mostRecentPlugins(ia,:);

            setpref(app.TypeStr, strcat('recent', plugin.Type), mostRecentPlugins);

            % update context menus for all children of this node
            thisNodeParent = Node.Parent;
            for node =1:length(thisNodeParent.Children)
                app.updateItemTypePluginMenus(plugin.Type, thisNodeParent.Children(node), ...
                    QSPViewerNew.Dialogs.PluginManager.getPlugins(app.SelectedSession.PluginsDirectory));
            end

            % if there are multiple selected nodes, apply plugin to all
            % selected nodes of plugin type
            % if there are errors, collect all messages and display at last
            errormsgs = strings; n=1;
            selNodes = app.TreeRoot.SelectedNodes;

            d = uiprogressdlg(app.UIFigure,'Title','Running plugins');
            if length(selNodes)>1
                selNodeData = vertcat(app.TreeRoot.SelectedNodes.NodeData);
                selNodeClasses = arrayfun(@(x) class(x), selNodeData, 'UniformOutput', false);
                selNodeClasses = cellfun(@(x) split(x,'.'), selNodeClasses, 'UniformOutput', false);
                selNodeClasses = cellfun(@(x) x{end}, selNodeClasses, 'UniformOutput', false);
                selNodesThisPluginType = selNodes(matches(string(selNodeClasses), plugin.Type));

                for i = 1:length(selNodesThisPluginType)
                    d.Message = sprintf("Running %s on %s", ...
                        plugin.Name{1}, selNodesThisPluginType(i).NodeData.Name);
                    try
                        plugin.FunctionHandle{1}(selNodesThisPluginType(i).NodeData);
                    catch ME
                        nodeName = sprintf("Error running %s on %s", ...
                            plugin.Name{1}, selNodesThisPluginType(i).NodeData.Name);
                        errormsgs(n) = sprintf("%s\n%s\n", nodeName, ME.message);
                        n=n+1;
                    end
                    d.Value = i/length(selNodesThisPluginType);
                end
            else
                d.Message = sprintf("Running %s on %s", ...
                    plugin.Name{1}, Node.NodeData.Name);
                try
                    plugin.FunctionHandle{1}(Node.NodeData);
                catch ME
                    nodeName = sprintf("Error running %s on %s\n", ...
                        plugin.Name{1}, Node.NodeData.Name);
                    errormsgs(n) = strcat(nodeName, ME.message);
                end
                d.Value = 1;
            end
            if errormsgs~=""
                uialert(app.UIFigure, errormsgs, 'Error applying plugins');
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

        % TODOpax: Why do we need this function?
        function createUntitledSession(app)
            error("ApplicationUI:createUntitledSession");

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
            if isempty(app.SelectedSessionIdx)
                app.SelectedSessionIdx = idxNew;
            end

        end
        
        function createNewSession(app, Session)
            % CREATENEWSESSION  Adds a session to the controller. If none
            % supplied a new one is built.
            arguments
                app
                Session QSP.Session = QSP.Session()
            end
            
            % Add the session to the app
            app.Sessions(end+1) = Session;

            % Need a name for the session. If there is no name on it the
            % controller will assign a name.
            if isempty(Session.Name)
%                 app.initializeName(Session);
                  Session.Name = 'untitled';
                  Session.setSessionName(Session.Name); % why do we have two Names?!
            end

            % Tell the View we have a new session.
            eventData = QSPViewerNew.Application.NewSessionEventData(Session, app.buildingBlockTypes, app.functionalityTypes);
            notify(app, 'NewSession', eventData);            

            % Start timer
            initializeTimer(Session);
        end


        function createFolders(app, Session)
            allFolders = Session.Settings.Folder;

            if ~isempty(allFolders)
                topLevelFoldersIdx = arrayfun(@(x) ischar(x.Parent), allFolders);
                topLevelFolders = allFolders(topLevelFoldersIdx);

                for i = 1:length(topLevelFolders)
                    createFolderNode(app, topLevelFolders(i), Session);
                end
            end
        end

        function createFolderNode(app, thisFolder, Session)
            newFolder = QSP.Folder;
            newFolder.Name = thisFolder.Name;
            newFolder.Parent = thisFolder.Parent;
            newFolder.OldParent = thisFolder.OldParent;
            newFolder.Session = Session;

            if ischar(newFolder.Parent)
                ParentNode = getParentItemNode(newFolder, app.TreeRoot);
            else
                ParentItemNode = getParentItemNode(newFolder, app.TreeRoot);
                folderNodes = getAllChildrenFolderNodes(newFolder, ParentItemNode);
                newFolderParent = newFolder.Parent;
                newFolderParentNodeIdx = arrayfun(@(x) strcmp(x.NodeData.Name, newFolderParent.Name)...
                    && isequal(x.NodeData.Parent, newFolderParent.Parent), folderNodes);
                ParentNode = folderNodes(newFolderParentNodeIdx);
            end

            % Place the item and add the tree node
            if strcmp(ParentNode.Text, 'Deleted Items')
                hNode = app.createNode(ParentNode, newFolder, newFolder.Name, ...
                    QSPViewerNew.Resources.LoadResourcePath('folder_24.png'),...
                    'Deleted', 'Folder', '');
                newFolder.TreeNode = hNode; %Store node in the object for cross-ref
            elseif isscalar(ParentNode)
                app.createTree(ParentNode, newFolder);

                % update "Move to..." context menu
                updateMovetoContextMenu(app,ParentNode);
            else
                error('Invalid tree parent');
            end

            if isa(ParentNode.NodeData, 'QSP.Folder')
                newFolder.Parent = ParentNode.NodeData;
            end

            if isa(newFolder.OldParent, 'QSP.Folder')
                oldParent = newFolder.OldParent;
                ParentItemNode = getParentItemNode(oldParent, app.TreeRoot);
                folderNodes = getAllChildrenFolderNodes(oldParent, ParentItemNode);
                oldParentNodeIdx = arrayfun(@(x) strcmp(x.NodeData.Name, oldParent.Name)...
                    && isequal(x.NodeData.Parent, oldParent.Parent), folderNodes);
                oldParentNode = folderNodes(oldParentNodeIdx);
                newFolder.OldParent.TreeNode = oldParentNode;
            end

            % replace old folder with the new folder under Settings
            Session.Settings.Folder(Session.Settings.Folder==thisFolder) = newFolder;

            % attach all children nodes
            for i = 1:length(thisFolder.Children)
                thisChild = thisFolder.Children(i);

                if isempty(newFolder.Children)
                    newFolder.Children = thisChild;
                else
                    newFolder.Children(end+1) = thisChild;
                end

                if isa(thisChild, 'QSP.Folder')
                    createFolderNode(app, thisChild, Session);
                else
                    ParentItemNode = getParentItemNode(newFolder, app.TreeRoot);
                    if strcmp(ParentItemNode.Text, 'Deleted Items')
                        % create node since it is not already created
                        app.createTree(ParentItemNode, thisChild);
                    end
                    thisChildNodeIdx = arrayfun(@(x) isequal(x.NodeData, thisChild), ParentItemNode.Children);
                    thisChildNode = ParentItemNode.Children(thisChildNodeIdx);

                    thisFolderNodeIdx = arrayfun(@(x) isequal(x.NodeData, newFolder), ParentNode.Children);
                    thisFolderNode = ParentNode.Children(thisFolderNodeIdx);

                    thisChildNode.Parent = thisFolderNode;
                end
            end
        end

        function [StatusOk, Message, Session] = verifyValidSession(app, fullFilePath)
            StatusOk = true;
            Message='';
            Session=[];

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

            %If any of the above failed, we exit and display why
            if StatusOk == false
                uialert(app.UIFigure, Message, 'Invalid File')
            else
                %We have verified the session path, now verify the root
                %directory
                [StatusOk,newRootDir] = app.getValidSessionRootDirectory(loadedSession.Session.RootDirectory);
                Session = copy(loadedSession.Session);
                Session.RootDirectory = newRootDir;
            end
        end

        function loadSessionFromPath(app, fullFilePath)
            % Loads a session file from disk found at fullFilePath.
            sessionStatus = app.verifyValidSessionFilePath(fullFilePath);

            if sessionStatus
                %Try to load the session
                [StatusOk, Message, Session] = verifyValidSession(app, fullFilePath);
                if StatusOk == false
                    uialert(app.UIFigure, Message, 'Invalid File')
                else
                    % check if autosave more recent than session file exists
                    [~,autosaveSessName,ext] = fileparts(fullFilePath);
                    autosaveSessName = insertBefore(autosaveSessName, ".qsp", "_autosave");

                    asvFullPath = fullfile(Session.AutoSaveDirectory, [autosaveSessName, ext]);

                    % if autosave exists and not already loaded in the app
                    if exist(asvFullPath, 'file') && ~ismember(asvFullPath, app.SessionPaths)
                        asvMeta = dir(asvFullPath);
                        sessionMeta = dir(fullFilePath);

                        % if more autosave is more recent than session
                        if asvMeta.datenum > sessionMeta.datenum
                            selection = uiconfirm(app.UIFigure, ...
                                "The there exists a more recent autosave for the session. Do you want to load it instead?", ...
                                "Load autosave", ...
                                'Options', {'Yes', 'No (Open original Session)'},...
                                'DefaultOption',2);

                            if strcmp(selection, 'Yes')
                                [StatusOk, Message, asvSession] = verifyValidSession(app, asvFullPath);
                                if StatusOk == false
                                    uialert(app.UIFigure, strcat(Message, " Using original session file."), ...
                                        'Invalid Autosave File');
                                else
                                    fullFilePath = asvFullPath;
                                    Session = asvSession;
                                end
                            end
                        end
                    end

                    app.createNewSession(Session);

                    %Edit the app properties to reflect a new loaded session was
                    %added
                    idxNew = app.NumSessions + 1;
                    app.SessionPaths{end+1} = fullFilePath;
                    app.IsDirty(end+1) = false;
                    app.SelectedSessionIdx = idxNew;
                    app.addRecentSessionPath(fullFilePath);
                end
            end
            app.refresh();

            % Todopax deal with plugin manager separately
%             % check if an instance of plugin  manager is
%             % running
%             if isvalid(app.PluginManager)
%                 app.PluginManager.Sessions = app.Sessions;
%             else
%                 pluginTable = ...
%                     QSPViewerNew.Dialogs.PluginManager.getPlugins(Session.PluginsDirectory);
%                 updateAllPluginMenus(app, app.Sessions(idxNew), pluginTable)
%             end
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

        function [status,newFilePath] = getValidSessionRootDirectory(app, filePath)
            %Check if a directory exists. If not, find a valid one.
            existence = exist(filePath,'dir');

            %Check if the directory exists
            if existence

                %If the directory exists, we set the output values
                status =true;
                newFilePath = filePath;
            else
                questionResult = uiconfirm(app.getUIFigure(),'Session root directory is invalid. Select a new root directory?',...
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
                        uialert(app.getUIFigure,'The newly selected root directory was not valid','Invalid Directory');
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
            app.RecentSessionPaths(9:end) = []; %todopax parameterize this 9

            %redraw this context menu
            %             app.redrawRecentFiles() TODOpax
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
%             app.SessionPaths(sessionIdx) = []; % TODOpax
%            app.IsDirty(sessionIdx) = [];

% Send an event to let the plugin manager know.
%             % update sessions in plugin manager if it is open
%             if isvalid(app.PluginManager)
%                 app.PluginManager.Sessions = app.Sessions;
%             end


            %update app
            % TODOpax: Why do we need this?
            %             app.refresh();
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

        %TODOpax. What is this trying to do?
        function disableInteraction(app)
            % TODOpax
            %             app.TreeRoot.Enable = 'off';
            %             app.FileMenu.Enable = 'off';
            %             app.QSPMenu.Enable = 'off';
        end

        %TODOpax. What is this trying to do?
        function enableInteraction(app)
            % TODOpax
            %             app.TreeRoot.Enable = 'on';
            %             app.FileMenu.Enable = 'on';
            %             app.QSPMenu.Enable = 'on';
        end

        function changeInBackEnd(app,newObject)
            %This function is for other classes to provide a new session to
            %be added to session and corresponding tree
            
            %todopax hack for now
            app.SelectedSessionIdx = 1;

            switch class(newObject)
                %We have a new backend object to attach to the tree.
                case 'QSP.Session'
                    % check if plugins directory has changed
                    oldPluginsDirectory = app.Sessions(app.SelectedSessionIdx).PluginsDirectory;
                    newPluginsDirectory = newObject.PluginsDirectory;

                    %1.Replace the current Session with the newSession
                    app.Sessions(app.SelectedSessionIdx) = newObject;
                    newObject.updateLoggerFileDir(); % move logger file if root directory is changed

                    %2. It must update the tree to reflect all the new values from
                    %the session
                    app.updateTreeData(app.TreeRoot.Children(app.SelectedSessionIdx),newObject,'Session')

                    % update context menus if plugins directory had changed
                    if ~isequal(oldPluginsDirectory, newPluginsDirectory)
                        % check if an instance of plugin  manager is
                        % running
                        if isvalid(app.PluginManager)
                            app.PluginManager.Sessions = app.Sessions;
                        else
                            pluginTable = ...
                                QSPViewerNew.Dialogs.PluginManager.getPlugins(newPluginsDirectory);
                            updateAllPluginMenus(app, app.Sessions(app.SelectedSessionIdx), pluginTable)
                        end
                    end

                    app.refresh();
                case 'QSP.VirtualPopulation'
                    NewVirtualPopulation = newObject;

                    for idx = 1:numel(NewVirtualPopulation)
                        thisVpop = NewVirtualPopulation(idx);

                        thisSession = NewVirtualPopulation(idx).Session;
                        isbuildBlockNode = string({thisSession.TreeNode.Children.Text})=="Building blocks";
                        buildBlockNode = thisSession.TreeNode.Children(isbuildBlockNode);
                        virtualSubParentNode = buildBlockNode.Children(string({buildBlockNode.Children.Text})=="Virtual Subject(s)");

                        app.onAddItem(virtualSubParentNode,thisSession,thisVpop)

                        app.updateVpopFolderStructure(virtualSubParentNode);
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

        % todopax
        function refresh(app)
            %This method refreshes the view of the screen
            if app.IsConstructed
                %Update the names displayed in the tree
%                 app.updateTreeNames(); todopax

                %Update the file menu
%                 app.updateFileMenu();

                %Update the title of the application
%                 app.updateAppTitle();

                %Update the current shown frame
%                 app.updatePane();

%                 drawnow();
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

        %         function updateFolderContextMenus(app, treeNode)
        %             allChildren = {treeNode.Children.NodeData};
        %             isfolderIdx = cellfun(@(x) isa(x, 'QSP.Folder'), allChildren);
        %
        %             if any(isfolderIdx)
        %                 allTopFolders = treeNode.Children(isfolderIdx);
        %                 allItems = QSPViewerNew.Application.getAllChildrenItemTypeNodes(treeNode);
        %                 for itemNodeIdx = 1:length(allItems)
        %                     currentNode = allItems(itemNodeIdx);
        %                     CM = currentNode.ContextMenu;
        %                     m = uimenu('Parent',CM,'Label', 'Move to');
        %                     for folderIdx = 1:length(allTopFolders)
        %                         uimenu('Parent',m,'Label', allTopFolders(folderIdx).Text);
        %                     end
        %                 end
        %             end
        %
        %             CM = uicontextmenu('Parent',app.UIFigure);
        %             uimenu('Parent',CM,'Label', ['Add new ' ParentItemType],...
        %                 'MenuSelectedFcn', @(h,e)app.onAddItem(h.Parent.UserData,Node.NodeData.Session,ParentItemType));
        %
        %         end
        %
        %

        % todopax.. look at replacing this.
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

        % TODOpax. move this to viewpane manager.
        function updatePane(app, paneParent, selectedNode)
            arguments
                app
                paneParent
                selectedNode (1,1) matlab.ui.container.TreeNode
            end
            %             %Find the currently selected Node
            %             NodeSelected = app.TreeRoot.SelectedNodes;
            %             if length(NodeSelected)>1
            %                 NodeSelected = NodeSelected(end); % TODOpax rather arbitrary descison here.
            %             end

            %Determine if the Node will launch a Pane
            funcNames = ["Simulation", "Optimization", "VirtualPopulationGeneration", "GlobalSensitivityAnalysis", "CohortGeneration"];
            isFuncTopnode = any(matches(funcNames, string(selectedNode.UserData)));
            LaunchPaneTF = isempty(selectedNode.UserData) || isFuncTopnode;

            app.launchNewPane(paneParent, selectedNode);

            if false
                %If we shouldnt launch a pane and there is currently a pane,
                %close it
                if ~LaunchPaneTF && ~isempty(app.ActivePane)
                    app.ActivePane.hideThisPane();
                    app.ActivePane = [];
                elseif LaunchPaneTF
                    %Determine if the pane type has already been loaded
                    PaneType = app.getPaneClassFromQSPClass(class(selectedNode.NodeData));
                    idxPane = app.PaneTypes(strcmp(app.PaneTypes,PaneType));
                    if isempty(idxPane)
                        %Launch a new Pane with the data provided
                        if isFuncTopnode
                            app.launchNewPane(selectedNode);
                        else
                            app.launchNewPane(selectedNode.NodeData);
                        end
                    else
                        if isFuncTopnode
                            app.launchOldPane(selectedNode);
                        else
                            %Launch a pane that already exists with the new data
                            app.launchOldPane(selectedNode.NodeData);
                        end
                    end
                end
            end
        end



% 


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

        % TODOpax, this should be done via an event not wholesale like
        % this.
        function updateTreeNames(app)
            % Update the title of each session to reflect if its dirty
            for idx=1:numel(app.Sessions)

                % Get the session name for this node
                foo = app.SessionNames{idx};
                ThisRawName = app.Sessions(idx).Name;
                ThisName = ThisRawName;

                % Add dirty flag if needed
                if true %app.IsDirty(idx) % TODOpax move to event based.
                    ThisName = strcat(ThisName, ' *');
                end

                %Update the Node
                app.SessionNode(idx).Text = ThisName;

                %Assign the new name
                setSessionName(app.Sessions(idx),ThisRawName);
            end
            updateLoggerSessions(app);

            %Update the selected node's name in the tree based on the
            %name,unless it is a session
            if ~isempty(app.TreeRoot.SelectedNodes)
                SelNode = app.TreeRoot.SelectedNodes(end);
            else
                SelNode =[];
            end
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
                ItemClass = strrep(class(ThisObj), 'QSP.', '');
                ItemType = ItemTypes{strcmpi(ItemClass,ItemTypes(:,2)),1};

                % Where does the item go?
                if isprop(session,ItemType)
                    ParentObj = session ;
                    SuperParentArray = ParentObj.TreeNode.Children;
                    ChildTags = {SuperParentArray.Tag};
                    SuperParent = SuperParentArray(strcmpi(ChildTags,'Functionalities'));
                    ParentArray = SuperParent.Children;
                    ParentArrayTypes = {ParentArray.Tag};
                    ParentNode = ParentArray(strcmp(ParentArrayTypes,ItemType));
                    allChildNames = {ParentObj.(ItemType).Name};
                elseif strcmp(ItemType, "Folder")
                    restoreFolderNodes(app, node);

                    if ischar(ThisObj.Parent)
                        ParentNode = getParentItemNode(ThisObj, app.TreeRoot);
                    else
                        ParentNode = ThisObj.Parent.TreeNode;
                    end

                    if ~isempty(ParentNode.Children)
                        allChildren = {ParentNode.Children.NodeData};
                        allFoldersIdx = cellfun(@(x) isa(x, 'QSP.Folder'),allChildren );
                        if ~any(allFoldersIdx)
                            allChildNames = '';
                        else
                            allFolders = [allChildren{allFoldersIdx}];
                            allChildNames = {allFolders.Name};
                        end
                    else
                        allChildNames = '';
                    end

                    ParentObj = session.Settings;
                else
                    ParentObj = session.Settings;
                    ParentArray = ParentObj.TreeNode.Children;
                    ParentArrayTypes = {ParentArray.Tag};
                    ParentNode = ParentArray(strcmp(ParentArrayTypes,ItemType));
                    allChildNames = {ParentObj.(ItemType).Name};
                end

                % Update the name to include the timestamp
                TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');

                % Strip out date
                SplitName = regexp(ThisObj.Name,'\(\d\d-\D\D\D-\d\d\d\d_\d\d-\d\d-\d\d\)','split');
                if ~isempty(SplitName) && iscell(SplitName)
                    SplitName = SplitName{1}; % Take first
                end
                ThisObj.Name = strtrim(SplitName);

                ThisObj.Name = sprintf('%s (%s)',ThisObj.Name,TimeStamp);

                % check for duplicate names
                if any(strcmp(ThisObj.Name, allChildNames))
                    uialert(app.UIFigure,'Cannot restore deleted item because its name is identical to an existing item.','Restore');
                    return;
                end

                if ~strcmp(ItemType, "Folder")
                    % Move the object from deleted to the new parent
                    % for folders, this is already done in restoreFolderNodes
                    ParentObj.(ItemType)(end+1) = ThisObj;
                end

                MatchIdx = false(size(session.Deleted));
                for idx = 1:numel(session.Deleted)
                    MatchIdx(idx) = session.Deleted(idx)==ThisObj;
                end
                session.Deleted( MatchIdx ) = [];

                % Update the tree
                node.Parent = ParentNode;
                ParentNode.expand();

                % Change context menu
                delete(node.UIContextMenu.Children);
                app.createContextMenu(node, ItemType);

                % Update the display
                app.refresh();
                app.markDirty(session);
            catch ME
                ThisSession = node.NodeData.Session;
                loggerObj = QSPViewerNew.Widgets.Logger(ThisSession.LoggerName);
                loggerObj.write(node.Text, ItemType ,ME)
            end
        end

        function restoreFolderNodes(app, node)
            ThisObj = node.NodeData;
            % old parent becomes current parent when restoring
            oldParent = ThisObj.Parent;
            ThisObj.Parent = ThisObj.OldParent;
            ThisObj.OldParent = oldParent;

            % loop through all children
            for i = 1:length(node.Children)
                thisChild = node.Children(i);
                if isa(thisChild.NodeData, 'QSP.Folder')
                    restoreFolderNodes(app, thisChild);
                else
                    ParentNode = getParentItemNode(ThisObj, app.TreeRoot);
                    ItemType = ParentNode.Tag;
                    ParentObj = ParentNode.NodeData;
                    ParentObj.(ItemType)( end+1 ) = thisChild.NodeData;
                end
            end

            node.NodeData.Session.Settings.Folder(end+1) = ThisObj;
        end

        function duplicateNode(app,Node,~)

            % What type of item?
            ParentNode = Node.Parent;
            while isa(ParentNode.NodeData, 'QSP.Folder')
                ParentNode = ParentNode.Parent;
            end
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
            ParentNode = Node.Parent;
            while isa(ParentNode.NodeData, 'QSP.Folder')
                ParentNode = ParentNode.Parent;
            end
            ParentObj = ParentNode.NodeData;

            % Move the object from its parent to deleted
            session.Deleted(end+1) = ThisObj;
            if ~strcmp(ItemType, "Folder")
                ParentObj.(ItemType)( ParentObj.(ItemType)==ThisObj ) = [];
            else
                deleteFolderNodes(app, Node)
            end
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

        function deleteFolderNodes(app, node)
            % loop through all children
            for i = 1:length(node.Children)
                thisChild = node.Children(i);
                if isa(thisChild.NodeData, 'QSP.Folder')
                    deleteFolderNodes(app, thisChild);
                else
                    ParentNode = getParentItemNode(node.NodeData, app.TreeRoot);
                    ItemType = ParentNode.Tag;
                    ParentObj = ParentNode.NodeData;
                    ParentObj.(ItemType)( ParentObj.(ItemType)==thisChild.NodeData ) = [];
                end
            end

            node.NodeData.OldParent = node.NodeData.Parent;
            allFolders = node.NodeData.Session.Settings.Folder;
            nodeFolderIdx = arrayfun(@(x) isequal(x.Parent, node.NodeData.Parent)&&...
                strcmp(x.Name, node.NodeData.Name), allFolders);

            node.NodeData.Session.Settings.Folder(nodeFolderIdx).Parent = 'Deleted Items';
            node.NodeData.Session.Settings.Folder(nodeFolderIdx) = [];
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
                    loggerObj = QSPViewerNew.Widgets.Logger(session.Session.LoggerName);
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

        function updateMovetoContextMenu(app,currentNode)
            allItemTypeTags = {'Task'; 'Parameters'; 'OptimizationData'; 'VirtualPopulationData'; ...
                'VirtualPopulationGenerationData'; 'VirtualPopulation'; 'Simulation'; 'Optimization'; ...
                'CohortGeneration'; 'VirtualPopulationGeneration'; 'GlobalSensitivityAnalysis'};
            while ~ismember(currentNode.Tag, allItemTypeTags)
                currentNode = currentNode.Parent;
            end

            parentNode = currentNode;
            isfolderIdx = arrayfun(@(x) isa(x.NodeData, 'QSP.Folder'), parentNode.Children);

            allChildNodes = app.getAllChildrenItemTypeNodes(parentNode);

            if any(isfolderIdx)
                for i = 1:length(allChildNodes)
                    thisNode = allChildNodes(i);
                    isMovetoMenu = arrayfun(@(x) strcmp(x.Text, 'Move to ...'), thisNode.ContextMenu.Children);
                    thisNode.ContextMenu.Children(isMovetoMenu).Enable = 'on';
                end
            else
                for i = 1:length(allChildNodes)
                    thisNode = allChildNodes(i);
                    isMovetoMenu = arrayfun(@(x) strcmp(x.Text, 'Move to ...'), thisNode.ContextMenu.Children);
                    thisNode.ContextMenu.Children(isMovetoMenu).Enable = 'off';
                end
            end

        end

        function nodes = getAllChildrenItemTypeNodes(app, node)
            % get all item type children nodes below "node"
            nodes = [];
            for i = 1:length(node.Children)
                currentNode = node.Children(i);
                if ~isa(currentNode.NodeData, 'QSP.Folder')
                    nodes = [nodes; currentNode];
                else
                    nodes = [nodes; getAllChildrenItemTypeNodes(app, currentNode)];
                end
            end
        end

        function updateVpopFolderStructure(app, parentVpopNode)
            allChildrenInit = parentVpopNode.Children;
            for i = 1:length(allChildrenInit)
                if ~isa(allChildrenInit(i).NodeData, 'QSP.Folder')
                    thisVpop = allChildrenInit(i).NodeData;
                    if contains(thisVpop.Name, "Results -")
                        allChildren = thisVpop.TreeNode.Parent.Children;
                        sourceNodeName = extractBetween(thisVpop.Name, "= ", " ");
                        isExistSourceFolder = false;

                        if ~isempty(sourceNodeName)
                            % check if a folder exists with this name
                            isfolderidx = arrayfun(@(x) isa(x.NodeData, 'QSP.Folder'), allChildren);
                            if any(isfolderidx)
                                allFolders = allChildren(isfolderidx);
                                isSourceFolderIdx = arrayfun(@(x) strcmp(x.NodeData.Name,sourceNodeName{1}), ...
                                    allFolders);
                                if any(isSourceFolderIdx)
                                    isExistSourceFolder = true;
                                    SourceFolder = allFolders(isSourceFolderIdx).NodeData;
                                end
                            end
                        end

                        if ~isExistSourceFolder
                            SourceFolder = onAddFolder(app,parentVpopNode,thisVpop.Session,false);
                            SourceFolder.TreeNode.Text = sourceNodeName{1};
                            SourceFolder.Name = sourceNodeName{1};
                        end

                        thisVpop.TreeNode.Parent = SourceFolder.TreeNode;
                        expand(SourceFolder.TreeNode);
                    end
                end
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
                case 'QSP.Folder'
                    PaneClass = 'QSPViewerNew.Application.FolderPane';
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
            [~,value,ext] = cellfun(@fileparts, app.SessionPaths,'UniformOutput', false);
            value = strcat(value,ext);
            warning('deprecating this function');
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
            if ~isempty(app.Panes)
                value = cellfun(@class, app.Panes, 'UniformOutput', false);
            else
                value = [];
            end
        end

        function setCurrentSessionDirty(app)
            app.IsDirty(app.SelectedSessionIdx) = true;
        end

        function setCurrentSessionClean(app)
            app.IsDirty(app.SelectedSessionIdx) = true;
        end

        function value = getUIFigure(app) %todopax rename getViewTopElement
            % GETUIFIGURE  For the purpose of showing alerts and confirm
            % dialogs, the controller uses the view's top level window,
            % i.e. UIFigure.            
            value = app.OuterShell.UIFigure;
        end

    end

end
