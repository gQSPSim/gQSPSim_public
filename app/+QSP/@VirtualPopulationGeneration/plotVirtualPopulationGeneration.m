function [hSpeciesLine,hDatasetLine,hLegend,hLegendChildren] = plotVirtualPopulationGeneration(obj,hAxes)
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
    XLimMode{index} = get(hAxes(index),'XLimMode');
    YLimMode{index} = get(hAxes(index),'YLimMode');
    cla(hAxes(index));
    legend(hAxes(index),'off')
    set(hAxes(index),'XLimMode',XLimMode{index},'YLimMode',YLimMode{index})
    hold(hAxes(index),'on')    
end

NumAxes = numel(hAxes);
hSpeciesLine = cell(1,NumAxes);
hDatasetLine = cell(1,NumAxes);
hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);


%% Process

% TODO: These are not passed out
StatusOK = true;
Message = '';

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
        % NOTE: Indexing into Item may not be valid from PlotItemTable (Incorrect if there are/were invalids: simObj.Item(ii).TaskName = obj.Item(SelectedInds(ii)).TaskName;)
        simObj.Item(ii).TaskName = obj.PlotItemTable{SelectedInds(ii),3};
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
if ~isempty(Results)
    for ii = 1:length(indNotCached)
        newResults{indNotCached(ii)} = Results{ii};
    end
end

if ~isempty(newResults)
    Results = newResults(~cellfun(@isempty,newResults)); % combined cached & new simulations
end
% Get the associated colors
SelectedItemColors = cell2mat(obj.PlotItemTable(IsSelected,2));


%% Plot Simulation Items

if strcmp(obj.PlotType, 'Normal') && ~isempty(Results)
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
                    
                    if ~isempty(Results{itemIdx}.Data(:,setdiff(ColumnIdx, ColumnIdx_invalid)))
                        acc_lines = [acc_lines; plot(hAxes(allAxes),Results{itemIdx}.Time,Results{itemIdx}.Data(:,setdiff(ColumnIdx, ColumnIdx_invalid)),...
                            'LineStyle',ThisLineStyle,...
                            'Color',SelectedItemColors(itemIdx,:))];
                    end

                    % add upper and lower bounds if applicable
                    DataCol = find(strcmp(accCritHeader,'Data'));
                    accName = obj.PlotSpeciesTable(strcmp(ThisName,obj.PlotSpeciesTable(:,3)),4);

                    accDataRows = strcmp(accCritData(:,DataCol), accName) & ...
                        cell2mat(accCritData(:,strcmp(accCritHeader,'Group'))) == str2num(obj.PlotItemTable{itemIdx,4}) ;
                    LB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'LB')));
                    UB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'UB')));
                    accTime = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'Time')));

                    if any(accDataRows)
                        ublb_lines = [ublb_lines; plot(hAxes(allAxes), accTime, LB, 'ko', 'LineStyle', 'none', 'MarkerFaceColor', SelectedItemColors(itemIdx,:), 'MarkerEdgeColor', 'k', 'LineWidth', 2)];
                        ublb_lines = [ublb_lines; plot(hAxes(allAxes), accTime, UB, 'ko', 'LineStyle', 'none', 'MarkerFaceColor', SelectedItemColors(itemIdx,:), 'MarkerEdgeColor', 'k', 'LineWidth', 2)];
                    end
                end
            end
            %set(hAxes(allAxes), 'Children', [ublb_lines;  acc_lines; rej_lines]) % move UB/LB to top of plotting stack
            uistack([ublb_lines;  acc_lines; rej_lines],'top');
        end
    end
elseif strcmp(obj.PlotType,'Diagnostic') && ~isempty(Results)
   
    % all axes with species assigned to them
    allAxes = str2double(obj.PlotSpeciesTable(:,1));

    % all species names
    spNames = unique(obj.PlotSpeciesTable(:,3));

    % loop over axes
    unqAxis = unique(allAxes);
    for axIdx = 1:numel(unqAxis)
        currentAxis = unqAxis(axIdx);
