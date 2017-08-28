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


%% Update table contextmenu

hFigure = ancestor(vObj.UIContainer,'figure');
% Create context menu
vObj.h.PlotItemsTableContextMenu = uicontextmenu('Parent',hFigure);    
uimenu(vObj.h.PlotItemsTableContextMenu,...
    'Label','Set Color...',...
    'Tag','ItemsColor',...
    'Callback',@(h,e)onPlotItemsTableContextMenu(vObj,h,e));    
set(vObj.h.PlotItemsTable,'TableContextMenu',vObj.h.PlotItemsTableContextMenu);


%% Get Axes Options for Plot column

AxesOptions = getAxesOptions(vObj);


%% Re-import VirtualPopulationData

if ~isempty(vObj.Data) && ~isempty(vObj.Data.DatasetName) && ~isempty(vObj.Data.Settings.VirtualPopulationData)
    Names = {vObj.Data.Settings.VirtualPopulationData.Name};
    MatchIdx = strcmpi(Names,vObj.Data.DatasetName);
    
    if any(MatchIdx)
        vpopObj = vObj.Data.Settings.VirtualPopulationData(MatchIdx);
        
        [~,~,VpopHeader,VpopData] = importData(vpopObj,vpopObj.FilePath);
    else
        VpopHeader = {};
        VpopData = {};
    end
else
    VpopHeader = {};
    VpopData = {};
end

% Get unique values from Data Column
MatchIdx = strcmpi(VpopHeader,'Data');
if any(MatchIdx)
    UniqueDataVals = unique(VpopData(:,MatchIdx));
else
    UniqueDataVals = {};
end

% Get the group column
% GroupID
if ~isempty(VpopHeader) && ~isempty(VpopData)
    MatchIdx = strcmp(VpopHeader,vObj.Data.GroupName);
    GroupIDs = VpopData(:,MatchIdx);
    if iscell(GroupIDs)
        GroupIDs = cell2mat(GroupIDs);
    end
    GroupIDs = unique(GroupIDs);
    GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
else
    GroupIDs = {};
end


%% Plot Type

if ~isempty(vObj.Data)
    if strcmpi(vObj.Data.PlotType,'Normal')
        set(vObj.h.PlotTypeRadioButtonGroup,'SelectedObject',vObj.h.NormalPlotTypeRadioButton);
    else
        set(vObj.h.PlotTypeRadioButtonGroup,'SelectedObject',vObj.h.DiagnosticPlotTypeRadioButton);
    end
end


%% Refresh Items

if ~isempty(vObj.Data)
    
    % Get the raw TaskNames, GroupIDNames
    TaskNames = {vObj.Data.Item.TaskName};
    GroupIDNames = {vObj.Data.Item.GroupID};
    
    RemoveIndices = false(size(TaskNames));
    for idx = 1:numel(TaskNames)
        % Check if the task is valid
        ThisTask = getValidSelectedTasks(vObj.Data.Settings,TaskNames{idx});
        MissingGroup = ~ismember(GroupIDNames{idx},GroupIDs(:)');
        if isempty(ThisTask) || MissingGroup
            RemoveIndices(idx) = true;
        end
    end
   
    if any(RemoveIndices)
        % Then, prune
        TaskNames(RemoveIndices) = [];
        GroupIDNames(RemoveIndices) = [];
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotItemTable)
        vObj.Data.PlotItemTable = cell(numel(TaskNames),4);
        vObj.Data.PlotItemTable(:,1) = {false};
        vObj.Data.PlotItemTable(:,3) = TaskNames;
        vObj.Data.PlotItemTable(:,4) = GroupIDNames;
        
        % Update the item colors
        ItemColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        vObj.Data.PlotItemTable(:,2) = num2cell(ItemColors,2);
        
        vObj.PlotItemAsInvalidTable = vObj.Data.PlotItemTable;
        vObj.PlotItemInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(TaskNames),4);
        NewPlotTable(:,1) = {false};
        NewPlotTable(:,3) = TaskNames;
        NewPlotTable(:,4) = GroupIDNames;
        
        NewColors = getItemColors(vObj.Data.Session,numel(TaskNames));
        NewPlotTable(:,2) = num2cell(NewColors,2);   
        
        % Update Table
        [vObj.Data.PlotItemTable,vObj.PlotItemAsInvalidTable,vObj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotItemTable,NewPlotTable,[3 4]);
    end
    
    % Check which results files are invalid
    ResultsDir = fullfile(vObj.Data.Session.RootDirectory,vObj.Data.VPopResultsFolderName);
    if exist(fullfile(ResultsDir,vObj.Data.ExcelResultFileName),'file') == 2
        IsInvalidResultFile = [];
    else
        IsInvalidResultFile = 1:size(vObj.PlotItemAsInvalidTable,1);
    end
    
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
        'ColumnName',{'Include','Color','Task','Group'},...
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
        'ColumnName',{'Include','Color','Task','Group'},...
        'ColumnFormat',{'boolean','char','char','char'},...
        'ColumnEditable',[true,false,false,false]...
        );
