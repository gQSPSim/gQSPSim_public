classdef ViewPane < matlab.mixin.Heterogeneous & handle
    % ViewPane - An abstract base class for various view panes
    % ---------------------------------------------------------------------
    % Base properties that should be observed by all subclasses
    %
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %   1/14/20
    % ---------------------------------------------------------------------
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private) 
        IsConstructed = false
        Parent
        CurrentPane
        LayoutColumn
        LayoutRow
        ParentApp
        Focus = '';
        HasVisualization
        PlotSettings = QSP.PlotSettings.empty(1,0)
    end
    
    properties (SetAccess=protected)       
       PlotArray = matlab.ui.control.UIAxes.empty(12,0);
       VisDirty = false;
       AxesLegend
       AxesLegendChildren
       SpeciesGroup
       DatasetGroup
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        OuterGrid           matlab.ui.container.GridLayout
        SummaryPanel        matlab.ui.container.Panel
        SummaryGrid         matlab.ui.container.GridLayout
        SummaryContent      QSPViewerNew.Widgets.Summary
        EditPanel           matlab.ui.container.Panel
        EditLayout          matlab.ui.container.GridLayout
        FileSelectLayout    matlab.ui.container.GridLayout
        EditButtonLayout    matlab.ui.container.GridLayout
        RemoveButton        matlab.ui.control.Button
        SaveButton          matlab.ui.control.Button
        CancelButton        matlab.ui.control.Button
        DescriptionLabel    matlab.ui.control.Label
        DescriptionEditBox  matlab.ui.control.EditField
        NameLabel           matlab.ui.control.Label
        NameEditBox         matlab.ui.control.EditField
        EditButton          matlab.ui.control.Button
        SummaryButton       matlab.ui.control.Button
        ButtonsLayout       matlab.ui.container.GridLayout
        SummaryLabel        matlab.ui.control.Label
        EditLabel           matlab.ui.control.Label
        RunButton           matlab.ui.control.Button
        ParallelButton      matlab.ui.control.Button
        GitButton           matlab.ui.control.Button
        VisualizeButton     matlab.ui.control.Button
        SettingsButton      matlab.ui.control.Button
        ZoomInButton        matlab.ui.control.StateButton
        ZoomOutButton       matlab.ui.control.StateButton
        PanButton           matlab.ui.control.StateButton
        ExploreButton       matlab.ui.control.StateButton
        VisualizationPanel  matlab.ui.container.Panel
        VisualizationGrid   QSPViewerNew.Widgets.GridFlex
        PlottingGrid        matlab.ui.container.GridLayout
        PlotInteractionGrid matlab.ui.container.GridLayout
        PlotDropDown        matlab.ui.control.DropDown
        YScaleMenu  = matlab.ui.control.UIAxes.empty(1,0);
        
        ContextMenuArray = matlab.ui.control.UIAxes.empty(1,0);
        YLinearMenu = matlab.ui.container.Menu.empty(1,0);
        YLogMenu = matlab.ui.container.Menu.empty(1,0);
        SaveMenu = matlab.ui.container.Menu.empty(1,0);
        SaveFullMenu = matlab.ui.container.Menu.empty(1,0);
        TracesMenu = matlab.ui.container.Menu.empty(1,0);
        QuantilesMenu = matlab.ui.container.Menu.empty(1,0);
        MeanMenu = matlab.ui.container.Menu.empty(1,0);
        MedianMenu = matlab.ui.container.Menu.empty(1,0);
        StandardDeviationMenu = matlab.ui.container.Menu.empty(1,0);
        
        EmptyParent = matlab.ui.Figure.empty(1,0);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constants for UI specification
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant = true)
        ButtonPadding = [0,0,0,0];
        ButtonWidthSpacing = 0; 
        ButtonHeightSpacing = 0; 
        WidgetPadding = [0,0,0,0];
        WidgetWidthSpacing = 5; 
        WidgetHeightSpacing = 5; 
        PanelPadding = [5,5,5,0];
        PanelWidthSpacing = 5; 
        PanelHeightSpacing = 5; 
        SubPanelPadding = [5,5,5,5];
        SubPanelWidthSpacing = 5; 
        SubPanelHeightSpacing = 5; 
        OuterGridPadding = [5,5,5,0];
        OuterGridColumnSpacing = 0;
        OuterGridRowSpacing = 0;
        ButtonWidth = 30;
        ButtonHeight = 30;
        WidgetHeight = 30;
        TextBoxHeight = 30;
        HeaderColor = [.25,.60,.72];
        FontSize = 15;
        Font = 'default';
        HeaderHeight = 20;
        RowSpacing = 0;
        LabelLength = 100;
        LabelHeight = 30;
        NameProportion = '3x';
        DescriptionProportion = '5x';
        RemoveInvalidButtonWidth = 100;
        SaveButtonWidth = 100;
        CancelButtonWidth = 100;
        EditLabelText = ' Edit';
        SummaryLabelText = ' Summary'
        PanelBackgroundColor = [.97,.97,.97];
        SubPanelColor = [.97,.97,.97];
        SmallLabel = 80;
        MaxNumPlots = 12
        PlotLayoutOptions = {'1x1','1x2','2x1','2x2','3x2','3x3','3x4'}
        DescriptionSize = 200;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = ViewPane(varargin)
            if nargin == 5 && isa(varargin{1},'matlab.ui.container.GridLayout')
                obj.Parent = varargin{1};
                obj.LayoutRow = varargin{2};
                obj.LayoutColumn = varargin{3};
                obj.ParentApp = varargin{4};
                obj.HasVisualization = varargin{5};
            else
                message = ['This constructor requires the following inputs' ...
                    newline '1.' ...
                    newline '-Graphical Parent: uigridlayout...' ...
                    newline '-GridRow: int' ...
                    newline '-GridColumn: int' ...
                    newline '-uigridlayout...' ...
                    newline '-Parent application: matlab.apps.AppBase' ...
                    newline '-VisualizationYorN: boolean'];
                    error(message)
            end

            %create the objects on our end
            obj.create();
            obj.OuterGrid.Parent = obj.Parent;
            obj.OuterGrid.Visible = 'off';
            
            %Mark as constructed
            obj.IsConstructed = true;
            
            %Set the focus to the summary screen
            obj.Focus = 'Summary';
        end
        
        function delete(~)
            %Destructor
            hTimer = timerfindall('Tag','QSPtimer');
            if ~isempty(hTimer)
                stop(hTimer)
                delete(hTimer)
            end
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Methods for UI components initilization
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
       function create(obj)
           %Setup Outer Panel         
           obj.OuterGrid = uigridlayout(obj.Parent);
           obj.OuterGrid.ColumnWidth = {'1x'};
           obj.OuterGrid.RowHeight = {obj.ButtonHeight,'1x'};
           obj.OuterGrid.ColumnWidth = {'1x'};
           obj.OuterGrid.Padding = obj.OuterGridPadding;
           obj.OuterGrid.RowSpacing = obj.OuterGridRowSpacing;
           obj.OuterGrid.Layout.Row = obj.LayoutRow;
           obj.OuterGrid.Layout.Column = obj.LayoutColumn;

           %Setup the Summary Panel and Button
           obj.SummaryPanel = uipanel(obj.OuterGrid);
           obj.SummaryPanel.BackgroundColor = [.9,.9,.9];
           obj.SummaryPanel.Layout.Row = 2;
           obj.SummaryPanel.Layout.Column = 1;
           obj.SummaryPanel.BackgroundColor = obj.PanelBackgroundColor;
           obj.SummaryPanel.Visible = 'off';
           %Setup SummaryGrid
           obj.SummaryGrid = uigridlayout(obj.SummaryPanel);
           obj.SummaryGrid.ColumnWidth = {'1x'};
           obj.SummaryGrid.RowHeight = {obj.HeaderHeight,'1x'};
           obj.SummaryGrid.Padding = obj.PanelPadding;
           obj.SummaryGrid.RowSpacing = obj.PanelHeightSpacing;
           obj.SummaryGrid.RowSpacing = obj.PanelWidthSpacing;
           
           %Add label to the top
           obj.SummaryLabel = uilabel(obj.SummaryGrid);
           obj.SummaryLabel.Text = obj.SummaryLabelText;
           obj.SummaryLabel.FontName = obj.Font;
           obj.SummaryLabel.BackgroundColor = obj.HeaderColor;
           obj.SummaryLabel.Layout.Row = 1;
           obj.SummaryLabel.Layout.Column = 1;
           
           %Summary Widget
           obj.SummaryContent = QSPViewerNew.Widgets.Summary(obj.SummaryGrid,2,1,{'Dummy','info';'Purpose','Testing'});
           obj.SummaryContent.Information = {'Yellow','Dog'; 'Blue','Cat'};
            
           %Edit Panel
           obj.EditPanel = uipanel(obj.OuterGrid);
           obj.EditPanel.BackgroundColor = obj.PanelBackgroundColor;
           obj.EditPanel.Layout.Row = 2;
           obj.EditPanel.Layout.Column = 1;
           obj.EditPanel.Visible = 'off';
           
           %All Edit Panels have the following 3 subpanels
           % 1. the name and description
           % 2. The contents of the panel
           % 3. The svae/cancel/remove invalid button
        
            %Setup EditGrid
           obj.EditLayout = uigridlayout(obj.EditPanel);
           obj.EditLayout.ColumnWidth = {'1x'};
           obj.EditLayout.RowHeight = {obj.HeaderHeight,obj.WidgetHeight,'1x',obj.ButtonHeight};
           obj.EditLayout.Padding = obj.PanelPadding;
           obj.EditLayout.RowSpacing = obj.PanelHeightSpacing;
           obj.EditLayout.RowSpacing = obj.PanelWidthSpacing;
           
           %Setup Edit Panel Label
           obj.EditLabel = uilabel(obj.EditLayout);
           obj.EditLabel.Text = obj.EditLabelText;
           obj.EditLabel.FontName = obj.Font;
           obj.EditLabel.BackgroundColor = obj.HeaderColor;
           obj.EditLabel.Layout.Row = 1;
           obj.EditLabel.Layout.Column = 1;
           
           %Row 1: The name and desecription
           obj.FileSelectLayout = uigridlayout(obj.EditLayout);
           obj.FileSelectLayout.ColumnWidth = {obj.LabelLength,obj.NameProportion,obj.LabelLength,obj.DescriptionProportion};
           obj.FileSelectLayout.RowHeight = {'1x'};
           obj.FileSelectLayout.Padding = obj.WidgetPadding;
           obj.FileSelectLayout.ColumnSpacing = obj.WidgetWidthSpacing;
           obj.FileSelectLayout.RowSpacing = obj.WidgetHeightSpacing;
           obj.FileSelectLayout.Layout.Row = 2;
           obj.FileSelectLayout.Layout.Column = 1;
           
           obj.NameLabel = uilabel(obj.FileSelectLayout);
           obj.NameLabel.Layout.Row = 1;
           obj.NameLabel.Layout.Column = 1;
           obj.NameLabel.Text = 'Name';
           obj.NameLabel.HorizontalAlignment = 'center';
           obj.NameLabel.FontWeight = 'bold';
           obj.NameLabel.FontName = obj.Font;
           
           obj.NameEditBox = uieditfield(obj.FileSelectLayout);
           obj.NameEditBox.Layout.Row = 1;
           obj.NameEditBox.Layout.Column = 2;
           obj.NameEditBox.ValueChangedFcn = @(h,e) obj.onEdit('Name',e.Value);
           
           obj.DescriptionLabel = uilabel(obj.FileSelectLayout);
           obj.DescriptionLabel.Layout.Row = 1;
           obj.DescriptionLabel.Layout.Column = 3;
           obj.DescriptionLabel.Text = 'Description';
           obj.DescriptionLabel.HorizontalAlignment = 'center';
           obj.DescriptionLabel.FontWeight = 'bold';
           obj.DescriptionLabel.FontName = obj.Font;
           
           obj.DescriptionEditBox = uieditfield(obj.FileSelectLayout);
           obj.DescriptionEditBox.Layout.Row = 1;
           obj.DescriptionEditBox.Layout.Column = 4;
           obj.DescriptionEditBox.ValueChangedFcn = @(h,e) obj.onEdit('Description',e.Value);
          
           %Rows 3: Save/cancel/Remove invalid
           obj.EditButtonLayout = uigridlayout(obj.EditLayout);
           obj.EditButtonLayout.Layout.Column = 1;
           obj.EditButtonLayout.Layout.Row = 4;
           obj.EditButtonLayout.ColumnWidth = {'1x',obj.RemoveInvalidButtonWidth,obj.SaveButtonWidth,obj.CancelButtonWidth};
           obj.EditButtonLayout.RowHeight = {'1x'};
           obj.EditButtonLayout.Padding= obj.ButtonPadding;
           obj.EditButtonLayout.ColumnSpacing = obj.ButtonWidthSpacing;
           
           obj.RemoveButton = uibutton(obj.EditButtonLayout,'push');
           obj.RemoveButton.Layout.Row = 1;
           obj.RemoveButton.Layout.Column = 2;
           obj.RemoveButton.Text = 'Remove Invalid';
           obj.RemoveButton.Tag = 'Remove';
           obj.RemoveButton.Tooltip = 'Remove Invalid Entries';
           obj.RemoveButton.ButtonPushedFcn = @(~,~) obj.onRemoveInvalid();
           
           obj.SaveButton = uibutton(obj.EditButtonLayout,'push');
           obj.SaveButton.Layout.Row = 1;
           obj.SaveButton.Layout.Column = 3;
           obj.SaveButton.Text = 'OK';
           obj.SaveButton.Tag = 'Save';
           obj.SaveButton.Tooltip = 'Apply and Save Changes to Selection';
           obj.SaveButton.ButtonPushedFcn = @(~,~) obj.onSave();
           
           obj.CancelButton = uibutton(obj.EditButtonLayout,'push');
           obj.CancelButton.Layout.Row = 1;
           obj.CancelButton.Layout.Column = 4;
           obj.CancelButton.Text = 'Cancel';
           obj.CancelButton.Tag = 'Cancel';
           obj.CancelButton.Tooltip = 'Close without Saving';
           obj.CancelButton.ButtonPushedFcn = @(~,~) obj.onCancel();
           
           obj.ButtonsLayout = uigridlayout(obj.OuterGrid);
           obj.ButtonsLayout.Layout.Row =1;
           obj.ButtonsLayout.Layout.Column = 1;
           obj.ButtonsLayout.Padding = obj.ButtonPadding;
           obj.ButtonsLayout.ColumnSpacing = obj.ButtonWidthSpacing;
           obj.ButtonsLayout.RowSpacing = obj.ButtonHeightSpacing;
           obj.ButtonsLayout.RowHeight = {'1x'};
           obj.ButtonsLayout.ColumnWidth = {obj.ButtonWidth,obj.ButtonWidth,...
           obj.ButtonWidth,obj.ButtonWidth,obj.ButtonWidth,...
           obj.ButtonWidth,obj.ButtonWidth,obj.ButtonWidth,...
           obj.ButtonWidth,obj.ButtonWidth,obj.ButtonWidth,...
           obj.ButtonWidth,'1x'};
           
           %Summary Button
           obj.SummaryButton = uibutton(obj.ButtonsLayout,'push');
           obj.SummaryButton.Layout.Row = 1;
           obj.SummaryButton.Layout.Column = 1;
           obj.SummaryButton.Icon = QSPViewerNew.Resources.LoadResourcePath('report_24.png');
           obj.SummaryButton.Tooltip = 'View summary';
           obj.SummaryButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Summary');
           obj.SummaryButton.Text = '';
           
           %Edit Button
           obj.EditButton = uibutton(obj.ButtonsLayout,'push');
           obj.EditButton.Layout.Row = 1;
           obj.EditButton.Layout.Column = 2;
           obj.EditButton.Icon = QSPViewerNew.Resources.LoadResourcePath('edit_24.png');
           obj.EditButton.Tooltip = 'Edit the selected item';
           obj.EditButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Edit');
           obj.EditButton.Text = '';
           
           if obj.HasVisualization
               %Draw items specific to the visualization
               ButtonGroupGrid = obj.getButtonGrid();
               %DrawButtons on the top
               %Run Button
               obj.RunButton = uibutton(ButtonGroupGrid,'push');
               obj.RunButton.Layout.Row = 1;
               obj.RunButton.Layout.Column = 3;
               obj.RunButton.Icon = QSPViewerNew.Resources.LoadResourcePath('play_24.png');
               obj.RunButton.Tooltip = 'Run the selected item';
               obj.RunButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Run');
               obj.RunButton.Text = '';
               
               %Run Button

               obj.ParallelButton = uibutton(ButtonGroupGrid,'push');
               obj.ParallelButton.Layout.Row = 1;
               obj.ParallelButton.Layout.Column = 4;
               obj.ParallelButton.Icon = QSPViewerNew.Resources.LoadResourcePath('paralleloff_24.png');
               obj.ParallelButton.Tooltip = 'Enable Parallel';
               obj.ParallelButton.UserData = 'off';
               obj.ParallelButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Parallel');
               obj.ParallelButton.Text = '';

               obj.GitButton = uibutton(ButtonGroupGrid,'push');
               obj.GitButton.Layout.Row = 1;
               obj.GitButton.Layout.Column = 5;
               obj.GitButton.Icon = QSPViewerNew.Resources.LoadResourcePath('play_24.png');
               obj.GitButton.Tooltip = 'Enable Git';
               obj.GitButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Git');
               obj.GitButton.Text = '';

               %Visualize Button
               obj.VisualizeButton = uibutton(ButtonGroupGrid,'push');
               obj.VisualizeButton.Layout.Row = 1;
               obj.VisualizeButton.Layout.Column = 7;
               obj.VisualizeButton.Icon = QSPViewerNew.Resources.LoadResourcePath('plot_24.png');
               obj.VisualizeButton.Tooltip = 'Visualize the selected item';
               obj.VisualizeButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Visualize');
               obj.VisualizeButton.Text = '';

               % Settings Button
               obj.SettingsButton = uibutton(ButtonGroupGrid,'push');
               obj.SettingsButton.Layout.Row = 1;
               obj.SettingsButton.Layout.Column = 8;
               obj.SettingsButton.Icon = QSPViewerNew.Resources.LoadResourcePath('settings_24.png');
               obj.SettingsButton.Tooltip = 'Customize plot settings the selected item';
               obj.SettingsButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Settings');
               obj.SettingsButton.Text = '';

               %ZoomIn
               obj.ZoomInButton = uibutton(ButtonGroupGrid,'state');
               obj.ZoomInButton.Layout.Row = 1;
               obj.ZoomInButton.Layout.Column = 9;
               obj.ZoomInButton.Icon = QSPViewerNew.Resources.LoadResourcePath('zoomin.png');
               obj.ZoomInButton.Tooltip = 'Zoom in';
               obj.ZoomInButton.ValueChangedFcn = @(h,e)obj.onNavigation('ZoomIn');
               obj.ZoomInButton.Text = '';

               % Zoom out
               obj.ZoomOutButton = uibutton(ButtonGroupGrid,'state');
               obj.ZoomOutButton.Layout.Row = 1;
               obj.ZoomOutButton.Layout.Column = 10;
               obj.ZoomOutButton.Icon = QSPViewerNew.Resources.LoadResourcePath('zoomout.png');
               obj.ZoomOutButton.Tooltip = 'Zoom out';
               obj.ZoomOutButton.ValueChangedFcn = @(h,e)obj.onNavigation('ZoomOut');
               obj.ZoomOutButton.Text = '';

               % Pan
               obj.PanButton = uibutton(ButtonGroupGrid,'state');
               obj.PanButton.Layout.Row = 1;
               obj.PanButton.Layout.Column = 11;
               obj.PanButton.Icon = QSPViewerNew.Resources.LoadResourcePath('pan.png');
               obj.PanButton.Tooltip = 'Pan';
               obj.PanButton.ValueChangedFcn = @(h,e)obj.onNavigation('Pan');
               obj.PanButton.Text = '';

               % Explore
               obj.ExploreButton = uibutton(ButtonGroupGrid,'state');
               obj.ExploreButton.Layout.Row = 1;
               obj.ExploreButton.Layout.Column = 12;
               obj.ExploreButton.Icon = QSPViewerNew.Resources.LoadResourcePath('datatip.png');
               obj.ExploreButton.Tooltip = 'Explore';
               obj.ExploreButton.ValueChangedFcn = @(h,e)obj.onNavigation('Explore');
               obj.ExploreButton.Text = '';
               
               %Create Visualization Panel
               obj.VisualizationPanel = uipanel(obj.OuterGrid);
               obj.VisualizationPanel.BackgroundColor = obj.PanelBackgroundColor;
               obj.VisualizationPanel.Layout.Row = 2;
               obj.VisualizationPanel.Layout.Column = 1;
               obj.VisualizationPanel.Visible = 'off';
               
               %Create visualization panel layout. 
               obj.VisualizationGrid = QSPViewerNew.Widgets.GridFlex(obj.VisualizationPanel);
               
               %Create the plotting grid
               obj.PlottingGrid = uigridlayout(obj.VisualizationGrid.getGridHandle());
               obj.PlottingGrid.Layout.Column = 1;
               obj.PlottingGrid.Layout.Row = 1;
               obj.PlottingGrid.ColumnWidth = {'1x'};
               obj.PlottingGrid.RowHeight = {'1x'};
               
               obj.PlotInteractionGrid = uigridlayout(obj.VisualizationGrid.getGridHandle());
               obj.PlotInteractionGrid.Layout.Column = 3;
               obj.PlotInteractionGrid.Layout.Row = 1;
               obj.PlotInteractionGrid.ColumnWidth = {'1x'};
               obj.PlotInteractionGrid.RowHeight = {obj.WidgetHeight,'1x',obj.WidgetHeight};
               
               obj.PlotDropDown = uidropdown(obj.PlotInteractionGrid);
               obj.PlotDropDown.Layout.Column = 1;
               obj.PlotDropDown.Layout.Row = 1;
               obj.PlotDropDown.Items = obj.PlotLayoutOptions;
               obj.PlotDropDown.ValueChangedFcn = @(h,e) obj.onEdit('PlotConfig',e.Value);
               
               obj.RemoveButton = uibutton(obj.PlotInteractionGrid,'push');
               obj.RemoveButton.Layout.Row = 3;
               obj.RemoveButton.Layout.Column = 1;
               obj.RemoveButton.Text = 'Remove Invalid';
               obj.RemoveButton.Tag = 'Remove Invalid Visualization';
               obj.RemoveButton.Tooltip = 'Remove Invalid Visualization';
               obj.RemoveButton.ButtonPushedFcn = @(~,~) obj.onRemoveInvalidVisualization();
               
               initbShowTraces = false; % default off
               initbShowQuantiles = true; % default on
               initbShowMean = false; % default off
               initbShowMedian = true; % default on
               initbShowSD = false; % default off
               
               % Override default for VirtualPopulationGenerationPane
               if strcmpi(class(obj),'QSPViewerNew.Application.VirtualPopulationGenerationPane')
                   initbShowMean = true; % default on
                   initbShowMedian = false; % default off
               end
                
               %Create all plot objects
               for plotIndex = 1:obj.MaxNumPlots
                    obj.PlotArray(plotIndex) = uiaxes('Parent',obj.EmptyParent);
                    currentPlot = obj.PlotArray(plotIndex);
                    disableDefaultInteractivity(currentPlot);
                    obj.PlotArray(plotIndex).Tag = ['plot',num2str(plotIndex)];
                    set(currentPlot,'Interactions',[]);
                    enableDefaultInteractivity(currentPlot);

                    %Title
                    currentPlot.Title.String = sprintf('Plot %d',plotIndex);
                    currentPlot.Title.FontWeight = QSP.PlotSettings.DefaultTitleFontWeight;
                    currentPlot.Title.FontSize = QSP.PlotSettings.DefaultTitleFontSize;

                    %Xlabel
                    currentPlot.XLabel.String = QSP.PlotSettings.DefaultXLabel;
                    currentPlot.XLabel.FontWeight = QSP.PlotSettings.DefaultXLabelFontWeight;
                    currentPlot.XLabel.FontSize = QSP.PlotSettings.DefaultXLabelFontSize;

                    %XRuler
                    currentPlot.XAxis.FontWeight = QSP.PlotSettings.DefaultXTickLabelFontWeight;
                    currentPlot.XAxis.FontSize = QSP.PlotSettings.DefaultXTickLabelFontSize;

                    %YLabel
                    currentPlot.YLabel.String = QSP.PlotSettings.DefaultYLabel;
                    currentPlot.YLabel.FontWeight = QSP.PlotSettings.DefaultYLabelFontWeight;
                    currentPlot.YLabel.FontSize = QSP.PlotSettings.DefaultYLabelFontSize;

                    %YRuler 
                    currentPlot.YAxis.FontWeight = QSP.PlotSettings.DefaultYTickLabelFontWeight;
                    currentPlot.YAxis.FontSize = QSP.PlotSettings.DefaultYTickLabelFontSize;

                    %Plot area properties
                    currentPlot.XGrid = QSP.PlotSettings.DefaultXGrid;
                    currentPlot.YGrid = QSP.PlotSettings.DefaultYGrid;
                    currentPlot.XMinorGrid = QSP.PlotSettings.DefaultXMinorGrid;
                    currentPlot.YMinorGrid = QSP.PlotSettings.DefaultYMinorGrid;
                    currentPlot.YScale = QSP.PlotSettings.DefaultYScale;
                    currentPlot.XLim = str2double(strsplit(QSP.PlotSettings.DefaultCustomXLim));
                    currentPlot.XLimMode = QSP.PlotSettings.DefaultXLimMode;
                    currentPlot.YLim = str2double(strsplit(QSP.PlotSettings.DefaultCustomYLim));
                    currentPlot.YLimMode = QSP.PlotSettings.DefaultYLimMode;
                    
                    obj.PlotSettings(plotIndex) = QSP.PlotSettings(currentPlot);
                    obj.PlotSettings(plotIndex).Title = sprintf('Plot %d',plotIndex);
                    
                    %Add the context menus. 
                    %create context menu object;
                    obj.ContextMenuArray(plotIndex) = uicontextmenu(ancestor(obj.PlottingGrid,'figure'));
                    obj.ContextMenuArray(plotIndex).Tag = ['plot',num2str(plotIndex)];
                    
                    obj.YScaleMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.YScaleMenu(plotIndex).Label = 'Y-Scale';
                    obj.YScaleMenu(plotIndex).Tag = 'YScale';
                    
                    obj.YLinearMenu(plotIndex) = uimenu(obj.YScaleMenu(plotIndex));
                    obj.YLinearMenu(plotIndex).Label = 'Linear';
                    obj.YLinearMenu(plotIndex).Tag = 'YScaleLinear';
                    obj.YLinearMenu(plotIndex).Checked = 'on';
                    obj.YLinearMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.YLogMenu(plotIndex) = uimenu(obj.YScaleMenu(plotIndex));
                    obj.YLogMenu(plotIndex).Label = 'Log';
                    obj.YLogMenu(plotIndex).Tag = 'YScaleLog';
                    obj.YLogMenu(plotIndex).Checked = 'off';
                    obj.YLogMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.SaveMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.SaveMenu(plotIndex).Label = 'Save Current Axes...';
                    obj.SaveMenu(plotIndex).Tag = 'ExportSingleAxes';
                    obj.SaveMenu(plotIndex).Separator = 'on';
                    obj.SaveMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.SaveFullMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.SaveFullMenu(plotIndex).Label = 'Save Full View';
                    obj.SaveFullMenu(plotIndex).Tag = 'ExportAllAxes';
                    obj.SaveFullMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.TracesMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.TracesMenu(plotIndex).Label = 'Show Traces';
                    obj.TracesMenu(plotIndex).Checked = initbShowTraces;
                    obj.TracesMenu(plotIndex).Separator = 'on';
                    obj.TracesMenu(plotIndex).Tag = 'ShowTraces';
                    obj.TracesMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.QuantilesMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.QuantilesMenu(plotIndex).Label = 'Show Upper/Lower Quantiles';
                    obj.QuantilesMenu(plotIndex).Checked = initbShowQuantiles;
                    obj.QuantilesMenu(plotIndex).Tag = 'ShowQuantiles';
                    obj.QuantilesMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.MeanMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.MeanMenu(plotIndex).Label = 'Show Mean (Weighted)';
                    obj.MeanMenu(plotIndex).Checked = initbShowMean;
                    obj.MeanMenu(plotIndex).Tag = 'ShowMean';
                    obj.MeanMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.MedianMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.MedianMenu(plotIndex).Label = 'Show Median (Weighted)';
                    obj.MedianMenu(plotIndex).Checked = initbShowMedian;
                    obj.MedianMenu(plotIndex).Tag = 'ShowMedian';
                    obj.MedianMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
                    
                    obj.StandardDeviationMenu(plotIndex) = uimenu(obj.ContextMenuArray(plotIndex));
                    obj.StandardDeviationMenu(plotIndex).Label = 'Show Standard Deviation (Weighted)';
                    obj.StandardDeviationMenu(plotIndex).Checked = initbShowSD;
                    obj.StandardDeviationMenu(plotIndex).Tag = 'ShowSD';
                    obj.StandardDeviationMenu(plotIndex).MenuSelectedFcn = @(h,e) obj.onAxisContextMenu(h,e);
               end
           end
           
       end
       
   end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function onNavigation(obj,keyword)
            Figure = ancestor(obj.OuterGrid,'figure');
            Figure.Pointer = 'watch';
            obj.Focus = keyword;
            obj.refocus;
            Figure.Pointer = 'arrow';
        end
        
        function onRemoveInvalid(obj)
            obj.checkForInvalid();
        end
        
        function onRemoveInvalidVisualization(obj)
            obj.removeInvalidVisualization();
        end
        
        function onSave(obj)
            SuccesfulSave = obj.saveBackEndInformation();
            if SuccesfulSave
                obj.Focus = 'Summary';
                obj.refocus();
            end
        end
        
        function onCancel(obj)
            %Prompt the user to makse sure they want to cancel;
            if obj.checkDirty()
                Options = {'Save','Don''t Save','Cancel'};
                selection = uiconfirm(obj.getUIFigure,...
                'Changes have not been saved. How would you like to continue?',...
                   'Continue?','Options',Options,'DefaultOption',3);
            else
                selection = 'Don''t Save';
            end
           
           %Determine next steps based on their response
            switch selection
                case 'Save'   
                   
                    %Save as normal
                    obj.onSave();
                    obj.deleteTemporary();
                case 'Don''t Save'
                    
                    %Delete any temporaryCopies
                    obj.deleteTemporary();
                    %Just return to the main screen.
                    obj.Focus = 'Summary';
                    obj.refocus;
                case 'Cancel'
                    
                    %Do nothing
            end
        end
        
        function onEdit(obj,fieldName,value)
            switch fieldName
                case 'Name'
                    obj.NotifyOfChangeInName(value);
                case 'Description'
                    obj.NotifyOfChangeInDescription(value);
                case 'PlotConfig'
                    obj.NotifyOfChangeInPlotConfig(value);
            end
        end
        
        function onAxisContextMenu(obj,h,~)
            %Determine what plot we are working with
            
            plotIndex = str2double(erase(ancestor(h,'uicontextmenu').Tag,'plot'));
            CurrentPlot = obj.PlotArray(plotIndex);
            
            BackEnd = obj.getBackEnd;
            
            %Determine what our action should be
            switch h.Tag
                case 'YScaleLinear'
                    obj.YLinearMenu(plotIndex).Checked = 'on';
                    obj.YLogMenu(plotIndex).Checked = 'off';
                    set(CurrentPlot,'YScale','linear');  
                case 'YScaleLog'
                    obj.YLinearMenu(plotIndex).Checked = 'off';
                    obj.YLogMenu(plotIndex).Checked = 'on';
                    set(CurrentPlot,'YScale','log');  
                case 'ExportSingleAxes'
                    Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        };
                    Title = 'Save as';
                    SaveFilePath = getRootDirectory(obj);
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        
                        hFigure = ancestor(h,'figure');
                        set(hFigure,'pointer','watch');
                        drawnow limitrate
                        
                        SaveFilePath = fullfile(SavePathName,SaveFileName);
                        
                        % Call helper to copy axes, format, and print
                        obj.printAxesHelper(CurrentPlot,SaveFilePath,obj.PlotSettings(plotIndex))                        
                        
                        set(hFigure,'pointer','arrow');
                    end
                    
                case 'ExportAllAxes'  
                    Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';
                        };
                    Title = 'Save as';
                    SaveFilePath = getRootDirectory(obj);
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        
                        hFigure = ancestor(h,'figure');
                        set(hFigure,'pointer','watch');
                        drawnow;
                        
                        % Print using option
                        [~,~,FileExt] = fileparts(SaveFileName);
                        
                        % Get children and remove not-shown axes
                        Ch = flip(get(obj.PlottingGrid,'Children'));
                        
                        switch obj.PlotDropDown.Value
                            case '1x1'
                                Ch = Ch(1);
                            case '1x2'     
                                Ch = Ch(1:2);
                            case '2x1'     
                                Ch = Ch(1:2);
                            case '2x2'
                                Ch = Ch(1:4);
                            case '3x2'
                                Ch = Ch(1:6);
                            case '3x3'
                                Ch = Ch(1:9);
                            case '3x4'
                                Ch = Ch(1:12);
                        end
                        
                        for index = 1:numel(Ch)
                            
                            % Append _# to file name
                            [~,BaseSaveFileName] = fileparts(SaveFileName);
                            SaveFilePath = fullfile(SavePathName,[BaseSaveFileName,'_',num2str(index),FileExt]);
                            
                            ThisAxes = Ch(index);
                            
                            % Check if the plot has children
                            TheseChildren = get(ThisAxes,'Children');     
                            if ~isempty(TheseChildren) && iscell(TheseChildren) 
                                HasVisibleItem = true(1,numel(TheseChildren));
                                for chIdx = 1:numel(TheseChildren)
                                    
                                    ThisGroup = TheseChildren{chIdx};
                                    ThisGroupChildren = get(ThisGroup,'Children');
                                    if ~iscell(ThisGroupChildren)
                                        ThisGroupChildren = {ThisGroupChildren};
                                    end
                                    if ~isempty(ThisGroupChildren)
                                        HasVisibleItem(chIdx) = any(strcmpi(get(vertcat(ThisGroupChildren{:}),'Visible'),'on') &...
                                            ~strcmpi(get(vertcat(ThisGroupChildren{:}),'Tag'),'DummyLine'));
                                    else
                                        HasVisibleItem(chIdx) = false;
                                    end
                                    
                                    
                                end
                                % Filter to only allow export of plots that
                                % have children (at least one visible item
                                % that is not a dummyline)
                                TheseChildren = TheseChildren(HasVisibleItem);
                            end
                            
                            if ~isempty(TheseChildren)
                                % Call helper to copy axes and format 
                                obj.printAxesHelper(ThisAxes,SaveFilePath,obj.PlotSettings(index))
                            end
                          
                        end % for
                        
                        set(hFigure,'pointer','arrow');
                    end
                case 'ShowTraces'
                    BackEnd.bShowTraces(plotIndex) = ~BackEnd.bShowTraces(plotIndex);
                    h.Checked = BackEnd.bShowTraces(plotIndex);
                    obj.refreshVisualization(plotIndex);
                case 'ShowQuantiles'
                    BackEnd.bShowQuantiles(plotIndex) = ~BackEnd.bShowQuantiles(plotIndex);
                    h.Checked = BackEnd.bShowQuantiles(plotIndex);
                    obj.refreshVisualization(plotIndex);
                case 'ShowMean'
                    BackEnd.bShowMean(plotIndex) = ~BackEnd.bShowMean(plotIndex);
                    h.Checked = BackEnd.bShowMean(plotIndex);         
                    obj.refreshVisualization(plotIndex);
                case 'ShowMedian'
                    BackEnd.bShowMedian(plotIndex) = ~BackEnd.bShowMedian(plotIndex);
                    h.Checked = BackEnd.bShowMedian(plotIndex);
                    obj.refreshVisualization(plotIndex);
                case 'ShowSD'
                    BackEnd.bShowSD(plotIndex) = ~BackEnd.bShowSD(plotIndex);
                    h.Checked = BackEnd.bShowSD(plotIndex);
                    obj.refreshVisualization(plotIndex);
            end
                      
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Methods for updating UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function refocus(obj)
            %Determine which panel should be in focus
            switch obj.Focus
                
                %If the window should be the summary
                case 'Summary'
                    if strcmp(obj.SummaryPanel.Visible,'off')
                        %If the Summary window is not already shown.
                        obj.CurrentPane.Visible = 'off';
                        obj.CurrentPane = obj.SummaryPanel;
                        obj.deleteTemporary();
                        obj.draw();
                        obj.CurrentPane.Visible = 'on';
                        
                        %Turn the buttons on 
                        obj.ParentApp.enableInteraction();
                        obj.SummaryButton.Enable = 'on';
                        obj.EditButton.Enable = 'on';
                        if obj.HasVisualization
                            if obj.isValid()
                                VisPanelEnable = 'on';
                            else
                                VisPanelEnable = 'off';
                            end
                             obj.toggleButtonsInteraction({'on','on','on',VisPanelEnable,'on','off','off','off','off'});
                        end
                    end
                case 'Edit'
                    if strcmp(obj.EditPanel.Visible,'off')
                        %If the Edit window is not already shown
                        obj.CurrentPane.Visible = 'off';
                        obj.CurrentPane = obj.EditPanel;
                        obj.deleteTemporary();
                        obj.draw();
                        obj.CurrentPane.Visible = 'on';
                        
                        %Disable all external buttons and other views
                        obj.ParentApp.disableInteraction();
                        obj.SummaryButton.Enable = 'off';
                        obj.EditButton.Enable = 'off';
                        if obj.HasVisualization
                            obj.toggleButtonsInteraction({'on','on','on','on','on','off','off','off','off'});
                            %obj.toggleButtonsInteraction({'off','off','off','off','off','off','off','off','off'});
                        end
                    end
                case 'Run'
                    obj.runModel();
                    if strcmp(obj.SummaryPanel.Visible,'off')
                        %If the Summary window is not already shown.
                        obj.CurrentPane.Visible = 'off';
                        obj.CurrentPane = obj.SummaryPanel;
                        obj.deleteTemporary();
                        obj.draw();
                        obj.CurrentPane.Visible = 'on';
                    else
                        obj.deleteTemporary();
                        obj.draw();
                    end
                    
                    %Turn the buttons on
                    obj.ParentApp.enableInteraction();
                    obj.SummaryButton.Enable = 'on';
                    obj.EditButton.Enable = 'on';
                    if obj.HasVisualization
                        obj.toggleButtonsInteraction({'on','on','on','on','on','off','off','off','off'});
                    end

                case 'Parallel'
                    obj.updateParallelButtonStatus();              
                    obj.updateSessionParallelOption(obj.ParallelButton.UserData);

                case 'Git'
                    obj.toggleGitButtonStatus();                    
                    obj.updateSessionGitOption(obj.GitButton.UserData);

                case 'Visualize'
                    if strcmp(obj.VisualizationPanel.Visible,'off')
                        %If the Visualize window is not already shown
                        obj.CurrentPane.Visible = 'off';
                        obj.CurrentPane = obj.VisualizationPanel;
                        drawnow
                        obj.CurrentPane.Visible = 'on';
                        obj.drawVisualization();
                        obj.updateLines();
                        obj.updateLegends();
                        obj.UpdateBackendPlotSettings();
                        
                        %Disable all external buttons and other views
                        obj.toggleButtonsInteraction({'on','on','on','on','on','on','on','on','on'});
                    end
                case 'Settings'
                    Figure = ancestor(obj.OuterGrid,'figure');
                    Figure.Pointer = 'arrow';
                    bandPlotLB = [obj.PlotSettings.BandplotLowerQuantile];
                    bandPlotUB = [obj.PlotSettings.BandplotUpperQuantile];
                    PopUP = QSPViewerNew.Widgets.SettingsCustom(ancestor(obj.OuterGrid,'figure'),obj.PlotSettings);
                    [StatusOk,NewSettings]= PopUP.wait();
                    PopUP.delete();

                    if StatusOk
                        replot = false;
                        if any([NewSettings.BandplotLowerQuantile] ~= bandPlotLB | ...
                            [NewSettings.BandplotUpperQuantile] ~= bandPlotUB)
                                replot = true;
                        end
                        
                        obj.PlotSettings = NewSettings;
                        
                        if replot
                            obj.drawVisualization();
                        else
                            obj.refreshVisualization([]);
                        end
                      Figure.Pointer = 'watch';
                    end
                case 'ZoomIn'
                    obj.toggleButtonsInteraction({'on','on','on','on','on','on','on','on','on'});
                    Figure = ancestor(obj.OuterGrid,'figure');
                    zoomObj = zoom(Figure);
                    if obj.ZoomInButton.Value
                        obj.toggleVisButtonsState([1,0,0,0]);
                        for idx = 1:numel(obj.PlotArray)
                            if ~isempty(obj.PlotArray(idx).Layout)
                                matlab.graphics.interaction.webmodes.toggleMode(obj.PlotArray(idx),'zoom','on')
                            end
                        end
                    else
                        set(obj.PlotArray,'Interactions',[]);
                        obj.toggleVisButtonsState([0,0,0,0]);
                        for idx = 1:numel(obj.PlotArray)
                            if ~isempty(obj.PlotArray(idx).Layout)
                                matlab.graphics.interaction.webmodes.toggleMode(obj.PlotArray(idx),'zoom','off')
                            end
                        end
                    end
                case 'ZoomOut'
                    obj.toggleButtonsInteraction({'on','on','on','on','on','on','on','on','on'});
                    if obj.ZoomOutButton.Value
                        obj.toggleVisButtonsState([0,1,0,0]);
                        for idx = 1:numel(obj.PlotArray)
                            if ~isempty(obj.PlotArray(idx).Layout)
                                matlab.graphics.interaction.webmodes.toggleMode(obj.PlotArray(idx),'zoomout','on')
                            end
                        end
                    else
                        obj.toggleVisButtonsState([0,0,0,0]);
                        for idx = 1:numel(obj.PlotArray)
                            if ~isempty(obj.PlotArray(idx).Layout)
                                matlab.graphics.interaction.webmodes.toggleMode(obj.PlotArray(idx),'zoomout','off')
                            end
                        end
                    end
                    
                case 'Pan'
                    obj.toggleButtonsInteraction({'on','on','on','on','on','on','on','on','on'});
                    if obj.PanButton.Value
                        obj.toggleVisButtonsState([0,0,1,0]);
                        for idx = 1:numel(obj.PlotArray)
                            if ~isempty(obj.PlotArray(idx).Layout)
                                matlab.graphics.interaction.webmodes.toggleMode(obj.PlotArray(idx),'pan','on')
                            end
                        end
                    else
                        obj.toggleVisButtonsState([0,0,0,0]);
                        for idx = 1:numel(obj.PlotArray)
                            if ~isempty(obj.PlotArray(idx).Layout)
                                matlab.graphics.interaction.webmodes.toggleMode(obj.PlotArray(idx),'pan','off')
                            end
                        end
                    end
                case 'Explore'
                    obj.toggleButtonsInteraction({'on','on','on','on','on','on','on','on','on'});
                    if obj.ExploreButton.Value
                        obj.toggleVisButtonsState([0,0,0,1]);
                        set(obj.PlotArray,'Interactions',dataTipInteraction);
                    else
                        obj.toggleVisButtonsState([0,0,0,0]);
                        set(obj.PlotArray,'Interactions',[]);
                    end
            end 
        end
           
        function toggleButtonsInteraction(obj,ButtonVector)
            obj.SummaryButton.Enable = ButtonVector{1};
            obj.RunButton.Enable = ButtonVector{2};
            obj.EditButton.Enable = ButtonVector{3};
            obj.VisualizeButton.Enable = ButtonVector{4};
            obj.SettingsButton.Enable = ButtonVector{5};
            obj.ZoomInButton.Enable = ButtonVector{6};
            obj.ZoomOutButton.Enable = ButtonVector{7};
            obj.PanButton.Enable = ButtonVector{8};
            obj.ExploreButton.Enable = ButtonVector{9};            
            obj.ParallelButton.Enable = ButtonVector{2}; % same as run button status
            obj.GitButton.Enable = ButtonVector{2}; % same as run button status
        end
        
        function toggleVisButtonsState(obj,ButtonVector)
            obj.ZoomInButton.Value = ButtonVector(1);
            obj.ZoomOutButton.Value = ButtonVector(2);
            obj.PanButton.Value =  ButtonVector(3);
            obj.ExploreButton.Value =  ButtonVector(4);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Protected Methods for changing the display based on external
    % information
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = protected)
        
        function updateNameBox(obj,value)
            validateattributes(value,'char',{});
            obj.NameEditBox.Value = value;
        end
        
        function updateDescriptionBox(obj,value)
            validateattributes(value,'char',{});
            obj.DescriptionEditBox.Value = value;
        end
        
        function updateSummary(obj,value)
            validateattributes(value,'cell',{'ncols',2});
            obj.SummaryContent.Information = value;
        end
        
        function hidePane(obj)           
            %Remove callbacks for pane
            if obj.HasVisualization
                obj.ParentApp.removeWindowDownCallback(obj.VisualizationGrid.getButtonDownCallback());
                obj.ParentApp.removeWindowUpCallback(obj.VisualizationGrid.getButtonUpCallback());
            end
            
            %hide this pane
            obj.OuterGrid.Visible = 'off';
        end
        
        function showPane(obj)
            %show this pane. Whenever a pane is shown, start with the
            %summary
            obj.Focus = 'Summary';
            obj.refocus;
            
            if obj.HasVisualization
                obj.ParentApp.addWindowDownCallback(obj.VisualizationGrid.getButtonDownCallback());
                obj.ParentApp.addWindowUpCallback(obj.VisualizationGrid.getButtonUpCallback());
            end
            obj.OuterGrid.Visible = 'on';
        end
        
        function notifyOfChange(obj,newBackEndObject)
            obj.ParentApp.changeInBackEnd(newBackEndObject);
        end
        
        function updatePlotConfig(obj,value)
            %If the drop down has not been updated, do so
            obj.PlotDropDown.Value = value;
            
            %Extract the row and column values
            SplitValue = strsplit(value,'x');
            Rows = SplitValue{1};
            Columns = SplitValue{2};
            RowsInput = repmat({'1x'},1,str2double(Rows));
            ColumnsInput = repmat({'1x'},1,str2double(Columns));
            
            %While we are working, set the grid to invisible
            obj.PlottingGrid.Visible = 'off';
            
            %For all plots that will not be shown, set their parent to an
            %empty object
            for plotIndex = str2double(Rows)*str2double(Columns)+1:obj.MaxNumPlots
                obj.PlotArray(plotIndex).Parent = obj.EmptyParent;
            end
            
            %For 1 to the number of plots to show, add them in order
            PlotCount = 1;
            for ColumnIndex = 1:str2double(Columns)
                for RowIndex = 1:str2double(Rows)
                    obj.PlotArray(PlotCount).Parent = obj.PlottingGrid;
                    obj.PlotArray(PlotCount).ContextMenu =  obj.ContextMenuArray(PlotCount);
                    obj.PlotArray(PlotCount).Layout.Row = RowIndex;
                    obj.PlotArray(PlotCount).Layout.Column = ColumnIndex;
                    PlotCount = PlotCount +1;
                end
            end
            
            obj.PlottingGrid.RowHeight = RowsInput;
            obj.PlottingGrid.ColumnWidth = ColumnsInput;
            obj.PlottingGrid.Visible = 'on';
        end
        
        function updateLines(obj)
            %SpeciesGroup is the cell array to store all of the 
            % Iterate through each axes and turn on SelectedProfileRow
            if isprop(obj,'SpeciesGroup') && ~isempty(obj.SpeciesGroup)
                BackEnd = obj.getBackEnd();
                BackEndPlotSettings = BackEnd.PlotSettings;
                for axIndex = 1:size(obj.SpeciesGroup,2)
                    MeanLineWidth = BackEndPlotSettings(axIndex).MeanLineWidth;
                    MedianLineWidth = BackEndPlotSettings(axIndex).MedianLineWidth;
                    StandardDevLineWidth = BackEndPlotSettings(axIndex).StandardDevLineWidth;
                    BoundaryLineWidth = BackEndPlotSettings(axIndex).BoundaryLineWidth;
                    LineWidth = BackEndPlotSettings(axIndex).LineWidth;
                    
                    hPlots = obj.SpeciesGroup(:,axIndex,:);
                    if iscell(hPlots)
                        hPlots = horzcat(hPlots{:});
                    end
                    hPlots(~ishandle(hPlots)) = [];
                    if ~isempty(hPlots) && isa(hPlots,'matlab.graphics.primitive.Group')
                        hPlots = vertcat(hPlots.Children);
                        hPlots(~ishandle(hPlots)) = [];
                    end         
                    ThisTag = get(hPlots,'Tag');
                    IsMeanLine = strcmpi(ThisTag,'MeanLine');
                    IsMedianLine = strcmpi(ThisTag,'MedianLine');
                    IsStandardDevLine = strcmpi(ThisTag,'WeightedSD');
                    IsBoundaryLine = strcmpi(ThisTag,'BoundaryLine');
                    if ~isempty(hPlots)
                        set(hPlots(IsMeanLine),...
                            'LineWidth',MeanLineWidth);
                        set(hPlots(IsMedianLine),...
                            'LineWidth',MedianLineWidth);
                        set(hPlots(IsStandardDevLine),...
                            'LineWidth',StandardDevLineWidth);
                        set(hPlots(IsBoundaryLine),...
                            'LineWidth',BoundaryLineWidth);
                        set(hPlots(~IsMeanLine & ~IsMedianLine & ~IsStandardDevLine & ~IsBoundaryLine),...
                            'LineWidth',LineWidth);
                    end
                end
            end
            
            % Dataset line
            if isprop(obj,'DatasetGroup') && ~isempty(obj.DatasetGroup)
                BackEnd = obj.getBackEnd();
                BackEndPlotSettings = BackEnd.PlotSettings;
                for axIndex = 1:size(obj.DatasetGroup,2)
                    
                    DataSymbolSize = BackEndPlotSettings(axIndex).DataSymbolSize;
                    
                    hPlots = obj.DatasetGroup(:,axIndex);
                    if iscell(hPlots)
                        hPlots = horzcat(hPlots{:});
                    end
                    hPlots(~ishandle(hPlots)) = [];
                    if ~isempty(hPlots) && isa(hPlots,'matlab.graphics.primitive.Group')
                        hPlots = vertcat(hPlots.Children);
                        hPlots(~ishandle(hPlots)) = [];
                    end
                    ThisTag = get(hPlots,'Tag');
                    IsDummyLine = strcmpi(ThisTag,'DummyLine');
                    if ~isempty(hPlots)
                        set(hPlots(~IsDummyLine),...
                            'MarkerSize',DataSymbolSize);
                    end
                end
            end
            
        end
        
        function updateLegends(obj)
            if isprop(obj,'AxesLegend') && ~isempty(obj.AxesLegend)
                BackEnd = obj.getBackEnd();
                BackEndPlotSettings = BackEnd.PlotSettings;
                
                for axIndex = 1:numel(BackEndPlotSettings)
                    if ~isempty(obj.AxesLegend{axIndex}) && ishandle(obj.AxesLegend{axIndex})
                        % Visible, Location
                        obj.AxesLegend{axIndex}.Visible = BackEndPlotSettings(axIndex).LegendVisibility;
                        obj.AxesLegend{axIndex}.Location = BackEndPlotSettings(axIndex).LegendLocation;
                        obj.AxesLegend{axIndex}.FontSize = BackEndPlotSettings(axIndex).LegendFontSize;
                        obj.AxesLegend{axIndex}.FontWeight = BackEndPlotSettings(axIndex).LegendFontWeight;
                        
                        % FontSize, FontWeight
                        if isprop(obj,'AxesLegendChildren') && ~isempty(obj.AxesLegendChildren)
                            
                            ch = obj.AxesLegendChildren{axIndex};
                            if all(ishandle(ch))
                                for cIndex = 1:numel(ch)
                                    if isprop(ch(cIndex),'FontSize')
                                        ch(cIndex).FontSize = BackEnd.PlotSettings(axIndex).LegendFontSize;
                                    end
                                    if isprop(ch(cIndex),'FontWeight')
                                        ch(cIndex).FontWeight = BackEnd.PlotSettings(axIndex).LegendFontWeight;
                                    end
                                end 
                            end 
                        end
                    end 
                end
            end 
        end
        
        function redrawAxesContextMenu(obj)
        
            BackEnd = obj.getBackEnd;
            if ~isempty(BackEnd)
                % Re-initialize
                initOptions(BackEnd);
                
                % Y-Scale
                ShowLinear = strcmpi(string({BackEnd.PlotSettings.YScale}),'linear');
                
                set(obj.YLinearMenu(ShowLinear),'Checked','on');
                set(obj.YLogMenu(ShowLinear),'Checked','off');
                
                set(obj.YLinearMenu(~ShowLinear),'Checked','off');
                set(obj.YLogMenu(~ShowLinear),'Checked','on');
                
                % Traces
                ShowTraces = logical([BackEnd.bShowTraces]);
                set(obj.TracesMenu(ShowTraces),'Checked','on')
                set(obj.TracesMenu(~ShowTraces),'Checked','off')
                
                % Upper/Lower quantiles
                ShowQuantiles = logical([BackEnd.bShowQuantiles]);
                set(obj.QuantilesMenu(ShowQuantiles),'Checked','on')
                set(obj.QuantilesMenu(~ShowQuantiles),'Checked','off')
                
                % Weighted mean
                ShowMean = logical([BackEnd.bShowMean]);
                set(obj.MeanMenu(ShowMean),'Checked','on')
                set(obj.MeanMenu(~ShowMean),'Checked','off')
                
                % Weighted median
                ShowMedian = logical([BackEnd.bShowMedian]);
                set(obj.MedianMenu(ShowMedian),'Checked','on')
                set(obj.MedianMenu(~ShowMedian),'Checked','off')
                
                % Weighted standard deviation
                ShowSD = logical([BackEnd.bShowSD]);
                set(obj.StandardDeviationMenu(ShowSD),'Checked','on')
                set(obj.StandardDeviationMenu(~ShowSD),'Checked','off')
            end
        end
        
        function updateParallelButtonStatus(obj)
            if strcmp(obj.ParallelButton.UserData, 'off')
                obj.ParallelButton.Icon = QSPViewerNew.Resources.LoadResourcePath('parallelon_24.png');
                obj.ParallelButton.Tooltip = 'Disable Parallel';
                obj.ParallelButton.UserData = 'on';
            else
                obj.ParallelButton.Icon = QSPViewerNew.Resources.LoadResourcePath('paralleloff_24.png');
                obj.ParallelButton.Tooltip = 'Enable Parallel';
                obj.ParallelButton.UserData = 'off';
            end
        end
        
        function updateParallelButtonSession(obj, value)
            if value
                obj.ParallelButton.Icon = QSPViewerNew.Resources.LoadResourcePath('parallelon_24.png');
                obj.ParallelButton.Tooltip = 'Disable Parallel';
                obj.ParallelButton.UserData = 'on';
            else
                obj.ParallelButton.Icon = QSPViewerNew.Resources.LoadResourcePath('paralleloff_24.png');
                obj.ParallelButton.Tooltip = 'Enable Parallel';
                obj.ParallelButton.UserData = 'off';
            end
        end
       
        function toggleGitButtonStatus(obj)
            if strcmp(obj.GitButton.UserData, 'off')
                obj.GitButton.Icon = QSPViewerNew.Resources.LoadResourcePath('giton_24.png');
                obj.GitButton.Tooltip = 'Disable Git';
                obj.GitButton.UserData = 'on';
            else
                obj.GitButton.Icon = QSPViewerNew.Resources.LoadResourcePath('gitoff_24.png');
                obj.GitButton.Tooltip = 'Enable Git';
                obj.GitButton.UserData = 'off';
            end
        end

        function updateGitButtonSession(obj, value)
            if value
                obj.GitButton.Icon = QSPViewerNew.Resources.LoadResourcePath('giton_24.png');
                obj.GitButton.Tooltip = 'Disable Git';
                obj.GitButton.UserData = 'on';
            else
                obj.GitButton.Icon = QSPViewerNew.Resources.LoadResourcePath('gitoff_24.png');
                obj.GitButton.Tooltip = 'Enable Git';
                obj.GitButton.UserData = 'off';
            end
        end
    end
    
    methods(Access = public)
       
        function value = getUIFigure(obj)
            value = obj.ParentApp.getUIFigure();
        end
        
        function value = getEditGrid(obj)
            value = obj.EditLayout;
        end
        
        function value = getButtonGrid(obj)
            value = obj.ButtonsLayout;
        end
        
        function value = getVisualizationGrid(obj)
            if obj.HasVisualization
                value = obj.PlotInteractionGrid;
            else
                error('Only panes with visualization should access this property')
            end
        end
        
        function Value = getAxesOptions(obj)
            % Get axes options for dropdown
            Value = num2cell(1:obj.MaxNumPlots)';
            Value = cellfun(@(x)num2str(x),Value,'UniformOutput',false);
            Value = vertcat({' '},Value);
            
        end 
        
        function setPlotSettings(obj,index,fields,Values)
            %The backened cannot handle on/off switch state
            %Change all on/off switch state to chars
           for fieldIndex = 1:numel(fields)
               if isa(Values{fieldIndex},'matlab.lang.OnOffSwitchState')
                   Values{fieldIndex} = char(Values{fieldIndex});
               end
           end
               
            set(obj.PlotSettings(index),fields,Values);
        end
        
        function Value = getPlotSettings(obj)
            Value = obj.PlotSettings;
        end

        function Value = getPlotArray(obj)
            Value = obj.PlotArray;
        end
        
    end
    
    methods(Access = public)
        
        function printAxesHelper(obj,hAxes,SaveFilePath,PlotSettings)
            
            % Use current axes to determine which line handles should be
            % used for the legend
            hUIAxes = hAxes(~strcmpi(get(hAxes,'Tag'),'legend'));
            theseGroups = get(hUIAxes,'Children');
            
            for index = 1:numel(theseGroups)
                ch = get(theseGroups(index),'Children');
                
                % Turn off all and turn on
                hAnn = get(ch,'Annotation');
                if ~iscell(hAnn)
                    hAnn = {hAnn};
                end
                hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
                
                % Set icondisplaystyle for export
                if strcmpi(get(theseGroups(index),'Tag'),'Data') && strcmpi(PlotSettings.LegendDataGroup,'off')
                    % If Data and legend data group is off
                    KeepIdxOn = false(1,numel(hAnn));
                else
                    % Species or Data Group is on
                    if numel(ch) > 1
                        KeepIdxOn = ~strcmpi(get(ch,'Tag'),'DummyLine') & ~cellfun(@isempty,(get(ch,'DisplayName'))) & strcmpi(get(ch,'Visible'),'on');
                    else
                        KeepIdxOn = ~strcmpi(get(ch,'Tag'),'DummyLine') & ~isempty(get(ch,'DisplayName')) & strcmpi(get(ch,'Visible'),'on');
                    end
                end
                cellfun(@(x)set(x,'IconDisplayStyle','on'),hAnn(KeepIdxOn),'UniformOutput',false);
                cellfun(@(x)set(x,'IconDisplayStyle','off'),hAnn(~KeepIdxOn),'UniformOutput',false);
                
            end
            
            % Copy axes to figure
            hNewAxes = hAxes;
            
            % Delete the legend from hThisAxes
            delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
            hNewAxes = hNewAxes(ishandle(hNewAxes));
            
            % Create new plot settings and initialize with values from
            % original plot settings
            NewPlotSettings = QSP.PlotSettings(hNewAxes);
            Summary = getSummary(PlotSettings);
            
            %Convert all On/OffSwitchStates to 'on' or 'off' 
            for fieldID = fieldnames(Summary)'
                if isa(Summary.(fieldID{1}),'matlab.lang.OnOffSwitchState')
                    Summary.(fieldID{1}) = char(Summary.(fieldID{1}));
                end
            end

            set(NewPlotSettings,fieldnames(Summary),struct2cell(Summary)');
            
            % Create a new legend
            OrigLegend = hAxes.Legend;
            if ~isempty(OrigLegend)
                hLine = hAxes.Children;
                % Format display name
                for idx = 1:numel(hLine)
                    % Replace _ with \_
                    hLine(idx).DisplayName = regexprep(hLine(idx).DisplayName,'_','\\_');
                    % In case there is now a \\_ (if previous formatted in plotting code), replace it with \_
                    hLine(idx).DisplayName = regexprep(hLine(idx).DisplayName,'\\\\_','\\_');
                end
                
                Location = OrigLegend.Location;
                Visible = OrigLegend.Visible;
                FontSizeTemp = OrigLegend.FontSize;
                FontWeight = OrigLegend.FontWeight;
                
                % Make current axes and place legend
                
                hLine = flipud(hLine(:));
                hLine = vertcat(hLine.Children);
                
                hAnn = get(hLine,'Annotation');
                if ~iscell(hAnn)
                    hAnn = {hAnn};
                end
                hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
                hAnn = cellfun(@(x)get(x,'IconDisplayStyle'),hAnn,'UniformOutput',false);
                KeepIdx = strcmpi(hAnn,'on');
                
                if any(KeepIdx)
                    [hLegend] = legend(hAxes,hLine(KeepIdx));
                    % Set the legend - location and visibility
                    hLegend.Location = Location;
                    hLegend.Visible = Visible;
                    hLegend.EdgeColor = 'none';
                    
                    % Set the fontsize and fontweight
                    hLegend.FontSize = FontSizeTemp;
                    hLegend.FontWeight = FontWeight;
                    %[hLegendChildren(arrayfun(@(x)isprop(x,'FontSize'),hLegendChildren)).FontSize] = deal(FontSizeTemp);
                    %[hLegendChildren(arrayfun(@(x)isprop(x,'FontWeight'),hLegendChildren)).FontWeight] = deal(FontWeight);
                end
            end
            
            exportgraphics(hNewAxes,SaveFilePath,'Resolution',300);
            AxIndices = str2double(hNewAxes.Tag(5:end));
            [UpdatedAxesLegend,UpdatedAxesLegendChildren] = updatePlots(...
                obj.getBackEnd,obj.getPlotArray(),obj.SpeciesGroup,obj.DatasetGroup,...
                'AxIndices',AxIndices);
            obj.AxesLegend(AxIndices) = UpdatedAxesLegend(AxIndices);
            obj.AxesLegendChildren(AxIndices) = UpdatedAxesLegendChildren(AxIndices);
        end
    end
    
    methods(Abstract)
        NotifyOfChangeInName(obj,value);
        NotifyOfChangeInDescription(obj,value);
        saveBackEndInformation(obj);
        checkForDuplicateNames(obj);
        checkForInvalid(obj);
        draw(obj);
        deleteTemporary(obj);
        hideThisPane(obj);
        showThisPane(obj);
        checkDirty(obj);
        getRootDirectory(obj);
    end
    
    methods (Static)
        
         function [hThisLegend,hThisLegendChildren] = redrawLegend(hThisAxes,LegendItems,ThesePlotSettings)
            
             hThisLegend = [];
             hThisLegendChildren = [];
             
             if ~isempty(LegendItems)
                 try
                     % Add legend
                     [hThisLegend] = legend(hThisAxes,LegendItems,'FontSize',ThesePlotSettings.LegendFontSize,'FontWeight',ThesePlotSettings.LegendFontWeight);
                     set(hThisLegend,...
                         'EdgeColor','none',...
                         'Visible',ThesePlotSettings.LegendVisibility,...
                         'Location',ThesePlotSettings.LegendLocation,...
                         'FontSize',ThesePlotSettings.LegendFontSize,...
                         'FontWeight',ThesePlotSettings.LegendFontWeight);
                 catch ME
                     warning(ME.message)
                 end
             else
                 Siblings = get(get(hThisAxes,'Parent'),'Children');
                 IsLegend = strcmpi(get(Siblings,'Type'),'legend');
                 
                 if any(IsLegend)
                     if isvalid(Siblings(IsLegend))
                         delete(Siblings(IsLegend));
                     end
                 elseif ~isempty(hThisAxes.Legend)
                     delete(hThisAxes.Legend)
                 end
                 
                 hThisLegend = [];
                 hThisLegendChildren = [];
             end
             
        end %function
        
    end
    
       
end



