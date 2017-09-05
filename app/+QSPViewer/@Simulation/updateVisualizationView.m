function updateVisualizationView(vObj)
% updateVisualizationView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateVisualizationView(vObj)
%
% Inputs:
%           vObj - The MyPackageViewer.Empty vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2014-2015 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
% ---------------------------------------------------------------------


%% Update table contextmenus

hFigure = ancestor(vObj.UIContainer,'figure');
% Create context menu
vObj.h.PlotItemsTableContextMenu = uicontextmenu('Parent',hFigure);
uimenu(vObj.h.PlotItemsTableContextMenu,...
    'Label','Set Color...',...
    'Tag','ItemsColor',...
    'Callback',@(h,e)onPlotItemsTableContextMenu(vObj,h,e));
set(vObj.h.PlotItemsTable,'TableContextMenu',vObj.h.PlotItemsTableContextMenu);

% Create context menu
vObj.h.PlotGroupTableContextMenu = uicontextmenu('Parent',hFigure);
uimenu(vObj.h.PlotGroupTableContextMenu,...
    'Label','Set Color...',...
    'Tag','ItemsColor',...
    'Callback',@(h,e)onPlotGroupTableContextMenu(vObj,h,e));
set(vObj.h.PlotGroupTable,'TableContextMenu',vObj.h.PlotGroupTableContextMenu);


%% Get Axes Options for Plot column

AxesOptions = getAxesOptions(vObj);


%% Refresh Species

% List only SpeciesNames from Valid Sim Items, not all Tasks
if ~isempty(vObj.Data)
    
    ItemTaskNames = {vObj.Data.Item.TaskName};
    SpeciesNames = getSpeciesFromValidSelectedTasks(vObj.Data.Settings,ItemTaskNames);
    
    if isempty(vObj.Data.PlotSpeciesTable)
        % If empty, populate, but first update line styles
        vObj.Data.PlotSpeciesTable = cell(numel(SpeciesNames),3);
        updateSpeciesLineStyles(vObj.Data);
        
        vObj.Data.PlotSpeciesTable(:,1) = {' '};
        vObj.Data.PlotSpeciesTable(:,2) = vObj.Data.SpeciesLineStyles(:);
        vObj.Data.PlotSpeciesTable(:,3) = SpeciesNames;
        
        vObj.PlotSpeciesAsInvalidTable = vObj.Data.PlotSpeciesTable;
        vObj.PlotSpeciesInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(SpeciesNames),3);
        NewPlotTable(:,1) = {' '};
        NewPlotTable(:,2) = {'-'}; % vObj.Data.SpeciesLineStyles(:); % TODO: !!
        NewPlotTable(:,3) = SpeciesNames;
        
        % Adjust size if from an old saved session
        if size(vObj.Data.PlotSpeciesTable,2) == 2
            vObj.Data.PlotSpeciesTable(:,3) = vObj.Data.PlotSpeciesTable(:,2);
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};  % TODO: !!
        end
        % Update Table
        [vObj.Data.PlotSpeciesTable,vObj.PlotSpeciesAsInvalidTable,vObj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotSpeciesTable,NewPlotTable,3);
        % Update line styles
        updateSpeciesLineStyles(vObj.Data);
    end
    
    % Species table
    set(vObj.h.PlotSpeciesTable,...
        'Data',vObj.PlotSpeciesAsInvalidTable,...
        'ColumnName',{'Plot','Style','Name'},...
        'ColumnFormat',{AxesOptions,vObj.Data.Settings.LineStyleMap,'char'},...
        'ColumnEditable',[true,true,false]...
        );
else
    set(vObj.h.PlotSpeciesTable,...
        'Data',cell(0,3),...
        'ColumnName',{'Plot','Style','Name'},...
        'ColumnFormat',{AxesOptions,'char','char'},...
        'ColumnEditable',[true,true,false]...
        );
end


%% Refresh Items

