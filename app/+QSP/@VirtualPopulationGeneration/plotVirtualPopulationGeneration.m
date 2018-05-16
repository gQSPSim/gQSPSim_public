function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotVirtualPopulationGeneration(obj,hAxes)
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
hSpeciesGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);
hDatasetGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);

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
    obj.SimResults = cell(size(obj.PlotItemTable(:,1)));
else
    IsCached = ~cellfun(@isempty, obj.SimResults);
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
        simObj.Item(ii).Group = obj.PlotItemTable{SelectedInds(ii),4};
    end
else
    simObj = QSP.Simulation.empty(0,1);
end

% get the virtual population object
allVpopNames = {obj.Settings.VirtualPopulation.Name};
vObj = obj.Settings.VirtualPopulation(strcmp(obj.VPopName,allVpopNames));

%% Run the simulations for those that are not cached
if ~isempty(simObj)

    [ThisStatusOK,Message,ResultFileNames,~,Results] = simulationRunHelper(simObj, [], {}, TimeVec);
    
    if ~ThisStatusOK        
        error('plotVirtualPopulationGeneration: %s',Message);
    end
    
    % cache the result to avoid simulating again
    for ii = 1:length(simObj.Item)
        obj.SimResults{SelectedInds(ii)}.Time = Results{ii}.Time;
        obj.SimResults{SelectedInds(ii)}.SpeciesNames = Results{ii}.SpeciesNames;        
        obj.SimResults{SelectedInds(ii)}.Data = Results{ii}.Data;    
        obj.SimResults{SelectedInds(ii)}.VpopWeights = Results{ii}.VpopWeights;
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

ResultsIdx = find(IsSelected);

if strcmp(obj.PlotType, 'Normal') && ~isempty(Results)
    % all axes with species assigned to them
    allAxes = str2double(obj.PlotSpeciesTable(:,1));
    
    for sIdx = 1:size(obj.PlotSpeciesTable,1)
        axIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
%         cla(hAxes(allAxes))
        if ~isnan(axIdx)
            set(hAxes(axIdx),'XTickMode','auto','XTickLabelMode','auto','YTickMode','auto','YTickLabelMode','auto')
        end
        ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
        ThisName = obj.PlotSpeciesTable{sIdx,3};
        ThisDataName = obj.PlotSpeciesTable{sIdx,4};
        
        acc_lines = [];
        rej_lines = [];
        ublb_lines = [];
        mean_line = [];
        
        if ~isempty(axIdx) && ~isnan(axIdx)
            
            for itemIdx = 1:numel(Results)
                itemNumber = ResultsIdx(itemIdx);
                % Plot the species from the simulation item in the appropriate
                % color

                % Get the match in Sim 1 (Virtual Patient 1) in this VPop
                ColumnIdx = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName));

                % since not all tasks will contain all species...
                if ~isempty(ColumnIdx)
                    % Update ColumnIdx to get species for ALL virtual patients
                    NumSpecies = numel(Results{itemIdx}.SpeciesNames);
                    ColumnIdx = ColumnIdx:NumSpecies:size(Results{itemIdx}.Data,2);
                    ColumnIdx_invalid = find(strcmp(Results{itemIdx}.SpeciesNames,ThisName)) + (find(Results{itemIdx}.VpopWeights==0)-1) * NumSpecies;

                    
                    if isempty(hSpeciesGroup{sIdx,axIdx})
                        hSpeciesGroup{sIdx,axIdx} = hggroup(hAxes(axIdx),...
                            'DisplayName',regexprep(ThisName,'_','\\_'));
                        % Add dummy line for legend
                        line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx},...
                            'LineStyle',ThisLineStyle,...
                            'Color',[0 0 0]);
                    end                    
                    
                    % Plot
                    % Normal plot type
                    % plot over for just the invalid / rejected vpatients
                    
                    % transform data 
                    thisData = obj.SpeciesData(sIdx).evaluate(Results{itemIdx}.Data);

                    % invalid lines
                    if ~isempty(ColumnIdx_invalid) && obj.ShowInvalidVirtualPatients
                        % Plot
                        hThis = plot(hSpeciesGroup{sIdx,axIdx},Results{itemIdx}.Time,thisData(:,ColumnIdx_invalid),...
                            'Color',[0.5,0.5,0.5],...
                            'LineStyle',ThisLineStyle);
                        hThisAnn = get(hThis,'Annotation');
                        if iscell(hThisAnn)
                            hThisAnn = [hThisAnn{:}];
                        end
                        hThisAnnLegend = get(hThisAnn,'LegendInformation');
                        if iscell(hThisAnnLegend)
                            hThisAnnLegend = [hThisAnnLegend{:}];
                        end
                        set(hThisAnnLegend,'IconDisplayStyle','off');
                        rej_lines = [rej_lines; hThis];
                        
