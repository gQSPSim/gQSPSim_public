classdef MainView < handle
    properties(Access = {?matlab.uitest.TestCase, ?QSPViewerNew.Application.Controller})
        % Would be nice to remove the Controller from the access list but
        % there are a few use cases that require it at the moment.
        UIFigure                 matlab.ui.Figure
    end

    properties        
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
        ModelManagerMenu         matlab.ui.container.Menu
        PluginsMenu              matlab.ui.container.Menu
        LoggerMenu               matlab.ui.container.Menu
        HelpMenu                 matlab.ui.container.Menu
        AboutMenu                matlab.ui.container.Menu
        FlexGridLayout           matlab.ui.container.GridLayout
        SessionExplorerPanel     matlab.ui.container.Panel
        SessionExplorerGrid      matlab.ui.container.GridLayout
        TreeCtrl                 matlab.ui.container.Tree
        TreeMenu
        OpenRecentMenuArray
        paneGridLayout
        paneManager QSPViewerNew.Application.PaneManager
        paneToolbar QSPViewerNew.Application.PaneToolbar
        iconList (1,1) struct
        aboutMessage (:,1) string
        contextMenuStore (1,1) struct
        
        % Keep a reference of these from the app. If they are not written
        % to then there is no memory overhead (i.e. no copy)
        itemTypes cell
    end

    events
        SessionChange

        % Events for File Menu items
        New_Request, Open_Request, OpenRecent, Close_Request, Save_Request, SaveAs_Request, Exit_Request
        OpenFile_Request

        Delete_Request, Restore_Request
        
        PermanentlyDelete_Request

        Duplicate_Request

        % Event for QSP Menu item
        AddTreeNode

        % Events for Tools Menu items
        OpenModelManager, OpenPluginManager, OpenLogger

        % Toolbar events. These are relays from 
        % view widgets/components.
        GitStateChange
        UseParallelStateChange
    end

    methods
        function obj = MainView(app)
            % Main view constructor. 
            % ctrl is the controller and is supplied in order to connect
            % listeners on the controller with function in the View.
            % The controller should not be stored on the View.
            arguments                
                app 
            end

            % Keep a local reference to the itemTypes. This is needed
            % beyond the constructor for use by context menus. Note that if
            % not modified no copy if made by MATLAB.
            obj.itemTypes = app.ItemTypes;

            % initialize the list of icons and the mapping to the 
            % buildingBlock and functionality list provided by the 
            % controller. 
            obj.initializeIconList(app.buildingBlockTypes(:,2), app.functionalityTypes(:,2));

            % Create the view.
            obj.create(app);

            % Get the About Message 
            obj.aboutMessage = app.aboutMessage;

            % Listen to the following paneManager events.
            addlistener(obj.paneManager, "Alert",   @(h,e)obj.onAlert(h,e));
            addlistener(obj.paneManager, "PaneStateChange", @(h,e)obj.onPaneStateChange(e));

            % Listen to the following controller events.
            addlistener(app, 'Model_NewSession',    @(h,e)obj.onNewSession(e));
            addlistener(app, 'Model_NewItemAdded',  @(h,e)obj.onNewTreeItemAdded(e));
            addlistener(app, 'Model_SessionClosed', @(h,e)obj.onCloseSession(e));
            addlistener(app, 'Model_ItemDeleted',   @(h,e)obj.onItemDeleted(e));
            addlistener(app, 'Model_ItemRestored',  @(h,e)obj.onItemRestored(e));
            addlistener(app, 'Model_DeletedItemsDeleted', @(h,e)obj.onDeletedItemsDeleted(e));
            
            addlistener(app, 'DirtySessions',       @(h,e)obj.onDirtySessions(e));
            addlistener(app, 'CleanSessions',       @(h,e)obj.onCleanSessions(e));            
            
            addlistener(app, 'Controller_RecentSessionPathsChange', @(h,e)obj.onUpdateRecentListChange(e));

            % This is just a relay. Arguably overkill but keeps things clean.
            addlistener(obj.paneToolbar, 'GitStateChange',         @(h,e)obj.passEvent(e));
            addlistener(obj.paneToolbar, 'UseParallelStateChange', @(h,e)obj.passEvent(e));
        end

        function delete(obj)
            % View destructor. Save View dependent state and delete the
            % view.            

            % There are ways to close the UIFigure (main element of the UI)
            % (e.g. >> close all force) that do not trigger the UIFigure
            % CloseFcn but yet the UIFigure is deleted. therefore, this 
            % function must protect against that case. 
            if isvalid(obj.UIFigure)
                groupName = QSPViewerNew.Application.Controller.PreferencesGroupName;
                setpref(groupName, 'Position', obj.UIFigure.Position);
                delete(obj.UIFigure);
            end
        end

        function createSession(obj, session, buildingBlockTypes, functionalityTypes)
            arguments
                obj (1,1) QSPViewerNew.Application.MainView
                session (1,1) QSP.Session
                buildingBlockTypes cell
                functionalityTypes cell
            end

            assert(~isempty(obj.TreeCtrl));

            % Root Session node.
            sessionNode = obj.createTreeNode(obj.TreeCtrl, session, session.SessionName, 'folder_24.png', 'Session', "Session");

            % Root Building Blocks node.
            buildingBlocksNode = obj.createTreeNode(sessionNode, [], 'Building Blocks', 'settings_24.png', 'Session', "BuildingBlocks");

            buildingBlockNodeNames     = string(buildingBlockTypes(:,1));
            buildingBlockSettingsNames = string(buildingBlockTypes(:,2));

            for i = 1:numel(buildingBlockNodeNames)
                baseNode = obj.createTreeNode(buildingBlocksNode, [], buildingBlockNodeNames(i), obj.iconList.(buildingBlockSettingsNames(i)), buildingBlockNodeNames(i), buildingBlockSettingsNames(i));
                nodes = session.Settings.(buildingBlockSettingsNames(i));

                for j = 1:numel(nodes)
                    obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, obj.iconList.(buildingBlockSettingsNames(i)), buildingBlockNodeNames(i), "instance");
                end
            end

            functionalityNode  = obj.createTreeNode(sessionNode, [], 'Functionalities', 'settings_24.png', 'Session', "Functionality");

            functionalityBlockNodeNames = string(functionalityTypes(:,2));

            for i = 1:numel(functionalityBlockNodeNames)
                dummyNodeData.Type = "FunctionalitySummary";
                baseNode = obj.createTreeNode(functionalityNode, dummyNodeData, functionalityBlockNodeNames(i), obj.iconList.(functionalityBlockNodeNames(i)), functionalityBlockNodeNames(i), functionalityBlockNodeNames(i));
                nodes = session.(functionalityBlockNodeNames(i));
                for j = 1:numel(nodes)
                    obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, obj.iconList.(functionalityBlockNodeNames(i)), functionalityBlockNodeNames(i), "instance");
                end
            end

            obj.createTreeNode(sessionNode, [], 'Deleted Items', 'trash_24.png', 'Session', "DeletedItems");

            % Default state of the tree is to expand the Session and the
            % buildingBlocks.
            sessionNode.expand;
            buildingBlocksNode.expand;
        end
    end

    methods(Access = private)
        function create(obj, app)
            arguments
                obj QSPViewerNew.Application.MainView
                app QSPViewerNew.Application.Controller
            end

            obj.UIFigure = uifigure('Visible', 'off', 'HandleVisibility', 'on');
            obj.UIFigure.Position = [100 100 1005 864];
            obj.UIFigure.Name = app.Title;
            obj.UIFigure.CloseRequestFcn =  @(h,e)obj.onMenuNotify("Exit_Request");

            constructMenuItems(obj, app.ItemTypes);

            createContextMenus(obj);

            obj.FlexGridLayout = uigridlayout(obj.UIFigure);
            gOuter = obj.FlexGridLayout;
            gOuter.RowHeight = {'1x'};
            gOuter.ColumnWidth = {'33x', 5, '67x'};
            gOuter.ColumnSpacing = 0;
            gOuter.Padding = [0 0 0 0]+10;

            gLeft = uigridlayout(gOuter);
            gLeft.Layout.Row = 1;
            gLeft.Layout.Column = 1;
            gLeft.RowHeight = {20, '1x'};
            gLeft.ColumnWidth = {'1x'};
            gLeft.Padding = [0 0 0 0];
            gLeft.RowSpacing = 0;

            pLeft = uipanel(gLeft);
            pLeft.Layout.Row = 1;
            pLeft.Layout.Column = 1;
            pLeft.BorderType = 'line';
            pLeft.BackgroundColor = 'w';
            pLeft.Title = 'Session Explorer';

            pCenter = uipanel(gOuter);
            pCenter.Layout.Row = 1;
            pCenter.Layout.Column = 2;
            pCenter.BorderType = 'none';
            pCenter.BackgroundColor = [1 1 1]*.85;
            pCenter.Tag = 'divider';

            obj.TreeCtrl = uitree(gLeft);
            obj.TreeCtrl.Layout.Row = 2;
            obj.TreeCtrl.Layout.Column = 1;
            obj.TreeCtrl.Multiselect = 'on';
            obj.TreeCtrl.SelectionChangedFcn = @obj.onTreeSelectionChange;

            pRight = uipanel(gOuter);
            pRight.Layout.Row = 1;
            pRight.Layout.Column = 3;
            pRight.BorderType = 'line';

            obj.paneGridLayout = uigridlayout(pRight);
            obj.paneGridLayout.RowHeight = {30, '1x'}; 
            obj.paneGridLayout.ColumnWidth = {'1x'};

            % Construct the paneToolbar.
            obj.paneToolbar = QSPViewerNew.Application.PaneToolbar(obj.paneGridLayout);

            % Construct the paneManager.
            obj.paneManager = QSPViewerNew.Application.PaneManager(obj.paneGridLayout, app, app.ItemTypes, obj.paneToolbar);

            obj.UIFigure.WindowButtonDownFcn = @obj.onWindowButtonDown;
            obj.UIFigure.WindowButtonUpFcn   = @obj.onWindowButtonUp;

            % Make the UI visible.
            obj.UIFigure.Visible = 'on';
        end

        function initializeIconList(obj, buildingBlockTypes, functionalityTypes)
            arguments
                obj
                buildingBlockTypes (:,1) string
                functionalityTypes (:,1) string
            end

            % Create a map from itemType to iconfile.
            % Make a mapping from icon filenames to the item names. Note
            % that if a change is made to the list of items (buildingblocks
            % and functionalities) a corresponding icon will be needed.
            % Also this initialization assumes the order of that list.
            buildingBlockIcons = ["flask2.png", "param_edit_24.png", "datatable_24.png", "target_stats.png", "acceptance_criteria.png", "stickman3.png"];
            functionalityIcons = ["simbio_24.png", "optim_24.png", "stickman-3.png", "stickman-3-color.png", "sensitivity.png"];
            for i = 1:numel(buildingBlockTypes)
                obj.iconList.(buildingBlockTypes(i)) = buildingBlockIcons(i);
            end

            for i = 1:numel(functionalityTypes)
                obj.iconList.(functionalityTypes(i)) = functionalityIcons(i);
            end

            obj.iconList.Folder = "folder_24.png";
        end

        function onWindowButtonUp(~, src, ~)
            src.WindowButtonMotionFcn = '';
            src.Pointer = 'arrow';
        end

        function onWindowButtonDown(obj, src, ~)
            co = src.CurrentObject;
            if co.Tag == "divider"
                src.Pointer = 'left';
                src.WindowButtonMotionFcn = @obj.onWindowButtonMotion;
            end
        end

        function onWindowButtonMotion(obj, src, ~)
            currentPoint = src.CurrentPoint;
            xFraction = 100*currentPoint(1)./src.Position(3);
            obj.FlexGridLayout.ColumnWidth = {sprintf('%dx', xFraction), 5, sprintf('%dx',100-xFraction)};
            drawnow limitrate
        end

        function onTreeSelectionChange(obj, ~, eventData)
            arguments
                obj
                ~
                eventData (1,1) matlab.ui.eventdata.SelectedNodesChangedData
            end

            SelectedNodes = eventData.SelectedNodes;

            % Only open panes for singly selected nodes.
            if numel(SelectedNodes) == 1
                % Determine if a Summary treenode has been selected.
                if isfield(SelectedNodes.NodeData, "Type") %TODOpax, convert this to use Tag.
                    nodeData = SelectedNodes.NodeData;
                    if ~isempty(SelectedNodes.Children)
                        nodeData.ChildNodeData = [SelectedNodes.Children.NodeData];
                        obj.paneManager.openPane(nodeData);                    
                    end                    
                elseif ~isempty(SelectedNodes.NodeData)
                    % There are nodes (e.g. Task root) that don't have
                    % summary panes associated to them. If that were to be
                    % needed those nodes simply need to add a struct (as
                    % the functionality nodes have) and a pane written for
                    % them. But meanwhile those nodes have no NodeData so
                    % we need to protect here.                    
                    obj.paneManager.openPane(SelectedNodes.NodeData);
                else
                    % Clear out the pane area since the selected node has no associated pane.
                    obj.paneManager.closeActivePane();
                end
            end
            
            % Delete and Restore selected menu items' enabled state depends
            % on the selection. The Tag is used to more quickly determine
            % what is selected.
            selectedNodesTags = string({SelectedNodes.Tag});
            
            if all(selectedNodesTags == "instance")
                obj.DeleteSelectedItemMenu.Enable = true;
            else
                obj.DeleteSelectedItemMenu.Enable = false;
            end

            if all(selectedNodesTags == "deleted_instance")
                obj.RestoreSelectedItemMenu.Enable = true;
            else
                obj.RestoreSelectedItemMenu.Enable = false;
            end
        end

        function onNewTreeItemAdded(obj, eventData)
            % A new item has been added to the model. Respond by creating
            % a treeNode for it the current session. 
            sessionTreeNode = getCurrentSessionTreeNode(obj);

            % The itemType can specify a Folder so decompose it if needed. 
            if eventData.itemType.contains(":Folder")
                parentTag = eventData.itemType.extractBefore(":Folder");
                iconType = "Folder";
                itemTag = "folder";
            else
                parentTag = eventData.itemType;
                iconType = eventData.itemType;
                itemTag = "instance";
            end

            parent = findobj(sessionTreeNode, 'Tag', parentTag);

            assert(numel(parent) == 1);
            obj.createTreeNode(parent, eventData.newItem, eventData.newItem.Name, obj.iconList.(iconType), eventData.itemType, itemTag);

            % By default expand nodes added.
            parent.expand;
        end

        function treeNode = createTreeNode(obj, Parent, Data, Name, Icon, PaneType, tag)
            treeNode = uitreenode(...
                'Parent',   Parent,...
                'NodeData', Data,...
                'Text',     Name,...
                'UserData', PaneType,...
                'Tag',      tag,...
                'Icon',     QSPViewerNew.Resources.LoadResourcePath(Icon));

            % Assign context menus based on creation time's value of tag.
            obj.assignContextMenus(tag, treeNode);
        end
        
        function assignContextMenus(obj, type, treeNode)
            % Assign context menus based on type/tag.
            % See createContextMenus for the types handled in
            % this function's switch statement. 
            % Note that type/tag is not necessarily that of the treeNode,
            % for example an instance treenode might be deleted and would
            % then have the contextmenu associated with deleted items.
            arguments
                obj
                type     (1,1) string
                treeNode (1,1) matlab.ui.container.TreeNode
            end

            % Check if the type is in the itemTypes if so then handle here
            % otherwise go to the switch statement.
            switch type
                case {'Session', 'DeletedItems', 'Deleted', 'instance'}
                    treeNode.ContextMenu = obj.contextMenuStore.(type);

                case 'Folder'
                    disp('Not ready yet');

                case obj.itemTypes(:,2)
                      treeNode.ContextMenu = obj.contextMenuStore.header;

                case {'BuildingBlocks', 'Functionality'}
                    % Do nothing for these nodes. 
                
                otherwise
                    assert(false, "Unhandled type.");
            end
        end

        function createContextMenus(obj)
            % Session
            obj.contextMenuStore.Session = uicontextmenu(obj.UIFigure, 'Tag', 'Session');
            uimenu(obj.contextMenuStore.Session, "Text", "Close",      "MenuSelectedFcn", @(h,e)obj.onMenuNotifyWithSession("Close_Request"));
            uimenu(obj.contextMenuStore.Session, "Text", "Save",       "MenuSelectedFcn", @(h,e)obj.onMenuNotifyWithSession("Save_Request"));
            uimenu(obj.contextMenuStore.Session, "Text", "Save As...", "MenuSelectedFcn", @(h,e)obj.onMenuNotifyWithSession("SaveAs_Request"));

            % DeletedItems
            obj.contextMenuStore.DeletedItems = uicontextmenu(obj.UIFigure, 'Tag', 'DeletedItems');
            uimenu(obj.contextMenuStore.DeletedItems, "Text", "Empty Deleted Items", "MenuSelectedFcn", @(h,e)obj.onMenuNotifyWithSession("PermanentlyDelete_Request"));

            % Deleted
            obj.contextMenuStore.Deleted = uicontextmenu(obj.UIFigure, 'Tag', 'Deleted');
            uimenu(obj.contextMenuStore.Deleted, "Text", "Restore", "MenuSelectedFcn",            @(h,e)obj.onSelectedItemsAction("Restore_Request"));
            uimenu(obj.contextMenuStore.Deleted, "Text", "Permanently Delete", "MenuSelectedFcn", @(h,e)obj.onSelectedItemsAction("PermanentlyDelete_Request"));

            % instance
            obj.contextMenuStore.instance = uicontextmenu(obj.UIFigure, 'Tag', 'instance');
            uimenu(obj.contextMenuStore.instance, "Text", "Duplicate", "MenuSelectedFcn", @(h,e)obj.onSelectedItemsAction("Duplicate_Request"));
            uimenu(obj.contextMenuStore.instance, "Text", "Delete", "MenuSelectedFcn",    @(h,e)obj.onSelectedItemsAction("Delete_Request"));
            uimenu(obj.contextMenuStore.instance, "Text", "Move To:");

            % header nodes: these are the grouping of nodes such as Task,
            % Parameter, Dataset, Simulation, Optimization, etc.
            obj.contextMenuStore.header = uicontextmenu(obj.UIFigure, 'Tag', 'header');
            uimenu(obj.contextMenuStore.header, "Text", "Add new", "MenuSelectedFcn", @(h,e)obj.onMenuNotifyAdd(type));
            uimenu(obj.contextMenuStore.header, "Text", "Add new Folder");            
        end

        function onAbout(obj, ~, ~)
            uialert(obj.UIFigure, obj.aboutMessage, 'About', 'Icon','');
        end

        function onAlert(obj, ~, eventData)
            uialert(obj.UIFigure, eventData.message, 'Run Failed'); %todopax add this last arg to the eventData
        end

        function onMenuNotify(obj, type)
            % Simply notifies listeners of the event. No other processing
            % on the View.
            notify(obj, type);
        end

        function onMenuNotifyAdd(obj, type)            
            ed = QSPViewerNew.Application.NewItemEventData(obj.getCurrentSession(), type);
            notify(obj, 'AddTreeNode', ed);
        end

        function onMenuNotifyWithSession(obj, type)
            % Notifies the controller of an action that requires the current 
            % session. Define the current session as that containing the 
            % selected tree node or, if it is the case, the only session in
            % the project. Otherwise alert there is no current session.
            selectedSession = obj.getCurrentSession();
            notify(obj, type, QSPViewerNew.Application.Session_EventData(selectedSession));
        end

        function onMenuNotifyWithFile(obj, type, eventData)
            notify(obj, type, QSPViewerNew.Application.RecentSessionPaths_EventData(eventData.Source.Text));            
        end

        function onNewSession(obj, e)
            obj.createSession(e.Session, e.buildingBlockTypes, e.functionalityTypes);
        end

        function onCloseSession(obj, eventData)
            % Controller is broadcasting that a session has
            % been removed. Update the view accordingly.
            sessions = [obj.TreeCtrl.Children.NodeData];
            closeSessionTF = eventData.Session == sessions;
            delete(obj.TreeCtrl.Children(closeSessionTF));
            % NOTIFY with an event is an option here but since this is all view internal
            % its ok to keep as a direct call. 
            obj.paneManager.closeActivePane();
        end

        function onItemDeleted(obj, eventData)
            % An Item has been deleted on the model and needs to be moved
            % into the Deleted Items node in the UI.            
            item = eventData.Items;
            sessionTF = [obj.TreeCtrl.Children.NodeData] == eventData.Session;
            sessionNode = obj.TreeCtrl.Children(sessionTF);
            type = string(class(item)).extractAfter("QSP.");
            typeNode = findobj(sessionNode, 'Tag', type);
            treeNodeToDelete = typeNode.Children([typeNode.Children.NodeData] == item);
    
            deletedItems = findobj(sessionNode, 'Tag', 'DeletedItems');
            treeNodeToDelete.Parent = deletedItems;
            treeNodeToDelete.Tag = "deleted_instance";

            % Change the context menu items on the deleted node. Remember            
            % to set back upon restore.
            treeNodeToDelete.ContextMenu = obj.contextMenuStore.Deleted;

            deletedItems.expand();
        end

        function onDeletedItemsDeleted(obj, eventData)
            sessionTF = [obj.TreeCtrl.Children.NodeData] == eventData.Session;
            sessionNode = obj.TreeCtrl.Children(sessionTF);
            deletedItemsNode = findobj(sessionNode, 'Tag', 'DeletedItems');
            delete(deletedItemsNode.Children);            
        end

        function onItemRestored(obj, eventData)
            arguments
                obj
                eventData
            end
            % An Item has been restored on the model and needs to be moved
            % into the Deleted Items node in the UI.                        
            sessionTF = [obj.TreeCtrl.Children.NodeData] == eventData.Session;
            sessionNode = obj.TreeCtrl.Children(sessionTF);
            
            item = eventData.Items;
            type = string(class(item)).extractAfter("QSP.");
            newParentNode = findobj(sessionNode, 'Tag', type);                       
    
            deletedItemsNode = findobj(sessionNode, 'Tag', 'DeletedItems');

            % Cannot use vector compare since eq is not sealed and
            % deletedItemsNode.Children is a heterogeneous array.
            itemToRestoreIndex = 0;
            for i = 1:numel(deletedItemsNode.Children)
                if deletedItemsNode.Children(i).NodeData == item
                    itemToRestoreIndex = i;
                    break;
                end
            end

            nodeToRestore = deletedItemsNode.Children(itemToRestoreIndex);

            nodeToRestore.Parent = newParentNode;
            nodeToRestore.ContextMenu = obj.contextMenuStore.instance;
            
            newParentNode.expand();
        end

        function onDirtySessions(obj, eventData)
            sessionNodeIndexTF = [obj.TreeCtrl.Children.NodeData] == eventData.Session;
            sessionNode = obj.TreeCtrl.Children(sessionNodeIndexTF);
            
            sessionNode.Text = sessionNode.Text + " *";
        end

        function onCleanSessions(obj, eventData)
            sessionNodeIndexTF = [obj.TreeCtrl.Children.NodeData] == eventData.Session;
            sessionNode = obj.TreeCtrl.Children(sessionNodeIndexTF);

            sessionNode.Text = string(sessionNode.Text).extractBefore(" *");
        end

        function onSelectedItemsAction(obj, eventType)
            % Todopax: do we need to support items from multiple sessions
            % here? currently assuming items are in one session.
            eventData = QSPViewerNew.Application.MultipleItems_EventData(obj.getCurrentSession(), [obj.TreeCtrl.SelectedNodes.NodeData]);
            notify(obj, eventType, eventData);
        end

        function onUpdateRecentListChange(obj, eventData)

            delete(obj.OpenRecentMenu.Children);

            paths = eventData.Paths;

            for i = 1:numel(paths)
                uimenu(obj.OpenRecentMenu, 'Text', paths(i), 'MenuSelectedFcn', @(h,e)obj.onMenuNotifyWithFile('OpenFile_Request', e));
            end            
        end

        function onPaneStateChange(obj, eventData)
            assert(obj.TreeCtrl.SelectedNodes.NodeData == eventData.change);
            obj.TreeCtrl.SelectedNodes.Text = eventData.change.Name;            
        end

        function constructMenuItems(obj, itemTypes)
            % Construct the menu items in the toolbar.
            arguments
                obj
                itemTypes cell
            end

            obj.FileMenu        = obj.createMenuItem(obj.UIFigure, "File");
            obj.NewCtrlNMenu    = obj.createMenuItem(obj.FileMenu, "New...",      @(h,e)obj.onMenuNotify("New_Request"),  "N");
            obj.OpenCtrl0Menu   = obj.createMenuItem(obj.FileMenu, "Open...",     @(h,e)obj.onMenuNotify("Open_Request"), "O");
            obj.OpenRecentMenu  = obj.createMenuItem(obj.FileMenu, "Open Recent");%, @(h,e)obj.onMenuNotifyWithFile('OpenFile_Request', e));
            obj.CloseMenu       = obj.createMenuItem(obj.FileMenu, "Close",       @(h,e)obj.onMenuNotifyWithSession("Close_Request"), "W", "on");
            obj.SaveCtrlSMenu   = obj.createMenuItem(obj.FileMenu, "Save",        @(h,e)obj.onMenuNotifyWithSession("Save_Request"),  "S", "on");
            obj.SaveAsMenu      = obj.createMenuItem(obj.FileMenu, "Save As...",  @(h,e)obj.onMenuNotifyWithSession("SaveAs_Request"));
            obj.ExitCtrlQMenu   = obj.createMenuItem(obj.FileMenu, "Exit",        @(h,e)obj.onMenuNotify("Exit_Request"), "Q", "on");

            obj.QSPMenu         = obj.createMenuItem(obj.UIFigure, "QSP");
            obj.AddNewItemMenu  = obj.createMenuItem(obj.QSPMenu,  "Add New Item");
            
            % Create menus for all the QSP Item types.
            shortCuts = ["T", "P", "D", "A", "E", "V", "I", "F", "C", "G", "Z"]; % maybe useful but here now for debugging.
            for i = 1:size(itemTypes,1)
                type = itemTypes{i,2};
                obj.createMenuItem(obj.AddNewItemMenu, itemTypes{i,1}, @(h,e)obj.onMenuNotifyAdd(type), shortCuts(i));
            end

            obj.DeleteSelectedItemMenu  = obj.createMenuItem(obj.QSPMenu, "Delete Selected Item",  @(h,e)obj.onSelectedItemsAction("Delete_Request"));
            obj.RestoreSelectedItemMenu = obj.createMenuItem(obj.QSPMenu, "Restore Selected Item", @(h,e)obj.onSelectedItemsAction("Restore_Request"));
            
            % Start with these disabled. Their state depends on treeNode selection.
            obj.DeleteSelectedItemMenu.Enable  = false;
            obj.RestoreSelectedItemMenu.Enable = false;
            
            obj.ToolsMenu        = obj.createMenuItem(obj.UIFigure, "Tools");
            obj.ModelManagerMenu = obj.createMenuItem(obj.ToolsMenu, "Model Manager",  @(h,e)obj.onMenuNotifyWithSession("OpenModelManager"));
            obj.PluginsMenu      = obj.createMenuItem(obj.ToolsMenu, "Plugin Manager", @(h,e)obj.onMenuNotify("OpenPluginManager"));
            obj.LoggerMenu       = obj.createMenuItem(obj.ToolsMenu, "Logger",         @(h,e)obj.onMenuNotify("OpenLogger"));

            obj.HelpMenu         = obj.createMenuItem(obj.UIFigure, "Help");
            obj.AboutMenu        = obj.createMenuItem(obj.HelpMenu, "About", @(h,e)obj.onAbout);
        end

        function menuObj = createMenuItem(~, parent, text, menuSelectedFcn, accelerator, separator)
            arguments
                ~
                parent
                text (1,1) string
                menuSelectedFcn = ''
                accelerator (1,:) char = ''
                separator (1,1) string = "off"
            end
            menuObj = uimenu(parent, "Text", text, "MenuSelectedFcn", menuSelectedFcn, "Separator", separator, "Accelerator", accelerator);
        end
  
        function selectedSession = getCurrentSession(obj)
            % GETCURRENTSESSION  Return the current session selected in the
            % tree. If only one session in the tree that is returned even
            % when there are no selected tree nodes. If there are more than
            % one session in the tree then a selection is needed and if
            % none selected this function returns []

            % TODOpax, replace this with the function getCurrentSessionTreeNode
            selectedSession = [];

            if numel(obj.TreeCtrl.Children) == 1
                selectedSession = obj.TreeCtrl.Children.NodeData;
            else
                if numel(obj.TreeCtrl.SelectedNodes) > 1
                    % todopax: send an alert.
                else
                    selectedSession = ancestor(obj.TreeCtrl.SelectedNodes, 'uitreenode', 'toplevel').NodeData;
                end
            end
        end

        function passEvent(obj, eventData)
            % This is a relay/passthrough message. Widgets in the View
            % don't have (and should not have) access to the controller so
            % the MainView relays messages. This is low overhead and
            % provides uncoupling between implementation details of the
            % View from the controller.
            notify(obj, eventData.EventName, eventData);
        end

        function currentSessionTreeNode = getCurrentSessionTreeNode(obj)
            % Current session is either the only one open or one that has 
            % any nodes selected in the tree. If there is no session maybe
            % we want to create one? 
            
            % TODOpax add support for multi-selection on the tree.
            if numel(obj.TreeCtrl.Children) == 1
                currentSessionTreeNode = obj.TreeCtrl.Children;
            else
                currentSessionTreeNode = ancestor(obj.TreeCtrl.SelectedNodes, 'matlab.ui.container.TreeNode', 'toplevel');
            end
        end
    end
end
