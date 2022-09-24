classdef OuterShell_UIFigureBased < handle
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
        FlexGridLayout           matlab.ui.container.GridLayout %QSPViewerNew.Widgets.GridFlex
        SessionExplorerPanel     matlab.ui.container.Panel
        SessionExplorerGrid      matlab.ui.container.GridLayout
        TreeRoot                 matlab.ui.container.Tree
        TreeMenu
        OpenRecentMenuArray
        IsConstructed (1,1) logical = false
        paneGridLayout
        paneManager
    end

    events
        ReadyState
        TreeSelectionChange
        SessionChange
    end

    methods
        function obj = OuterShell_UIFigureBased(appname, app)
            arguments
                appname (1,1) string
                app %todopax remove if possible.
            end

            % Create the graphics objects
            obj.create(appname, app);

            % Register the app with App Designer
            obj.IsConstructed = true;
        end

        function onNewSession(obj, ~, e)
            obj.createSession(e.Session, e.ItemTypes);
        end

        function createSession(obj, session, itemTypes)
            arguments
                obj (1,1) QSPViewerNew.Application.OuterShell_UIFigureBased
                session (1,1) QSP.Session
                itemTypes cell
            end

            assert(~isempty(obj.TreeRoot));

            sessionNode = obj.createTreeNode(obj.TreeRoot, session, session.SessionName, 'folder_24.png', 'Session');

            buildingBlocksNode = obj.createTreeNode(sessionNode, [], 'Building Blocks', 'settings_24.png', 'Session');

            % TODOpax fix this map..
            iconFileName = ["flask2.png", "param_edit_24.png", "datatable_24.png", "target_stats.png", "acceptance_criteria.png", "stickman3.png"];

            buildingBlockNodeNames     = string(itemTypes(1:6,1));
            buildingBlockSettingsNames = string(itemTypes(1:6,2));

            for i = 1:numel(buildingBlockNodeNames)
                baseNode = obj.createTreeNode(buildingBlocksNode, [], buildingBlockNodeNames(i), iconFileName(i), buildingBlockNodeNames(i));
                nodes = session.Settings.(buildingBlockSettingsNames(i));

                for j = 1:numel(nodes)
                    obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, iconFileName(i), buildingBlockNodeNames(i));
                end
            end

            functionalityNode  = obj.createTreeNode(sessionNode, [], 'Functionalities', 'settings_24.png', 'Session');

            functionalityBlockNodeNames = string(itemTypes(7:end,2));
            iconFileNames = ["simbio_24.png", "optim_24.png", "stickman-3.png", "stickman-3-color.png", "sensitivity.png"];

            for i = 1:numel(functionalityBlockNodeNames)
                dummyNodeData.Type = "FunctionalitySummary";
                baseNode = obj.createTreeNode(functionalityNode, dummyNodeData, functionalityBlockNodeNames(i), iconFileNames(i), functionalityBlockNodeNames(i));
                nodes = session.(functionalityBlockNodeNames(i));
                for j = 1:numel(nodes)
                    obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, iconFileNames(i), functionalityBlockNodeNames(i));
                end
            end

            obj.createTreeNode(sessionNode, [], 'Deleted Items', 'trash_24.png', 'Session');
        end
    end

    methods(Access = private)
        function create(obj, appName, app)
            obj.UIFigure = uifigure('Visible', 'off');
            obj.UIFigure.Position = [100 100 1005 864];
            obj.UIFigure.Name = appName;
            %             obj.UIFigure.WindowButtonUpFcn = @(h,e) obj.executeCallbackArray(obj.WindowButtonUpCallbacks,h,e);
            %             obj.UIFigure.WindowButtonDownFcn = @(h,e)
            %             obj.executeCallbackArray(obj.WindowButtonDownCallbacks,h,e);%             TODOpax
            obj.UIFigure.CloseRequestFcn = @obj.onExit;

            constructMenuItems(obj);

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

            t = uitree(gLeft);
            t.Layout.Row = 2;
            t.Layout.Column = 1;
            obj.TreeRoot = t;
            obj.TreeRoot.Multiselect = 'on';
            obj.TreeRoot.SelectionChangedFcn = @obj.onTreeSelectionChange;

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

            % Show the figure after all components are created
            obj.UIFigure.Visible = 'on';

            addlistener(obj.paneManager, "Alert", @(h,e)obj.onAlert(h,e));
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

        function onTreeSelectionChange(obj, hSource, eventData)
            %TODOpax app.UIFigure.Pointer = 'watch'; This action should be fast
            %enough that we don't need the pointer to change.
            %app.container.Busy =0 this brings up the busy.

            %TODOpax drawnow limitrate;
            % TODO: Finish
            %First we determine the session that is selected
            %We can select mutliple nodes at once. Therefore we need to consider if SelectedNodes is a vector
            SelectedNodes = eventData.SelectedNodes;
            %             Root = handle.TreeRoot;

            %We only make changes if a single node is selected
            if numel(SelectedNodes) == 1
                % %                 ThisSessionNode = SelectedNodes;
                % %
                % %                 %Find which session is the parent of the current one
                % %                 while ~isempty(ThisSessionNode) && ThisSessionNode.Parent~=Root
                % %                     ThisSessionNode = ThisSessionNode.Parent;
                % %                 end

                %Update which session is currently selected
                % %                 if isempty(ThisSessionNode)
                % %                     app.SelectedSessionIdx = [];
                % %                 else
                % %
                % %                     % update path to include drop the UDF for previous session
                % %                     % and include the UDF for current session
                % %                     app.SelectedSession.removeUDF();
                % %                     app.SelectedSessionIdx = find(ThisSessionNode == app.SessionNode);
                % %                     app.SelectedSession.addUDF();
                % %
                % %                 end

                %Now that we have the correct session, we can work
                % TODOpax. I see no need to refresh everthing on tree selection
                % change.
                %app.refresh();


                % Determine if a Summary treenode has been selected.
                if isfield(SelectedNodes.NodeData, "Type")
                    nodeData = SelectedNodes.NodeData;
                    nodeData.ChildNodeData = [SelectedNodes.Children.NodeData];
                    obj.paneManager.openPane(nodeData);
                else
                    obj.paneManager.openPane(SelectedNodes.NodeData);
                end

                %                 app.updatePane(handle.paneGridLayout, SelectedNodes);

                %app.UIFigure.Pointer = 'arrow'; TODOpax no longer this
                %way.
            end
        end

        function treeNode = createTreeNode(~, Parent, Data, Name, Icon, PaneType)
            treeNode = uitreenode(...
                'Parent',   Parent,...
                'NodeData', Data,...
                'Text',     Name,...
                'UserData', PaneType,...
                'Icon',     QSPViewerNew.Resources.LoadResourcePath(Icon));
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

        function onAlert(obj, hSource, eventData)
            uialert(obj.UIFigure, eventData.message, 'Run Failed'); %todopax add this last arg to the eventData
        end

        function constructMenuItems(obj)
            obj.FileMenu                        = obj.createMenuItem(obj.UIFigure, "File");
            obj.NewCtrlNMenu                    = obj.createMenuItem(obj.FileMenu, "New...", @obj.onNew, "N");
            obj.OpenCtrl0Menu                   = obj.createMenuItem(obj.FileMenu, "Open...", @obj.onOpen, "O");
            obj.OpenRecentMenu                  = obj.createMenuItem(obj.FileMenu, "Open Recent");
            obj.CloseMenu                       = obj.createMenuItem(obj.FileMenu, "Close", @(h,e)obj.onClose([]), "", "on");
            obj.SaveCtrlSMenu                   = obj.createMenuItem(obj.FileMenu, "Save", @(h,e)obj.onSave([]), "S", "on");
            obj.SaveAsMenu                      = obj.createMenuItem(obj.FileMenu, "Save As...", @(h,e)obj.onSaveAs([]));
            obj.ExitCtrlQMenu                   = obj.createMenuItem(obj.FileMenu, "Exit", @obj.onExit, "Q", "on");
            obj.QSPMenu                         = obj.createMenuItem(obj.UIFigure, "QSP");
            obj.AddNewItemMenu                  = obj.createMenuItem(obj.QSPMenu, "Add New Item");
            obj.DatasetMenu                     = obj.createMenuItem(obj.AddNewItemMenu, "Dataset", @(h,e)obj.onAddItem([], 'OptimizationData'));
            obj.ParameterMenu                   = obj.createMenuItem(obj.AddNewItemMenu, "Parameter", @(h,e)obj.onAddItem([], 'Parameters'));
            obj.TaskMenu                        = obj.createMenuItem(obj.AddNewItemMenu, "Task", @(h,e)obj.onAddItem([], 'Task'));
            obj.VirtualSubjectsMenu             = obj.createMenuItem(obj.AddNewItemMenu, "Virtual Subject(s)", @(h,e)obj.onAddItem([], 'VirtualPopulation'));
            obj.AcceptanceCriteriaMenu          = obj.createMenuItem(obj.AddNewItemMenu, "Acceptance Criteria", @(h,e)obj.onAddItem([], 'VirtualPopulationData'));
            obj.TargetStatisticsMenu            = obj.createMenuItem(obj.AddNewItemMenu, "Target Statistics", @(h,e)obj.onAddItem([], 'VirtualPopulationGenerationData'));
            obj.SimulationMenu                  = obj.createMenuItem(obj.AddNewItemMenu, "Simulation", @(h,e)obj.onAddItem([], 'Simulation'));
            obj.OptimizationMenu                = obj.createMenuItem(obj.AddNewItemMenu, "Optimization", @(h,e)obj.onAddItem([], 'Optimization'));
            obj.CohortGenerationMenu            = obj.createMenuItem(obj.AddNewItemMenu, "Cohort Generation", @(h,e)obj.onAddItem([], 'CohortGeneration'));
            obj.VirtualPopulationGenerationMenu = obj.createMenuItem(obj.AddNewItemMenu, "Virtual Population Generation", @(h,e)obj.onAddItem([], 'VirtualPopulationGeneration'));
            obj.GlobalSensitivityAnalysisMenu   = obj.createMenuItem(obj.AddNewItemMenu, "Global Sensitivity Analysis", @(h,e)obj.onAddItem([], 'GlobalSensitivityAnalysis'));
            obj.DeleteSelectedItemMenu          = obj.createMenuItem(obj.QSPMenu, "Delete Selected Item", @(h,e)obj.onDeleteSelectedItem([], []));
            obj.RestoreSelectedItemMenu         = obj.createMenuItem(obj.QSPMenu, "Restore Selected Item", @(h,e)obj.onRestoreSelectedItem([], []));
            obj.ToolsMenu                       = obj.createMenuItem(obj.UIFigure, "Tools");
            obj.ModelManagerMenu                = obj.createMenuItem(obj.ToolsMenu, "Model Manager", @(h,e)obj.onOpenModelManager);
            obj.PluginsMenu                     = obj.createMenuItem(obj.ToolsMenu, "Plugin Manager", @(h,e)obj.onOpenPluginManager);
            obj.LoggerMenu                      = obj.createMenuItem(obj.ToolsMenu, "Logger", @(h,e)obj.onOpenLogger);
            obj.HelpMenu                        = obj.createMenuItem(obj.UIFigure, "Help");
            obj.AboutMenu                       = obj.createMenuItem(obj.HelpMenu, "About", @(h,e)obj.onAbout);
        end

        function menuObj = createMenuItem(obj, parent, text, menuSelectedFcn, accelerator, separator)
            arguments
                obj
                parent
                text (1,1) string
                menuSelectedFcn = ''
                accelerator (1,1) string = ""
                separator (1,1) string = "off"
            end
            menuObj = uimenu(parent, "Text", text, "MenuSelectedFcn", menuSelectedFcn, "Separator", separator, "Accelerator", accelerator);
        end
    end
end