%                         rej_lines = [rej_lines; plot(hAxes(axIdx),Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx_invalid),...
%                             'LineStyle',ThisLineStyle,...
%                             'Color',[0.5,0.5,0.5])];  
                    end
                    
                    % valid lines
                    if ~isempty(Results{itemIdx}.Data(:,setdiff(ColumnIdx, ColumnIdx_invalid)))

                        % Plot
                        hThis = plot(hSpeciesGroup{sIdx,axIdx},Results{itemIdx}.Time,thisData(:,setdiff(ColumnIdx, ColumnIdx_invalid)),...
                            'Color',SelectedItemColors(itemIdx,:),...
                            'LineStyle',ThisLineStyle);
                        hThisAnn = get(hThis,'Annotation');
                        if iscell(hThisAnn)
                            hThisAnn = [hThisAnn{:}];
                        end
                        hThisAnnLegend = get(hThisAnn,'LegendInformation');
                        if iscell(hThisAnnLegend)
                            hThisAnnLegend = [hThisAnnLegend{:}];
                        end
                        set(hThisAnnLegend,'IconDisplayStyle','off');
                        acc_lines = [acc_lines; hThis];                        
                        
%                         acc_lines = [acc_lines; plot(hAxes(axIdx),Results{itemIdx}.Time,Results{itemIdx}.Data(:,setdiff(ColumnIdx, ColumnIdx_invalid)),...
%                             'LineStyle',ThisLineStyle,...
%                             'Color',SelectedItemColors(itemIdx,:))];
                    end
                    
                    % mean
%                     mean_line = plot(hAxes(axIdx), Results{itemIdx}.Time, thisData(:,ColumnIdx) * obj.PrevalenceWeights/sum(obj.PrevalenceWeights),...
                    if iscell(Results{itemIdx}.VpopWeights)
                        vpopWeights = cell2mat(Results{itemIdx}.VpopWeights);
                    else
                        vpopWeights = Results{itemIdx}.VpopWeights;
                    end
                    
                    mean_line = plot(hSpeciesGroup{sIdx,axIdx}, Results{itemIdx}.Time, thisData(:,ColumnIdx) * ...
                            vpopWeights/sum(vpopWeights),...
                        'LineStyle',ThisLineStyle,...
                        'Color',SelectedItemColors(itemIdx,:), ...
                        'LineWidth', 3);


                    % add upper and lower bounds if applicable
                    DataCol = find(strcmp(accCritHeader,'Data'));
                    accName = obj.PlotSpeciesTable(strcmp(ThisDataName,obj.PlotSpeciesTable(:,4)),4);

                    accDataRows = strcmp(accCritData(:,DataCol), accName) & ...
                        cell2mat(accCritData(:,strcmp(accCritHeader,'Group'))) == str2num(obj.PlotItemTable{itemNumber,4}) ;
                    LB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'LB')));
                    UB = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'UB')));
                    accTime = cell2mat(accCritData(accDataRows, strcmp(accCritHeader, 'Time')));

                    if any(accDataRows)
                        % Plot
                        hThis = plot(hSpeciesGroup{sIdx,axIdx},accTime,LB,...
                            'MarkerFaceColor', SelectedItemColors(itemIdx,:),...
                            'MarkerEdgeColor','k',...
                            'LineWidth',2,...
                            'LineStyle','none');
                        hThisAnn = get(hThis,'Annotation');
                        if iscell(hThisAnn)
                            hThisAnn = [hThisAnn{:}];
                        end
                        hThisAnnLegend = get(hThisAnn,'LegendInformation');
                        if iscell(hThisAnnLegend)
                            hThisAnnLegend = [hThisAnnLegend{:}];
                        end
                        set(hThisAnnLegend,'IconDisplayStyle','off');
                        ublb_lines = [ublb_lines; hThis];      
                        
                        hThis = plot(hSpeciesGroup{sIdx,axIdx},accTime,UB,...
                            'MarkerFaceColor', SelectedItemColors(itemIdx,:),...
                            'MarkerEdgeColor','k',...
                            'LineWidth',2,...
                            'LineStyle','none');
                        hThisAnn = get(hThis,'Annotation');
                        if iscell(hThisAnn)
                            hThisAnn = [hThisAnn{:}];
                        end
                        hThisAnnLegend = get(hThisAnn,'LegendInformation');
                        if iscell(hThisAnnLegend)
                            hThisAnnLegend = [hThisAnnLegend{:}];
                        end
                        set(hThisAnnLegend,'IconDisplayStyle','off');
                        ublb_lines = [ublb_lines; hThis];      
                        
