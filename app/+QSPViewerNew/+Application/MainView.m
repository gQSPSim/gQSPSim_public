classdef MainView < handle
    properties
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
        paneManager
        iconList (1,1) struct
        aboutMessage (:,1) string
    end

    events
        SessionChange

        % Events for File Menu items
        New_Request, Open_Request, OpenRecent, Close_Request, Save_Request, SaveAs_Request, Exit_Request
        OpenFile_Request

        Delete_Request, Restore_Request

        % Event for QSP Menu item
        AddTreeNode

        % Events for Tools Menu items
        OpenModelManager, OpenPluginManager, OpenLogger
    end

    methods
        function obj = MainView(app)
            % Main View object constructor. 
            % ctrl is the controller and is supplied in order to connect
            % listeners on the controller with function in the View.
            % The controller should not be stored on the View.
            arguments                
                app 
            end

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

            % Listen to the following controller events.
            addlistener(app, 'Model_NewSession',    @(h,e)obj.onNewSession(e));
            addlistener(app, 'Model_NewItemAdded',  @(h,e)obj.onNewTreeItemAdded(e));
            addlistener(app, 'Model_SessionClosed', @(h,e)obj.onCloseSession(e));
            addlistener(app, 'Model_ItemDeleted',   @(h,e)obj.onItemDeleted(e));
            addlistener(app, 'Model_ItemRestored',  @(h,e)obj.onItemRestored(e));
            addlistener(app, 'DirtySessions',       @(h,e)obj.onDirtySessions(e));
            addlistener(app, 'CleanSessions',       @(h,e)obj.onCleanSessions(e));
            
            addlistener(app, 'Controller_RecentSessionPathsChange', @(h,e)obj.onUpdateRecentListChange(e));
        end

        function delete(obj)
            delete(obj.UIFigure);
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
            %sessionNode.Tag = "Session";

            % Root Building Blocks node.
            buildingBlocksNode = obj.createTreeNode(sessionNode, [], 'Building Blocks', 'settings_24.png', 'Session', "BuildingBlocks");
            %buildingBlocksNode.Tag = "BuildingBlocks";

            buildingBlockNodeNames     = string(buildingBlockTypes(:,1));
            buildingBlockSettingsNames = string(buildingBlockTypes(:,2));

            for i = 1:numel(buildingBlockNodeNames)
                baseNode = obj.createTreeNode(buildingBlocksNode, [], buildingBlockNodeNames(i), obj.iconList.(buildingBlockSettingsNames(i)), buildingBlockNodeNames(i), buildingBlockSettingsNames(i));
                %baseNode.Tag = buildingBlockSettingsNames(i); % Tag the base node of each buildingBlock.
                nodes = session.Settings.(buildingBlockSettingsNames(i));

                for j = 1:numel(nodes)
                    obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, obj.iconList.(buildingBlockSettingsNames(i)), buildingBlockNodeNames(i), "instance");
                    %instanceNode.Tag = "instance";
                end
            end

            functionalityNode  = obj.createTreeNode(sessionNode, [], 'Functionalities', 'settings_24.png', 'Session', "Functionality");
            %functionalityNode.Tag = "Functionality";

            functionalityBlockNodeNames = string(functionalityTypes(:,2));

            for i = 1:numel(functionalityBlockNodeNames)
                dummyNodeData.Type = "FunctionalitySummary";
                baseNode = obj.createTreeNode(functionalityNode, dummyNodeData, functionalityBlockNodeNames(i), obj.iconList.(functionalityBlockNodeNames(i)), functionalityBlockNodeNames(i), functionalityBlockNodeNames(i));
                %baseNode.Tag = functionalityBlockNodeNames(i);
                nodes = session.(functionalityBlockNodeNames(i));
                for j = 1:numel(nodes)
                    instanceNode = obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, obj.iconList.(functionalityBlockNodeNames(i)), functionalityBlockNodeNames(i), "instance");
                    %instanceNode.Tag = "instance";
                end
            end

            obj.createTreeNode(sessionNode, [], 'Deleted Items', 'trash_24.png', 'Session', "DeletedItems");
            %deletedItemsNode.Tag = "DeletedItems";

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

            obj.UIFigure = uifigure('Visible', 'off');
            obj.UIFigure.Position = [100 100 1005 864];
            obj.UIFigure.Name = app.Title;
            obj.UIFigure.CloseRequestFcn =  @(h,e)obj.onMenuNotify("Exit_Request");

            constructMenuItems(obj, app.ItemTypes);

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
            obj.paneGridLayout.RowHeight = {30, '1x'}; % todopax where does this 30 come from?
            obj.paneGridLayout.ColumnWidth = {'1x'};

            obj.paneManager = QSPViewerNew.Application.PaneManager(app.ItemTypes, obj.paneGridLayout, app);
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

        function treeNode = createTreeNode(~, Parent, Data, Name, Icon, PaneType, tag)
            treeNode = uitreenode(...
                'Parent',   Parent,...
                'NodeData', Data,...
                'Text',     Name,...
                'UserData', PaneType,...
                'Tag',      tag,...
                'Icon',     QSPViewerNew.Resources.LoadResourcePath(Icon));
        end
        
        function onAbout(obj, ~, ~)
            uialert(obj.UIFigure, obj.aboutMessage, 'About', 'Icon','');
        end

        function onAlert(obj, ~, eventData)
            uialert(obj.UIFigure, eventData.message, 'Run Failed'); %todopax add this last arg to the eventData
        end

        function onMenuNotify(obj, type)
            % ONMENUNOTIFY  Simply notifies listeners of the event. No
            % other processing on the View.
            notify(obj, type);
        end

        function onMenuNotifyAdd(obj, type)            
            ed = QSPViewerNew.Application.NewItemEventData(obj.getCurrentSession(), type);
            notify(obj, 'AddTreeNode', ed);
        end

        function onMenuNotifyWithSession(obj, type)
            % ONMENUNOTIFYWITHSESSION  Notifies the controller of an action
            % that requires the current session. Define the current session
            % as that containing the selected tree node or, if it is the
            % case, the only session in the project. Otherwise alert there
            % is no current session.
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
            % ONCLOSESESSION  Controller is broadcasting that a session has
            % been removed. Update the view accordingly.
            sessions = [obj.TreeCtrl.Children.NodeData];
            closeSessionTF = eventData.Session == sessions;
            delete(obj.TreeCtrl.Children(closeSessionTF));
            % NOTIFY with an event is an option here but since this is all view internal
            % keep this as a direct call. 
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
            deletedItems.expand();
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

            % Cannot use vectore compare since eq is not sealed and
            % deletedItemsNode.Children is a heterogeneous array.
            itemToRestoreIndex = 0;
            for i = 1:numel(deletedItemsNode.Children)
                if deletedItemsNode.Children(i).NodeData == item
                    itemToRestoreIndex = i;
                    break;
                end
            end

            deletedItemsNode.Children(itemToRestoreIndex).Parent = newParentNode;            
            
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

        function constructMenuItems(obj, itemTypes)
            % CONSTRUCTMENUITEMS  Construct the menu items in the toolbar.
            arguments
                obj
                itemTypes cell
            end

            obj.FileMenu                        = obj.createMenuItem(obj.UIFigure, "File");
            obj.NewCtrlNMenu                    = obj.createMenuItem(obj.FileMenu,   "New...",      @(h,e)obj.onMenuNotify("New_Request"),  "N");
            obj.OpenCtrl0Menu                   = obj.createMenuItem(obj.FileMenu,   "Open...",     @(h,e)obj.onMenuNotify("Open_Request"), "O");
            obj.OpenRecentMenu                  = obj.createMenuItem(obj.FileMenu,   "Open Recent");%, @(h,e)obj.onMenuNotifyWithFile('OpenFile_Request', e));
            %obj.OpenRecentMenu                  = obj.createMenuItem(obj.FileMenu,   "Open Recent", @(h,e)obj.onMenuNotify("OpenRecent"));
            obj.CloseMenu                       = obj.createMenuItem(obj.FileMenu,   "Close",       @(h,e)obj.onMenuNotifyWithSession("Close_Request"), "W", "on");
            obj.SaveCtrlSMenu                   = obj.createMenuItem(obj.FileMenu,   "Save",        @(h,e)obj.onMenuNotifyWithSession("Save_Request"),  "S", "on");
            obj.SaveAsMenu                      = obj.createMenuItem(obj.FileMenu,   "Save As...",  @(h,e)obj.onMenuNotifyWithSession("SaveAs_Request"));
            obj.ExitCtrlQMenu                   = obj.createMenuItem(obj.FileMenu,   "Exit",        @(h,e)obj.onMenuNotify("Exit_Request"), "Q", "on");

            obj.QSPMenu                         = obj.createMenuItem(obj.UIFigure,    "QSP");
            obj.AddNewItemMenu                  = obj.createMenuItem(obj.QSPMenu,      "Add New Item");
            
            % Create menus for all the QSP Item types.
            shortCuts = ["T", "P", "D", "A", "E", "V", "I", "F", "C", "G", "Z"]; % maybe useful but here now for debugging.
            for i = 1:size(itemTypes,1)
                type = itemTypes{i,2};
                obj.createMenuItem(obj.AddNewItemMenu, itemTypes{i,1}, @(h,e)obj.onMenuNotifyAdd(type), shortCuts(i));
            end

            obj.DeleteSelectedItemMenu          = obj.createMenuItem(obj.QSPMenu,      "Delete Selected Item",  @(h,e)obj.onSelectedItemsAction("Delete_Request"));
            obj.RestoreSelectedItemMenu         = obj.createMenuItem(obj.QSPMenu,      "Restore Selected Item", @(h,e)obj.onSelectedItemsAction("Restore_Request"));
            
            % Start with these disabled. Their state depends on treeNode
            % selection.
            obj.DeleteSelectedItemMenu.Enable  = false;
            obj.RestoreSelectedItemMenu.Enable = false;
            
            obj.ToolsMenu                       = obj.createMenuItem(obj.UIFigure, "Tools");
            obj.ModelManagerMenu                = obj.createMenuItem(obj.ToolsMenu, "Model Manager",  @(h,e)obj.onMenuNotifyWithSession("OpenModelManager"));
            obj.PluginsMenu                     = obj.createMenuItem(obj.ToolsMenu, "Plugin Manager", @(h,e)obj.onMenuNotify("OpenPluginManager"));
            obj.LoggerMenu                      = obj.createMenuItem(obj.ToolsMenu, "Logger",         @(h,e)obj.onMenuNotify("OpenLogger"));

            obj.HelpMenu                        = obj.createMenuItem(obj.UIFigure, "Help");
            obj.AboutMenu                       = obj.createMenuItem(obj.HelpMenu, "About", @(h,e)obj.onAbout);
        end

        function menuObj = createMenuItem(~, parent, text, menuSelectedFcn, accelerator, separator)
            arguments
                ~
                parent
                text (1,1) string
                menuSelectedFcn = ''
                accelerator (1,1) string = ""
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