if ~isempty(vObj.Data)
    TaskNames = {vObj.Data.Item.TaskName};
    VPopNames = {vObj.Data.Item.VPopName};
    
    RemoveIndices = false(size(TaskNames));
    for idx = 1:numel(TaskNames)
        % Check if the task is valid
        ThisTask = getValidSelectedTasks(vObj.Data.Settings,TaskNames{idx});
        ThisVPop = getValidSelectedVPops(vObj.Data.Settings,VPopNames{idx});
        if isempty(ThisTask) || isempty(ThisVPop)
            RemoveIndices(idx) = true;
        end
    end
    
    if any(RemoveIndices)
        % Then, prune
        TaskNames(RemoveIndices) = [];
        VPopNames(RemoveIndices) = [];
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotItemTable)
        vObj.Data.PlotItemTable = cell(numel(TaskNames),4);
        vObj.Data.PlotItemTable(:,1) = {false};
        vObj.Data.PlotItemTable(:,3) = TaskNames;
        vObj.Data.PlotItemTable(:,4) = VPopNames;
        
        % Update the item colors
        ItemColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        vObj.Data.PlotItemTable(:,2) = num2cell(ItemColors,2);
        
        vObj.PlotItemAsInvalidTable = vObj.Data.PlotItemTable;
        vObj.PlotItemInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(TaskNames),4);
        NewPlotTable(:,1) = {false};
        NewPlotTable(:,3) = TaskNames;
        NewPlotTable(:,4) = VPopNames;
        
        NewColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        NewPlotTable(:,2) = num2cell(NewColors,2);   
        
        % Update Table
        [vObj.Data.PlotItemTable,vObj.PlotItemAsInvalidTable,vObj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotItemTable,NewPlotTable,[3 4]);
    end
    
    % Check which results files are invalid
    ResultsDir = fullfile(vObj.Data.Session.RootDirectory,vObj.Data.SimResultsFolderName);
    IsInvalidResultFile = find(cellfun(@(X) ~isequal(exist(fullfile(ResultsDir,X),'file'),2), {vObj.Data.Item.MATFileName}));
    
    % Only make the "valids" missing. Leave the invalids as is
    TableData = vObj.PlotItemAsInvalidTable;
    MissingIdx = setdiff(IsInvalidResultFile(:),vObj.PlotItemInvalidRowIndices(:));
    for index = MissingIdx(:)'
        TableData{index,3} = QSP.makeMissing(TableData{index,3});
        TableData{index,4} = QSP.makeMissing(TableData{index,4});
    end
    
    % Update Colors column
    TableData(:,2) = uix.utility.getHTMLColor(vObj.Data.PlotItemTable(:,2));
    % Items table
    set(vObj.h.PlotItemsTable,...
        'Data',TableData,...
        'ColumnName',{'Include','Color','Task','Virtual Population'},...
        'ColumnFormat',{'boolean','char','char','char'},...
        'ColumnEditable',[true,false,false,false]...
        );
    % Set cell color
    for index = 1:size(TableData,1)
        ThisColor = vObj.Data.PlotItemTable{index,2};
        if ~isempty(ThisColor)
            vObj.h.PlotItemsTable.setCellColor(index,2,ThisColor);
        end
    end
else
    % Items table
    set(vObj.h.PlotItemsTable,...
        'Data',cell(0,4),...
        'ColumnName',{'Include','Color','Task','Virtual Population'},...
        'ColumnFormat',{'boolean','char','char','char'},...
        'ColumnEditable',[true,false,false,false]...
        );
end


%% Refresh DataCol

OptimHeader = {};
OptimData = {};

