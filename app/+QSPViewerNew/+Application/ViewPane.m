classdef ViewPane < handle
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
        PanelPadding = [0,0,0,0];
        PanelWidthSpacing = 5; 
        PanelHeightSpacing = 5; 
        SubPanelPadding = [5,5,5,5];
        SubPanelWidthSpacing = 5; 
        SubPanelHeightSpacing = 5; 
        OuterGridPadding = [0,0,0,0];
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
        LabelLength = 200;
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
                message = ['This constructor requires one of the following of inputs' ...
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
           obj.RemoveButton.ButtonPushedFcn = @(~,~) obj.onRemoveInvalid();
           
           obj.SaveButton = uibutton(obj.EditButtonLayout,'push');
           obj.SaveButton.Layout.Row = 1;
           obj.SaveButton.Layout.Column = 3;
           obj.SaveButton.Text = 'Save';
           obj.SaveButton.Tag = 'Save';
           obj.SaveButton.ButtonPushedFcn = @(~,~) obj.onSave();
           
           obj.CancelButton = uibutton(obj.EditButtonLayout,'push');
           obj.CancelButton.Layout.Row = 1;
           obj.CancelButton.Layout.Column = 4;
           obj.CancelButton.Text = 'Cancel';
           obj.CancelButton.Tag = 'Cancel';
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
           obj.ButtonWidth,obj.ButtonWidth,'1x'};
           
           %Summary Button
           obj.SummaryButton = uibutton(obj.ButtonsLayout,'push');
           obj.SummaryButton.Layout.Row = 1;
           obj.SummaryButton.Layout.Column = 1;
           obj.SummaryButton.Icon = '+QSPViewerNew\+Resources\report_24.png';
           obj.SummaryButton.Tooltip = 'View summary';
           obj.SummaryButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Summary');
           obj.SummaryButton.Text = '';
           
           %Edit Button
           obj.EditButton = uibutton(obj.ButtonsLayout,'push');
           obj.EditButton.Layout.Row = 1;
           obj.EditButton.Layout.Column = 2;
           obj.EditButton.Icon = '+QSPViewerNew\+Resources\edit_24.png';
           obj.EditButton.Tooltip = 'Edit the selected item';
           obj.EditButton.ButtonPushedFcn = @(h,e)obj.onNavigation('Edit');
           obj.EditButton.Text = '';
       end
       
   end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function onNavigation(obj,keyword)
            obj.Focus = keyword;
            obj.refocus;
        end
        
        function onRemoveInvalid(obj)
            obj.checkForInvalid();
        end
        
        function onSave(obj)
            obj.saveBackEndInformation();
            obj.Focus = 'Summary';
            obj.refocus();
        end
        
        function onCancel(obj)
            %Prompt the user to makse sure they want to cancel;
            if obj.checkDirty()
                Options = {'Save','Don''t Save','Cancel'};
                selection = uiconfirm(obj.getUIFigure,...
                'Changes Have not been saved. How would you like to continue?',...
                   'Continue?','Options',Options,'DefaultOption',3);
            else
                selection = 'Don''t Save';
            end
           
           %Determine next steps based on their response
            switch selection
                case 'Save'   
                   
                    %Save as normal
                    obj.onSave();
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
                        obj.draw();
                        obj.CurrentPane.Visible = 'on';
                        
                        %Turn the buttons on 
                        obj.ParentApp.enableInteraction();
                        obj.SummaryButton.Enable = 'on';
                        %TODO obj.VisualizationButton.Enable = 'off';
                    end
                case 'Edit'
                    if strcmp(obj.EditPanel.Visible,'off')
                        %If the Edit window is not already shown
                        obj.CurrentPane.Visible = 'off';
                        obj.CurrentPane = obj.EditPanel;
                        obj.draw();
                        obj.CurrentPane.Visible = 'on';
                        
                        %Disable all external buttons and other views
                        obj.ParentApp.disableInteraction();
                        obj.SummaryButton.Enable = 'off';
                        %TODO  obj.VisualizationButton.Enable = 'off';
                    end
            end 
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
            %hide this pane
            obj.OuterGrid.Visible = 'off';
        end
        
        function showPane(obj)
            %show this pane. Whenever a pane is shown, start with the
            %summary
            obj.Focus = 'Summary';
            obj.refocus;
            obj.OuterGrid.Visible = 'on';
        end
        
        function notifyOfChange(obj,newBackEndObject)
            obj.ParentApp.changeInBackEnd(newBackEndObject);
        end
        
    end

    methods(Access = public)
       
        function value = getUIFigure(obj)
            value = obj.ParentApp.getUIFigure();
        end
        
        function value = getEditGrid(obj)
            value = obj.EditLayout;
        end
    end
    
    methods(Abstract)
        NotifyOfChangeInName(obj,value);
        NotifyOfChangeInDescription(obj,value);
        saveBackEndInformation(obj);
        checkForInvalid(obj);
        draw(obj);
        deleteTemporary(obj);
        hideThisPane(obj);
        showThisPane(obj);
        checkDirty(obj);
    end
       
end



