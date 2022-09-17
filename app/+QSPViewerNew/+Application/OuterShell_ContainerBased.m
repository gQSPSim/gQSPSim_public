classdef OuterShell_ContainerBased < handle
    properties
        container      (1,1) matlab.ui.container.internal.AppContainer
        figureDocGroup (1,1) matlab.ui.internal.FigureDocumentGroup
        figDocument    (1,1) matlab.ui.internal.FigureDocument
        paneGridLayout (1,1) matlab.ui.container.GridLayout
        paneHolder     (1,1) struct
        TreeRoot       (1,1) matlab.ui.container.Tree
    end

    events
        ReadyState
        TreeSelectionChange        
    end

    methods
        function obj = OuterShell_ContainerBased()
            obj.container = matlab.ui.container.internal.AppContainer;
            obj.container.WindowBounds = [ 11   175   916   678];
            obj.container.Title = "gQSPSim";
            obj.container.Tag = 'gQSPimViewer';
            obj.container.ShowSingleDocumentTab = false;

            % Toolstrip
            constructToolstrip(obj);

            % Session Explorer
            pOptions.Region = 'left';
            pOptions.Title = 'Session Explorer';
            parentPanel = matlab.ui.internal.FigurePanel(pOptions);
            obj.container.addPanel(parentPanel);

            obj.TreeRoot = uitree(parentPanel.Figure);

            parentPanel.Figure.AutoResizeChildren = 'off';
            parentPanel.Figure.SizeChangedFcn = @(h,e) onFigurePanelSizeChanged(obj,h,e);

            %obj.TreeRoot.SelectionChangedFcn = @obj.onTreeSelectionChanged;
            addlistener(obj.container, 'StateChanged', @obj.onContainerStateChanged);

            % TODOpax. For development purposes load a Session here
            % Session = load('tests/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat');
            % obj.Sessions = Session.Session;
            % obj.createSession(obj.TreeRoot, obj.Sessions);

            % Create RHS panel
            obj.figureDocGroup = matlab.ui.internal.FigureDocumentGroup();
            obj.figureDocGroup.Tag = 'Panes';
            obj.figureDocGroup.Maximizable = true;
            obj.figureDocGroup.Closable = false;
            obj.container.registerDocumentGroup(obj.figureDocGroup);

            figOptions.Title = "Panes";
            figOptions.DocumentGroupTag = "Panes";
            obj.figDocument = matlab.ui.internal.FigureDocument(figOptions);

            obj.figDocument.Closable = false;

            obj.container.add(obj.figDocument);

            obj.paneGridLayout = uigridlayout(obj.figDocument.Figure);

            obj.paneGridLayout.ColumnWidth = {'1x'};
            obj.paneGridLayout.RowHeight   = {'1x'};

            if false
                % Plotting Area
                % Create and register a Figure-based document group
                % TODO, the documentGroup.SubGridDimensions does not take
                % effect until the objContainer has rendered. Need a callback
                % to get this to work.
                obj.plotGrid = Viewer.PlotGrid(obj);
                obj.container.registerDocumentGroup(obj.plotGrid.figureDocGroup);

                % Hook Viewer callbacks

                % Listen for GeneralSettings functionality changes
                addlistener(obj.generalSettings, 'FunctionalityChange', @obj.functionalityChange);

                % Within Viewer events/listeners (these don't go in the
                % controller)
                gs = obj.generalSettings;
                addlistener(obj.simulationTask, 'createNewVariant', @gs.addVariant);

                % 1. Listen to the objContainer StateChanged event for
                % initialization purposes.
                addlistener(obj.container, 'StateChanged', @(x,y)obj.initializationState(y));

                % 2. PlotGrid rows and columns controlled by dropdown widget in plot settings.
                % Fix this listener connection.
                addlistener(obj.plotSettings.plotLayout, 'ValueChanged', @(x,y)obj.plotGridChangeFcn(y));

            end
            obj.container.Visible = true;
        end

        function onNewSession(obj, ~, e)
            obj.createSession(e.Session, e.ItemTypes);
        end

        function createSession(obj, session, itemTypes)
            arguments
                obj (1,1) QSPViewerNew.Application.OuterShell_ContainerBased
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

            trashNode = obj.createTreeNode(sessionNode, [], 'Deleted Items', 'trash_24.png', 'Session');
        end
    end

    methods(Access=private)
        function constructToolstrip(obj)
            obj.container.ToolstripEnabled = true;
            TabGroup = matlab.ui.internal.toolstrip.TabGroup();
            homeTab = matlab.ui.internal.toolstrip.Tab("HOME");
            TabGroup.Tag = "Home";
            TabGroup.add(homeTab);

            % Project
            projectSection = homeTab.addSection("Project");
            % Open
            newColumn = projectSection.addColumn();
            openButton = matlab.ui.internal.toolstrip.SplitButton('Open', 'src/+view/icons/open_24.png');
            newColumn.add(openButton);
            popup = matlab.ui.internal.toolstrip.PopupList();
            openItem = matlab.ui.internal.toolstrip.ListItem('Open');
            openRecentItem = matlab.ui.internal.toolstrip.ListItemWithPopup('Open Recent');
            popup.add(openItem);
            popup.add(openRecentItem);
            openButton.Popup = popup;
            %                 openRecentItem.DynamicPopupFcn = @app.openRecentListFcn;       TODOpax

            % Save
            newColumn = projectSection.addColumn();
            saveButton = matlab.ui.internal.toolstrip.SplitButton('Save', 'src/+view/icons/save_24.png');
            newColumn.add(saveButton);
            popup = matlab.ui.internal.toolstrip.PopupList();
            SaveListItem = matlab.ui.internal.toolstrip.ListItem('Save');
            SaveAsListItem = matlab.ui.internal.toolstrip.ListItem('Save as');
            popup.add(SaveListItem);
            popup.add(SaveAsListItem);
            saveButton.Popup = popup;

            % Close
            newColumn = projectSection.addColumn();
            newColumn.add(matlab.ui.internal.toolstrip.Button('Close', 'src/+view/icons/close_24.png'));

            % Tools
            toolsSection = homeTab.addSection("Tools");

            % Model Manager
            newColumn = toolsSection.addColumn();
            newColumn.add(matlab.ui.internal.toolstrip.Button('Model Manager', 'src/+view/icons/close_24.png'));

            % Plugin Manager
            newColumn = toolsSection.addColumn();
            newColumn.add(matlab.ui.internal.toolstrip.Button('Plugin Manager', 'src/+view/icons/close_24.png'));

            % Logger
            newColumn = toolsSection.addColumn();
            newColumn.add(matlab.ui.internal.toolstrip.Button('Logger', 'src/+view/icons/close_24.png'));

            % Run
            runSection = homeTab.addSection("Run");
            newColumn = runSection.addColumn();
            runButton = matlab.ui.internal.toolstrip.Button('Run', 'src/+view/icons/run_24.png');
            runButton.ButtonPushedFcn = @app.runPushedFcn;
            newColumn.add(runButton);

            % Help
            runSection = homeTab.addSection("Resources");
            newColumn = runSection.addColumn();
            helpButton = matlab.ui.internal.toolstrip.SplitButton('Help', 'src/+view/icons/help_24.png');
            newColumn.add(helpButton);

            popup = matlab.ui.internal.toolstrip.PopupList();
            userGuideItem = matlab.ui.internal.toolstrip.ListItem('User Guide...');
            aboutItem = matlab.ui.internal.toolstrip.ListItem('About gPKPDSim...');
            popup.add(userGuideItem);
            popup.add(aboutItem);
            helpButton.Popup = popup;

            obj.container.add(TabGroup);
        end

        function onFigurePanelSizeChanged(obj, h, e)
%             obj.TreeRoot = uitree(h);
            obj.TreeRoot.Position = h.Position;            
            h.SizeChangedFcn = [];
            h.AutoResizeChildren = 'on';
            addlistener(obj.TreeRoot, 'SelectionChanged', @obj.treeSelectionChange);

        end

        function treeSelectionChange(obj, hSource, eData)
            notify(obj, 'TreeSelectionChange', eData);
        end

        function onContainerStateChanged(obj, hSource, evt)
            % Could finalize the layout here
            if strcmp(hSource.State, 'RUNNING')
                notify(obj, 'ReadyState');
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
    end
end