function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotOptimization(obj,hAxes)
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
    ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
    ThisName = obj.PlotSpeciesTable{sIdx,3};
    
    
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
                    if isempty(hSpeciesGroup{sIdx,axIdx})
                        hSpeciesGroup{sIdx,axIdx} = hggroup(hAxes(axIdx),...
                            'DisplayName',regexprep(ThisName,'_','\\_'));
                        % Add dummy line for legend
                        line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx},...
                            'LineStyle',ThisLineStyle,...
                            'Color',[0 0 0]);
                    end
                    
                    % Plot
                    hThis = plot(hSpeciesGroup{sIdx,axIdx},Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx),...
                        'Color',SelectedItemColors(itemIdx,:),...
                        'LineStyle',ThisLineStyle);
                    set(get(get(hThis,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                    
                    
%                     hSpeciesGroup{axIdx} = [hSpeciesGroup{axIdx} ...                        
%                         plot(hAxes(axIdx),Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx),...
%                         'Color',SelectedItemColors(itemIdx,:),...
%                         'DisplayName',regexprep(sprintf('%s Results (%d)',ThisName,itemIdx),'_','\\_'))];
                end %if
            end %if
        end %for itemIdx
    end %if
end %for sIdx
        

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
            SelectedGroupIDs = categorical(obj.PlotItemTable(IsSelected,4));
            
            % Get the Group Column from the imported dataset
            GroupColumn = OptimData(:,strcmp(OptimHeader,obj.GroupName));
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
            TimeColumn = cell2mat(OptimData(:,strcmp(OptimHeader,'Time')));
            ThisMarker = '*';
            
            for dIdx = 1:size(obj.PlotSpeciesTable,1)
                axIdx = str2double(obj.PlotSpeciesTable{dIdx,1});
                ThisName = obj.PlotSpeciesTable{dIdx,3};
                ColumnIdx = find(strcmp(OptimHeader,ThisName));
                
                if ~isempty(ColumnIdx) && ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn
                        MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx));
                        
                        % Create a group
                        if isempty(hDatasetGroup{dIdx,axIdx})
                            hDatasetGroup{dIdx,axIdx} = hggroup(hAxes(axIdx),...
                                'DisplayName',regexprep(ThisName,'_','\\_'));
                            % Add dummy line for legend
                            line(nan,nan,'Parent',hDatasetGroup{dIdx,axIdx},...
                                'LineStyle','none',...
                                'Marker',ThisMarker,...
                                'Color',[0 0 0]);
                        end
                        
                        % Plot but remove from the legend
                        hThis = plot(hDatasetGroup{dIdx,axIdx},TimeColumn(MatchIdx),cell2mat(OptimData(MatchIdx,ColumnIdx)),...
                            'Color',SelectedItemColors(gIdx,:),...
                            'LineStyle','none',...
                            'Marker',ThisMarker,...
                            'DisplayName',regexprep(ThisName,'_','\\_'));
                        set(get(get(hThis,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        
%                         % Plot the selected column by GroupID
%                         hDatasetGroup{axIdx} = [hDatasetGroup{axIdx} ... 
%                             plot(hAxes(axIdx),TimeColumn(MatchIdx), cell2mat(OptimData(MatchIdx,ColumnIdx)),...
%                             'LineStyle','none',...
%                             'Marker','*',...
%                             'Color',SelectedItemColors(gIdx,:),... %SelectedGroupColors(gIdx,:));
%                             'DisplayName',regexprep(sprintf('%s %s',ThisName,SelectedGroupIDs(gIdx)),'_','\\_'))];
                    end %for gIdx
                end %if
            end %for dIdx
        end %if any
    end %if StatusOk
end %if any


%% Legend

hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);
for axIndex = 1:NumAxes
    
    % Append
    LegendItems = [horzcat(hSpeciesGroup{:,axIndex}) horzcat(hDatasetGroup{:,axIndex})];
    
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