function plotOptimization(obj,hAxes)
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

% Initialize
simObj = QSP.Simulation.empty(0,1);

% Get the selected items
IsSelected = obj.PlotItemTable(:,1);
if iscell(IsSelected)
    IsSelected = cell2mat(IsSelected);
end
if any(IsSelected)
    % make Task-Vpop pairs for each selected task
    nSelected = sum(IsSelected);
    SelectedInds = find(IsSelected);
    simObj = QSP.Simulation;
    simObj.Session = obj.Session;
    simObj.Settings = obj.Settings;
    for ii = 1:nSelected  
        simObj.Item(ii) = QSP.TaskVirtualPopulation;        
        % NOTE: Indexing into Item may not be valid from PlotItemTable (Incorrect if there are/were invalids: obj.Item(SelectedInds(ii)).TaskName;)
        simObj.Item(ii).TaskName = obj.PlotItemTable{SelectedInds(ii),3};
    end
    
    % If Vpop is selected, must provide names the of the Vpops associated
    % with each Task-Group
    VPopNames = {obj.Settings.VirtualPopulation.Name};
    
    if any(strcmp(obj.PlotParametersSource,VPopNames)) 
        if ~isempty(obj.SpeciesIC)
            for ii = 1:nSelected
                % find the group associated with this task
                ThisGroupName = obj.PlotItemTable{SelectedInds(ii),4};
                % find the name of the vpop generated for this task + group
                IndCell = strfind(obj.VPopName,['Group = ' ThisGroupName]);
                NonEmpty = ~cellfun(@isempty, IndCell);

                % only 1 Vpop should match
                if nnz(NonEmpty)~=1
                    Message = 'Multiple Vpops share the same group.';
                    error('plotOptimization: %s',Message);
                end
                % assign the vpop name
                simObj.Item(ii).VPopName = obj.VPopName{NonEmpty};
            end
                
        else
            % in this case, there should only be one Vpop produced
            if length(obj.VPopNames)~=1
                Message = 'Expected there to be one Vpop produced by this optimization, but instead found 0 or more than 1.';
                error('plotOptimization: %s',Message);
            end
            % each task is assigned the same vpop
            for ii = 1:nSelected
                simObj.Item(ii).VPopName = obj.VPopNames;
            end
            
        end

    end
    
    % If Parameter is selected, then leave the Vpop names empty
end


%% Run the simulations
ParamNames = obj.PlotParametersData(:,1);
Pin = obj.PlotParametersData(:,2);
if iscell(Pin)
    Pin = cell2mat(Pin);
end

Results = [];

if any(IsSelected)
    [StatusOK,Message,~,Results] = simulationRunHelper(simObj,Pin,ParamNames);
    
    if ~StatusOK
        error('plotOptimization: %s',Message);
    end
end

% Get the associated colors
SelectedItemColors = cell2mat(obj.PlotItemTable(IsSelected,2));


%% Plot Simulation Items

for sIdx = 1:size(obj.PlotSpeciesTable,1)
    axIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    ThisName = obj.PlotSpeciesTable{sIdx,2};
    if ~isempty(axIdx) && ~isnan(axIdx) && ~isempty(Results)
        for itemIdx = 1:numel(Results)
            % Plot the species from the simulation item in the appropriate
            % color
            
            if isempty(Results{itemIdx})                
                continue
            end
            
            % Get the match in Sim 1 (Virtual Patient 1) in this VPop
            ColumnIdx = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName));
            
            % since not all tasks will contain all species...
            if ~isempty(ColumnIdx) && ~isempty(size(Results{1}.Data,2))
                % Update ColumnIdx to get species for ALL virtual patients
                NumSpecies = numel(Results{itemIdx}.SpeciesNames);
                ColumnIdx = ColumnIdx:NumSpecies:size(Results{1}.Data,2);
                
                % Plot
                if ~isempty(ColumnIdx)
                    plot(hAxes(axIdx),Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx),'Color',SelectedItemColors(itemIdx,:));
                end
            end
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
        
        if any(IsSelected)
            %SelectedGroupColors = getGroupColors(obj.Session,sum(IsSelected));
            SelectedGroupIDs = obj.PlotItemTable(IsSelected,4);
            
            % Get the Group Column from the imported dataset
            GroupColumn = cell2mat(OptimData(:,strcmp(OptimHeader,obj.GroupName)));
            
            % Get the Time Column from the imported dataset
            TimeColumn = cell2mat(OptimData(:,strcmp(OptimHeader,'Time')));
            
            for dIdx = 1:size(obj.PlotSpeciesTable,1)
                axIdx = str2double(obj.PlotSpeciesTable{dIdx,1});
                ThisName = obj.PlotSpeciesTable{dIdx,3};
                ColumnIdx = find(strcmp(OptimHeader,ThisName));
                
                if ~isempty(ColumnIdx) && ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn
                        MatchIdx = (GroupColumn == str2double(SelectedGroupIDs{gIdx}));
                        
                        % Plot the selected column by GroupID
                        plot(hAxes(axIdx),TimeColumn(MatchIdx), cell2mat(OptimData(MatchIdx,ColumnIdx)),...
                            'LineStyle','none',...
                            'Marker','*',...
                            'Color',SelectedItemColors(gIdx,:)); %SelectedGroupColors(gIdx,:));
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