%                         ublb_lines = [ublb_lines; plot(hAxes(axIdx), accTime, LB, 'ko', 'LineStyle', 'none', 'MarkerFaceColor', SelectedItemColors(itemIdx,:), 'MarkerEdgeColor', 'k', 'LineWidth', 2)];
%                         ublb_lines = [ublb_lines; plot(hAxes(axIdx), accTime, UB, 'ko', 'LineStyle', 'none', 'MarkerFaceColor', SelectedItemColors(itemIdx,:), 'MarkerEdgeColor', 'k', 'LineWidth', 2)];
                    end
                end
            end

            uistack([ublb_lines;  acc_lines; rej_lines],'top');
        end
    end
    
    
elseif strcmp(obj.PlotType,'Diagnostic') && ~isempty(Results)
   
    % all axes with species assigned to them
    allAxes = str2double(obj.PlotSpeciesTable(:,1));

    % all species names
    spNames = obj.PlotSpeciesTable(:,3);
    dataNames = obj.PlotSpeciesTable(:,4);
    
    % loop over axes
    unqAxis = unique(allAxes);
    for axIdx = 1:numel(unqAxis)
        currentAxis = unqAxis(axIdx);
%         cla(hAxes(unqAxis(axIdx)))

        % get all species for this axis
        axData = dataNames(allAxes==currentAxis);

        axDataArray = {};
        xlabArray = {};
        colorArray = {};
        UBArray = [];
        LBArray = [];

        % loop over the species on this axis
        for dataIdx = 1:length(axData)    
            currentData = axData(dataIdx);
            currentDataIdx = strcmp(currentData, obj.PlotSpeciesTable(:,4));
            % loop over all tasks and get the data for this species  
            for itemIdx = 1:numel(Results)

                itemNumber = ResultsIdx(itemIdx);

                % species in this task 
                NumSpecies = numel(Results{itemIdx}.SpeciesNames);
                currentSpecies = obj.PlotSpeciesTable( strcmp(obj.PlotSpeciesTable(:,4), currentData), 3);
                % time points for this species in this group in the acc. crit.
                thisTime = TimeVec(grpVec == str2num(obj.PlotItemTable{itemNumber,4}) & strcmp(DataVec, currentData));
                if isempty(thisTime)
                    continue
                end
                
                % ub/lb
                thisUB = UBVec(grpVec == str2num(obj.PlotItemTable{itemNumber,4}) & strcmp(DataVec, currentData));
                thisLB = LBVec(grpVec == str2num(obj.PlotItemTable{itemNumber,4}) & strcmp(DataVec, currentData));

                % get times that are in the acceptance criteria for this task / species      
                [b_time,timeIdx] = ismember(thisTime, Results{itemIdx}.Time);
                timeIdx = timeIdx(b_time); % rows to subset for data distributions

                % index of all columns for this species in this group 
                NumVpop = size(Results{itemIdx}.Data,2) / NumSpecies;
                
                if ~obj.ShowInvalidVirtualPatients && ~isempty(Results{itemIdx}.VpopWeights)
                    if isempty(Results{itemIdx}.VpopWeights)
                        ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpecies)) + (0:NumVpop-1)*NumSpecies;
                        warning('plotVirtualPopulationGeneration: missing prevalence weights in vpop. Showing all trajectories.')
                    else
                        ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpecies)) + (find(Results{itemIdx}.VpopWeights)-1)*NumSpecies ;
                        if isempty(ColumnIdx)
                            return
                        end
                    end
                else
                    ColumnIdx = find( strcmp(Results{itemIdx}.SpeciesNames, currentSpecies)) + (0:NumVpop-1)*NumSpecies;
                end

                thisData = obj.SpeciesData(currentDataIdx).evaluate(Results{itemIdx}.Data(:, ColumnIdx));
                thisData = thisData(timeIdx, :);

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
        if isempty(axDataArray)
            continue
        end
        warning('off','DISTRIBUTIONPLOT:ERASINGLABELS')
        distributionPlot(hAxes(currentAxis), axDataArray, 'color', colorArray, 'xNames', xlabArray, 'showMM', 0, 'histOpt', 1.1)

        % add error bars
        for k=1:length(UBArray)
            errorbar(hAxes(currentAxis), k, (UBArray(k)+LBArray(k))/2, (UBArray(k)-LBArray(k))/2, 'Marker', 's', 'LineStyle', 'none',  ..., ...
                            'Color', 'k', 'LineWidth', 2) % colorArray{k}
        end

    end

