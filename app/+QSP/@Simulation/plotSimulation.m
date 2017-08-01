function plotSimulation(obj,hAxes)
% plot - plots the analysis
% -------------------------------------------------------------------------
% Abstract: This plots the analysis based on the settings and data table.
%
% Syntax:
%           plot(aObj,hAxes)
%
% Inputs:
%           obj - QSP.Simulation object
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

%% Turn on hold

for index = 1:numel(hAxes)
    cla(hAxes(index));
    hold(hAxes(index),'on')    
end


%% Get the selections and MATResultFilePaths

% Get the selected items
IsSelected = obj.PlotItemTable(:,1);
if iscell(IsSelected)
    IsSelected = cell2mat(IsSelected);
end
if any(IsSelected)
    ResultsDir = fullfile(obj.Session.RootDirectory,obj.SimResultsFolderName);
    MATResultFilePaths = cellfun(@(X) fullfile(ResultsDir,X), {obj.Item(IsSelected).MATFileName}, 'UniformOutput', false);
    if ~iscell(MATResultFilePaths)
        MATResultFilePaths = {MATResultFilePaths};
    end    
else
    MATResultFilePaths = {};
end


%% Load the MATResultFilePaths

Results = [];
% Load selected MAT files
for index = 1:numel(MATResultFilePaths)
    if ~isdir(MATResultFilePaths{index}) && exist(MATResultFilePaths{index},'file')
        ThisFileData = load(MATResultFilePaths{index},'Results');
        if isfield(ThisFileData,'Results') && ...
                all(isfield(ThisFileData.Results,{'Time','Data','SpeciesNames'}))
            if isempty(Results)
                Results = ThisFileData.Results;
            else
                Results(index) = ThisFileData.Results; %#ok<AGROW>
            end
        else
            warning('plotSimulation: Data cannot be loaded from %s. File must contain Results structure with fields Time, Data, SpeciesNames.',MATResultFilePaths{index});
        end
    elseif ~isdir(MATResultFilePaths{index}) % Invalid file
        warning('plotSimulation: Invalid file %s',MATResultFilePaths{index});
    end
end

% Get the associated colors
SelectedItemColors = cell2mat(obj.PlotItemTable(IsSelected,2));


%% Plot Simulation Items

for sIdx = 1:size(obj.PlotSpeciesTable,1)
    axIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    ThisName = obj.PlotSpeciesTable{sIdx,2};
    if ~isempty(axIdx) && ~isnan(axIdx)
        for itemIdx = 1:numel(Results)
            % Plot the species from the simulation item in the appropriate
            % color
            
            % Get the match in Sim 1 (Virtual Patient 1) in this VPop
            ColumnIdx = find(strcmp(Results(itemIdx).SpeciesNames,ThisName));
            
            % Update ColumnIdx to get species for ALL virtual patients
            NumSpecies = numel(Results(itemIdx).SpeciesNames);
            ColumnIdx = ColumnIdx:NumSpecies:size(Results(1).Data,2);
            
            % Plot
            plot(hAxes(axIdx),Results(itemIdx).Time,Results(itemIdx).Data(:,ColumnIdx),'Color',SelectedItemColors(itemIdx,:));
        end
    end
end
        

%% Plot Dataset

Names = {obj.Settings.OptimizationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

% Continue if dataset exists
if any(MatchIdx)
    % Get dataset
    dObj = obj.Settings.OptimizationData(MatchIdx);
    
    % Import
    DestDatasetType = 'wide';
    [StatusOk,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
    % Continue if OK
    if StatusOk
        IsSelected = obj.PlotGroupTable(:,1);
        if iscell(IsSelected)
            IsSelected = cell2mat(IsSelected);
        end
        
        if any(IsSelected)
            SelectedGroupColors = cell2mat(obj.PlotGroupTable(IsSelected,2));
            SelectedGroupIDs = categorical(obj.PlotGroupTable(IsSelected,3));
            
            % Get the Group Column from the imported dataset
            GroupColumn = OptimData(:,strcmp(OptimHeader,obj.GroupName));
            GroupColumn = categorical(GroupColumn);
            
            % Get the Time Column from the imported dataset
            Time = OptimData(:,strcmp(OptimHeader,'Time'));
            
            for dIdx = 1:size(obj.PlotDataTable,1)
                axIdx = str2double(obj.PlotDataTable{dIdx,1});
                ThisName = obj.PlotDataTable{dIdx,2};
                ColumnIdx = find(strcmp(OptimHeader,ThisName));
                
                if ~isempty(ColumnIdx) && ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn
                        MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx));
                        
                        % Plot the selected column by GroupID
                        plot(hAxes(axIdx),cell2mat(Time(MatchIdx)),cell2mat(OptimData(MatchIdx,ColumnIdx)),...
                            'LineStyle','none',...
                            'Marker','*',...
                            'Color',SelectedGroupColors(gIdx,:));
                    end
                end
            end
        end
    end
end


%% Turn off hold

for index = 1:numel(hAxes)
    xlabel(hAxes(index),'Time');
    ylabel(hAxes(index),'States');
    hold(hAxes(index),'off')
end