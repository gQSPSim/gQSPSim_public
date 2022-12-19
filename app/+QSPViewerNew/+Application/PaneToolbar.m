classdef PaneToolbar < handle
    properties (Access = ?matlab.uitest.TestCase)
        parent
        buttonsLayout
        
        summaryButton
        editButton
        runButton
        parallelButton
        gitButton
        visualizeButton
        settingsButton
        zoomInButton
        zoomOutButton
        panButton
        exploreButton

        minimalModeButtons
        maximalModeButtons
        explorationButtons
    end

    properties(Dependent)
        mode (1,1) QSPViewerNew.Application.ToolbarMode
    end

    events
        Summary
        Edit
        Run
        Parallel
        Visualize
        Settings
        ZoomIn
        ZoomOut
        Pan
        Explore

        GitStateChange
        UseParallelStateChange
    end

    methods
        function obj = PaneToolbar(parent)
            arguments
                parent matlab.ui.container.GridLayout
            end

            obj.parent = parent;
            obj.construct();

            obj.mode = "None";
        end

        function construct(obj)
            arguments
                obj (1,1) QSPViewerNew.Application.PaneToolbar
            end

            buttonWidth          = 30;
            numberOfButtonSpaces = 12;           

            obj.buttonsLayout = uigridlayout(obj.parent);
            obj.buttonsLayout.Tag           = "PaneToolbar:buttonsLayout";
            obj.buttonsLayout.Layout.Row    = 1;
            obj.buttonsLayout.Layout.Column = 1;
            obj.buttonsLayout.Padding       = [0 0 0 0];
            obj.buttonsLayout.ColumnSpacing = 2;
            obj.buttonsLayout.RowSpacing    = 0;
            obj.buttonsLayout.RowHeight     = {30};
            obj.buttonsLayout.ColumnWidth   = horzcat(repmat({buttonWidth}, 1, numberOfButtonSpaces), '1x');

            obj.summaryButton   = obj.createButton(1,  "push",  "Summary",        "report_24.png",      "View summary");
            obj.editButton      = obj.createButton(2,  "push",  "Edit",           "edit_24.png",        "Edit the selected item");            
            obj.runButton       = obj.createButton(3,  "push",  "Run",            "play_24.png",        "Run the selected item");            
            
            obj.parallelButton  = obj.createButton(4,  "state", "UseParallelStateChange", ["paralleloff_24.png", "parallelon_24.png"], "Enable Parallel");            
            obj.gitButton       = obj.createButton(5,  "state", "GitStateChange",         ["gitoff_24.png",      "giton_24.png"],      "Enable Git");

            obj.visualizeButton = obj.createButton(7,  "push",  "Visualize", "plot_24.png",        "Visualize the selected item");
            obj.settingsButton  = obj.createButton(8,  "push",  "Settings",  "settings_24.png",    "Customize plot settings the selected item");
            obj.zoomInButton    = obj.createButton(9,  "state", "ZoomIn",    ["zoomin.png", ""],   "Zoom In");
            obj.zoomOutButton   = obj.createButton(10, "state", "ZoomOut",   ["zoomout.png", ""],  "Zoom Out");
            obj.panButton       = obj.createButton(11, "state", "Pan",       ["pan.png", ""],      "Pan");
            obj.exploreButton   = obj.createButton(12, "state", "Explore",   ["datatip.png", ""],  "Explore");


            % Make sets of buttons that make up a "mode"
            obj.minimalModeButtons = [obj.summaryButton, obj.editButton];
            obj.maximalModeButtons = [obj.runButton, obj.parallelButton, obj.gitButton, obj.visualizeButton, obj.settingsButton,...
                obj.zoomInButton, obj.zoomOutButton, obj.panButton, obj.exploreButton];
            obj.explorationButtons = [obj.zoomInButton, obj.zoomOutButton, obj.panButton, obj.exploreButton];

            % Set the initial state of the exploration buttons to disabled.
            set(obj.explorationButtons, 'Enable', 'off');
        end

        function newButton = createButton(obj, positionIndex, type, name, iconName, tooltipText)
            % Creates two kinds of buttons, push and state. This makes the
            % API a little clumsy. I.e. iconName is a string array because
            % for state we need two names and by assumption the first one is
            % for the off state. 
            newButton= uibutton(obj.buttonsLayout, type);
            newButton.Layout.Row    = 1;
            newButton.Layout.Column = positionIndex;
            newButton.Icon = QSPViewerNew.Resources.LoadResourcePath(iconName(1));
            newButton.Tooltip = tooltipText;
            if type == "push"
                newButton.ButtonPushedFcn = @(h,e)obj.onPushButton(name, e);
            elseif type == "state"
                newButton.ValueChangedFcn = @(h,e)obj.onStateChange(name, e);
                newButton.UserData.icons.on  = iconName(2);
                newButton.UserData.icons.off = iconName(1);
            end
            newButton.Text = '';
            newButton.Visible = true;            
        end

        function set.mode(obj, mode)
            % The button toolbar can be in one of 4 states/modes.
            % None, Minimal, Maximal, MaximalToolsDisabled (all disabled).
            arguments
                obj
                mode (1,1) QSPViewerNew.Application.ToolbarMode
            end

            switch mode
                case QSPViewerNew.Application.ToolbarMode.None
                    set([obj.minimalModeButtons, obj.maximalModeButtons], 'Visible', 'off');
                case QSPViewerNew.Application.ToolbarMode.Minimal
                    set(obj.minimalModeButtons, 'Visible', 'on');
                    set(obj.maximalModeButtons, 'Visible', 'off');
                case QSPViewerNew.Application.ToolbarMode.Maximal
                    set([obj.minimalModeButtons, obj.maximalModeButtons], 'Visible', 'on');
                case QSPViewerNew.Application.ToolbarMode.MaximalToolsDisabled
                    % Todopax
            end
        end

        function onStateChange(obj, name, event)
            % A state button pressed. Change the icon and send a notification.
            if event.Value == 1                
                event.Source.Icon = QSPViewerNew.Resources.LoadResourcePath(event.Source.UserData.icons.on);
            elseif event.Value == 0
                event.Source.Icon = QSPViewerNew.Resources.LoadResourcePath(event.Source.UserData.icons.off);
            end

            notify(obj, name, event);            
        end

        function onPushButton(obj, name, event)
            % push button pressed. Notify of the event and take care of
            % configuring the toolbar based on the selection made. Right
            % now that is only relevant for the visualize case.
            if name == "Visualize"
                set(obj.explorationButtons, 'Enable', 'on');
            else
                set(obj.explorationButtons, 'Enable', 'off');
            end

            notify(obj, name, event);
        end
    end
end