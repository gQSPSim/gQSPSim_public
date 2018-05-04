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
    GroupIDs = [];
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

    hSelect = vObj.h.PlotItemsTable.CellSelectionCallback;
    hEdit = vObj.h.PlotItemsTable.CellEditCallback;
    vObj.h.PlotItemsTable.CellSelectionCallback = [];
    vObj.h.PlotItemsTable.CellEditCallback = [];
    set(vObj.h.PlotItemsTable,...
        'Data',TableData,...
        'ColumnName',{'Include','Color','Task','Group'},...
        'ColumnFormat',{'boolean','char','char','char'},...
        'ColumnEditable',[true,false,false,false]...
        );
    vObj.h.PlotItemsTable.CellSelectionCallback = hSelect;
    vObj.h.PlotItemsTable.CellEditCallback = hEdit;
    
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
        if ~isempty(vObj.Data.SpeciesLineStyles(:))
            vObj.Data.PlotSpeciesTable(:,2) = vObj.Data.SpeciesLineStyles(:);
        else
            vObj.Data.PlotSpeciesTable(:,2) = {'-'};
        end
            
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

% Source popup
if ~isempty(vObj.Data)
    % Update PlotParametersSourceOptions
    Names = {vObj.Data.Settings.Parameters.Name};
    MatchIdx = strcmpi(Names,vObj.Data.RefParamName);
    
    % TODO: Confirm - is this an issue if the Vpop name is renamed so it no
    % longer matches the ExcelResultFileName?
