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


%% Re-import OptimizationData

if ~isempty(vObj.Data) && ~isempty(vObj.Data.DatasetName) && ~isempty(vObj.Data.Settings.OptimizationData)
    Names = {vObj.Data.Settings.OptimizationData.Name};
    MatchIdx = strcmpi(Names,vObj.Data.DatasetName);
    
    if any(MatchIdx)
        dObj = vObj.Data.Settings.OptimizationData(MatchIdx);
        
        DestDatasetType = 'wide';
        [~,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
    else
        OptimHeader = {};
        OptimData = {};
    end
else
    OptimHeader = {};
    OptimData = {};
end


% Get the group column
% GroupID
if ~isempty(OptimHeader) && ~isempty(OptimData)
    MatchIdx = strcmp(OptimHeader,vObj.Data.GroupName);
    GroupIDs = OptimData(:,MatchIdx);
    if iscell(GroupIDs)
        GroupIDs = cell2mat(GroupIDs);
    end
    GroupIDs = unique(GroupIDs);
    GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
else
    GroupIDs = {};
end


%% Refresh Items

if ~isempty(vObj.Data)
    
    % Get the raw TaskNames, GroupIDNames
    TaskNames = {vObj.Data.Item.TaskName};
    GroupIDNames = {vObj.Data.Item.GroupID};
    
    InvalidIndices = false(size(TaskNames));
    for idx = 1:numel(TaskNames)
        % Check if the task is valid
        ThisTask = getValidSelectedTasks(vObj.Data.Settings,TaskNames{idx});
        MissingGroup = ~ismember(GroupIDNames{idx},GroupIDs(:)');
        if isempty(ThisTask) || MissingGroup
            InvalidIndices(idx) = true;
        end
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotItemTable)
        
        if any(InvalidIndices)
            % Then, prune
            TaskNames(InvalidIndices) = [];
            GroupIDNames(InvalidIndices) = [];
        end
        
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
        KeyColumn = [3 4];
        [vObj.Data.PlotItemTable,vObj.PlotItemAsInvalidTable,vObj.PlotItemInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotItemTable,NewPlotTable,InvalidIndices,KeyColumn);        
    end

    % Update Colors column 
    TableData = vObj.PlotItemAsInvalidTable;
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
    
    InvalidIndices = false(size(SpeciesNames));
    for idx = 1:numel(SpeciesNames)
        % Check if the species is missing
        MissingSpecies = ~ismember(SpeciesNames{idx},ValidSpeciesList);        
        MissingData = ~ismember(DataNames{idx},OptimHeader);
        if MissingSpecies || MissingData
            InvalidIndices(idx) = true;
        end
    end
    
    % If empty, populate
    if isempty(vObj.Data.PlotSpeciesTable)
        
        if any(InvalidIndices)
            % Then, prune
            SpeciesNames(InvalidIndices) = [];
            DataNames(InvalidIndices) = [];
        end
        
        % If empty, populate, but first update line styles
        vObj.Data.PlotSpeciesTable = cell(numel(SpeciesNames),4);
        
        vObj.Data.PlotSpeciesTable(:,1) = {' '};
        vObj.Data.PlotSpeciesTable(:,2) = vObj.Data.SpeciesLineStyles(:);
        vObj.Data.PlotSpeciesTable(:,3) = SpeciesNames;
        vObj.Data.PlotSpeciesTable(:,4) = DataNames;
        
        vObj.PlotSpeciesAsInvalidTable = vObj.Data.PlotSpeciesTable;
        vObj.PlotSpeciesInvalidRowIndices = [];
    else
        NewPlotTable = cell(numel(SpeciesNames),4);
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
        KeyColumn = [3 4];
        [vObj.Data.PlotSpeciesTable,vObj.PlotSpeciesAsInvalidTable,vObj.PlotSpeciesInvalidRowIndices] = QSPViewer.updateVisualizationTable(vObj.Data.PlotSpeciesTable,NewPlotTable,InvalidIndices,KeyColumn);                     
        % Update line styles
        updateSpeciesLineStyles(vObj.Data);
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


%% Refresh Parameters

% Update PlotParametersSourceOptions
if ~isempty(vObj.Data)
    Names = {vObj.Data.Settings.Parameters.Name};
    MatchIdx = strcmpi(Names,vObj.Data.RefParamName);
    
    VPopNames = {};
    for idx = 1:numel(vObj.Data.ExcelResultFileName)
        [~,VPopNames{idx}] = fileparts(vObj.Data.ExcelResultFileName{idx}); %#ok<AGROW>
    end
    
    % Filter VPopNames list (only if name does not exist, not if invalid)
    AllVPopNames = {vObj.Data.Session.Settings.VirtualPopulation.Name};
    VPopNames = VPopNames(ismember(VPopNames,AllVPopNames));
    
    if any(MatchIdx)
        pObj = vObj.Data.Settings.Parameters(MatchIdx);        
        vObj.Data.PlotParametersSourceOptions = vertcat({pObj.Name},VPopNames(:));
    else
        vObj.Data.PlotParametersSourceOptions = VPopNames;
    end
    
    % Source
    MatchIdx = find(strcmpi(vObj.Data.PlotParametersSource,vObj.Data.PlotParametersSourceOptions));
    
    if isempty(MatchIdx) && ~isempty(vObj.Data.PlotParametersSourceOptions)
        MatchIdx = 1;
        vObj.Data.PlotParametersSource = vObj.Data.PlotParametersSourceOptions{1};
        % Re-import
        [StatusOk,Message] = importParametersSource(vObj.Data,vObj.Data.PlotParametersSource);                
    end
    
    if isempty(vObj.Data.PlotParametersSourceOptions)
        vObj.Data.PlotParametersSourceOptions = {
            'N/A'
            };
    end
    
    if isempty(MatchIdx)
        MatchIdx = 1;
    end
    set(vObj.h.PlotSourcePopup,...
        'String',vObj.Data.PlotParametersSourceOptions,...
        'Value',MatchIdx);
else
    set(vObj.h.PlotSourcePopup,...
        'String',{'N/A'},...
        'Value',1);
end    


% Parameters Table
if ~isempty(vObj.Data)
    set(vObj.h.PlotParametersTable,...
        'Data',vObj.Data.PlotParametersData,...
        'ColumnName',{'Parameter','Value'},...
        'ColumnFormat',{'char','float'},...
        'ColumnEditable',[false,true]);
else
    set(vObj.h.PlotParametersTable,...
        'Data',cell(0,2),...
        'ColumnName',{'Parameter','Value'},...
        'ColumnFormat',{'char','float'},...
        'ColumnEditable',[false,true]);
end