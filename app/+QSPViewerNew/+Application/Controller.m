classdef Controller < handle
    % Controller - This is the Controller class for gQSPSim.

    properties (SetAccess = private)
        Sessions (1,:) QSP.Session = QSP.Session.empty(0,1)
        Title
        SelectedNodePath (1,1) string
        ItemTypes cell
        UseUI (1,1) logical = true;
    end

    properties(Transient)
        IsDirty = logical.empty(0,1);
    end

    properties(Constant)
        AppName = "gQSPSim"
        Version = 'v2.0'
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

        PreferencesGroupName (1,1) string  = "gQSPSim_preferences";
    end

    properties (SetAccess = private)
        AllowMultipleSessions = true;
        FileSpec ={'*.mat','MATLAB MAT File'}
        SelectedSessionIdx = double.empty(0,1)
        SessionPaths (:,1) string = string.empty(0,1) % Stores the fullPath of the Session on disk (if on disk)
        RecentSessionPaths = string.empty(0,1)
        LastFolder = pwd
        Type % replaced with PreferencesGroupName
        TypeStr %todopax remove.
        WindowButtonDownCallbacks = {}; % TODOpax remove this
        WindowButtonUpCallbacks = {}; % TODOpax remove this

        OuterShell QSPViewerNew.Application.MainView
        ModelManagerDialog ModelManager
        LoggerDialog QSPViewerNew.Dialogs.LoggerDialog
    end

    properties (SetAccess = private, Dependent = true, AbortSet = true)
        %         SelectedSessionName
        SelectedSessionPath
        NumSessions %TODOpax remove
        %         SessionNames %TODOpax remove
        SelectedSession
        %         SessionNode % TODOpax remove
        %         PaneTypes %TODOpax remove
    end

    properties (SetAccess = private, SetObservable, AbortSet)
        PluginManager QSPViewerNew.Dialogs.PluginManager
    end

    properties (Hidden, SetAccess = private, Transient, NonCopyable)
        % listener handle for Sessions property
        SessionsListener

        % listener handle for PluginTableData property
        PluginTableDataListener event.listener

        aboutMessage = [
            "gQSPsim version "
            ""
            "http://www.github.com/gQSPsim/gQSPsim"
            ""
            "Authors:"
            ""
            "Justin Feigelman (feigelman.justin@gene.com)"
            "Iraj Hosseini (hosseini.iraj@gene.com)"
            "Anita Gajjala (agajjala@mathworks.com)"];
    end

    events
        Model_NewSession
        Model_NewItemAdded
        Model_SessionClosed
        Model_ItemDeleted
        Model_ItemRestored
        Model_DeletedItemsDeleted

        Controller_RecentSessionPathsChange

        CleanSessions
        DirtySessions
    end

    % Constructor / Destructor
    methods (Access = public)
        function app = Controller(useUI)
            arguments
                useUI (1,1) logical = true
            end

            % Store this state because there are a small number of uses for
            % ui elements in the controller. Technically a bad thing to do
            % but the use is limited to {uialert, uiconfirm, uigetfile}.
            % Consider removing those uses and also removing the UseUI
            % state from this class.
            app.UseUI = useUI;

            app.Title = app.AppName + " " + app.Version;
            app.FileSpec = {'*.qsp.mat','MATLAB QSP MAT File'};
            app.ItemTypes = vertcat(app.buildingBlockTypes, app.functionalityTypes);

            app.loadPreferences();

            % Construct the view. The app (i.e. controller) is supplied to the View
            % constructor for the purpose of connecting listeners. The app
            % should not (and is not) stored by the View.
            if useUI
                app.OuterShell = QSPViewerNew.Application.MainView(app);
                % Listen to these events from the View.
                addlistener(app.OuterShell, 'New_Request',       @(h,e)app.createNewSession);
                addlistener(app.OuterShell, 'AddTreeNode',       @(h,e)app.onAddItemNew(e));
                addlistener(app.OuterShell, 'OpenModelManager',  @(h,e)app.onOpenModelManager(e));
                addlistener(app.OuterShell, 'OpenPluginManager', @(h,e)app.onOpenPluginManager);
                addlistener(app.OuterShell, 'OpenLogger',        @(h,e)app.onOpenLogger);

                addlistener(app.OuterShell, 'Close_Request',     @(h,e)app.onCloseRequest(e));
                addlistener(app.OuterShell, 'Open_Request',      @(h,e)app.onOpenRequest);
                addlistener(app.OuterShell, 'OpenFile_Request',  @(h,e)app.onOpenWithFileRequest(e));
                addlistener(app.OuterShell, 'Exit_Request',      @(h,e)app.onExit);
                addlistener(app.OuterShell, 'Save_Request',      @(h,e)app.onSaveRequest(e));
                addlistener(app.OuterShell, 'SaveAs_Request',    @(h,e)app.onSaveRequest(e));

                addlistener(app.OuterShell, 'Delete_Request',    @(h,e)app.onDeleteItem(e));
                addlistener(app.OuterShell, 'Restore_Request',   @(h,e)app.onRestoreItem(e));
                addlistener(app.OuterShell, 'PermanentlyDelete_Request', @(h,e)app.onEmptyDeletedItems(e));
                addlistener(app.OuterShell, 'Duplicate_Request', @(h,e)app.onDuplicateItem(e));
                
                addlistener(app.OuterShell, 'GitStateChange',         @(h,e)app.onGitStateChange(e));
                addlistener(app.OuterShell, 'UseParallelStateChange', @(h,e)app.onUseParallelStateChange(e));

                % Notify with initialization values
                notify(app, 'Controller_RecentSessionPathsChange', QSPViewerNew.Application.RecentSessionPaths_EventData(app.RecentSessionPaths));
            end
        end

        % TODOpax remove this when done. This is helpful to me since it avoids the RootDirectory issue.
        function forDebuggingInit(app)
            app.loadSession('tests/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD_pax.qsp.mat')
        end

        function delete(app)
            % Controller destructor. Save preferences and close down the UI
            % if it is open.
            % Note that this destructor only stores preferences for state
            % owned by the controller. 
            setpref(app.PreferencesGroupName, 'LastFolder',         app.LastFolder);
            setpref(app.PreferencesGroupName, 'RecentSessionPaths', app.RecentSessionPaths);            

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

        function addFolder(app)
            ed = QSPViewerNew.Application.NewItemEventData(app.Sessions(1), "Task:Folder");
            app.onAddItemNew(ed);
        end

        function newSession(app)
            app.createNewSession();
        end

        function addSession(app, session)
            arguments
                app
                session (1,1) QSP.Session
            end
            app.createNewSession(session);
        end

        function loadSession(app, fullFilePath)
            arguments
                app
                fullFilePath (1,1) string
            end
            % Loads a session file from disk found at fullFilePath.
            sessionStatus = app.verifyValidSessionFilePath(fullFilePath);

            if sessionStatus
                %Try to load the session
                [StatusOk, Message, Session] = verifyValidSession(app, fullFilePath);
                if StatusOk == false
                    if app.UseUI
                        uialert(app.UIFigure, Message, 'Invalid File')
                    else
                        error(Message);
                    end
                else
                    % check if autosave more recent than session file exists
                    [~,autosaveSessName,ext] = fileparts(fullFilePath);
                    autosaveSessName = insertBefore(autosaveSessName, ".qsp", "_autosave");

                    asvFullPath = fullfile(Session.AutoSaveDirectory, autosaveSessName + ext);

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
                                    if app.UseUI
                                        uialert(app.UIFigure, strcat(Message, " Using original session file."), 'Invalid Autosave File');
                                    else
                                        error(Message);
                                    end
                                else
                                    fullFilePath = asvFullPath;
                                    Session = asvSession;
                                end
                            end
                        end
                    end

                    app.createNewSession(Session, fullFilePath);

                    %Edit the app properties to reflect a new loaded session was
                    %added
                    % This all should be happening in createNewSession.
                    %                     idxNew = app.NumSessions + 1;
                    %                     app.SessionPaths{end+1} = fullFilePath;
                    %                     app.SelectedSessionIdx = idxNew;
                    %                     app.addRecentSessionPath(fullFilePath);
                end
            end

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
    end

    methods (Access = private)
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

        function loadPreferences(app)            
            % Migrate old preferences to the new name.
            allPreferences = string(fieldnames(getpref));
            qspViewerNewTF = allPreferences.contains("QSPViewerNew");
            if any(qspViewerNewTF)
                app.migrateOldPreferences(allPreferences(qspViewerNewTF));
            end            

            if ispref(app.PreferencesGroupName)
                preferences = getpref(app.PreferencesGroupName);

                if isfield(preferences, "LastFolder")
                    app.LastFolder = preferences.LastFolder;
                end

                if isfield(preferences, "RecentSessionPaths")
                    app.RecentSessionPaths = string(preferences.RecentSessionPaths);
                    % Remove invalid file paths
                    idxOkTF = arrayfun(@(x)isfile(x), app.RecentSessionPaths);
                    app.RecentSessionPaths(~idxOkTF) = [];
                end
            end
        end

        function migrateOldPreferences(app, oldPreferencesName)
            % This will migrate old preferences for v2.0 (i.e. based on
            % QSPViewerNew) to the new lable for the preferences and will
            % clean up the old names. 
            for i = 1:numel(oldPreferencesName)
                prefName = oldPreferencesName(i);
                switch prefName
                    case "QSPViewerNew_Dialogs_LoggerDialog"
                        loggerPosition = getpref(prefName).Position;
                        setpref(app.PreferencesGroupName, 'LoggerPosition', loggerPosition);
                        rmpref(prefName);

                    case "QSPViewerNew_Dialogs_PluginManager"
                        pluginManagerPosition = getpref(prefName).Position;
                        setpref(app.PreferencesGroupName, 'PluginManagerPosition', pluginManagerPosition);
                        rmpref(prefName);

                    case "QSPViewerNew_Application_ApplicationUI"
                        rmpref(prefName);
                end
            end
        end
    end

    % Event handlers
    % TODOpax: some methods in here are not event handlers.
    methods (Access = private)
        function onOpenWithFileRequest(app, eventData)
            path = eventData.Paths;
            if exist(path, 'file')
                app.loadSession(path);
            else
                % send alert
            end
        end

        function onOpenRequest(app)
            % Allow the controller to call this ui utility. We could hide
            % this implemenation in a utility package but there is little
            % need for that overhead.
            if ~app.UseUI
                disp('This function cannot be called without the UI.')
                return
            end

            [FileName, PathName] = uigetfile(app.FileSpec, 'Open File', app.LastFolder, 'MultiSelect', 'on');

            % If the user did not cancel
            if ~isequal(FileName, 0)

                switch class(FileName)
                    case 'char'
                        app.LastFolder = PathName;
                        fullFilePath = fullfile(PathName,FileName);
                        app.loadSession(fullFilePath);
                    case 'cell'
                        app.LastFolder = PathName;
                        for fileIndex = 1:numel(FileName)
                            fullFilePath = fullfile(PathName,FileName{fileIndex});
                            app.loadSession(fullFilePath);
                        end
                end
            end
        end

        function onCloseRequest(app, eventData)
            % Close a session. If it is dirty ask to save.
            sessionIndex = app.getSessionIndex(eventData.Session);

            if app.IsDirty(sessionIndex)
                app.savePromptBeforeClose(sessionIndex);
            else
                app.closeSession(sessionIndex);
            end
        end

        function onSaveRequest(app, eventData)
            % Save the supplied session. This function
            % handles both save and saveas. 

            sessionIndex = app.getSessionIndex(eventData.Session);

            if eventData.EventName == "Save_Request"
                requestSaveAs = false;
            elseif eventData.EventName == "SaveAs_Request"
                requestSaveAs = true;
            end

            statusTF = app.saveSession(sessionIndex, requestSaveAs);

            % TODOpax: need to think about what handling is needed if
            % statusTF is false.

            if statusTF
                app.IsDirty(sessionIndex) = false;
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

        function onDeleteItem(app, eventData)
            activeSession = eventData.Session;

            activeNodes = eventData.Items;

            for i = 1:length(activeNodes)
                app.deleteNode(activeNodes(i), activeSession);
            end

        end

        function onRestoreItem(app, eventData)
            activeSession = eventData.Session;

            activeNodes = eventData.Items;

            for i = 1:length(activeNodes)
                app.restoreNode(activeNodes(i), activeSession)
            end
        end

        function onOpenModelManager(app, eventData)
            % Open the ModelManager UI.
            session = eventData.Session;
            rootDir = session.RootDirectory;
            % Used to handle empty rootDir. Why? What does the ModelManager
            % do with an empty RootDir?

            % Allow only one instance of the ModelManager
            if isempty(app.ModelManagerDialog) || ~isvalid(app.ModelManagerDialog)
                app.ModelManagerDialog = ModelManager(rootDir);
            end
        end

        function onAddItemNew(app, eventData)
            % ONADDITEMNEW Add a new item to the model. The parent session
            % and the type are provided in the eventData.
            arguments
                app
                eventData (1,1) QSPViewerNew.Application.NewItemEventData
            end

            newItemPrefix = "New ";

            session = eventData.Session;
            itemType = eventData.type;

            % The Model should provide a way to add to its structure, but
            % that is not the case right now so handle it here at the
            % expense of some technical debt. If the model were
            % to have this add functionality then it would be the one
            % notifying the controller about the addition.
            % Also, the model does not support default names.
            % Rather than adding it in the Model deal with it here, but
            % that is more technical debt.
            buildingBlockType_TF = strcmp(itemType, app.buildingBlockTypes(:,2));
            functionalityType_TF = strcmp(itemType, app.functionalityTypes(:,2));

            if any(buildingBlockType_TF)
                newName = newItemPrefix + app.buildingBlockTypes(buildingBlockType_TF, 1);
                currentIndex = sum(string({session.Settings.(itemType).Name}).contains(newName));
                if currentIndex > 0
                    newName = newName + "_" + currentIndex;
                end
                newItem = QSP.(itemType)('Name', char(newName));
                session.Settings.(itemType)(end+1) = newItem;
            
            elseif any(functionalityType_TF)
                newName = char(newItemPrefix + app.functionalityTypes(functionalityType_TF, 1));
                currentIndex = sum(string({session.(itemType).Name}).contains(newName));
                if currentIndex > 0
                    newName = newName + "_" + currentIndex;
                end
                newItem = QSP.(itemType)('Name', char(newName));
                session.(itemType)(end+1) = newItem;

                % This is probably not needed but the old code did it and
                % changing this would be a lot of work, so maintain this
                % for now. Hand a reference to the session.Settings to the
                % functionality nodes.
                newItem.Settings = session.Settings;
            
            elseif itemType.contains(":Folder")
                qspType = "Folder";
                folderType = itemType.extractBefore(":Folder");
                newName = char(newItemPrefix + " Folder");
                newItem = QSP.(qspType)('Name', char(newName));
                % if parentFolder is a buildingblock or functionality this
                % will work. If parentFolder is a "user" folder then need
                % to find it based on the parentFolder name.
                session.Settings.(folderType)(end+1) = newItem;
            end

            % I would prefer if the session is not stored in the items but
            % a lot of code depends on this now.
            % TODOpax: remove this from the model.
            newItem.Session = session;

            app.IsDirty(app.Sessions == session) = true;

            notify(app, 'Model_NewItemAdded', QSPViewerNew.Application.NewItemAddedEventData(newItem, itemType)); % todopax would be nice if we don't need itemType
        end

        function ThisFolder = onAddFolder(app,thisSession,TfAcceptName)

            % suspect code duplication with createFolderNode
            app.createFolderNode();

            ParentNode = thisSession.Settings.Task;

            ThisFolder = QSP.Folder;
            if isa(ParentNode, 'QSP.Folder')
                ThisFolder.Name = 'SubFolder';
                if isempty(ParentNode.Children)
                    ParentNode.Children = ThisFolder;
                else
                    ParentNode.Children(end+1) = ThisFolder;
                end
                ThisFolder.OldParent = ThisFolder.Parent;
                ThisFolder.Parent = ParentNode.NodeData;
            else
                ThisFolder.OldParent = ThisFolder.Parent;
                %todopax: ThisFolder.Parent = ParentNode.Text;
            end

            ThisFolder.Session = thisSession; % todopax: why do we need to store the session in the folder

            % todopax: Why do we care about the children here?
            %             if false
            %                 if ~isempty(ParentNode.Children)
            %                     allChildren = {ParentNode.Children.NodeData};
            %                     allFoldersIdx = cellfun(@(x) isa(x, 'QSP.Folder'),allChildren );
            %
            %                     if any(allFoldersIdx)
            %                         allFolders = [allChildren{allFoldersIdx}];
            %                         DisallowedNames = {allFolders.Name};
            %                         NewName = matlab.lang.makeUniqueStrings(ThisFolder.Name, DisallowedNames);
            %                         ThisFolder.Name = NewName;
            %                     end
            %                 end
            %             end

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

            % finish this pax
            app.IsDirty()

            % Update the display
            app.updateTreeNames();

            %Update the file menu
            app.updateFileMenu();

            %Update the title of the application
            app.updateAppTitle();

        end

        function onMoveFolder(app, thisNode)
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

        function onDuplicateItem(app, eventData) %activeSession,activeNode)
            activeSession = eventData.Session;
            activeNodes = eventData.Items;

            for i = 1:length(activeNodes)
                app.duplicateItem(activeNodes(i), activeSession)
            end

            app.IsDirty(app.getSessionIndex(activeSession)) = true;            
        end

        function onEmptyDeletedItems(app, eventData)
            session = eventData.Session;
            app.permDelete(session);                        
            notify(app, 'Model_DeletedItemsDeleted', QSPViewerNew.Application.Session_EventData(session));            
        end

        function onOpenLogger(app)
            try
                app.LoggerDialog = QSPViewerNew.Dialogs.LoggerDialog;
                app.LoggerDialog.Sessions = app.Sessions;
            catch ME
                if app.UseUI
                    uialert(app.getUIFigure, ME.message, 'Error opening logger dialog');
                else
                    error(ME.message);
                end
            end
        end

        function updateLoggerSessions(app,~,~)
            if isvalid(app.LoggerDialog)
                app.LoggerDialog.Sessions = app.Sessions;
            end
        end

        % TODOpax. This is subsumed by new code. Keep for reference until
        % tests provide coverage.
        %         function onMoveToSelectedItem(app,h,~)
        %             error("Controller:onMoveToSelectedItem");
        %             currentNode = h.Parent.UserData;
        %             allItemTypeTags = {'Task'; 'Parameters'; 'OptimizationData'; 'VirtualPopulationData'; ...
        %                 'VirtualPopulationGenerationData'; 'VirtualPopulation'; 'Simulation'; 'Optimization'; ...
        %                 'CohortGeneration'; 'VirtualPopulationGeneration'; 'GlobalSensitivityAnalysis'};
        %             parentNode = currentNode;
        %             while ~ismember(parentNode.Tag, allItemTypeTags)
        %                 parentNode = parentNode.Parent;
        %             end
        %
        %             nodeSelDialog = QSPViewerNew.Widgets.TreeNodeSelectionModalDialog (app, ...
        %                 parentNode, ...
        %                 'ParentAppPosition', app.UIFigure.Position, ...
        %                 'DialogName', 'Select node to move item(s) to');
        %
        %             uiwait(nodeSelDialog.MainFigure);
        %
        %             selNode = app.SelectedNodePath;
        %             allNodes = split(selNode, filesep);
        %             newParentNode = parentNode;
        %             for i = length(allNodes)-1:-1:1
        %                 childName = allNodes(i);
        %                 childNodeIdx = childName==string({newParentNode.Children.Text});
        %                 newParentNode = newParentNode.Children(childNodeIdx);
        %             end
        %
        %             % assign all current selected nodes to new parent
        %             selNodes = [currentNode; app.TreeRoot.SelectedNodes];
        %             selNodes = unique(selNodes);
        %             for i = 1:length(selNodes)
        %                 if isa(selNodes(i).NodeData, class(currentNode.NodeData)) % move all nodes of same type
        %                     selNodes(i).Parent = newParentNode;
        %                     if isa(newParentNode.NodeData, 'QSP.Folder') % if folder, assign the new children
        %                         if isempty(newParentNode.NodeData.Children)
        %                             newParentNode.NodeData.Children = selNodes(i).NodeData;
        %                         else
        %                             newParentNode.NodeData.Children(end+1) = selNodes(i).NodeData;
        %                         end
        %                     end
        %                 end
        %             end
        %             expand(newParentNode);
        %             app.markDirty(currentNode.NodeData.Session);
        %         end

        function onOpenPluginManager(app)
            try
                app.PluginManager = QSPViewerNew.Dialogs.PluginManager;
                app.PluginManager.Sessions = app.Sessions;

                % Attach listener to plugin table property to update context
                % menus
                app.PluginTableDataListener = addlistener(app.PluginManager, 'PluginTableData', 'PostSet', @(h,e) onPluginTableChanged(app));

            catch ME
                if app.UseUI
                    uialert(app.getUIFigure, ME.message, 'Error opening plugin manager.');
                else
                    error(ME.message);
                end
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

        function onGitStateChange(app, eventData)            
            app.Sessions.AutoSaveGit = eventData.Value;
        end

        function onUseParallelStateChange(app, eventData)
            app.Sessions.UseParallel = eventData.Value;
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
            if errormsgs ~= ""
                if app.UseUI
                    uialert(app.UIFigure, errormsgs, 'Error applying plugins');
                else
                    error(errormsgs);
                end
            end
        end
    end

    % Session methods
    methods (Access = private)
        % TODOpax: cleanup this function.
        function StatusTF = saveSession(app, sessionIdx, saveAsTF)
            arguments
                app
                sessionIdx (1,1) double
                saveAsTF   (1,1) logical
            end

            % This function requires user interaction. A cleanup of this
            % function would allow saveSession to be tested with the CLI
            % only tests.
            if ~app.UseUI
                StatusTF = false;
                return
            end

            %Retrieve session info
            Session = app.Sessions(sessionIdx);
            OldSessionPath = app.SessionPaths(sessionIdx);
            StatusTF = false;

            %Get a valid file location to start in
            ThisFile = OldSessionPath;
            IsNewFile = ~exist(ThisFile,'file');

            % Check for a valid extension.
            ValidFileExtension = ThisFile.endsWith(".qsp.mat");
            ValidFileType = ValidFileExtension;

            if isempty(fileparts(ThisFile))
                ThisFile = fullfile(app.LastFolder,ThisFile);
            end

            % Do we need to prompt for a filename?
            PutFileSuccess = true;
            if saveAsTF || IsNewFile || ~ValidFileType

                % Need special handling for non-PC
                [PathName,FileName] = fileparts(ThisFile);
                FileName = regexp(FileName,'\.','split');

                if numel(FileName) > 1
                    FileName = FileName(1);
                end

                ThisFile = fullfile(PathName,FileName);

                %Get file location using UI
                [FileName,PathName,FilterIndex] = uiputfile(app.FileSpec, 'Save as', ThisFile);

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
                if  app.saveSessionToFile(Session,ThisFile)
                    app.addRecentSessionPath(ThisFile);
                    StatusTF = true;
                    app.SessionPaths(sessionIdx) = ThisFile;
                    app.IsDirty(sessionIdx) = false;
                end
            end
        end

        function StatusTF = saveSessionToFile(app, session, filePath)
            StatusTF = true;
            try
                s.Session = session;
                save(filePath,'-struct','s');
            catch err
                StatusTF = false;
                if app.UseUI
                    uialert(app.UIFigure, sprintf('The file %s could not be saved:\n%s',filePath, err.message), 'Error saving file');
                else
                    error('The file %s could not be saved:\n%s',filePath, err.message);
                end
            end
        end

        function createNewSession(app, Session, filePath)
            % Adds a session to the controller. If none
            % supplied a new one is built.
            arguments
                app
                Session (1,1)  QSP.Session = QSP.Session()
                filePath (1,1) string      = "";
            end

            % Add the session to the app
            app.Sessions(end+1)     = Session;
            app.IsDirty(end+1)      = false;
            app.SessionPaths(end+1) = filePath;
            app.addRecentSessionPath(filePath);

            % Need a name for the session. If there is no name on it the
            % controller will assign a name.
            if isempty(Session.Name)
                existingNames = string({app.Sessions.Name});
                nextIndex = sum(existingNames.startsWith("untitled"));
                if nextIndex == 0
                    newName = char("untitled");
                else
                    newName = char("untitled_" + nextIndex);
                end
                Session.Name = newName;
                Session.setSessionName(Session.Name); % why do we have two Names?! bc set was done incorrectly.
            end

            % Notify new session.
            eventData = QSPViewerNew.Application.NewSessionEventData(Session, app.buildingBlockTypes, app.functionalityTypes);
            notify(app, 'Model_NewSession', eventData);

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
                if app.UseUI
                    uialert(app.UIFigure, Message, 'Invalid File')
                else
                    error(Message);
                end

            else
                %We have verified the session path, now verify the root
                %directory
                [StatusOk,newRootDir] = app.getValidSessionRootDirectory(loadedSession.Session.RootDirectory);
                Session = copy(loadedSession.Session);
                Session.RootDirectory = newRootDir;
            end
        end

        function status = verifyValidSessionFilePath(app, fullFilePath)
            % This status function checks whether the filepath provided is valid
            %If not, it will try to find a valid session path
            %If the user cannot find a valid session path, the output is
            %false
            status = true;

            if ~exist(fullFilePath,'file')
                if app.UseUI
                    uialert(app.UIFigure, sprintf('The specified file does not exist: \n%s',fullFilePath), 'Invalid File')
                else
                    warning('The specified file does not exist: \n%s',fullFilePath);
                end
                status =false;
            end

            %Check that the file isnt already loaded
            if ismember(fullFilePath, app.SessionPaths)
                if app.UseUI
                    uialert(app.getUIFigure,sprintf('The specified file is already open: \n%s',fullFilePath),'Invalid File');
                else
                    warning('The specified file is already open: \n%s',fullFilePath);
                end
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
                        if app.UseUI
                            uialert(app.getUIFigure,'The newly selected root directory was not valid','Invalid Directory');
                        else
                            warning('The newly selected root directory was not valid');
                        end
                    end
                else
                    %They chose not to select a new file.
                    status = false;
                    newFilePath = '';
                end
            end
        end

        function addRecentSessionPath(app, newPath)
            % Adds recently used paths (load/save) to a list. Keep the list
            % to 10 items.
            arguments
                app
                newPath (1,1) string
            end
            
            listSize = 10;
            inRecentListTF = app.RecentSessionPaths == newPath;
            app.RecentSessionPaths(inRecentListTF) = [];

            app.RecentSessionPaths(end+1) = newPath;            

            % Keep the first 'listSize' items.
            if numel(app.RecentSessionPaths) > listSize
                app.RecentSessionPaths = app.RecentSessionPaths(1:listSize);
            end

            notify(app, 'Controller_RecentSessionPathsChange', QSPViewerNew.Application.RecentSessionPaths_EventData(app.RecentSessionPaths));
        end

        function closeSession(app, sessionIndex)
            % CLOSESESSION  Closes the session with index sessionIndex by
            % removing it from the controller's session list.
            % Notifies: Model_SessionClosed

            closingSession = app.Sessions(sessionIndex);

            % Delete timer
            deleteTimer(closingSession);

            % remove the session's UDF from the path
            closingSession.removeUDF();

            % Remove the session object
            app.Sessions(sessionIndex) = [];
            app.IsDirty(sessionIndex) = [];
            app.SessionPaths(sessionIndex) = [];

            % Send an event to let the plugin manager know.
            %             % update sessions in plugin manager if it is open
            %             if isvalid(app.PluginManager)
            %                 app.PluginManager.Sessions = app.Sessions;
            %             end

            notify(app, "Model_SessionClosed", QSPViewerNew.Application.Session_EventData(closingSession));
        end

        function cancelTF = savePromptBeforeClose(app, sessionIndex)
            %Ask user if they would like to save
            prompt = "Save changes to " + app.Sessions(sessionIndex).Name + "?";
            Result = uiconfirm(app.getUIFigure, prompt, 'Save Changes','Options',{'Yes','No','Cancel'},'DefaultOption','Cancel');

            cancelTF = false;
            switch Result
                case 'Yes'
                    savedTF = app.saveSession(sessionIndex, false);
                    if savedTF
                        app.closeSession(sessionIndex);
                    else
                        cancelTF = true;
                    end
                case 'No'
                    app.closeSession(sessionIndex);
                case 'Cancel'
                    cancelTF = true;
            end
        end
    end

    % These need review and mostly likely removal.
    methods (Access = public)
        % Unclear why this is here since it is not needed. These are all
        % handle objects so no need to update anything with the "new" copy.
        % It is not a completely new copy but rather a copy of fields into
        % an exising object. But leave here for now for reference. There is
        % something happening with the VirtualPopulation and Parameters
        % that needs further investigation.
        function changeInBackEnd(~,~)
            %This function is for other classes to provide a new session to
            %be added to session and corresponding tree

            return

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

        % The following 4 functions are required because uiaxes in R2020a do
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

    methods (Access = private)
        function restoreNode(app, nodeToRestore, session)
            arguments
                app
                nodeToRestore
                session
            end

            type = string(class(nodeToRestore)).extractAfter("QSP.");

            buildingBlocksTF = app.buildingBlockTypes(:,2) == type;
            functionalityTF  = app.functionalityTypes(:,2) == type;

            if any(buildingBlocksTF)
                session.Settings.(type)(end+1) = nodeToRestore;
            elseif any(functionalityTF)
                session.(type)(end+1) = nodeToRestore;
            end

            % We cannot use vectorized eq due to heterogeneous array and
            % non-sealed eq method.
            whichOne = 0;
            for i = 1:numel(session.Deleted)
                if session.Deleted(i) == nodeToRestore
                    whichOne = i;
                    break;
                end
            end
            assert(whichOne > 0 && whichOne <= numel(session.Deleted));
            session.Deleted(whichOne) = [];

            sessionIndex = app.getSessionIndex(session);
            app.IsDirty(sessionIndex) = true;

            notify(app, 'Model_ItemRestored', QSPViewerNew.Application.MultipleItems_EventData(session, nodeToRestore));

            % TODOpax. Keep this for reference while tests are written.
            %             if false
            %                 try
            %                     % What is the data object?
            %                     ThisObj = node.NodeData;
            %
            %                     % What type of item?
            %                     ItemTypes = {
            %                         'Dataset',                          'OptimizationData'
            %                         'Parameter',                        'Parameters'
            %                         'Task',                             'Task'
            %                         'Virtual Subject(s)',               'VirtualPopulation'
            %                         'Acceptance Criteria',              'VirtualPopulationData'
            %                         'Target Statistics',                'VirtualPopulationGenerationData'
            %                         'Simulation',                       'Simulation'
            %                         'Optimization',                     'Optimization'
            %                         'Cohort Generation',                'CohortGeneration'
            %                         'Virtual Population Generation',    'VirtualPopulationGeneration'
            %                         'Global Sensitivity Analysis',      'GlobalSensitivityAnalysis'
            %                         };
            %                     ItemClass = strrep(class(ThisObj), 'QSP.', '');
            %                     ItemType = ItemTypes{strcmpi(ItemClass,ItemTypes(:,2)),1};
            %
            %                     % Where does the item go?
            %                     if isprop(session,ItemType)
            %                         ParentObj = session ;
            %                         SuperParentArray = ParentObj.TreeNode.Children;
            %                         ChildTags = {SuperParentArray.Tag};
            %                         SuperParent = SuperParentArray(strcmpi(ChildTags,'Functionalities'));
            %                         ParentArray = SuperParent.Children;
            %                         ParentArrayTypes = {ParentArray.Tag};
            %                         ParentNode = ParentArray(strcmp(ParentArrayTypes,ItemType));
            %                         allChildNames = {ParentObj.(ItemType).Name};
            %                     elseif strcmp(ItemType, "Folder")
            %                         restoreFolderNodes(app, node);
            %
            %                         if ischar(ThisObj.Parent)
            %                             ParentNode = getParentItemNode(ThisObj, app.TreeRoot);
            %                         else
            %                             ParentNode = ThisObj.Parent.TreeNode;
            %                         end
            %
            %                         if ~isempty(ParentNode.Children)
            %                             allChildren = {ParentNode.Children.NodeData};
            %                             allFoldersIdx = cellfun(@(x) isa(x, 'QSP.Folder'),allChildren );
            %                             if ~any(allFoldersIdx)
            %                                 allChildNames = '';
            %                             else
            %                                 allFolders = [allChildren{allFoldersIdx}];
            %                                 allChildNames = {allFolders.Name};
            %                             end
            %                         else
            %                             allChildNames = '';
            %                         end
            %
            %                         ParentObj = session.Settings;
            %                     else
            %                         ParentObj = session.Settings;
            %                         ParentArray = ParentObj.TreeNode.Children;
            %                         ParentArrayTypes = {ParentArray.Tag};
            %                         ParentNode = ParentArray(strcmp(ParentArrayTypes,ItemType));
            %                         allChildNames = {ParentObj.(ItemType).Name};
            %                     end
            %
            %                     % Update the name to include the timestamp
            %                     TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
            %
            %                     % Strip out date
            %                     SplitName = regexp(ThisObj.Name,'\(\d\d-\D\D\D-\d\d\d\d_\d\d-\d\d-\d\d\)','split');
            %                     if ~isempty(SplitName) && iscell(SplitName)
            %                         SplitName = SplitName{1}; % Take first
            %                     end
            %                     ThisObj.Name = strtrim(SplitName);
            %
            %                     ThisObj.Name = sprintf('%s (%s)',ThisObj.Name,TimeStamp);
            %
            %                     % check for duplicate names
            %                     if any(strcmp(ThisObj.Name, allChildNames))
            %                         if app.UseUI
            %                             uialert(app.UIFigure,'Cannot restore deleted item because its name is identical to an existing item.','Restore');
            %                         else
            %                             warning('Cannot restore deleted item because its name is identical to an existing item.');
            %                         end
            %                         return;
            %                     end
            %
            %                     if ~strcmp(ItemType, "Folder")
            %                         % Move the object from deleted to the new parent
            %                         % for folders, this is already done in restoreFolderNodes
            %                         ParentObj.(ItemType)(end+1) = ThisObj;
            %                     end
            %
            %                     MatchIdx = false(size(session.Deleted));
            %                     for idx = 1:numel(session.Deleted)
            %                         MatchIdx(idx) = session.Deleted(idx)==ThisObj;
            %                     end
            %                     session.Deleted( MatchIdx ) = [];
            %
            %                     % Update the tree
            %                     node.Parent = ParentNode;
            %                     ParentNode.expand();
            %
            %                     % Change context menu
            %                     delete(node.UIContextMenu.Children);
            %                     app.createContextMenu(node, ItemType);
            %
            %                     % Update the display
            %                     app.refresh();
            %                     app.markDirty(session);
            %                 catch ME
            %                     ThisSession = node.NodeData.Session;
            %                     loggerObj = QSPViewerNew.Widgets.Logger(ThisSession.LoggerName);
            %                     loggerObj.write(node.Text, ItemType ,ME)
            %                 end
            %             end
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

        function duplicateItem(app, node, session)
            % todopax reuse onNewItem as much as possible to avoid duplicate code.

            type = string(class(node)).extractAfter("QSP.");
            
            % Create the duplicate item

            % Need to find all the children of the type we have to make
            % sure we get a unique name.
            buildingBlocksTF = app.buildingBlockTypes(:,2) == type;
            functionalityTF  = app.functionalityTypes(:,2) == type;
            
            % Make the copy of the item. The sequence is, maybe, a bit odd.
            % We make the copy and afterwards determine the unique name
            % available as well as adding the item to the right list. This
            % is so that we only need to check for the type {building,
            % functionality} once.
            newNode = node.copy();

            % This removes paths to results from the item being copied.
            newNode.clearData(); 
            
            % Get the siblings so we can make names unique and add the
            % newItem to the correct list.
            if any(buildingBlocksTF)                
                disallowedNames = string({session.Settings.(type).Name});
                session.Settings.(type)(end+1) = newNode;
            elseif any(functionalityTF)                
                disallowedNames = string({session.(type).Name});
                session.(type)(end+1) = newNode;
            end           
                        
            newNode.Name = matlab.lang.makeUniqueStrings(node.Name, disallowedNames);            
            
            app.IsDirty(app.getSessionIndex(session)) = true;

            % Just as we do with adding a new item, a duplicate is just the
            % same relative to the View so reuse the same notification.
            notify(app, 'Model_NewItemAdded', QSPViewerNew.Application.NewItemAddedEventData(newNode, type)); % todopax would be nice if we don't need itemType
            
            % Record in log.
            loggerObj = QSPViewerNew.Widgets.Logger(session.LoggerName);
            loggerObj.write(node.Name, type, "INFO", 'duplicated item');
        end

        function deleteNode(app, deletedNode, session)
            % Move a node in session into the session's deleted container.
            arguments
                app
                deletedNode
                session
            end

            session.Deleted(end+1) = deletedNode;

            type = string(class(deletedNode)).extractAfter("QSP.");

            buildingBlocksTF = app.buildingBlockTypes(:,2) == type;
            functionalityTF  = app.functionalityTypes(:,2) == type;

            if any(buildingBlocksTF)
                whichOneTF = session.Settings.(type) == deletedNode;
                session.Settings.(type)(whichOneTF) = [];
            elseif any(functionalityTF)
                whichOneTF = session.(type) == deletedNode;
                session.(type)(whichOneTF) = [];
            end

            sessionIndex = app.getSessionIndex(session);
            app.IsDirty(sessionIndex) = true;

            notify(app, 'Model_ItemDeleted', QSPViewerNew.Application.MultipleItems_EventData(session, deletedNode));

            % update log todopax
            loggerObj = QSPViewerNew.Widgets.Logger(session.LoggerName);
            loggerObj.write(deletedNode.Name, type, "WARNING", 'deleted item');
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

        function permDelete(app, session) %nodes,session)
            % Permanently delete the items in the Deleted container.
            % Note there is no confirmation asked, the items are just
            % deleted.
            arguments
                app
                session
            end

            nodesToDelete = session.Deleted;
            for i = 1:numel(nodesToDelete)
                % Update log
                itemType = split(class(nodesToDelete(i)), '.');
                loggerObj = QSPViewerNew.Widgets.Logger(session.LoggerName);
                loggerObj.write(nodesToDelete(i).Name, itemType{end}, "DEBUG", 'permanently deleted item')

                % Delete the node.
                delete(nodesToDelete(i));
            end

            % Ideally the Model provides a way to empty this property
            % further separating the Controller from the Model. But there
            % aren't currently methods to do that and changing things in
            % the Model will make needed (and large) merges complicated.
            % To be precise, the Controller should not know that this next
            % line is the type of the Deleted property.
            session.Deleted = QSP.abstract.BaseProps.empty(1,0);

            app.IsDirty(app.Sessions == session) = true;
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

    % Static Methods
    methods(Static)
        function itemTypes = getItemTypes()
            % This function should be removed. It is here to support
            % unconverted View functionality such as the plugin manager.
            itemTypes = vertcat(QSPViewerNew.Application.Controller.buildingBlockTypes, QSPViewerNew.Application.Controller.functionalityTypes);
        end
    end

    % Get/Set Methods
    methods
        function value = get.aboutMessage(app)
            value = app.aboutMessage;
            value(1) = value(1) + app.Version;
        end

        %         function value = get.SessionNames(app)
        %             [~,value,ext] = cellfun(@fileparts, app.SessionPaths,'UniformOutput', false);
        %             value = strcat(value,ext);
        %             error('deprecating this function');
        %         end

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

        %         function value = get.SelectedSessionName(app)
        %             % Grab the session object for the selected session
        %             sIdx = app.SelectedSessionIdx;
        %             if isempty(sIdx) || isempty(app.SessionPaths)
        %                 value = '';
        %             else
        %                 value = app.SessionNames{app.SelectedSessionIdx};
        %             end
        %         end

        function value = get.NumSessions(app)
            value = numel(app.SessionPaths);
        end

        %         function value = get.SelectedSessionIdx(app)
        %             error("Controller:get.SelecgtedSessionIdx");
        %             ns = app.NumSessions;
        %             if ns==0
        %                 value = double.empty(0,1);
        %             elseif app.SelectedSessionIdx > ns
        %                 value = ns;
        %             else
        %                 value = app.SelectedSessionIdx;
        %             end
        %         end

        function set.Sessions(app,value)
            app.Sessions = value;
        end

        %         function set.SelectedSessionIdx(app,value)
        %             error("Controller:set.SelectedSessionIdx");
        %             if isempty(value)
        %                 app.SelectedSessionIdx = double.empty(0,1);
        %             else
        %                 validateattributes(value, {'double'},...
        %                     {'scalar','positive','integer','<=',app.NumSessions}) %TODO and Discuss
        %                 app.SelectedSessionIdx = value;
        %             end
        %         end

        function set.SessionPaths(app, value)
            arguments
                app
                value (:,1) string
            end
            app.SessionPaths = value;
        end

        %         function value = get.SelectedSession(app)
        %             error("deprecating this function");
        %             % Grab the session object for the selected session
        %             value = app.Sessions(app.SelectedSessionIdx);
        %         end
        %
        %         function set.SelectedSession(app,value)
        %             error("deprecating this function");
        %             % Grab the session object for the selected session
        %             app.Sessions(app.SelectedSessionIdx) = value;
        %         end

        %         function value = get.SessionNode(app)
        %             if isempty(app.Sessions)
        %                 value = matlab.ui.container.TreeNode;
        %             else
        %                 value = [app.Sessions.TreeNode];
        %             end
        %         end

        %         function value = get.PaneTypes(app)
        %             if ~isempty(app.Panes)
        %                 value = cellfun(@class, app.Panes, 'UniformOutput', false);
        %             else
        %                 value = [];
        %             end
        %         end

        function set.IsDirty(app, value)
            % This approach is a bit fragile but avoids building a new
            % associative array to hold sessions and their other metadata
            % (e.g. a table). See if we can use this for the time being.
            % Note that as a set method it must be in a block with no
            % attributes therefore it cannot be made private but it should
            % be private. Be careful.
            arguments
                app
                value (:,1) logical
            end

            cleanSessions = [];
            dirtySessions = [];

            if numel(app.IsDirty) > numel(value)
                % A session was removed, nothing needed here.
            elseif numel(app.IsDirty) < numel(value)
                % A session was added and its the last entry.
                if value(end) == 1
                    assert(numel(app.Sessions) == numel(value));
                    dirtySessions = app.Sessions(end);
                end
            else
                assert(numel(app.Sessions) == numel(app.IsDirty));

                % Determine which session changed.
                change = value - app.IsDirty;

                % -1 values are now clean
                cleanSessions = app.Sessions(change == -1);

                % +1 are values that are now dirty
                dirtySessions = app.Sessions(change == 1);
            end

            % Finally store the new value
            app.IsDirty = value;

            % Notify the dirty state change if any.
            if ~isempty(cleanSessions)
                notify(app, 'CleanSessions', QSPViewerNew.Application.Session_EventData(cleanSessions));
            end

            if ~isempty(dirtySessions)
                notify(app, 'DirtySessions', QSPViewerNew.Application.Session_EventData(dirtySessions));
            end
        end

        function value = getUIFigure(app) %todopax rename getViewTopElement
            % GETUIFIGURE  For the purpose of showing alerts and confirm
            % dialogs, the controller uses the view's top level window,
            % i.e. UIFigure.
            value = [];
            if ~isempty(app.OuterShell)
                value = app.OuterShell.UIFigure;
            end
        end

        function sessionIndex = getSessionIndex(app, session)
            arguments
                app
                session (1,1) QSP.Session
            end

            sessionTF = session == app.Sessions;
            assert(sum(sessionTF) == 1);
            sessionIndex = find(sessionTF);
        end
    end
end
