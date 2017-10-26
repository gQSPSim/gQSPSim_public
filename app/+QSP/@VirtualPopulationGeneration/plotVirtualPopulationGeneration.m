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

% load acceptance criteria
Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);

    [ThisStatusOk,ThisMessage,accCritHeader,accCritData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);        
    end
    else
    accCritHeader = {};
    accCritData = {};
end

grpVec = cell2mat(accCritData(:,strcmp('Group', accCritHeader)));
LBVec = cell2mat(accCritData(:,strcmp('LB', accCritHeader)));
UBVec = cell2mat(accCritData(:,strcmp('UB', accCritHeader)));
DataVec = accCritData(:,strcmp('Data', accCritHeader));
TimeVec = cell2mat(accCritData(:,strcmp('Time', accCritHeader)));


%% Get the selections and Task-Vpop pairs

% Get the selected items
IsSelected = obj.PlotItemTable(:,1);
if iscell(IsSelected)
    IsSelected = cell2mat(IsSelected);
end

if isempty(obj.SimResults)
    IsCached = false(size(obj.PlotItemTable(:,1)));
else
    IsCached = ~cellfun(@isempty, obj.SimResults)';
end
CachedInds = find(IsCached);
RunInds = IsSelected & ~IsCached;    

if any(RunInds) && ~isempty(obj.VPopName)
        
    SelectedInds = find(RunInds);

    % make Task-Vpop pairs for each selected task
    nSelected = nnz(RunInds);
    
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

% get the virtual population object
allVpopNames = {obj.Settings.VirtualPopulation.Name};
vObj = obj.Settings.VirtualPopulation(strcmp(obj.VPopName,allVpopNames));

%% Run the simulations for those that are not cached
if ~isempty(simObj)
    [StatusOK,Message,ResultFileNames,Results] = simulationRunHelper(simObj, [], {}, TimeVec);
    
    if StatusOK == false
        error('plotVirtualPopulationGeneration: %s',Message);
    end
    
    % cache the result to avoid simulating again
    for ii = 1:length(simObj.Item)
        obj.SimResults{SelectedInds(ii)}.Time = Results{ii}.Time;
        obj.SimResults{SelectedInds(ii)}.SpeciesNames = Results{ii}.SpeciesNames;        
        obj.SimResults{SelectedInds(ii)}.Data = Results{ii}.Data;        
    end
else
    Results = [];    
end

%% add the cached results to get the complete simulation results

% add cached results
indCached = find(IsSelected & IsCached);
newResults = [];

for ii = 1:length(indCached)
    newResults{indCached(ii)} = obj.SimResults{indCached(ii)};
end

indNotCached = find(IsSelected & ~IsCached);
for ii = 1:length(indNotCached)
    newResults{indNotCached(ii)} = Results{ii};
end
   
if ~isempty(newResults)
    Results = newResults(~cellfun(@isempty,newResults)); % combined cached & new simulations
end
% Get the associated colors
SelectedItemColors = cell2mat(obj.PlotItemTable(IsSelected,2));


%% Plot Simulation Items



if strcmp(obj.PlotType, 'Normal')
    for sIdx = 1:size(obj.PlotSpeciesTable,1)
        allAxes = str2double(obj.PlotSpeciesTable{sIdx,1});
%         cla(hAxes(allAxes))
        if ~isnan(allAxes)
            set(hAxes(allAxes),'XTickMode','auto','XTickLabelMode','auto')
        end
        ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
        ThisName = obj.PlotSpeciesTable{sIdx,3};
        
        acc_lines = [];
        rej_lines = [];
        ublb_lines = [];
        
        if ~isempty(allAxes) && ~isnan(allAxes)
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
                    ColumnIdx_invalid = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName)) + (find(~obj.SimFlag)-1) * NumSpecies;

                    % Plot
                    % Normal plot type
                    % plot over for just the invalid / rejected vpatients
                    if ~isempty(ColumnIdx_invalid) && obj.ShowInvalidVirtualPatients
                        rej_lines = [rej_lines; plot(hAxes(allAxes),Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx_invalid),...
                            'LineStyle',ThisLineStyle,...
                            'Color',[0.5,0.5,0.5])];  
                    end
                    
                    acc_lines = [acc_lines; plot(hAxes(allAxes),Results{itemIdx}.Time,Results{itemIdx}.Data(:,setdiff(ColumnIdx, ColumnIdx_invalid)),...
                        'LineStyle',ThisLineStyle,...
                        'Color',SelectedItemColors(itemIdx,:))];             

                    % add upper and lower bounds if applicable
                    DataCol = find(strcmp(accCritHeader,'Data'));
                    accName = obj.PlotSpeciesTable(strcmp(ThisName,obj.PlotSpeciesTable(:,3)),4);

                    accDataRows = strcmp(accCritData(:,DataCol), accName) & ...
                        cell2mat(accCritData(:,strcmp(accCritHeader,'Group'))) == str2num(obj.PlotItemTable{itemIdx,4}) ;
                    LB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'LB')));
                    UB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'UB')));
                    accTime = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'Time')));

                    if any(accDataRows)
                        ublb_lines = [ublb_lines; plot(hAxes(allAxes), accTime, LB, 'ko--', 'MarkerFaceColor', SelectedItemColors(itemIdx,:), 'MarkerEdgeColor', 'k', 'LineWidth', 2)];
                        ublb_lines = [ublb_lines; plot(hAxes(allAxes), accTime, UB, 'ko--', 'MarkerFaceColor', SelectedItemColors(itemIdx,:), 'MarkerEdgeColor', 'k', 'LineWidth', 2)];
                    end
                end
            end
            set(hAxes(allAxes), 'Children', [ublb_lines;  acc_lines; rej_lines]) % move UB/LB to top of plotting stack
        end
    end
