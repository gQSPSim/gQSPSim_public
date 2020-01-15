classdef ViewPane < uix.mixin.AssignPVPairs & handle
    % ViewPane - A Base class for view panes to be shown on the right side
    % of the QSP viewer application
    % ---------------------------------------------------------------------
    % Base properties and methods for a view pane. 
    %
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %   1/14/20
    % ---------------------------------------------------------------------
    
    properties
        TempData % Stores all the temporary data for this pane
        Data % A saved version of TempData 
        Selection = 1
        IsDeleted = false
        SelectedPlotLayout = '1x1'
        PlotSettings = QSP.PlotSettings.empty(0,1) 
    end
    
    properties (SetAccess=protected)
       bShowTraces = []
       bShowQuantiles = []
       bShowMean = []
       bShowMedian = []
       bShowSD = []
    end
    
    properties      
        UseRunVis = false % Determines if the pane gets the added buttons
        LastPath = pwd % Not sure what this is yet %TODO
        Parent % Can be a grid 
        OuterGrid % should be a panel
        h = struct() % struct containing the graphcs objects
        Position;
    end 
    
    properties (Constant=true)
        MaxNumPlots = 12 %Available plot options
        PlotLayoutOptions = {'1x1','1x2','2x1','2x2','3x2','3x3','3x4'}
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function obj = ViewPane(UseRunVis,varargin)
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});

            % Set UseRunVis before calling create
            obj.UseRunVis = UseRunVis;
            
            %create
            obj.create();
        end 
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Create UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected)
        
        function create(obj)     
           ButtonSize = 30 ;%Enter the button size;
           
           %Setup Outer Panel         
           obj.OuterGrid = uigridlayout(obj.Parent);
           obj.OuterGrid.ColumnWidth = {'1x'};
           obj.OuterGrid.RowHeight = {ButtonSize,'1x'};
           obj.OuterGrid.Padding = [0,0,0,0];
           obj.OuterGrid.RowSpacing = 0;

           %Setup the Summary Panel and Button
           obj.h.SummaryPanel = uipanel(obj.OuterGrid);
           obj.h.SummaryPanel.BackgroundColor = [.9,.9,.9];
           obj.h.SummaryPanel.Layout.Row = 2;
           obj.h.SummaryPanel.Layout.Column = 1;
           
           %Setup SummaryGrid
           obj.h.SummaryGrid = uigridlayout(obj.h.SummaryPanel);
           obj.h.SummaryGrid.ColumnWidth = {'1x'};
           obj.h.SummaryGrid.RowHeight = {'1x'};
           
           %Summary Widget
           obj.h.SummaryContent = QSPViewerNew.Widgets.Summary(obj.h.SummaryGrid,{'Dummy','info';'Purpose','Testing'});
           obj.h.SummaryContent.Information = {'Yellow','Dog'; 'Blue','Cat'};
           obj.h.SummaryContent.HtmlComponent.Visible = 'off';
            
           %Edit Panel
           obj.h.EditPanel = uipanel(obj.OuterGrid);
           obj.h.EditPanel.BackgroundColor = [.9,.9,.9];
           obj.h.EditPanel.Layout.Row = 2;
           obj.h.EditPanel.Layout.Column = 1;
           
           %All Edit Panels have the following 3 subpanels
           % 1. the name and description
           % 2. The contents of the panel
           % 3. The svae/cancel/remove invalid button
           
           %First setup the grid layout
           obj.h.EditLayout = uigridlayout(obj.h.EditPanel);
           obj.h.EditLayout.ColumnWidth = {'1x'};
           obj.h.EditLayout.RowHeight = {ButtonSize,'1x',ButtonSize};
           obj.h.EditLayout.Padding = [4,4,4,4];
         
           %Row 1: The name and secription
           obj.h.FileSelectLayout = uigridlayout(obj.h.EditLayout);
           obj.h.FileSelectLayout.ColumnWidth = {80,'3x',80,'5x'};
           obj.h.FileSelectLayout.RowHeight = {'1x'};
           obj.h.FileSelectLayout.Padding = [0,0,0,2];
           obj.h.FileSelectLayout.ColumnSpacing = 0;
           
           obj.h.FileSelect(1) = uilabel(obj.h.FileSelectLayout);
           obj.h.FileSelect(1).Layout.Row = 1;
           obj.h.FileSelect(1).Layout.Column = 1;
           obj.h.FileSelect(1).Text = 'Name';
           obj.h.FileSelect(1).HorizontalAlignment = 'center';
           obj.h.FileSelect(1).FontWeight = 'bold';
           
           obj.h.FileSelect(2) = uieditfield(obj.h.FileSelectLayout);
           obj.h.FileSelect(2).Layout.Row = 1;
           obj.h.FileSelect(2).Layout.Column = 2;
           obj.h.FileSelect(2).ValueChangedFcn = @obj.onEditName;
           
           obj.h.FileSelect(3) = uilabel(obj.h.FileSelectLayout);
           obj.h.FileSelect(3).Layout.Row = 1;
           obj.h.FileSelect(3).Layout.Column = 3;
           obj.h.FileSelect(3).Text = 'Description';
           obj.h.FileSelect(3).HorizontalAlignment = 'center';
           obj.h.FileSelect(3).FontWeight = 'bold';
           
           obj.h.FileSelect(4) = uieditfield(obj.h.FileSelectLayout);
           obj.h.FileSelect(4).Layout.Row = 1;
           obj.h.FileSelect(4).Layout.Column = 4;
           obj.h.FileSelect(4).ValueChangedFcn = @obj.onEditDescription;
          
           %Rows 3: Save/cancel/Remove invalid
           obj.h.EditButtonLayout = uigridlayout(obj.h.EditLayout);
           obj.h.EditButtonLayout.Layout.Column = 1;
           obj.h.EditButtonLayout.Layout.Row = 3;
           obj.h.EditButtonLayout.ColumnWidth = {'1x',100,80,80};
           obj.h.EditButtonLayout.RowHeight = {'1x'};
           obj.h.EditButtonLayout.Padding= [0,2,0,0];
           obj.h.EditButtonLayout.ColumnSpacing = 0;
           
           obj.h.RemoveButton = uibutton(obj.h.EditButtonLayout,'push');
           obj.h.RemoveButton.Layout.Row = 1;
           obj.h.RemoveButton.Layout.Column = 2;
           obj.h.RemoveButton.Text = 'Remove Invalid';
           obj.h.RemoveButton.Tag = 'Remove';
           obj.h.RemoveButton.ButtonPushedFcn = @obj.onEditButtonPress;
           
           obj.h.SaveButton = uibutton(obj.h.EditButtonLayout,'push');
           obj.h.SaveButton.Layout.Row = 1;
           obj.h.SaveButton.Layout.Column = 3;
           obj.h.SaveButton.Text = 'Save';
           obj.h.SaveButton.Tag = 'Save';
           obj.h.SaveButton.ButtonPushedFcn = @obj.onEditButtonPress;
           
           obj.h.CancelButton = uibutton(obj.h.EditButtonLayout,'push');
           obj.h.CancelButton.Layout.Row = 1;
           obj.h.CancelButton.Layout.Column = 4;
           obj.h.CancelButton.Text = 'Cancel';
           obj.h.CancelButton.Tag = 'Cancel';
           obj.h.CancelButton.ButtonPushedFcn = @obj.onEditButtonPress;
           
           %Only enter if this cardview will use visualization
           if obj.UseRunVis
               
               %Setup visulization panel
               obj.h.VisualizePanel = uipanel(obj.OuterGrid);
               obj.h.VisualizePanel.BackgroundColor = [.9,.9,.9];
               obj.h.VisualizePanel.Layout.Row = 2;
               obj.h.VisualizePanel.Layout.Column = 1;
               obj.h.VisualizePanel.Visible = 'off';
               
               %Visualization grid
               obj.h.VisualizationLayout = uigridlayout(obj.h.VisualizePanel);
               obj.h.VisualizationLayout.ColumnWidth = {'2x','1x'};
               obj.h.VisualizationLayout.RowHeight = {'1x'};
               obj.h.VisualizationLayout.Padding = [0,0,0,0];
               
               
               %LHS: The grid of plots
               obj.h.PlotGrid = uigridlayout(obj.h.VisualizationLayout);
               obj.h.PlotGrid.ColumnWidth = {'1x','1x','1x','1x'};
               obj.h.PlotGrid.RowHeight = {'1x','1x','1x'};
               
               for index = 1:obj.MaxNumPlots
                   %Add Axis;
                   obj.h.MainAxes(index) = uiaxes(obj.h.PlotGrid,'Visible','on');
                   
                   %Setup Plot Title; 
                   obj.h.MainAxes(index).Title.String = sprintf('Plot %d',index);
                   obj.h.MainAxes(index).Title.FontSize = QSP.PlotSettings.DefaultTitleFontSize;
                   obj.h.MainAxes(index).Title.FontWeight = QSP.PlotSettings.DefaultTitleFontWeight;
                   
                   %Setup Xlabel; 
                   obj.h.MainAxes(index).XLabel.String = QSP.PlotSettings.DefaultXLabel;
                   obj.h.MainAxes(index).XLabel.FontSize = QSP.PlotSettings.DefaultXLabelFontSize;
                   obj.h.MainAxes(index).XLabel.FontWeight = QSP.PlotSettings.DefaultXLabelFontWeight;
                   
                   %Setup XRuler
                   obj.h.MainAxes(index).XAxis.FontSize = QSP.PlotSettings.DefaultXTickLabelFontSize;
                   obj.h.MainAxes(index).XAxis.FontWeight = QSP.PlotSettings.DefaultXTickLabelFontWeight;
                   
                   %Setup Ylabel
                   obj.h.MainAxes(index).YLabel.String = QSP.PlotSettings.DefaultYLabel;
                   obj.h.MainAxes(index).YLabel.FontSize = QSP.PlotSettings.DefaultYLabelFontSize;
                   obj.h.MainAxes(index).YLabel.FontWeight = QSP.PlotSettings.DefaultYLabelFontWeight;
                   
                   %Setup YRuler
                   obj.h.MainAxes(index).YAxis.FontSize = QSP.PlotSettings.DefaultYTickLabelFontSize;
                   obj.h.MainAxes(index).YAxis.FontWeight = QSP.PlotSettings.DefaultYTickLabelFontWeight;
                   
                   %Setup Axis grid properties;
                   obj.h.MainAxes(index).XGrid = QSP.PlotSettings.DefaultXGrid;
                   obj.h.MainAxes(index).YGrid = QSP.PlotSettings.DefaultYGrid;
                   obj.h.MainAxes(index).XMinorGrid = QSP.PlotSettings.DefaultXMinorGrid;
                   obj.h.MainAxes(index).YMinorGrid = QSP.PlotSettings.DefaultYMinorGrid;
                   obj.h.MainAxes(index).YScale = QSP.PlotSettings.DefaultYScale;
                   obj.h.MainAxes(index).XLim = str2num(QSP.PlotSettings.DefaultCustomXLim);
                   obj.h.MainAxes(index).XLimMode = QSP.PlotSettings.DefaultXLimMode;
                   obj.h.MainAxes(index).YLim = str2num(QSP.PlotSettings.DefaultCustomYLim);
                   obj.h.MainAxes(index).YLimMode = QSP.PlotSettings.DefaultYLimMode;
                   
                   %Assign plot settings
                   
                   %TODO: Assign the current plot settings to the plot
                   %settings array. This is not currently possible becuase
                   %the QSP.PlotSettings Class does not support UIAXes,
                   %only Axes. This also includes checking if they want
                   %default interactivity 
                   
                   %Find the outermost uifigure handle
                   hFigure = ancestor(obj.Parent,'Figure');
                   
                   obj.h.ContextMenu(index) = uicontextmenu('Parent',hFigure);
                   obj.h.MainAxes(index).ContextMenu = obj.h.ContextMenu(index);
                   obj.h.ContextMenuYScale(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Y-Scale',...
                        'Tag','YScale');
                    uimenu(obj.h.ContextMenuYScale(index),...
                        'Label','Linear',...
                        'Tag','YScaleLinear',...
                        'Checked','on',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    uimenu(obj.h.ContextMenuYScale(index),...
                        'Label','Log',...
                        'Tag','YScaleLog',...
                        'Checked','off',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    uimenu(obj.h.ContextMenu(index),...
                        'Label','Save Current Axes...',...
                        'Tag','ExportSingleAxes',...
                        'Separator','on',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    uimenu(obj.h.ContextMenu(index),...
                        'Label','Save Full View...',...
                        'Tag','ExportAllAxes',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));                    
                    
                    if strcmpi(class(obj),'QSPViewer.VirtualPopulationGeneration')
                        obj.bShowTraces(index) = false; % default off
                        obj.bShowQuantiles(index) = true; % default on
                        obj.bShowMean(index) = true; % default on
                        obj.bShowMedian(index) = false; % default off
                        obj.bShowSD(index) = false; % default off
                    else
                        obj.bShowTraces(index) = false; % default off
                        obj.bShowQuantiles(index) = true; % default on
                        obj.bShowMean(index) = false; % default off
                        obj.bShowMedian(index) = true; % default on
                        obj.bShowSD(index) = false; % default off
                    end
                    
                    % Show traces/quantiles/mean/median/SD
                    obj.h.ContextMenuTraces(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Traces',...
                        'Checked',uix.utility.tf2onoff(obj.bShowTraces(index)),...
                        'Separator','on',...
                        'Tag','ShowTraces',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                     obj.h.ContextMenuQuantiles(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Upper/Lower Quantiles',...
                        'Checked',uix.utility.tf2onoff(obj.bShowQuantiles(index)),...
                        'Tag','ShowQuantiles',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    obj.h.ContextMenuMean(index) = uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Mean (Weighted)',...
                        'Checked',uix.utility.tf2onoff(obj.bShowMean(index)),...
                        'Tag','ShowMean',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    obj.h.ContextMenuMedian(index) =uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Median (Weighted)',...
                        'Checked',uix.utility.tf2onoff(obj.bShowMedian(index)),...
                        'Tag','ShowMedian',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));
                    obj.h.ContextMenuSD(index) =uimenu(obj.h.ContextMenu(index),...
                        'Label','Show Standard Deviation (Weighted)',...
                        'Checked',uix.utility.tf2onoff(obj.bShowSD(index)),...
                        'Tag','ShowSD',...
                        'Callback',@(h,e)onAxesContextMenu(obj,h,e,index));   
               end
               %RHS: The settings panel
               obj.h.PlotSettingsLayout = uigridlayout(obj.h.VisualizationLayout);
               obj.h.PlotSettingsLayout.ColumnWidth = {'1x'};
               obj.h.PlotSettingsLayout.RowHeight = {ButtonSize,'1x',ButtonSize};
               obj.h.PlotSettingsLayout.Layout.Row = 1;
               obj.h.PlotSettingsLayout.Layout.Column = 2;
               obj.h.PlotSettingsLayout.Padding = [0,0,0,0];
               
               %1. The plot dropdown
               obj.h.PlotConfigPopUpLayout = uigridlayout(obj.h.PlotSettingsLayout);
               obj.h.PlotConfigPopUpLayout.Layout.Row = 1;
               obj.h.PlotConfigPopUpLayout.Layout.Column = 1;
               obj.h.PlotConfigPopUpLayout.RowHeight = {'1x'};
               obj.h.PlotConfigPopUpLayout.ColumnWidth = {80,'1x'};
               obj.h.PlotConfigPopUpLayout.Padding = [0,0,0,0];
               
               %Drop down label
               obj.h.PlotConfigPopUpLabel = uilabel(obj.h.PlotConfigPopUpLayout);
               obj.h.PlotConfigPopUpLabel.Layout.Row = 1;
               obj.h.PlotConfigPopUpLabel.Layout.Column = 1;
               obj.h.PlotConfigPopUpLabel.Text = 'Plot Layout';
               obj.h.PlotConfigPopUpLabel.HorizontalAlignment = 'center';
               obj.h.PlotConfigPopUpLabel.FontWeight = 'bold';
               
               %Drop down menu
               obj.h.PlotConfigPopUp = uidropdown(obj.h.PlotConfigPopUpLayout);
               obj.h.PlotConfigPopUp.Items = obj.PlotLayoutOptions;
               obj.h.PlotConfigPopUp.ValueChangedFcn = @app.onPlotConfigChange;
               obj.h.PlotConfigPopUp.Tag = 'PlotConfigPopup';
               obj.h.PlotConfigPopUp.Layout.Row = 1;
               obj.h.PlotConfigPopUp.Layout.Column = 2;
               
               %2. The panel to display information
               obj.h.PlotSettingsPanel = uipanel(obj.h.PlotSettingsLayout);
               obj.h.PlotSettingsPanel.Layout.Row = 2;
               obj.h.PlotSettingsPanel.Layout.Column = 1;
               
               %3. The remove invalid button
               obj.h.RemoveInvalidVisualization = uigridlayout(obj.h.PlotSettingsLayout);
               obj.h.RemoveInvalidVisualization.Layout.Row = 3;
               obj.h.RemoveInvalidVisualization.Layout.Column = 1;
               obj.h.RemoveInvalidVisualization.RowHeight = {ButtonSize,'1x'};
               obj.h.RemoveInvalidVisualization.ColumnWidth = {'1x',100,'1x'};
               obj.h.RemoveInvalidVisualization.Padding = [0,0,0,0];
               
               obj.h.RemoveInvalidVisualizationButton = uibutton(obj.h.RemoveInvalidVisualization,'push');
               obj.h.RemoveInvalidVisualizationButton.Text = 'Remove Invalid';
               obj.h.RemoveInvalidVisualizationButton.Tag = 'RemoveInvalid';
               obj.h.RemoveInvalidVisualizationButton.Layout.Row = 1;
               obj.h.RemoveInvalidVisualizationButton.Layout.Column = 2;
               obj.h.RemoveInvalidVisualizationButton.Tooltip = 'Remove Invalid Entries';
               obj.h.RemoveInvalidVisualizationButton.ButtonPushedFcn = @obj.RemoveInvalidVisualizationButtonLayout;
           end
           
           %Update selection
           obj.h.CardPanel.Selection = obj.Selection;
           
           %Create the Buttons grid layout;
           obj.h.ButtonsLayout = uigridlayout(obj.OuterGrid);
           obj.h.ButtonsLayout.Layout.Row =1;
           obj.h.ButtonsLayout.Layout.Column = 1;
           obj.h.ButtonsLayout.Padding = [0,0,0,0];
           obj.h.ButtonsLayout.ColumnSpacing = 0;
           obj.h.ButtonsLayout.RowSpacing = 0;
           obj.h.ButtonsLayout.RowHeight = {'1x'};
           obj.h.ButtonsLayout.ColumnWidth = {ButtonSize,ButtonSize,ButtonSize,ButtonSize,ButtonSize,ButtonSize,ButtonSize,ButtonSize,ButtonSize,ButtonSize,'1x'};
           
           %Summary Button
           obj.h.SummaryButton = uibutton(obj.h.ButtonsLayout,'push');
           obj.h.SummaryButton.Layout.Row = 1;
           obj.h.SummaryButton.Layout.Column = 1;
           obj.h.SummaryButton.Icon = uix.utility.findIcon('report_24.png');
           obj.h.SummaryButton.Tooltip = 'View summary';
           obj.h.SummaryButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Summary');
           obj.h.SummaryButton.Text = '';
           
           %Edit Button
           obj.h.EditButton = uibutton(obj.h.ButtonsLayout,'push');
           obj.h.EditButton.Layout.Row = 1;
           obj.h.EditButton.Layout.Column = 2;
           obj.h.EditButton.Icon = uix.utility.findIcon('edit_24.png');
           obj.h.EditButton.Tooltip = 'Edit the selected item';
           obj.h.EditButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Edit');
           obj.h.EditButton.Text = '';
           
           %Run Button
           obj.h.RunButton = uibutton(obj.h.ButtonsLayout,'push');
           obj.h.RunButton.Layout.Row = 1;
           obj.h.RunButton.Layout.Column = 3;
           obj.h.RunButton.Icon = uix.utility.findIcon('play_24.png');
           obj.h.RunButton.Tooltip = 'Run the selected item';
           obj.h.RunButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Run');
           obj.h.RunButton.Text = '';
           
           %Visualize Button
           obj.h.VisualizeButton = uibutton(obj.h.ButtonsLayout,'push');
           obj.h.VisualizeButton.Layout.Row = 1;
           obj.h.VisualizeButton.Layout.Column = 5;
           obj.h.VisualizeButton.Icon = uix.utility.findIcon('visualize_24.png');
           obj.h.VisualizeButton.Tooltip = 'Visualize the selected item';
           obj.h.VisualizeButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Visualize');
           obj.h.VisualizeButton.Text = '';
           
           %PlotSettings Button
           obj.h.PlotSettingsButton = uibutton(obj.h.ButtonsLayout,'push');
           obj.h.PlotSettingsButton.Layout.Row = 1;
           obj.h.PlotSettingsButton.Layout.Column = 6;
           obj.h.PlotSettingsButton.Icon =  uix.utility.findIcon('settings_24.png');
           obj.h.PlotSettingsButton.Tooltip = 'Customize plot settings for the selected item';
           obj.h.PlotSettingsButton.ButtonPushedFcn = @(h,e)obj.onNavigation('CustomizeSettings');
           obj.h.PlotSettingsButton.Text = '';
           
           %Zoom in Button ZoomIn
           obj.h.ZoomInButton = uibutton(obj.h.ButtonsLayout,'state');
           obj.h.ZoomInButton.Layout.Row = 1;
           obj.h.ZoomInButton.Layout.Column = 7;
           obj.h.ZoomInButton.Icon = '+QSPViewerNew\+Resources\zoomin.png';
           obj.h.ZoomInButton.Tooltip = 'Zoom In';
           obj.h.ZoomInButton.ValueChangedFcn = @(h,e)obj.onNavigation('ZoomIn');
           obj.h.ZoomInButton.Text = '';
           
           %Zoom out Button
           obj.h.ZoomOutButton = uibutton(obj.h.ButtonsLayout,'state');
           obj.h.ZoomOutButton.Layout.Row = 1;
           obj.h.ZoomOutButton.Layout.Column = 8; 
           obj.h.ZoomOutButton.Icon = '+QSPViewerNew\+Resources\zoomout.png';
           obj.h.ZoomOutButton.Tooltip = 'Zoom Out';
           obj.h.ZoomOutButton.ValueChangedFcn = @(h,e)obj.onNavigation('ZoomOut');
           obj.h.ZoomOutButton.Text = '';
           
           %Pan Button
           obj.h.PanButton = uibutton(obj.h.ButtonsLayout,'state');
           obj.h.PanButton.Layout.Row = 1;
           obj.h.PanButton.Layout.Column = 9;
           obj.h.PanButton.Icon = '+QSPViewerNew\+Resources\pan.png';
           obj.h.PanButton.Tooltip = 'Pan';
           obj.h.PanButton.ValueChangedFcn = @(h,e)obj.onNavigation('Pan');
           obj.h.PanButton.Text = '';
           
           %Data Cursor Button
           obj.h.DatacursorButton = uibutton(obj.h.ButtonsLayout,'state');
           obj.h.DatacursorButton.Layout.Row = 1;
           obj.h.DatacursorButton.Layout.Column = 10;
           obj.h.DatacursorButton.Icon = '+QSPViewerNew\+Resources\datatip.png';
           obj.h.DatacursorButton.Tooltip = 'Explore';
           obj.h.DatacursorButton.ValueChangedFcn = @(h,e)obj.onNavigation('Datacursor');
           obj.h.DatacursorButton.Text = '';
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function onEditName(obj,h,e)
            % Update the name
            if ~isempty(obj.TempData)
                obj.TempData.Name = get(h,'String');
            end
            
            % Update the view
            obj.updateNameDescription();
        end   
        
        function onEditDescription(obj,h,e) 
            % Update the description
            if ~isempty(obj.TempData)
                obj.TempData.Description = get(h,'String');
            end
            % Update the view
            obj.updateNameDescription();
        end
        
        function onEditButtonPress(obj,h,e);
            %Get the tag of the button pressed
            ThisTag = get(h,'Tag');
            
            %Choose the button
            switch ThisTag
                case 'RemoveInvalid'
                    disp('TODO: Remove Invalid')
                case 'Save'
                    disp('TODO: Save panel')
                case 'Cancel'
                    disp('TODO: Cancel')
            end    
        end
        
        function onRemoveInvalidVisualization(obj,h,e);
            disp("TODO: Remoev invalid Visualization");
        end
        
        function onNavigation(obj,viewSelected)
            switch viewSelected
                case 'Summary'
                    disp('TODO:Summary, this is a temporary solution)')
                case 'Edit'
                    disp('TODO:Edit, this is a temporary solution)')
                case 'Run'
                    disp('TODO:Run, this is a temporary solution)')
                case 'Visualize'
                    disp('TODO:Run, this is a temporary solution')
                case 'CustomizeSettings'
                    disp('You Selected CustomizeSettings')
                case 'ZoomIn'
                    disp('Zoom')
                case 'ZoomOut'
                    disp('Zoomout')
                case 'Pan'
                    disp('pan')
                case 'Datacursor'
                    disp('datacursor')
            end    
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Helper Functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function [StatusOK, Message] = checkDuplicateNames(obj, StatusOK, Message)
            %TODO
        end
        
        function refresh(obj)
            %TODO
        end
        
        function updateToggleButtons(obj)
            %TODO
        end
        
        function update(obj)
            %TODO
        end
        
        function Value = getAxesOptions(obj)
            %TODO
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Static methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function fixAxesInFigure(hFigure,hAxes)
            %TODO
        end
        
        function [hThisLegend,hThisLegendChildren] = redrawLegend(hThisAxes,LegendItems,ThesePlotSettings)
            %TODO
        end
        
    end
    
end


