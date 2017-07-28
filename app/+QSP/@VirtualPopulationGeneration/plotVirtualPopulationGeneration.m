function plotVirtualPopulationGeneration(obj,hAxes)
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


%% Get the selections and Task-Vpop pairs

% Get the selected items
IsSelected = obj.PlotItemTable(:,1);
if iscell(IsSelected)
    IsSelected = cell2mat(IsSelected);
end
if any(IsSelected) && ~isempty(obj.VPopName)
    % make Task-Vpop pairs for each selected task
    nSelected = sum(IsSelected);
    SelectedInds = find(IsSelected);
    simObj = QSP.Simulation;
    simObj.Settings = obj.Settings;
    simObj.Session = obj.Session;
    for ii = 1:nSelected
        simObj.Item(ii) = QSP.TaskVirtualPopulation;
        simObj.Item(ii).TaskName = obj.Item(SelectedInds(ii)).TaskName;
        simObj.Item(ii).VPopName = obj.VPopName;
    end
else
    simObj = QSP.Simulation.empty(0,1);
end


%% Run the simulations
if ~isempty(simObj)
    [StatusOK,Message,~,Results] = simulationRunHelper(simObj);
    
    if StatusOK == false
        error('plotVirtualPopulationGeneration: %s',Message);
    end
else
    Results = [];    
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
            ColumnIdx = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName));
            
            % since not all tasks will contain all species...
            if ~isempty(ColumnIdx)
                % Update ColumnIdx to get species for ALL virtual patients
                NumSpecies = numel(Results{itemIdx}.SpeciesNames);
                ColumnIdx = ColumnIdx:NumSpecies:size(Results{1}.Data,2);
                
                % Plot
                plot(hAxes(axIdx),Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx),'Color',SelectedItemColors(itemIdx,:));
            end
        end
    end
end
        

%% Plot Dataset

Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

% Continue if dataset exists
if any(MatchIdx)
    % Get dataset
    dObj = obj.Settings.VirtualPopulationData(MatchIdx);
    
    % Import
    [StatusOk,~,AccCritHeader,AccCritData] = importData(dObj,dObj.FilePath);
    % Continue if OK
    if StatusOk
        
        if any(IsSelected)
            SelectedGroupColors = getGroupColors(obj.Session,sum(IsSelected));
            SelectedGroupIDs = obj.PlotItemTable(IsSelected,4);
            
            % Get the Group Column from the imported dataset
            GroupColumn = AccCritData(:,strcmp(AccCritHeader,obj.GroupName));
            if iscell(GroupColumn)
                GroupColumn = cell2mat(GroupColumn);
            end
            
            % Get the Time Column from the imported dataset
            TimeColumn = AccCritData(:,strcmp(AccCritHeader,'Time'));
            
            % Get the Species COlumn from the imported dataset
            SpeciesColumn = AccCritData(:,strcmp(AccCritHeader,'Data'));
            
            for dIdx = 1:size(obj.PlotSpeciesTable,1)
                axIdx = str2double(obj.PlotSpeciesTable{dIdx,1});
                ThisName = obj.PlotSpeciesTable{dIdx,3};
                
                if ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn and
                        % species name match within the SpeciesColumn
                        MatchIdx = (GroupColumn == str2double(SelectedGroupIDs{gIdx}) & strcmp(SpeciesColumn,ThisName));
                        
                        % Plot the lower and upper bounds associated with
                        % the selected Group and Species, for each time
                        % point
                        plot(hAxes(axIdx),TimeColumn{MatchIdx},AccCritData{MatchIdx,strcmp(AccCritHeader,'LB')}, ...
                            TimeColumn{MatchIdx},AccCritData{MatchIdx,strcmp(AccCritHeader,'UB')},...
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