end


%% Refresh Species-Data

if ~isempty(vObj.Data)
    % Get the raw SpeciesNames, DataNames
    TaskNames = {vObj.Data.Item.TaskName};
    SpeciesNames = {vObj.Data.SpeciesData.SpeciesName};
    DataNames = {vObj.Data.SpeciesData.DataName};
    
    % Get the list of all active species from all valid selected tasks
    ValidSpeciesList = getSpeciesFromValidSelectedTasks(vObj.Data.Settings,TaskNames);
    
    RemoveIndices = false(size(SpeciesNames));
    for idx = 1:numel(SpeciesNames)
        % Check if the species is missing
        MissingSpecies = ~ismember(SpeciesNames{idx},ValidSpeciesList);        
        MissingData = ~ismember(DataNames{idx},UniqueDataVals);
        if MissingSpecies || MissingData
            RemoveIndices(idx) = true;
        end
    end
    
    if any(RemoveIndices)
        % Then, prune
        SpeciesNames(RemoveIndices) = [];
        DataNames(RemoveIndices) = [];
    end
    
    % If empty, populate, but first update line styles
    updateSpeciesLineStyles(vObj.Data);
    if isempty(vObj.Data.PlotSpeciesTable)
        vObj.Data.PlotSpeciesTable = cell(numel(SpeciesNames),3);
        vObj.Data.PlotSpeciesTable(:,1) = {' '};
        vObj.Data.PlotSpeciesTable(:,2) = vObj.Data.SpeciesLineStyles(:);
        vObj.Data.PlotSpeciesTable(:,3) = SpeciesNames;
        vObj.Data.PlotSpeciesTable(:,4) = DataNames;
        
        vObj.PlotSpeciesAsInvalidTable = vObj.Data.PlotSpeciesTable;
        vObj.PlotSpeciesInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(SpeciesNames),3);
        NewPlotTable(:,1) = {' '};
        NewPlotTable(:,2) = {'-'}; % vObj.Data.SpeciesLineStyles(:); % TODO: !!
        NewPlotTable(:,3) = SpeciesNames;
        NewPlotTable(:,4) = DataNames;
        
        % Adjust size if from an old saved session
        if size(vObj.Data.PlotSpeciesTable,2) == 3
            vObj.Data.PlotSpeciesTable(:,4) = vObj.Data.PlotSpeciesTable(:,3);
            vObj.Data.PlotSpeciesTable(:,3) = vObj.Data.PlotSpeciesTable(:,2);
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};  % TODO: !!
        end
         % Update Table
        [vObj.Data.PlotSpeciesTable,vObj.PlotSpeciesAsInvalidTable,vObj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotSpeciesTable,NewPlotTable,[3 4]);   
    end

     % Species table
    set(vObj.h.PlotSpeciesTable,...
        'Data',vObj.PlotSpeciesAsInvalidTable,...
        'ColumnName',{'Plot','Style','Species','Data'},...
        'ColumnFormat',{AxesOptions,vObj.Data.Settings.LineStyleMap,'char','char'},...
        'ColumnEditable',[true,true,false,false]...
        );    
else
    set(vObj.h.PlotSpeciesTable,...
        'Data',cell(0,4),...
        'ColumnName',{'Plot','Style','Species','Data'},...
        'ColumnFormat',{AxesOptions,'char','char','char'},...
        'ColumnEditable',[true,true,false,false]...
        );
end





