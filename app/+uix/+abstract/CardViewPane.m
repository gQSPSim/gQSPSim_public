classdef (Abstract) CardViewPane < uix.abstract.ViewPane
    % CardViewPane - A base class for building view panes
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated. It
    % provides the basic properties needed for a view pane that will
    % contain a group of graphics objects to build a complex view pane.
    %
    
    %   Copyright 2008-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    properties (AbortSet=true, SetObservable)
        TempData
        Selection = 1
        IsDeleted = false
    end
    
    properties (SetAccess=private)
        SelectedPlotLayout = '1x1'
        UseRunVis = false
    end
    
    properties (Constant=true)
        MaxNumPlots = 12
        PlotLayoutOptions = {'1x1','1x2','2x1','2x2','3x2','3x3','3x4'}
    end
    
    events( NotifyAccess = protected )
        TempDataEdited
    end
    
    %% Constructor and Destructor
    methods
        function obj = CardViewPane( UseRunVis, varargin )
            
            % First step is to create the parent class. We pass the
            % arguments (if any) just incase the parent needs setting
            obj = obj@uix.abstract.ViewPane( varargin{:} );
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
            % Set UseRunVis before calling create
            obj.UseRunVis = UseRunVis;
            
        end
    end
    
    methods (Access=protected)
        function create(obj)
            
            WidgetHeight = 30;
            LabelWidth = 80;
            Pad = 2;
            VSpace = 4;
            HSpace = 6; %Space between controls
            TitleColor = [0.6235    0.7255    0.8314];
            
            hFigure = ancestor(obj.UIContainer,'Figure');
            
            % Turn off border for UIContainer
            set(obj.UIContainer,'BorderType','none');
            
            
            obj.h.MainLayout = uix.VBox(...
                'Parent',obj.UIContainer);
            
            % Buttons
            obj.h.ButtonLayout = uix.HBox(...
                'Parent',obj.h.MainLayout);
            
            % Create card panel
            obj.h.CardPanel = uix.CardPanel(...
                'Parent',obj.h.MainLayout);
            
            % Sizes
            obj.h.MainLayout.Heights = [WidgetHeight -1];
            
            %%% Summary
            obj.h.SummaryPanel = uix.BoxPanel(...
                'Parent',obj.h.CardPanel,...
                'Title','Summary',...
                'ForegroundColor',[0 0 0],...
                'TitleColor',TitleColor,...
                'FontSize',10,...
                'Padding',Pad);
            % Add Summary widget
            obj.h.SummaryContent = uix.widget.Summary(...
                'Parent',obj.h.SummaryPanel);
            
            %%% Add/Edit
            obj.h.EditPanel = uix.BoxPanel(...
                'Parent',obj.h.CardPanel,...
                'Title','Edit',...
                'ForegroundColor',[0 0 0],...
                'TitleColor',TitleColor,...
                'FontSize',10,...
                'Padding',5);
            obj.h.EditLayout = uix.VBox(...
                'Parent',obj.h.EditPanel,...
                'Padding',5,...
                'Spacing',12);
            % Row 1: File/Description, Row 2: Contents, Row 3: Buttons
            obj.h.FileSelectRows(1) = uix.HBox(...
                'Parent',obj.h.EditLayout,...
                'Padding',0,...
                'Spacing',5);
            obj.h.EditContentsPanel = uix.Panel(...
                'Parent',obj.h.EditLayout,...
                'BorderType','none');
            obj.h.EditButtonLayout = uix.HBox(...
                'Parent',obj.h.EditLayout);
            obj.h.EditLayout.Heights = [WidgetHeight -1 WidgetHeight];
            
            %%% Row 1
            obj.h.FileSelect(1) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','text',...
                'String','Name',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            obj.h.FileSelect(2) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','edit',...
                'HorizontalAlignment','left',...
                'FontSize',10,...
                'Callback',@(h,e)onEditName(obj,h,e));
            obj.h.FileSelect(3) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','text',...
                'String','Description',...
                'FontSize',10,...
                'FontWeight','bold',...
                'HorizontalAlignment','left');
            obj.h.FileSelect(4) = uicontrol(...
                'Parent',obj.h.FileSelectRows(1),...
                'Style','edit',...
                'HorizontalAlignment','left',...
                'FontSize',10,...
                'Callback',@(h,e)onEditDescription(obj,h,e));
            set(obj.h.FileSelectRows(1),'Widths',[LabelWidth -1 LabelWidth -2]);
            
            %%% Row 3
            uix.Empty('Parent',obj.h.EditButtonLayout);
            obj.h.RemoveButton = uicontrol(...
                'Parent',obj.h.EditButtonLayout,...
                'Style','pushbutton',...
                'Tag','RemoveInvalid',...
                'String','Remove Invalid',...
                'TooltipString','Remove Invalid Entries',...
                'FontSize',10,...
                'Callback',@(h,e)onButtonPress(obj,h,e));
            obj.h.SaveButton = uicontrol(...
                'Parent',obj.h.EditButtonLayout,...
                'Style','pushbutton',...
                'Tag','Save',...
                'String','Save',...
                'TooltipString','Apply and Save Changes to Selection',...
                'FontSize',10,...
                'Callback',@(h,e)onButtonPress(obj,h,e));
            obj.h.CloseButton = uicontrol(...
                'Parent',obj.h.EditButtonLayout,...
                'Style','pushbutton',...
                'Tag','Close',...
                'String','Close',...
                'TooltipString','Close without Saving',...
                'FontSize',10,...
                'Callback',@(h,e)onButtonPress(obj,h,e));
            obj.h.EditButtonLayout.Widths = [-1 125 75 75];
            
            %%% Visualize
            if obj.UseRunVis
                obj.h.VisualizePanel = uix.BoxPanel(...
                    'Parent',obj.h.CardPanel,...
                    'Title','Visualize',...
                    'ForegroundColor',[0 0 0],...
                    'TitleColor',TitleColor,...
                    'FontSize',10,...
                    'Padding',Pad);
                obj.h.VisualizeLayout = uix.HBoxFlex(...
                    'Parent',obj.h.VisualizePanel);
                % LHS: Grid
                obj.h.PlotGrid = uix.Grid(...
                    'Parent',obj.h.VisualizeLayout,...
                    'Padding',5);
                for index = 1:obj.MaxNumPlots
                    obj.h.MainAxesContainer(index) = uicontainer(...
                        'Parent',obj.h.PlotGrid);
                    obj.h.MainAxes(index) = axes(...
                        'Parent',obj.h.MainAxesContainer(index),...
                        'Visible','off');
                    hContextMenu = uicontextmenu('Parent',hFigure);
                    hContextMenuYScale = uimenu(hContextMenu,...
                        'Label','Y-Scale',...
                        'Tag','YScale');
                    uimenu(hContextMenuYScale,...
                        'Label','Linear',...
                        'Tag','YScaleLinear',...
                        'Checked','on',...
                        'Callback',@(h,e)onAxesContextMenu(app,h,e,index));
                    uimenu(hContextMenuYScale,...
                        'Label','Log',...
                        'Tag','YScaleLog',...
                        'Checked','off',...
                        'Callback',@(h,e)onAxesContextMenu(app,h,e,index));
                    uimenu(hContextMenu,...
                        'Label','Save Current Axes...',...
                        'Tag','ExportSingleAxes',...
                        'Separator','on',...
                        'Callback',@(h,e)onAxesContextMenu(app,h,e,index));
                    uimenu(hContextMenu,...
                        'Label','Save Full View...',...
                        'Tag','ExportAllAxes',...
                        'Callback',@(h,e)onAxesContextMenu(app,h,e,index));
                    set(obj.h.MainAxes(index),'UIContextMenu',hContextMenu);
                end
                set(obj.h.MainAxes(1),'Visible','on');
                
                % RHS: Settings
                obj.h.PlotSettingsLayout = uix.VBox(...
                    'Parent',obj.h.VisualizeLayout,...
                    'Padding',5,...
                    'Spacing',10);
               obj.h.VisualizeLayout.Widths = [-2 -1];
                
                % RHS: Settings Panel
                obj.h.PlotConfigPopup = uix.widget.PopupFieldWithLabel(...
                    'Parent',obj.h.PlotSettingsLayout,...
                    'Tag','PlotConfigPopup',...
                    'String',{' '},...
                    'LabelString','Plot Layout',...
                    'LabelFontSize',10,...
                    'LabelFontWeight','bold',...
                    'Callback',@(h,e)onPlotConfigChange(obj,h,e));
                obj.h.PlotSettingsPanel = uix.Panel(...
                    'Parent',obj.h.PlotSettingsLayout,...
                    'BorderType','none');
                obj.h.RemoveInvalidVisualizationButtonLayout = uix.HButtonBox(...
                    'Parent',obj.h.PlotSettingsLayout);
                obj.h.RemoveInvalidVisualizationButton = uicontrol(...
                    'Parent',obj.h.RemoveInvalidVisualizationButtonLayout,...
                    'Style','pushbutton',...
                    'Tag','RemoveInvalid',...
                    'String','Remove Invalid',...
                    'TooltipString','Remove Invalid Entries',...
                    'FontSize',10,...
                    'Callback',@(h,e)onRemoveInvalidVisualization(obj,h,e));
                obj.h.RemoveInvalidVisualizationButtonLayout.ButtonSize = [125 WidgetHeight];
                    
                obj.h.PlotSettingsLayout.Heights = [WidgetHeight -1 WidgetHeight];
            end
            
            % Update selection
            obj.h.CardPanel.Selection = obj.Selection;
            
            %%% Buttons
            obj.h.SummaryButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'report_24.png' ), ...
                'TooltipString', 'View summary',...
                'Callback', @(h,e)onNavigation(obj,'Summary') );
            obj.h.EditButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'edit_24.png' ), ...
                'TooltipString', 'Edit the selected item',...
                'Callback', @(h,e)onNavigation(obj,'Edit') );
            obj.h.RunButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'play_24.png' ), ...
                'TooltipString', 'Run the selected item.',...
                'Callback', @(h,e)onNavigation(obj,'Run') );
            obj.h.VisualizeButton = uicontrol( ...
                'Parent', obj.h.ButtonLayout, ...
                'Style', 'pushbutton', ...
                'CData', uix.utility.loadIcon( 'visualize_24.png' ), ...
                'TooltipString', 'Visualize the selected item.',...
                'Callback', @(h,e)onNavigation(obj,'Visualize') );
            uix.Empty('Parent',obj.h.ButtonLayout);
            
            obj.h.ButtonLayout.Widths = [WidgetHeight WidgetHeight WidgetHeight WidgetHeight -1];
            
        end %function
        
    end
    
    methods
        
        function onEditName(obj,h,e) %#ok<*INUSD>
            % Update the name
            if ~isempty(obj.TempData)
                obj.TempData.Name = get(h,'String');
            end
            
            % Update the view
            updateNameDescription(obj);
            
        end %function
        
        function onEditDescription(obj,h,e)
            
            % Update the description
            if ~isempty(obj.TempData)
                obj.TempData.Description = get(h,'String');
            end
            
            % Update the view
            updateNameDescription(obj);
            
        end %function
        
        function onButtonPress(obj,h,e)
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'RemoveInvalid'
                    FlagRemoveInvalid = true;
                    % Remove the invalid entries
                    validate(obj.TempData,FlagRemoveInvalid);
                    
                case 'Save'
                    FlagRemoveInvalid = false;
                    [StatusOK,Message] = validate(obj.TempData,FlagRemoveInvalid);
                    
                    if StatusOK
                        % Copy from TempData into Data, using obj.Data as a
                        % starting point
                        obj.Data = copy(obj.TempData,obj.Data);
                        % Update time
                        updateLastSavedTime(obj.Data);
                        % Call the callback
                        evt.InteractionType = sprintf('Updated %s',class(obj.Data));
                        evt.Name = obj.Data.Name;
                        obj.callCallback(evt);
                    else
                        hDlg = errordlg(sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save','modal');
                        uiwait(hDlg);
                    end
                    
                case 'Close'
                    if ~isPublicPropsEqual(obj.Data,obj.TempData)
                        Prompt = sprintf('Changes have not been saved. How would you like to continue?');
                        Result = questdlg(Prompt,'Continue?','Save','Don''t Save','Cancel','Cancel');
                        if strcmpi(Result,'Save')
                            FlagRemoveInvalid = false;
                            [StatusOK,Message] = validate(obj.TempData,FlagRemoveInvalid);
                            
                            if StatusOK
                                obj.Selection = 1;
                                set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                                % Copy from TempData into Data, using obj.Data as a
                                % starting point
                                obj.Data = copy(obj.TempData,obj.Data);
                                % Update time
                                updateLastSavedTime(obj.Data);
                                % Call the callback
                                evt.InteractionType = sprintf('Updated %s',class(obj.Data));
                                evt.Name = obj.Data.Name;
                                obj.callCallback(evt);
                            else
                                hDlg = errordlg(sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save','modal');
                                uiwait(hDlg);
                            end
                            
                        elseif strcmpi(Result,'Don''t Save')
                            obj.Selection = 1;
                            set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                            % Copy from Data into TempData, using obj.TempData as a
                            % starting point
                            obj.TempData = copy(obj.Data,obj.TempData);
                        end %Else, do nothing
                    else
                        obj.Selection = 1;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                        % Copy from Data into TempData, using obj.TempData as a
                        % starting point
                        obj.TempData = copy(obj.Data,obj.TempData);
                    end
            end
            
            % Update the view
            if obj.UseRunVis            
                updateEditView(obj);
            else
                update(obj);
            end
            
        end %function
        
        function onRemoveInvalidVisualization(obj,h,e)
            
            if ~obj.UseRunVis
                return;
            end
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'RemoveInvalid'
                    
                    removeInvalidVisualization(obj);
                    
            end
        end %function
        
        function onNavigation(obj,View)
            
            switch View
                case 'Summary'
                    if obj.Selection == 2 && ~isPublicPropsEqual(obj.Data,obj.TempData)
                        Prompt = sprintf('Do you want to continue without saving changes?');
                        Result = questdlg(Prompt,'Continue','Yes','Cancel','Yes');
                        if strcmpi(Result,'Yes')
                            obj.Selection = 1;
                            % Copy from Data into TempData, using obj.TempData as a
                            % starting point
                            obj.TempData = copy(obj.Data,obj.TempData);
                        end
                    else
                        obj.Selection = 1;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                    end
                    
                case 'Edit'
                    
                    % Copy from Data into TempData, using obj.TempData as a
                    % starting point (Visualization view edits obj.Data and
                    % TempData may be out of date)
                    obj.TempData = copy(obj.Data,obj.TempData);
                    
                    obj.Selection = 2;
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','off');
                    
                case 'Run'
                    % Run
                    
                    hFigure = ancestor(obj.UIContainer,'Figure');
                    set(hFigure,'pointer','watch');
                    drawnow;
                    
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                    
                    [StatusOK,Message,vpopObj] = run(obj.Data);
                    if ~StatusOK
                        hDlg = errordlg(Message,'Run Failed','modal');
                        uiwait(hDlg);
                    elseif ~isempty(vpopObj)
                        % Call the callback
                        evt.InteractionType = sprintf('Updated %s',class(vpopObj));
                        evt.Data = vpopObj;
                        obj.callCallback(evt);
                    end
                    
                    set(hFigure,'pointer','arrow');
                    drawnow;
                    
                case 'Visualize'
                    if obj.Selection == 2
                        Prompt = sprintf('Do you want to continue without saving changes?');
                        Result = questdlg(Prompt,'Continue','Yes','Cancel','Yes');
                        if strcmpi(Result,'Yes')
                            obj.Selection = 3;
                            set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                        end
                    else
                        obj.Selection = 3;
                        set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');
                    end
            end
            
            % Update the view
            update(obj);
            
        end %function
        
        function onPlotConfigChange(obj,h,e)
            
            Value = get(h,'Value');
            obj.SelectedPlotLayout = obj.PlotLayoutOptions{Value};
            
            % Update the view
            updateVisualizationView(obj);
            update(obj);
        end
        
        function onAxesContextMenu(obj,h,~,axIndex)
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'YScaleLinear'
                    % Manage context menu states here for ease
                    set(get(get(h,'Parent'),'Children'),'Checked','off');
                    set(h,'Checked','on')
                    set(obj.h.MainAxes(axIndex),'YScale','linear');
                case 'YScaleLog'
                    % Manage context menu states here for ease
                    set(get(get(h,'Parent'),'Children'),'Checked','off');
                    set(h,'Checked','on')
                    set(obj.h.MainAxes(axIndex),'YScale','log');
                case 'ExportSingleAxes'
                    % Prompt the user for a filename
                    Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        '*.fig','MATLAB Figure';...
                        };
                    Title = 'Save as';
                    SaveFilePath = obj.LastPath;
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        SaveFilePath = fullfile(SavePathName,SaveFileName);
                        hTempFig = figure('Visible','off');
                        ThisAxes = get(obj.h.MainAxesContainer(axIndex),'Children');
                        hNewAxes = copyobj(ThisAxes,hTempFig);
                        set(hTempFig,'Color','white');
                        
                        % Print using option
                        [~,~,FileExt] = fileparts(SaveFilePath);
                        if strcmpi(FileExt,'.fig')
                            % Delete the legend from hThisAxes
                            delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
                            hNewAxes = hNewAxes(ishandle(hNewAxes));
                            % Create a new legend
                            OrigLegend = ThisAxes(strcmpi(get(ThisAxes,'Tag'),'legend'));
                            if ~isempty(OrigLegend)
                                % Make current axes and place legend
                                axes(hNewAxes);                                
                                legend(OrigLegend.String{:});
                            end
                            set(hTempFig,'Visible','on')
                            saveas(hTempFig,SaveFilePath);
                        else
                            if strcmpi(FileExt,'.png')
                                Option = '-dpng';
                            elseif strcmpi(FileExt,'.eps')
                                Option = '-depsc';
                            else
                                Option = '-dtiff';
                            end
                            print(hTempFig,Option,SaveFilePath)
                        end
                        close(hTempFig)                        
                    end
                case 'ExportAllAxes'
                    % Prompt the user for a filename
                     Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        '*.fig','MATLAB Figure'...
                        };
                    Title = 'Save as';
                    SaveFilePath = obj.LastPath;
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        SaveFilePath = fullfile(SavePathName,SaveFileName);
                        
                        % Print using option
                        [~,~,FileExt] = fileparts(SaveFilePath);
                        
                        if strcmpi(FileExt,'.fig')
                            hTempFig = figure('Visible','off');
                            Pos = get(obj.h.PlotGrid,'Position');
                            set(hTempFig,'Units',obj.Figure.Units,'Position',[obj.Figure.Position(1:2) Pos(3) Pos(4)],'Color','white');
                            
                            Ch = get(obj.h.PlotGrid,'Children');
                            for index = 1:numel(Ch)
                                hThisContainer = uicontainer('Parent',hTempFig,'Units','pixels','Position',get(Ch(index),'Position'));
                                
                                ThisAxes = get(Ch(index),'Children');
                                hNewAxes = copyobj(ThisAxes,hThisContainer);
                                
                                % Delete the legend from hThisAxes
                                delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
                                hNewAxes = hNewAxes(ishandle(hNewAxes));
                                % Create a new legend
                                OrigLegend = ThisAxes(strcmpi(get(ThisAxes,'Tag'),'legend'));
                                if ~isempty(OrigLegend)
                                    % Make current axes and place legend
                                    axes(hNewAxes); %#ok<LAXES>
                                    legend(OrigLegend.String{:});
                                end
                                set(hThisContainer,'BackgroundColor','white','Units','normalized');
                            end
                            
                            set(hTempFig,'Visible','on')
                            saveas(hTempFig,SaveFilePath);
                            
                        else
                            
                            hTempFig = figure('Visible','off');
                            hGrid = copyobj(obj.h.PlotGrid,hTempFig);
                            Units = get(obj.h.PlotGrid,'Units');
                            Pos = get(obj.h.PlotGrid,'Position');
                            set(hGrid,'BackgroundColor','white','Units',Units,'Position',[0 0 Pos(3) Pos(4)]);
                            hContainers = get(hGrid,'Children');
                            set(hContainers,'BackgroundColor','white');
                            set(hTempFig,'Units',obj.Figure.Units,'Position',[obj.Figure.Position(1:2) Pos(3) Pos(4)],'Color','white');
                            
                            if strcmpi(FileExt,'.png')
                                Option = '-dpng';
                            elseif strcmpi(FileExt,'.eps')
                                Option = '-depsc';
                            else
                                Option = '-dtiff';
                            end
                            print(hTempFig,Option,SaveFilePath)
                            
                            close(hTempFig)
                        end
                    end
            end
            
            % Update the display
            obj.updateVisualizationView();
            
        end %function
        
        function refresh(obj)
            
            %%% Update TempData
            if ~isempty(obj.Data)
                % Copy from Data into TempData, using obj.TempData as a
                % starting point
                obj.TempData = copy(obj.Data,obj.TempData);                
            end
            
        end %function
        
        function updateNameDescription(obj)
            
            %%% Edit View (Use TempData)
            % Name, Description
            if ~isempty(obj.TempData)
                set(obj.h.FileSelect(2),'String',obj.TempData.Name);
                set(obj.h.FileSelect(4),'String',obj.TempData.Description);
            else
                set(obj.h.FileSelect(2),'String','');
                set(obj.h.FileSelect(4),'String','');
            end
            
        end %function
        
        function update(obj)
            
            %%% Buttons
            % Toggle visibility
            set([obj.h.RunButton,obj.h.VisualizeButton],'Visible',uix.utility.tf2onoff(obj.UseRunVis));
            
            %%% Summary (Use Data)
            if ~isempty(obj.Data)
                set(obj.h.SummaryContent,'AllItems',getSummary(obj.Data));
            else
                set(obj.h.SummaryContent,'AllItems',cell(0,2));
            end
            
            %%% Edit View (Use TempData)
            updateNameDescription(obj)
            
            %%%% Plots
            if obj.UseRunVis
                MatchIndex = find(strcmp(obj.SelectedPlotLayout,obj.PlotLayoutOptions));
                set(obj.h.PlotConfigPopup,'String',obj.PlotLayoutOptions,'Value',MatchIndex);
                
                switch obj.SelectedPlotLayout
                    case '1x1'
                        obj.h.PlotGrid.Heights = [-1 zeros(1,obj.MaxNumPlots-1)];
                        obj.h.PlotGrid.Widths = -1;
                        set(obj.h.MainAxes(1),'Visible','on');
                        set(obj.h.MainAxes(2:end),'Visible','off');
                    case '1x2'
                        obj.h.PlotGrid.Heights = -1;
                        obj.h.PlotGrid.Widths = [-1 -1 zeros(1,obj.MaxNumPlots-2)];
                        set(obj.h.MainAxes(1:2),'Visible','on');
                        set(obj.h.MainAxes(3:end),'Visible','off');
                    case '2x1'
                        obj.h.PlotGrid.Heights = [-1 -1 zeros(1,obj.MaxNumPlots-2)];
                        obj.h.PlotGrid.Widths = -1;
                        set(obj.h.MainAxes(1:2),'Visible','on');
                        set(obj.h.MainAxes(3:end),'Visible','off');
                    case '2x2'
                        obj.h.PlotGrid.Heights = [-1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1 0 0 0 0];
                        set(obj.h.MainAxes(1:4),'Visible','on');
                        set(obj.h.MainAxes(5:end),'Visible','off');
                    case '3x2'
                        obj.h.PlotGrid.Heights = [-1 -1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1 0 0];
                        set(obj.h.MainAxes(1:6),'Visible','on');
                        set(obj.h.MainAxes(7:end),'Visible','off');
                    case '3x3'
                        obj.h.PlotGrid.Heights = [-1 -1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1 -1 0];
                        set(obj.h.MainAxes(1:9),'Visible','on');
                        set(obj.h.MainAxes(10:end),'Visible','off');
                    case '3x4'
                        obj.h.PlotGrid.Heights = [-1 -1 -1];
                        obj.h.PlotGrid.Widths = [-1 -1 -1 -1];
                        set(obj.h.MainAxes(1:end),'Visible','on');                        
                end
            end
            
        end %function
        
        function Value = getAxesOptions(obj)
            % Get axes options for dropdown
            
            Value = num2cell(1:obj.MaxNumPlots)';
            Value = cellfun(@(x)num2str(x),Value,'UniformOutput',false);
            Value = vertcat({' '},Value);
            
        end %function
        
    end
    
    methods
        
        function set.IsDeleted(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'})
            obj.IsDeleted = Value;
            if obj.IsDeleted
                set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','off');
                obj.Selection = 1; %#ok<MCSUP>
            else
                if obj.Selection == 2 %#ok<MCSUP>
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','off');                
                else
                    set([obj.h.SummaryButton,obj.h.EditButton,obj.h.RunButton,obj.h.VisualizeButton],'Enable','on');                
                end
            end
        end
        
        function set.Selection(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','>=',1,'<=',3});
            obj.Selection = Value;
            obj.h.CardPanel.Selection = Value;
        end
        
        function set.TempData(obj,Value)
            obj.TempData = Value;
            refresh(obj);
        end
    end
    
end % classdef
