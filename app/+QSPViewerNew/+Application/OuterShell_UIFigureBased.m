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
        FlexGridLayout           QSPViewerNew.Widgets.GridFlex
        SessionExplorerPanel     matlab.ui.container.Panel
        SessionExplorerGrid      matlab.ui.container.GridLayout
        TreeRoot                 matlab.ui.container.Tree
        TreeMenu
        OpenRecentMenuArray
        IsConstructed (1,1) logical = false
        paneGridLayout
    end

    events
        ReadyState
        TreeSelectionChange
    end

    methods
        function obj = OuterShell_UIFigureBased(appname)
            arguments
                appname (1,1) string
            end
            
            % Create the graphics objects
            obj.create(appname);

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
                baseNode = obj.createTreeNode(functionalityNode, [], functionalityBlockNodeNames(i), iconFileNames(i), functionalityBlockNodeNames(i));
                nodes = session.(functionalityBlockNodeNames(i));
                for j = 1:numel(nodes)
                    obj.createTreeNode(baseNode, nodes(j), nodes(j).Name, iconFileNames(i), functionalityBlockNodeNames(i));
                end
            end

            obj.createTreeNode(sessionNode, [], 'Deleted Items', 'trash_24.png', 'Session');
        end
    end

    methods(Access = private)
        function create(obj, appName)
            obj.UIFigure = uifigure('Visible', 'off');
            obj.UIFigure.Position = [100 100 1005 864];
            obj.UIFigure.Name = appName;
            %             obj.UIFigure.WindowButtonUpFcn = @(h,e) obj.executeCallbackArray(obj.WindowButtonUpCallbacks,h,e);
            %             obj.UIFigure.WindowButtonDownFcn = @(h,e)
            %             obj.executeCallbackArray(obj.WindowButtonDownCallbacks,h,e);%             TODOpax
            obj.UIFigure.CloseRequestFcn = @obj.onExit;

            constructMenuItems(obj);

            % Create GridLayout
            obj.FlexGridLayout = QSPViewerNew.Widgets.GridFlex(obj.UIFigure);
            obj.FlexGridLayout.getGridHandle();
            %             obj.addWindowDownCallback(obj.FlexGridLayout.getButtonDownCallback());
            %             obj.addWindowUpCallback(obj.FlexGridLayout.getButtonUpCallback());

            % Create SessionExplorerPanel
            obj.SessionExplorerPanel = uipanel(obj.FlexGridLayout.getGridHandle());
            obj.SessionExplorerPanel.Title = 'Session Explorer';
            obj.SessionExplorerPanel.Layout.Row = 1;
            obj.SessionExplorerPanel.Layout.Column = 1;

            % Create TreeGrid
            obj.SessionExplorerGrid = uigridlayout(obj.SessionExplorerPanel);
            obj.SessionExplorerGrid.ColumnWidth = {'1x'};
            obj.SessionExplorerGrid.RowHeight = {'1x'};

            % Create Tree
            obj.TreeRoot = uitree(obj.SessionExplorerGrid);
            obj.TreeRoot.Multiselect = 'on';
            obj.TreeRoot.SelectionChangedFcn = @obj.onTreeSelectionChange;

            % Pane gridlayout
            obj.paneGridLayout = uigridlayout(obj.FlexGridLayout.getGridHandle());
            obj.paneGridLayout.Layout.Row = 1;
            obj.paneGridLayout.Layout.Column = 3;
            obj.paneGridLayout.RowHeight = {'1x'};
            obj.paneGridLayout.ColumnWidth = {'1x'};

            % Show the figure after all components are created
            obj.UIFigure.Visible = 'on';
        end

        function onTreeSelectionChange(obj, hSource, eData)
            notify(obj, 'TreeSelectionChange', eData);
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