%     VPopNames = {};
%     for idx = 1:numel(vObj.Data.ExcelResultFileName)
%         if ~isempty(vObj.Data.ExcelResultFileName{idx})
%             [~,VPopNames{idx}] = fileparts(vObj.Data.ExcelResultFileName{idx}); %#ok<AGROW>
%         else
%             VPopNames{idx} = [];
%         end
%     end

    % construct the VPopname from the name of the optimization
    VPopNames = {sprintf('Results - Optimization = %s -', vObj.Data.Name)};
    
    % Filter VPopNames list (only if name does not exist, not if invalid)
    AllVPopNames = {vObj.Data.Session.Settings.VirtualPopulation.Name};
    MatchVPopIdx = false(1,numel(AllVPopNames));
    for idx = 1:numel(VPopNames)
        if isempty(VPopNames{idx})
            continue
        end
        MatchVPopIdx = MatchVPopIdx | ~cellfun(@isempty,regexp(AllVPopNames,VPopNames{idx}));
    end
    VPopNames = AllVPopNames(MatchVPopIdx);
    
    if any(MatchIdx)
        pObj = vObj.Data.Settings.Parameters(MatchIdx);    
        pObj_derivs = AllVPopNames(~cellfun(@isempty, regexp(AllVPopNames, vObj.Data.RefParamName)));
        PlotParametersSourceOptions = vertcat('N/A',{pObj.Name}, pObj_derivs', VPopNames(:));
    else
        PlotParametersSourceOptions = vertcat('N/A',VPopNames(:));
    end
else
    PlotParametersSourceOptions = {'N/A'};
end

% History table
ThisProfileData = {}; % Initialize
if ~isempty(vObj.Data)
    Summary = horzcat(...
        num2cell(1:numel(vObj.Data.PlotProfile))',...        
        {vObj.Data.PlotProfile.Show}',...
        {vObj.Data.PlotProfile.Source}',...
        {vObj.Data.PlotProfile.Description}');
    
    % Loop over and italicize non-matches
    [IsSourceMatch,IsRowEmpty,ThisProfileData] = i_importParametersSourceHelper(vObj);    
    for rowIdx = 1:size(Summary,1)
        % Mark invalid if source parameters cannot be loaded
        if IsRowEmpty(rowIdx) && vObj.h.PlotHistoryTable.UseJTable
            Summary{rowIdx,3} = QSP.makeInvalid(Summary{rowIdx,3});
        elseif ~IsSourceMatch(rowIdx)
            % If parameters don't match the source, italicize
            if vObj.h.PlotHistoryTable.UseJTable
                tmp = [1, 3, 4];
            else
                tmp = [1, 4];
            end
                
            for colIdx = tmp
                Summary{rowIdx,colIdx} = QSP.makeItalicized(Summary{rowIdx,colIdx});
            end
        end
    end

    ThisCallback = get(vObj.h.PlotHistoryTable,'CellSelectionCallback');
    set(vObj.h.PlotHistoryTable,'CellSelectionCallback',''); % Disable    
    set(vObj.h.PlotHistoryTable,...
        'Data',Summary,...
        'ColumnName',{'Run','Show','Source','Description'},...
        'ColumnFormat',{'numeric','logical',PlotParametersSourceOptions(:),'char'},...
        'ColumnEditable',[false,true,true,true]...
        );
    if ~isempty(Summary)
        set(vObj.h.PlotHistoryTable,'SelectedRows',vObj.Data.SelectedProfileRow);
    end
    set(vObj.h.PlotHistoryTable,'CellSelectionCallback',ThisCallback); % Restore

else
    set(vObj.h.PlotHistoryTable,...
        'Data',cell(0,5),...
        'ColumnName',{'Run','Show','Source','Description'},...
        'ColumnFormat',{'numeric','logical','char','char'},...
        'ColumnEditable',[false,true,false,true]...
        );
end
    
% Selection
if ~isempty(vObj.Data)
    if ~isempty(vObj.Data.SelectedProfileRow)
        ThisProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);
    else
        ThisProfile = QSP.Profile.empty(0,1);
    end
else
    ThisProfile = QSP.Profile.empty(0,1);
end

% Enable
if ~isempty(ThisProfile)
%     set(vObj.h.PlotParametersSourcePopup,'Enable','on');
    set(vObj.h.SaveAsVPopButton,'Enable','on');
    set(vObj.h.PlotParametersTable,'Enable','on');
else
%     set(vObj.h.PlotParametersSourcePopup,'Enable','off');
    set(vObj.h.SaveAsVPopButton,'Enable','off');
    set(vObj.h.PlotParametersTable,'Enable','off');
end

% Parameters Table
if ~isempty(ThisProfileData) && size(ThisProfileData,2)==3
    
    % Mark the rows that are edited (column 2 does not equal column 3)
    if ispc
        italCols = 1:size(ThisProfileData,2);
    else
        italCols = 1;
    end
    
    for rowIdx = 1:size(ThisProfileData,1)
        tmp1 = ThisProfileData{rowIdx,2};
        tmp2 = ThisProfileData{rowIdx,3};
        if ischar(tmp1), tmp1=str2num(tmp1); end
        if ischar(tmp2), tmp2=str2num(tmp2); end
        
        if ~isequal(tmp1, tmp2)
            for colIdx = italCols
                ThisProfileData{rowIdx,colIdx} = QSP.makeItalicized(ThisProfileData{rowIdx,colIdx});
            end
        end
    end
    
    set(vObj.h.PlotParametersTable,...
        'Data',ThisProfileData,...
        'ColumnName',{'Parameter','Value','Source Value'},...
        'ColumnFormat',{'char','float','float'},...
        'ColumnEditable',[false,true,false], ...
        'LabelString', sprintf('Parameters (Run = %d)', vObj.Data.SelectedProfileRow));
else
    set(vObj.h.PlotParametersTable,...
        'Data',cell(0,3),...
        'ColumnName',{'Parameter','Value','Source Value'},...
        'ColumnFormat',{'char','float','float'},...
        'ColumnEditable',[false,true,false], ...
        'LabelString', sprintf('Parameters'));
end



%% Update plot

updateVisualizationPlot(vObj);


%--------------------------------------------------------------------------
function [IsSourceMatch,IsRowEmpty,SelectedProfileData] = i_importParametersSourceHelper(vObj)

UniqueSourceNames = unique({vObj.Data.PlotProfile.Source});
UniqueSourceData = cell(1,numel(UniqueSourceNames));

% First import just the unique sources
for index = 1:numel(UniqueSourceNames)
    % Get values
    [StatusOk,~,SourceData] = importParametersSource(vObj.Data,UniqueSourceNames{index});
    if StatusOk
        [~,order] = sort(upper(SourceData(:,1)));
        UniqueSourceData{index} = SourceData(order,:);
    else
        UniqueSourceData{index} = cell(0,2);
    end
end

% Exclude species from the parameters table
% idxSpecies = vObj.Data.


% Return which profile rows are different and return the selected profile
% row's data
nProfiles = numel(vObj.Data.PlotProfile);
IsSourceMatch = true(1,nProfiles);
IsRowEmpty = false(1,nProfiles);
for index = 1:nProfiles
    ThisProfile = vObj.Data.PlotProfile(index);
    ThisProfileValues = ThisProfile.Values; % Already sorted
    uIdx = ismember(UniqueSourceNames,ThisProfile.Source);
    
    if ~isequal(ThisProfileValues,UniqueSourceData{uIdx})
        IsSourceMatch(index) = false;
    end
    if isempty(UniqueSourceData{uIdx})
        IsRowEmpty(index) = true;
    end
end

if ~isempty(vObj.Data.SelectedProfileRow)
    try
        SelectedProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);
    catch thisError
        warning(thisError.message);
        SelectedProfileData = [];
        return
    end
        
        
    uIdx = ismember(UniqueSourceNames,SelectedProfile.Source);
    
    % Store - names, user's values, source values
%     SelectedProfileData = cell(size(UniqueSourceData{uIdx},1),3);
%     SelectedProfileData(1:size(SelectedProfile.Values,1),1:2) = Values;
    
    SelectedProfileData = SelectedProfile.Values;
    if ~isempty(UniqueSourceData{uIdx})
        % get matching values in the source
        [hMatch,MatchIdx] = ismember(SelectedProfileData(:,1), UniqueSourceData{uIdx}(:,1));
%         SelectedProfileData = SelectedProfileData(hMatch,:);
        SelectedProfileData(hMatch,3) = UniqueSourceData{uIdx}(MatchIdx(hMatch),end);
        [~,index] = sort(upper(SelectedProfileData(:,1)));
        SelectedProfileData = SelectedProfileData(index,:);

%         for idx = 1:size(SelectedProfileData,1)
%             MatchIdx = ismember(UniqueSourceData{uIdx}(:,1),SelectedProfileData{idx,1});
%             if any(MatchIdx)                
%                 SelectedProfileData{idx,3} = UniqueSourceData{uIdx}{MatchIdx,end};
%             end
%         end
    end
else
    SelectedProfileData = cell(0,3);
end