elseif strcmp(obj.PlotType,'Diagnostic') && ~isempty(Results)
    allAxes = str2double(obj.PlotSpeciesTable(:,1)); % all axes with species assigned to them
    
    % get all unique time points that exist in the simulation output and
    % acc. criteria

    % all simulated time points
    allTime = cell2mat(horzcat(cellfun(@(X) X.Time, Results, 'UniformOutput', false)));
    compareTime = intersect(allTime,TimeVec);
    spNames = unique(obj.PlotSpeciesTable(:,3));

    % loop over axes
    unqAxis = unique(allAxes);
    for axIdx = 1:numel(unqAxis)
        currentAxis = unqAxis(axIdx);
        % get all species on this axis
        axSpecies = find(allAxes==currentAxis);
        dpTimes = {};
        % get groups that contain species on the current axis
        for itemIdx = 1:numel(Results)
        
            [~,ColumnIdx] = ismember(spNames(axSpecies),Results{itemIdx}.SpeciesNames);
            % columns within the results object containing data for these
            % species
            NumSpecies = numel(Results{itemIdx}.SpeciesNames);
            NumVpop = size(Results{itemIdx}.Data,2) / NumSpecies;
            ColumnIdx = ColumnIdx + repelem(0:NumVpop-1, length(ColumnIdx), 1)*NumSpecies;
            
            % loop over the species in the acceptance criteria
            for spIdx =1:numel(axSpecies)
                dataName = obj.PlotSpeciesTable(axSpecies(spIdx), 4); % name of species in acc. crit.
                accIdx = strcmp(dataName, DataVec) & grpVec == itemIdx; % indices of entries in acc. crit. for this species & group
                
                accTime = TimeVec(accIdx); % time points in acc. crit.
                % get time points that are simulated for this group and also in
                % the acceptance criteria
                [b_time,timeIdx] = ismember(accTime, Results{itemIdx}.Time);
                timeIdx = timeIdx(b_time);

                % get the data points for this species at the correct time
                % points
                dpData{itemIdx,spIdx} = reshape(Results{itemIdx}.Data(timeIdx, ColumnIdx(spIdx,:)), [], 1);
                [~,timeGroup] = ismember(Results{itemIdx}.Time(timeIdx), compareTime); % unique time group index
                dpGroup{itemIdx,spIdx} = repmat(timeGroup, NumVpop, 1); 
                accGroup_lb{itemIdx,spIdx} = LBVec( grpVec==itemIdx & accIdx & ismember(TimeVec, Results{itemIdx}.Time) );
                accGroup_ub{itemIdx,spIdx} = UBVec( grpVec==itemIdx & accIdx & ismember(TimeVec, Results{itemIdx}.Time) );

                dpTime{itemIdx,spIdx} = timeGroup;
            end
        end
        
        % show all species/groups for each unique time point in this axis        
        counter = 1;
        for itemIdx = 1:size(dpData,1)
            for spIdx = 1:size(dpData,2)
                h = distributionPlot(hAxes(currentAxis), dpData{itemIdx,spIdx}, 'groups', dpGroup{itemIdx,spIdx}, 'widthDiv', [numel(dpData), counter], ...
                    'xNames', compareTime(dpTime{itemIdx,spIdx}), 'color', SelectedItemColors(itemIdx,:), 'showMM', 0, 'histOpt', 1);
                % add lines to distinguish species
                style = obj.PlotSpeciesTable{axSpecies(spIdx),2};

                for timeIdx = 1:numel(dpTime{itemIdx,spIdx})
                    x = mean(get(h{1}(timeIdx), 'XData'));
                    y = (accGroup_ub{itemIdx,spIdx}(timeIdx) + accGroup_lb{itemIdx,spIdx}(timeIdx))/2;
                    d = (accGroup_ub{itemIdx,spIdx}(timeIdx) - accGroup_lb{itemIdx,spIdx}(timeIdx))/2;
                    eb = errorbar(hAxes(currentAxis), x(1), y, d, d, 'Marker', 'none', 'LineStyle', 'none',  ..., ...
                        'Color', SelectedItemColors(itemIdx,:), 'CapSize', 18);
                    
                    line(hAxes(currentAxis), x(1)*ones(1,2), [y-d,y+d], 'LineStyle', style, ...
                        'Color', SelectedItemColors(itemIdx,:), 'LineWidth', 2)
                end
                counter =  counter + 1;
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
            SelectedGroupColors = vertcat(obj.PlotItemTable{IsSelected,2});
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
                allAxes = str2double(obj.PlotSpeciesTable{dIdx,1});
                ThisName = obj.PlotSpeciesTable{dIdx,3};
                
                if ~isempty(allAxes) && ~isnan(allAxes)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn and
                        % species name match within the SpeciesColumn
                        MatchIdx = (GroupColumn == str2double(SelectedGroupIDs{gIdx}) & strcmp(SpeciesColumn,ThisName));
                        
                        % Plot the lower and upper bounds associated with
                        % the selected Group and Species, for each time
                        % point
                        if any(MatchIdx)
                            plot(hAxes(allAxes),TimeColumn{MatchIdx},AccCritData{MatchIdx,strcmp(AccCritHeader,'LB')}, ...
                                TimeColumn{MatchIdx},AccCritData{MatchIdx,strcmp(AccCritHeader,'UB')},...
                                'LineStyle','none',...
                                'Marker','*',...
                                'Color',SelectedGroupColors(gIdx,:));
                        end
                    end %for
                end %if
            end %for
        end %if
    end %if
end %if


%% Turn off hold

for index = 1:numel(hAxes)
    xlabel(hAxes(index),'Time');
    ylabel(hAxes(index),'States');
    hold(hAxes(index),'off')
end