end %if PlotType is normal


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
            
            % Get the Species Column from the imported dataset
            SpeciesDataColumn = AccCritData(:,strcmp(AccCritHeader,'Data'));
            
            for dIdx = 1:size(obj.PlotSpeciesTable,1)
                axIdx = str2double(obj.PlotSpeciesTable{dIdx,1});
                ThisName = obj.PlotSpeciesTable{dIdx,4};
                ThisMarker = '*';
                
                if ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn and
                        % species name match within the SpeciesColumn
                        MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx) & strcmp(SpeciesDataColumn,ThisName));
                        
                        % Plot the lower and upper bounds associated with
                        % the selected Group and Species, for each time
                        % point
                        % Create a group                        
                        if isempty(hDatasetGroup{dIdx,axIdx})
                            hDatasetGroup{dIdx,axIdx} = hggroup(hAxes(axIdx),...
                                'DisplayName',regexprep(sprintf('%s',ThisName),'_','\\_'));
                            % Add dummy line for legend
                            line(nan,nan,'Parent',hDatasetGroup{dIdx,axIdx},...
                                'LineStyle','none',...
                                'Marker',ThisMarker,...
                                'Color',[0 0 0]);                            
                        end
                        
                        % Plot but remove from the legend
                        if any(MatchIdx)
                            hThis = plot(hDatasetGroup{dIdx,axIdx},[TimeColumn{MatchIdx}],[AccCritData{MatchIdx,strcmp(AccCritHeader,'LB')}], ...
                                [TimeColumn{MatchIdx}],[AccCritData{MatchIdx,strcmp(AccCritHeader,'UB')}],...
                                'LineStyle','none',...
                                'Marker',ThisMarker,...
                                'Color',SelectedGroupColors(gIdx,:),...
                                'DisplayName',regexprep(sprintf('%s',ThisName),'_','\\_'));
                            hThisAnn = get(hThis,'Annotation');
                            if iscell(hThisAnn)
                                hThisAnn = [hThisAnn{:}];
                            end
                            hThisAnnLegend = get(hThisAnn,'LegendInformation');
                            if iscell(hThisAnnLegend)
                                hThisAnnLegend = [hThisAnnLegend{:}];
                            end
                            set(hThisAnnLegend,'IconDisplayStyle','off');                            
                        end %if                        
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
    LegendItems = [horzcat(hSpeciesGroup{:,axIndex}) horzcat(hDatasetGroup{:,axIndex})];
    
    if ~isempty(LegendItems)
        % Add legend
        try
            [hLegend{axIndex},hLegendChildren{axIndex}] = legend(hAxes(axIndex),LegendItems);
        catch
            warning('Error drawing legends')
        end
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
        try
            zoom(hFigure,'out');
            zoom(hFigure,'reset');        
        catch ME
            warning(ME.message);
        end
    end
end
