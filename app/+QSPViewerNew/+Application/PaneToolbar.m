classdef PaneToolbar < handle

    properties
        parent
        buttonsLayout
        
        minimalModeButtons
        maximalModeButtons
        
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
    end

    methods
        function obj = PaneToolbar(parent)
            arguments
                parent
            end

            obj.parent = parent;
            obj.construct();
            obj.minimalModeButtons = [obj.summaryButton, obj.editButton];
            obj.maximalModeButtons = [obj.runButton, obj.parallelButton, obj.gitButton, obj.visualizeButton, obj.settingsButton, obj.zoomInButton, obj.zoomOutButton, obj.panButton, obj.exploreButton];
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

            obj.summaryButton   = obj.createButton(1,  "push",  "Summary",   "report_24.png",      "View summary");
            obj.editButton      = obj.createButton(2,  "push",  "Edit",      "edit_24.png",        "Edit the selected item");            
            obj.runButton       = obj.createButton(3,  "push",  "Run",       "play_24.png",        "Run the selected item");            
            obj.parallelButton  = obj.createButton(4,  "state", "Parallel",  "paralleloff_24.png", "Enable Parallel");            
            obj.gitButton       = obj.createButton(5,  "state", "Git",       "gitoff_24.png",      "Enable Git");

            obj.visualizeButton = obj.createButton(7,  "push",  "Visualize", "plot_24.png",        "Visualize the selected item");
            obj.settingsButton  = obj.createButton(8,  "push",  "Settings",  "settings_24.png",    "Customize plot settings the selected item");
            obj.zoomInButton    = obj.createButton(9,  "state", "ZoomIn",    "zoomin.png",         "Zoom In");
            obj.zoomOutButton   = obj.createButton(10, "state", "ZoomOut",   "zoomout.png",        "Zoom Out");
            obj.panButton       = obj.createButton(11, "state", "Pan",       "pan.png",            "Pan");
            obj.exploreButton   = obj.createButton(12, "state", "Explore",   "datatip.png",        "Explore");
        end

        function newButton = createButton(obj, positionIndex, type, name, iconName, tooltipText)
            newButton= uibutton(obj.buttonsLayout, type);
            newButton.Layout.Row = 1;
            newButton.Layout.Column = positionIndex;
            newButton.Icon = QSPViewerNew.Resources.LoadResourcePath(iconName);
            newButton.Tooltip = tooltipText;
            if type == "push"
                newButton.ButtonPushedFcn = @(h,e)obj.onNavigation(name, h, e);
            elseif type == "state"
                newButton.ValueChangedFcn = @(h,e)obj.onNavigation(name, h, e);
            end
            newButton.Text = '';
            newButton.Visible = true;            
        end

        function setMinimalMode(obj)
            set(obj.minimalModeButtons, 'Visible', 'on');
            set(obj.maximalModeButtons, 'Visible', 'off');

        end

        function setMaximalMode(obj)
            set([obj.minimalModeButtons, obj.maximalModeButtons], 'Visible', 'on');
        end

        function onNavigation(obj, name, source, event)
%             Figure = ancestor(obj.OuterGrid,'figure');
%             Figure.Pointer = 'watch';
%             obj.Focus = keyword;
%             obj.refocus;
%             Figure.Pointer = 'arrow';
            disp('onNavigation called');
        end
    end
end