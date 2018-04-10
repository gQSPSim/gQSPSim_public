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
% if any(IsSelected)
    % make Task-Vpop pairs for each selected task
%     nSelected = sum(IsSelected);
%     SelectedInds = find(IsSelected);
    simObj = QSP.Simulation;
    simObj.Session = obj.Session;
    simObj.Settings = obj.Settings;
    for ii = 1:size(obj.PlotItemTable(:,1),1) %nSelected  
        simObj.Item(ii) = QSP.TaskVirtualPopulation;        
        % NOTE: Indexing into Item may not be valid from PlotItemTable (Incorrect if there are/were invalids: obj.Item(SelectedInds(ii)).TaskName;)
        simObj.Item(ii).TaskName = obj.PlotItemTable{ii,3}; %obj.PlotItemTable{SelectedInds(ii),3};
    end
    
    % If Vpop is selected, must provide names the of the Vpops associated
    % with each Task-Group
    VPopNames = {obj.Settings.VirtualPopulation.Name};
    
%     if any(strcmp(obj.PlotParametersSource,VPopNames)) 
        % TODO: Review with Justin - how should this change for multiple
        % parameter sources (history table)
        if ~isempty(obj.SpeciesIC)
            for ii = 1:size(obj.PlotItemTable(:,1),1) %nSelected
                % find the group associated with this task
                ThisGroupName = obj.PlotItemTable{ii,4}; %{SelectedInds(ii),4};
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
            
            if length(obj.VPopName)>1
                Message = 'Expected there to be one Vpop produced by this optimization, but instead found 0 or more than 1.';
                error('plotOptimization: %s',Message);
            end
            % each task is assigned the same vpop
            for ii = 1:size(obj.PlotItemTable(:,1),1) %nSelected
                simObj.Item(ii).VPopName = obj.VPopName{1};
            end
            
        end

%     end
    
    % If Parameter is selected, then leave the Vpop names empty
% end


%% Run the simulations

Results = [];
ItemModels = obj.ItemModels;

if any(IsSelected)    
    
    % Loop through all profiles to be shown
    for index = 1:numel(obj.PlotProfile)
%         if ~obj.PlotProfile(index).Show
%             continue
%         end
        
        % TODO: Plot all profiles
        if ~isempty(obj.PlotProfile(index).Values)
            ParamNames = obj.PlotProfile(index).Values(:,1);
            Pin = obj.PlotProfile(index).Values(:,2);
        else
            ParamNames = {};
            Pin = {};
        end
        if iscell(Pin)
            Pin = cell2mat(Pin);
        end        
        if isempty(ItemModels)
            % profile needs to be resimulated b/c source changed or new
            [StatusOK,Message,~,TheseResults,ItemModels] = simulationRunHelper(simObj,Pin,ParamNames,[],[],find(IsSelected));
            obj.ItemModels = ItemModels;
        else
            % reuse the previous item model b/c only parameters have
            % changed
%             simObj_subset = simObj;
%             simObj_subset.Item = simObj_subset.Item(IsSelected);
            [StatusOK,Message,~,TheseResults] = simulationRunHelper(simObj,Pin,ParamNames, [], ItemModels, find(IsSelected));
        end
        if ~StatusOK
            error('plotOptimization: %s',Message);
        else
            Results = [Results; TheseResults]; %#ok<AGROW>
        end
    end
end

NumRuns = size(Results,1);
hSpeciesGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes, NumRuns);
hDatasetGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);



% Get the associated colors
SelectedItemColors = cell2mat(obj.PlotItemTable(IsSelected,2));


%% Plot Simulation Items

Show = [obj.PlotProfile.Show];
HighlightIdx = find(Show) == obj.SelectedProfileRow;
HighlightIdx = find(HighlightIdx);

for sIdx = 1:size(obj.PlotSpeciesTable,1)
    axIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
    ThisName = obj.PlotSpeciesTable{sIdx,3};    
    
    if ~isempty(axIdx) && ~isnan(axIdx) && ~isempty(Results)
        for runIdx = 1:NumRuns
            for itemIdx = 1:size(Results,2)
                % Plot the species from the simulation item in the appropriate
                % color
                
                if isempty(Results{runIdx,itemIdx})
                    continue
                end
                
                % Get the match in Sim 1 (Virtual Patient 1) in this VPop
                ColumnIdx = find(strcmp(Results{runIdx,itemIdx}.SpeciesNames,ThisName));
                
                % since not all tasks will contain all species...
                if ~isempty(ColumnIdx) && ~isempty(size(Results{1,1}.Data,2))
                    % Update ColumnIdx to get species for ALL virtual patients
                    NumSpecies = numel(Results{runIdx,itemIdx}.SpeciesNames);
                    ColumnIdx = ColumnIdx:NumSpecies:size(Results{runIdx,1}.Data,2);
                    
                    % Plot
                    if ~isempty(ColumnIdx)
                        if isempty(hSpeciesGroup{sIdx,axIdx,runIdx})
                            hSpeciesGroup{sIdx,axIdx,runIdx} = hggroup(hAxes(axIdx),...
                                'DisplayName',regexprep(ThisName,'_','\\_'),...
                                'HitTest','off');
                            % Add dummy line for legend
                            line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx,runIdx},...
                                'LineStyle',ThisLineStyle,...
                                'Color',[0 0 0]);
                        end
                        
                        % Apply thicker line width if needed
                        if runIdx == HighlightIdx
                            ThisLineWidth = 2;
                        else
                            ThisLineWidth = 0.5;
                        end
                        
                        % Plot
                        thisData = obj.SpeciesData(sIdx).evaluate(Results{runIdx,itemIdx}.Data(:,ColumnIdx));
                        hThis = plot(hSpeciesGroup{sIdx,axIdx,runIdx},Results{runIdx,itemIdx}.Time,thisData,...
                            'Color',SelectedItemColors(itemIdx,:),... 
                            'Visible', uix.utility.tf2onoff(Show(runIdx)),...
                            'LineStyle',ThisLineStyle,...
                            'LineWidth',ThisLineWidth,...
                            'HitTest','on',...
                            'Tag',num2str(runIdx));
                        set(get(get(hThis,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        
                        
                        %                     hSpeciesGroup{axIdx} = [hSpeciesGroup{axIdx} ...
                        %                         plot(hAxes(axIdx),Results{itemIdx}.Time,Results{itemIdx}.Data(:,ColumnIdx),...
                        %                         'Color',SelectedItemColors(itemIdx,:),...
                        %                         'DisplayName',regexprep(sprintf('%s Results (%d)',ThisName,itemIdx),'_','\\_'))];
                    end %if
                end %if
            end %for itemIdx
        end %for runIdx
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
                ThisName = obj.PlotSpeciesTable{dIdx,4};
                ColumnIdx = find(strcmp(OptimHeader,ThisName));
                
                if ~isempty(ColumnIdx) && ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn
                        MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx));
                        
                        % Create a group
                        if isempty(hDatasetGroup{dIdx,axIdx})
                            hDatasetGroup{dIdx,axIdx} = hggroup(hAxes(axIdx),...
                                'DisplayName',regexprep(ThisName,'_','\\_'),...
                                'HitTest','off');
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
                            'HitTest','off',...
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
    if size(hSpeciesGroup,3) > 0
        LegendItems = [horzcat(hSpeciesGroup{:,axIndex,1}) horzcat(hDatasetGroup{:,axIndex})];
    else
        LegendItems = [];
    end
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