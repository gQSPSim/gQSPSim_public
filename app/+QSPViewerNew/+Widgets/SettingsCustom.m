classdef SettingsCustom < QSPViewerNew.Widgets.ModalPopup
    % Custom dialog box to use instead of inputdlg used within uidlg;
    %----------------------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 6/9/20
    properties (Access = private)
        PanelQuest      matlab.ui.container.Panel
        PanelQuestGrid  matlab.ui.container.GridLayout
        PanelExit       matlab.ui.container.Panel
        ExitGrid        matlab.ui.container.GridLayout
        ExitButton      matlab.ui.control.Button
        SaveButton      matlab.ui.control.Button
        Parent
        SelectedPlot = [0,0,0,0,0];
        LabelTable      matlab.ui.control.Table
        BandTable       matlab.ui.control.Table
        FontTable       matlab.ui.control.Table 
        GridTable       matlab.ui.control.Table
        LineTable       matlab.ui.control.Table
        ContextMenu = {};
        Menu = {};
        Settings
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = SettingsCustom(Parentfigure,PlotSettings)  
            obj.create(Parentfigure,PlotSettings);
        end
        
        function delete(obj)
            delete(obj.PanelQuest);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function create(obj,Parentfigure,PlotSettings) 
            obj.Parent = Parentfigure;
            obj.PanelQuest = uipanel(Parentfigure);
            obj.PanelQuest.Position = [Parentfigure.Position(3)*.05,Parentfigure.Position(4)*.05,Parentfigure.Position(3)*.9,Parentfigure.Position(4)*.9];
            obj.PanelQuest.Scrollable = true;
            drawnow limitrate
            
            %Create Button 
            obj.PanelQuestGrid = uigridlayout(obj.PanelQuest);
            obj.PanelQuestGrid.ColumnWidth = {'1x','1x'};
            obj.PanelQuestGrid.RowHeight = {50,'1x','1x','1x','1x'};
            
            obj.PanelExit = uipanel(obj.PanelQuestGrid);
            obj.PanelExit.Layout.Row = 1;
            obj.PanelExit.Layout.Column = [1,2];
            obj.PanelExit.BackgroundColor = [.9,.9,.9];

            obj.ExitGrid = uigridlayout(obj.PanelExit);
            obj.ExitGrid.ColumnWidth = {'1x',50,50};
            obj.ExitGrid.RowHeight = {'1x'};

            %Yes Button
            obj.ExitButton= uibutton(obj.ExitGrid);
            obj.ExitButton.Layout.Row = 1;
            obj.ExitButton.Layout.Column = 3;
            obj.ExitButton.Text = 'Exit';
            obj.ExitButton.Tag = 'Exit';
            obj.ExitButton.ButtonPushedFcn = @obj.onExitButton;
            
            %Yes Button
            obj.SaveButton= uibutton(obj.ExitGrid);
            obj.SaveButton.Layout.Row = 1;
            obj.SaveButton.Layout.Column = 2;
            obj.SaveButton.Text = 'OK';
            obj.SaveButton.Tag = 'OK';
            obj.SaveButton.ButtonPushedFcn = @obj.onExitButton;
            
            %Create the 5 tables
            
            obj.LabelTable = uitable(obj.PanelQuestGrid);
            obj.LabelTable.Layout.Row = 2;
            obj.LabelTable.Layout.Column = 1;
            obj.LabelTable.CellEditCallback = @obj.onTableEdit;
            obj.LabelTable.CellSelectionCallback = @obj.onTableSelection;
            obj.LabelTable.Tag = 'Label';
            
            obj.BandTable = uitable(obj.PanelQuestGrid);
            obj.BandTable.Layout.Row = 2;
            obj.BandTable.Layout.Column = 2;
            obj.BandTable.CellEditCallback = @obj.onTableEdit;
            obj.BandTable.CellSelectionCallback = @obj.onTableSelection;
            obj.BandTable.Tag = 'Band';
            
            obj.FontTable = uitable(obj.PanelQuestGrid);
            obj.FontTable.Layout.Row = 3;
            obj.FontTable.Layout.Column = [1,2];
            obj.FontTable.CellEditCallback = @obj.onTableEdit;
            obj.FontTable.CellSelectionCallback = @obj.onTableSelection;
            obj.FontTable.Tag = 'Font';
            
            obj.GridTable = uitable(obj.PanelQuestGrid);
            obj.GridTable.Layout.Row = 4;
            obj.GridTable.Layout.Column = [1,2];
            obj.GridTable.CellEditCallback = @obj.onTableEdit;
            obj.GridTable.CellSelectionCallback = @obj.onTableSelection;
            obj.GridTable.Tag = 'Grid';
            
            obj.LineTable = uitable(obj.PanelQuestGrid);
            obj.LineTable.Layout.Row = 5;
            obj.LineTable.Layout.Column = [1,2];
            obj.LineTable.CellEditCallback = @obj.onTableEdit;
            obj.LineTable.CellSelectionCallback = @obj.onTableSelection;
            obj.LineTable.Tag = 'Line';

            %Set Context Menus;
            obj.ContextMenu{1} = uicontextmenu(Parentfigure);
            obj.Menu{1} = uimenu(obj.ContextMenu{1});
            obj.Menu{1}.Label = 'ApplyToAllPlots';
            obj.Menu{1}.Tag = 'Label';
            obj.Menu{1}.MenuSelectedFcn = @obj.onContextMenu;
            
            obj.ContextMenu{2} = uicontextmenu(Parentfigure);
            obj.Menu{2} = uimenu(obj.ContextMenu{2});
            obj.Menu{2}.Label = 'ApplyToAllPlots';
            obj.Menu{2}.Tag = 'Band';
            obj.Menu{2}.MenuSelectedFcn = @obj.onContextMenu;
            
            obj.ContextMenu{3} = uicontextmenu(Parentfigure);
            obj.Menu{3} = uimenu(obj.ContextMenu{3});
            obj.Menu{3}.Label = 'ApplyToAllPlots';
            obj.Menu{3}.Tag = 'Font';
            obj.Menu{3}.MenuSelectedFcn = @obj.onContextMenu;
            
            obj.ContextMenu{4}= uicontextmenu(Parentfigure);
            obj.Menu{4} = uimenu(obj.ContextMenu{4});
            obj.Menu{4}.Label = 'ApplyToAllPlots';
            obj.Menu{4}.Tag = 'Grid';
            obj.Menu{4}.MenuSelectedFcn = @obj.onContextMenu;
            
            obj.ContextMenu{5} = uicontextmenu(Parentfigure);
            obj.Menu{5} = uimenu(obj.ContextMenu{5});
            obj.Menu{5}.Label = 'ApplyToAllPlots';
            obj.Menu{5}.Tag = 'Line';
            obj.Menu{5}.MenuSelectedFcn = @obj.onContextMenu;
            
            obj.LabelTable.ContextMenu = obj.ContextMenu{1};
            obj.BandTable.ContextMenu = obj.ContextMenu{2};
            obj.FontTable.ContextMenu = obj.ContextMenu{3};
            obj.GridTable.ContextMenu = obj.ContextMenu{4};
            obj.LineTable.ContextMenu = obj.ContextMenu{5};
                   
            %Finally, fill in the table
            obj.setSettings(PlotSettings);
            
        end
        
        function onExitButton(obj,h,~)
            obj.ButtonPressed = h.Tag;
        end
        
        function setSettings(obj,PlotSettings)
            obj.Settings = PlotSettings;
            %This code is take from
            %\gqspsim_ui\app\utilities\CustomizePlots and adapted for the
            %new UI
            PropertyGroup = {...
                'SettablePropertiesGroup1',...
                'SettablePropertiesGroup2',...
                'SettablePropertiesGroup3',...
                'SettablePropertiesGroup4',...
                'SettablePropertiesGroup5',...
                };
            
            Tables = [obj.LabelTable, obj.BandTable, obj.FontTable, obj.GridTable, obj.LineTable];
            
            if ~isempty(PlotSettings)
                for pIndex = 1:numel(PropertyGroup)
                    Summary = {};
                    for index = 1:numel(PlotSettings)
                        ThisSummary = struct2cell(PlotSettings(index).getSummary(PropertyGroup{pIndex}));
                        ThisSummary = ThisSummary(:)';
                        %On/Off switch staes not allowed in a table
                        for idx = 1:numel(ThisSummary)
                            if isa(ThisSummary{idx},'matlab.lang.OnOffSwitchState')
                                ThisSummary{idx} = char(ThisSummary{idx});
                            end
                        end
                        
                        Summary = [Summary; ThisSummary]; %#ok<AGROW>
                    end
                    Fields = PlotSettings(1).(PropertyGroup{pIndex})(:,1);
                    ColumnFormat = PlotSettings(1).(PropertyGroup{pIndex})(:,2);
                    RowNames = cellfun(@(x)sprintf('Plot %d',x),num2cell(1:numel(PlotSettings)),'UniformOutput',false);
                    
                    % Set table
                    set(Tables(pIndex),...
                        'RowName',RowNames(:),...
                        'ColumnName',Fields,...
                        'ColumnEditable',true(1,numel(Fields)),...
                        'ColumnFormat',ColumnFormat(:)',...
                        'Data',Summary);
                end
            else
                Fields = {};
                Summary = {};
                ColumnFormat = {};
                RowNames = {};
                
                for pIndex = 1:numel(PropertyGroup)
                    % Set table
                    set(Tables(pIndex),...
                        'RowName',RowNames,...
                        'ColumnName',Fields,...
                        'ColumnEditable',true(1,numel(Fields)),...
                        'ColumnFormat',ColumnFormat(:)',...
                        'Data',Summary);
                end
            end
        end
        
        function [Settings] = getSettings(obj)
            Settings = obj.Settings;
        end
        
        function onTableEdit(obj,h,e)
            %Assume we are going to update the settings
            update = true;
            if iscell(h.ColumnFormat{e.Indices(2)}) && ~any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                update = false;
            elseif strcmpi(h.Tag,'Font') && e.Indices(2) == 8 || e.Indices(2) == 9
                %These values are limits and need to be check
                ValArray = split(e.NewData);
                
                %Check there are 2 entries
                if length(ValArray) == 2
                    Val1 = str2double(ValArray(1));
                    Val2 = str2double(ValArray(2));
                    
                    %Check that each entry is a number and 1<2
                    if isnan(Val1) || isnan(Val2) || Val1 >= Val2
                        h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                        update = false;
                    end
                else
                    h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
                    update = false;
                end
            end
            
            %If there was no issues, update
            if update
                Row = e.Indices(1);
                Col = e.Indices(2);
                obj.Settings(Row).(h.ColumnName{Col}) = e.NewData;
            end
            
        end
        
        function onTableSelection(obj,h,e)
            switch h.Tag
                case 'Label'
                    obj.SelectedPlot(1) = e.Indices(1);
                case'Band'
                    obj.SelectedPlot(2) = e.Indices(1);
                case'Font'
                    obj.SelectedPlot(3) = e.Indices(1);
                case'Grid'
                    obj.SelectedPlot(4) = e.Indices(1);
                case'Line'
                    obj.SelectedPlot(5) = e.Indices(1);
            end
        end
        
        function onContextMenu(obj,h,~)
            
            switch h.Tag
                case 'Label'
                    if obj.SelectedPlot(1)~=0
                        DuplicateRow = obj.LabelTable.Data(obj.SelectedPlot(1),:);
                        Table = obj.LabelTable;
                    else
                        DuplicateRow = [];
                        Table = [];
                    end
                case'Band'
                    if obj.SelectedPlot(2)~=0
                        DuplicateRow = obj.BandTable.Data(obj.SelectedPlot(2),:);
                        Table = obj.BandTable;
                    else
                        DuplicateRow = [];
                        Table = [];
                    end
                case'Font'
                    if obj.SelectedPlot(3)~=0
                        DuplicateRow = obj.FontTable.Data(obj.SelectedPlot(3),:);
                        Table = obj.FontTable;
                    else
                        DuplicateRow = [];
                        Table = [];
                    end
                case'Grid'
                    if obj.SelectedPlot(4)~=0
                        DuplicateRow = obj.GridTable.Data(obj.SelectedPlot(4),:);
                        Table = obj.GridTable;
                    else
                        DuplicateRow = [];
                        Table = [];
                    end
                case'Line'
                    if obj.SelectedPlot(5)~=0
                        DuplicateRow = obj.LineTable.Data(obj.SelectedPlot(5),:);
                        Table = obj.LineTable;
                    else
                        DuplicateRow = [];
                        Table = [];
                    end
            end
            
            if ~isempty(DuplicateRow)
                Data= Table.Data;
                [rows,~] = size(Table.Data);
                for idx = 1:rows
                    Data(idx,:) = DuplicateRow;
                end
                Table.Data = Data;
            end
        end

    end

    methods(Access = public)
    
        function [varargout] = wait(obj)
            obj.turnModalOn(obj.Parent);
            obj.ExitButton.Enable = 'on';
            waitfor(obj,'ButtonPressed');
            obj.turnModalOff();
            if strcmpi(obj.ButtonPressed,'Exit')
                varargout{1} = false;
                varargout{2} = [];
            else
                varargout{1} = true;
                varargout{2} = obj.Settings;
            end
        end
        
        function value = getPlotGrid(obj)
            value = obj.PanelQuestGrid();
        end
        
        function value = getWidth(obj)
            value = obj.numWidth;
        end
    end
end