%         cla(hAxes(unqAxis(axIdx)))

        % get all species for this axis
        axSpecies = spNames(allAxes==currentAxis);

        axDataArray = {};
        xlabArray = {};
        colorArray = {};
        UBArray = [];
        LBArray = [];

        % loop over the species on this axis
        for spIdx = 1:length(axSpecies)    
            currentSpec = axSpecies(spIdx);

            % loop over all tasks and get the data for this species  
            for itemIdx = 1:numel(Results)
                % species in this task 
                NumSpecies = numel(Results{itemIdx}.SpeciesNames);
                dataName = obj.PlotSpeciesTable( strcmp(obj.PlotSpeciesTable(:,3), currentSpec), 4);

                % time points for this species in this group in the acc. crit.
                thisTime = TimeVec(grpVec == itemIdx & strcmp(DataVec, dataName));

                % ub/lb
                thisUB = UBVec(grpVec == itemIdx & strcmp(DataVec, dataName));
                thisLB = LBVec(grpVec == itemIdx & strcmp(DataVec, dataName));

                % get times that are in the acceptance criteria for this task / species      
                [b_time,timeIdx] = ismember(thisTime, Results{itemIdx}.Time);
                timeIdx = timeIdx(b_time); % rows to subset for data distributions

                % index of all columns for this species in this group 
                ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpec)) + find(obj.SimFlag) - 1;
                NumVpop = size(Results{itemIdx}.Data,2) / NumSpecies;

                thisData = Results{itemIdx}.Data(timeIdx, ColumnIdx);

                for tix = 1:length(timeIdx)
                    axDataArray = [axDataArray, thisData(tix,:)];
                end

                xlabArray = [xlabArray; num2cell(thisTime)]; % add labels to array
                colorArray = [colorArray; repmat({SelectedItemColors(itemIdx,:)}, length(thisTime), 1)];
                UBArray = [UBArray; thisUB];
                LBArray = [LBArray; thisLB];
            end
        end

        % plot distribution plots for this axis
        distributionPlot(hAxes(currentAxis), axDataArray, 'color', colorArray, 'xNames', xlabArray, 'showMM', 0, 'histOpt', 1.1)

        % add error bars
        for k=1:length(UBArray)
            errorbar(hAxes(currentAxis), k, (UBArray(k)+LBArray(k))/2, (UBArray(k)-LBArray(k))/2, 'Marker', 'none', 'LineStyle', 'none',  ..., ...
                            'Color', colorArray{k})
        end

    end

end

%% Plot Dataset

Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

% Continue if dataset exists
if strcmp(obj.PlotType,'Normal') && any(MatchIdx)
    % Get dataset
    dObj = obj.Settings.VirtualPopulationData(MatchIdx);
    
    % Import
    [StatusOk,~,AccCritHeader,AccCritData] = importData(dObj,dObj.FilePath);
    % Continue if OK
    if StatusOk
        
        if any(IsSelected)            
            SelectedGroupColors = vertcat(obj.PlotItemTable{IsSelected,2});
            SelectedGroupIDs = categorical(obj.PlotItemTable(IsSelected,4));
            
            % Get the Group Column from the imported dataset
            GroupColumn = AccCritData(:,strcmp(AccCritHeader,obj.GroupName));
            if iscell(GroupColumn) 
                % If numeric column, convert to matrix to use categorical                
                IsNumeric = cellfun(@(x)isnumeric(x),GroupColumn);
                if all(IsNumeric)
                    GroupColumn = cell2mat(GroupColumn);                    
                else
                    GroupColumn(IsNumeric) = cellfun(@(x)num2str(x),GroupColumn(IsNumeric),'UniformOutput',false);
                end
            end
            GroupColumn = categorical(GroupColumn);
            
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
                        MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx) & strcmp(SpeciesColumn,ThisName));
                        
                        % Plot the lower and upper bounds associated with
                        % the selected Group and Species, for each time
                        % point
                        if any(MatchIdx)
                            hDatasetLine{allAxes} = [hDatasetLine{allAxes} ...
                                plot(hAxes(allAxes),TimeColumn{MatchIdx},AccCritData{MatchIdx,strcmp(AccCritHeader,'LB')}, ...
                                TimeColumn{MatchIdx},AccCritData{MatchIdx,strcmp(AccCritHeader,'UB')},...
                                'LineStyle','none',...
                                'Marker','*',...
                                'Color',SelectedGroupColors(gIdx,:),...
                                'DisplayName',regexprep(sprintf('%s Results (%d)',ThisName,itemIdx),'_','\\_'))];
                        end
                    end %for
                end %if
            end %for
        end %if
    end %if
end %if


%% Legend

hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);
for axIndex = 1:NumAxes
    
    % Append
    LegendItems = [hSpeciesLine{axIndex} hDatasetLine{axIndex}];
    
    if ~isempty(LegendItems)
        % Add legend
        [hLegend{axIndex},hLegendChildren{axIndex}] = legend(hAxes(axIndex),LegendItems);
    else
        hLegend{axIndex} = [];
        hLegendChildren{axIndex} = [];        
    end
end


%% Turn off hold

for index = 1:numel(hAxes)
    title(hAxes(index),sprintf('Plot %d',index));
    xlabel(hAxes(index),'Time');
    ylabel(hAxes(index),'States');
    hold(hAxes(index),'off')
     % Reset zoom state
    hFigure = ancestor(hAxes(index),'Figure');
    if ~isempty(hFigure) && strcmpi(XLimMode{index},'auto') && strcmpi(YLimMode{index},'auto')
        axes(hAxes(index));
        zoom(hFigure,'out');
        zoom(hFigure,'reset');        
    end
end