% DatasetHeaderPopupItems corresponds to header in DatasetName
if ~isempty(vObj.Data) && ~isempty(vObj.Data.DatasetName)
    Names = {vObj.Data.Settings.OptimizationData.Name};
    MatchIdx = strcmpi(Names,vObj.Data.DatasetName);
    
    if any(MatchIdx)
        dObj = vObj.Data.Settings.OptimizationData(MatchIdx);
        
        DestDatasetType = 'wide';
        [StatusOk,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
        if StatusOk
            % Prune to remove Time, Group, etc.
            DatasetHeaderPopupItems = setdiff(OptimHeader,{'Time','Group'});
        else
            DatasetHeaderPopupItems = {};
        end
    else
        DatasetHeaderPopupItems = {};
    end
    
    % Adjust size if from an old saved session
    if size(vObj.Data.PlotDataTable,2) == 2
        vObj.Data.PlotDataTable(:,3) = vObj.Data.PlotDataTable(:,2);
        vObj.Data.PlotDataTable(:,2) = {'*'};  % TODO: !!
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotDataTable)
        vObj.Data.PlotDataTable = cell(numel(DatasetHeaderPopupItems),2);
        vObj.Data.PlotDataTable(:,1) = {' '};
        vObj.Data.PlotDataTable(:,2) = {'*'}; % TODO: !!
        vObj.Data.PlotDataTable(:,3) = DatasetHeaderPopupItems;
        
        vObj.PlotDataAsInvalidTable = vObj.Data.PlotDataTable;
        vObj.PlotDataInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(DatasetHeaderPopupItems),2);
        NewPlotTable(:,1) = {' '};
        NewPlotTable(:,2) = {'*'}; % TODO: !!
        NewPlotTable(:,3) = DatasetHeaderPopupItems;
        
        % Update Table
        [vObj.Data.PlotDataTable,vObj.PlotDataAsInvalidTable,vObj.PlotDataInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotDataTable,NewPlotTable,3);
    end
    
    % Dataset table
    set(vObj.h.PlotDatasetTable,...
        'Data',vObj.PlotDataAsInvalidTable,...
        'ColumnName',{'Plot','Marker','Name'},...
        'ColumnFormat',{AxesOptions,vObj.Data.Settings.LineMarkerMap,'char'},...
        'ColumnEditable',[true,true,false]...
        );
else
    % Dataset table
    set(vObj.h.PlotDatasetTable,...
        'Data',cell(0,3),...
        'ColumnName',{'Plot','Marker','Name'},...
        'ColumnFormat',{AxesOptions,'char','char'},...
        'ColumnEditable',[true,true,false]...
        );
end


%% Refresh GroupID

if ~isempty(vObj.Data) && ~isempty(OptimData)
    MatchIdx = strcmp(OptimHeader,vObj.Data.GroupName);
    GroupIDs = OptimData(:,MatchIdx);
    if iscell(GroupIDs)
        GroupIDs = cell2mat(GroupIDs);
    end
    GroupIDs = unique(GroupIDs);
    GroupIDNames = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
    
    % If empty, populate
    if isempty(vObj.Data.PlotGroupTable)
        vObj.Data.PlotGroupTable = cell(numel(GroupIDNames),3);
        vObj.Data.PlotGroupTable(:,1) = {false};
        vObj.Data.PlotGroupTable(:,3) = GroupIDNames;
        
        % Update the group colors
        GroupColors = getGroupColors(vObj.Data.Session,numel(GroupIDNames));
        vObj.Data.PlotGroupTable(:,2) = num2cell(GroupColors,2);
        
        vObj.PlotGroupAsInvalidTable = vObj.Data.PlotGroupTable;
        vObj.PlotGroupInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(GroupIDNames),3);
        NewPlotTable(:,1) = {false};
        NewPlotTable(:,3) = GroupIDNames;
        
        NewColors = getGroupColors(vObj.Data.Session,numel(GroupIDNames));
        NewPlotTable(:,2) = num2cell(NewColors,2);   
        
        % Update Table
        [vObj.Data.PlotGroupTable,vObj.PlotGroupAsInvalidTable,vObj.PlotGroupInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotGroupTable,NewPlotTable,3);
        
    end
    
    % Update Colors column
    TableData = vObj.PlotGroupAsInvalidTable;
    TableData(:,2) = uix.utility.getHTMLColor(vObj.PlotGroupAsInvalidTable(:,2));
    % Group table
    set(vObj.h.PlotGroupTable,...
        'Data',TableData,...
        'ColumnName',{'Include','Color','Name'},...
        'ColumnFormat',{'boolean','char','char'},...
        'ColumnEditable',[true,false,false]...
        );
    % Set cell color
    for index = 1:size(TableData,1)
        ThisColor = vObj.Data.PlotGroupTable{index,2};
        if ~isempty(ThisColor)
            vObj.h.PlotGroupTable.setCellColor(index,2,ThisColor);
        end
    end
    
else
    % Group table
    set(vObj.h.PlotGroupTable,...
        'Data',cell(0,3),...
        'ColumnName',{'Include','Color','Name'},...
        'ColumnFormat',{'boolean','char','char'},...
        'ColumnEditable',[true,false,false]...
        );
end




