function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotOptimization(obj,hAxes, varargin)
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

StatusOK = true;

%% Turn on hold

for index = 1:numel(hAxes)

    cla(hAxes(index));
    legend(hAxes(index),'off')

    set(hAxes(index),...
        'XLimMode',obj.PlotSettings(index).XLimMode,...
        'YLimMode',obj.PlotSettings(index).YLimMode);
    if strcmpi(obj.PlotSettings(index).XLimMode,'manual')        
        tmp = obj.PlotSettings(index).CustomXLim;
        if ischar(tmp), tmp = str2num(tmp); end         %#ok<ST2NM>
        set(hAxes(index),...
            'XLim',tmp);
    end
    if strcmpi(obj.PlotSettings(index).YLimMode,'manual')
        tmp = obj.PlotSettings(index).CustomYLim;
        if ischar(tmp), tmp = str2num(tmp); end         %#ok<ST2NM>
        set(hAxes(index),...
            'YLim',tmp);
    end
    
    hold(hAxes(index),'on')    
end

NumAxes = numel(hAxes);

rerunSims = true;
if ~isempty(varargin{1})
    rerunSims = cell2mat(varargin{1});
end

if nargin>3
    refreshAxes = varargin{2};
else
    refreshAxes = [];
end
    

%% Get the selections and Task-Vpop pairs

% Initialize
simObj = QSP.Simulation.empty(0,1);


% Get the selected items
OrigIsSelected = obj.PlotItemTable(:,1);
if iscell(OrigIsSelected)
    OrigIsSelected = cell2mat(OrigIsSelected);
end
OrigIsSelected = find(OrigIsSelected);

% Process all
IsSelected = 1:size(obj.PlotItemTable,1);

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
                if ~isempty(obj.VPopName)
                    % assign the vpop name
                    IndCell = strfind(obj.VPopName,['Group = ' ThisGroupName]);
                    NonEmpty = ~cellfun(@isempty, IndCell);
                    simObj.Item(ii).VPopName = obj.VPopName{NonEmpty};

                    % only 1 Vpop should match
                    if nnz(NonEmpty)>1
                        Message = 'Multiple Vpops share the same group.';
                        error('plotOptimization: %s',Message);
                    end
                end

                
            end
                
        else
            % in this case, there should only be one Vpop produced
            
            if length(obj.VPopName)>1
                Message = 'Expected there to be one Vpop produced by this optimization, but instead found 0 or more than 1.';
                error('plotOptimization: %s',Message);
            end
            % each task is assigned the same vpop
            for ii = 1:size(obj.PlotItemTable(:,1),1) %nSelected
                if ~isempty(obj.VPopName) && ~isempty(obj.VPopName{1}) && any(strcmp(obj.VPopName{1}, {obj.Settings.VirtualPopulation.Name}) )
                    simObj.Item(ii).VPopName = obj.VPopName{1};
                else
                    simObj.Item(ii).VPopName = QSP.Simulation.NullVPop;
                end
            end
            
        end

%     end
    
    % If Parameter is selected, then leave the Vpop names empty
% end


%% Run the simulations

ItemModels = obj.ItemModels;

% Loop through all profiles to be shown
ParamNames = cell(1,numel(obj.PlotProfile));
ParamValues = cell(1,numel(obj.PlotProfile));

for index = 1:numel(obj.PlotProfile)
    %         if ~obj.PlotProfile(index).Show
    %             continue
    %         end
    % TODO: Plot all profiles
    
    if ~isempty(obj.PlotProfile(index).Values)
        ParamNames{index} = obj.PlotProfile(index).Values(:,1);
        ParamValues{index} = obj.PlotProfile(index).Values(:,2);
        ixHasValue = ~cellfun(@isempty, obj.PlotProfile(index).Values(:,2));
        ParamNames{index} = ParamNames{index}(ixHasValue);
        ParamValues{index}= ParamValues{index}(ixHasValue);
    else
        ParamNames{index} = {};
        ParamValues{index} = {};
        continue
    end
    if iscell(ParamValues{index})
        %             tmp = cellfun(@str2num,ParamValues{index});
        isStr = cellfun(@ischar,ParamValues{index});
        ParamValues{index}(isStr) = num2cell(cellfun(@str2num, ParamValues{index}(isStr)));
        ParamValues{index} = cell2mat(ParamValues{index});
    end
end

if rerunSims && ~isempty(obj.PlotProfile) % need at least one profile
    [StatusOK,Message,~,Cancelled,Results,ItemModels] = simulationRunHelper(simObj,ParamValues,ParamNames,[],ItemModels,find(IsSelected));
    %         [StatusOK,Message,~,Results,ItemModels] = simulationRunHelper(simObj,ParamValues,ParamNames,[],[],find(IsSelected));
    
    obj.ItemModels = ItemModels;
    obj.Results = Results;
else
    StatusOK = true;
    Results = obj.Results; % cached results
end


NumRuns = size(Results,1);
hSpeciesGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes,NumRuns);
hDatasetGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);

if ~StatusOK && ~Cancelled
    hDlg = errordlg(Message,'Error on plot optimization','modal');
    uiwait(hDlg);
%     return
end


% Get the associated colors

try
    SelectedItemColors = cell2mat(obj.PlotItemTable(IsSelected,2));
catch thisError
    warning(thisError.message);
    return
end
    

%% Plot Simulation Items

Show = [obj.PlotProfile.Show];
HighlightIdx = find(Show) == obj.SelectedProfileRow;
HighlightIdx = find(HighlightIdx);

for sIdxIdx = 1:length(obj.SpeciesData) % 1:size(obj.PlotSpeciesTable,1)
    sIdx = find( strcmp(obj.SpeciesData(sIdxIdx).SpeciesName, obj.PlotSpeciesTable(:,3)) & ...
        strcmp(obj.SpeciesData(sIdxIdx).DataName, obj.PlotSpeciesTable(:,4)) );
    origAxIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    axIdx = origAxIdx;
    if isempty(axIdx) || isnan(axIdx)
        axIdx = 1;
    end
    
    ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
    ThisName = obj.PlotSpeciesTable{sIdx,3};   
    ThisDisplayName = obj.PlotSpeciesTable{sIdx,5};
    
    if ~isempty(axIdx) && ~isnan(axIdx) && ~isempty(Results) && (isempty(refreshAxes) || ismember(axIdx,refreshAxes))
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
                    ColumnIdx = ColumnIdx:NumSpecies:size(Results{runIdx,itemIdx}.Data,2);
                    
                    % Plot
                    if ~isempty(ColumnIdx)
                        if isempty(hSpeciesGroup{sIdx,axIdx,runIdx})
                            if isempty(origAxIdx) || isnan(origAxIdx)
                                ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
                            else
                                ThisParent = hAxes(axIdx);
                            end
                            hSpeciesGroup{sIdx,axIdx,runIdx} = hggroup(ThisParent,...
                                'Tag','Species',...
                                'DisplayName',regexprep(sprintf('%s [Sim]',ThisDisplayName),'_','\\_'),...
                                'UserData',[sIdx,runIdx],...
                                'HitTest','off');
                            % Add dummy line for legend
                            line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx,runIdx},...
                                'LineStyle',ThisLineStyle,...
                                'Color',[0 0 0],...
                                'Tag','DummyLine',...
                                'UserData',[sIdx,runIdx]);
                        end
                        
                        % Apply thicker line width if needed
                        if runIdx == HighlightIdx
                            ThisLineWidth = obj.PlotSettings(axIdx).LineWidth * 2;
                        else
                            ThisLineWidth = obj.PlotSettings(axIdx).LineWidth; % 0.5;
                        end
                        
                        % Plot
                        thisData = obj.SpeciesData(sIdx).evaluate(Results{runIdx,itemIdx}.Data(:,ColumnIdx));
                        hThis = plot(hSpeciesGroup{sIdx,axIdx,runIdx},Results{runIdx,itemIdx}.Time,thisData,...
                            'Color',SelectedItemColors(itemIdx,:),... 
                            'Visible', uix.utility.tf2onoff(Show(runIdx) && ismember(itemIdx,OrigIsSelected)),...
                            'LineStyle',ThisLineStyle,...
                            'LineWidth',ThisLineWidth,...
                            'HitTest','on',...
                            'UserData',[sIdx,itemIdx,runIdx],...
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
        
        % Ensure only one legend entry is added per run
        TheseGroups = hSpeciesGroup(sIdx,axIdx,:);
        if iscell(TheseGroups)
            TheseGroups = horzcat(TheseGroups{:});
        end
        if ~isempty(TheseGroups)
            % Take first group
            ch = TheseGroups(1).Children;
            ch = ch(~strcmpi(get(ch,'Tag'),'DummyLine'));
            ItemIndices = get(ch,'UserData');
            if iscell(ItemIndices)
                ItemIndices = cell2mat(ItemIndices);
            end
            ItemIndices = ItemIndices(:,2);
            for chIdx = 1:numel(ch)
                itemIdx = ItemIndices(chIdx);
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,5});
                set(ch(chIdx),'DisplayName',regexprep(sprintf('%s [Sim]',FullDisplayName),'_','\\_')); % For export, use patch since line width is not applied
            end
            
            % Turn off legend for the remaining items
            TheseAnnotations = get(TheseGroups,'Annotation');
            if iscell(TheseAnnotations)
                TheseAnnotations = horzcat(TheseAnnotations{:});
            end
            TheseAnnotationsInfo = get(TheseAnnotations,'LegendInformation');
            if iscell(TheseAnnotationsInfo)
                TheseAnnotationsInfo = horzcat(TheseAnnotationsInfo{:});
            end
            set(TheseAnnotationsInfo,'IconDisplayStyle','off');
        end
            
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
        
        %SelectedGroupColors = getGroupColors(obj.Session,sum(IsSelected));
        SelectedGroupIDs = categorical(obj.PlotItemTable(:,4));
        SelectedItemNames = obj.PlotItemTable(:,5);
        
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
            origAxIdx = str2double(obj.PlotSpeciesTable{dIdx,1});
            axIdx = origAxIdx;
            if isempty(axIdx) || isnan(axIdx)
                axIdx = 1;
            end
            ThisName = obj.PlotSpeciesTable{dIdx,4};
            ColumnIdx = find(strcmp(OptimHeader,ThisName));
            ThisDisplayName = obj.PlotSpeciesTable{dIdx,5};
            
            if ~isempty(ColumnIdx) % && ~isempty(axIdx) && ~isnan(axIdx)
                for gIdx = 1:numel(SelectedGroupIDs)
                    
                    if obj.PlotItemTable{gIdx,1} % ismember(gIdx,OrigIsSelected)
                        IsVisible = true;
                    else
                        IsVisible = false;
                    end
                    
                    % Find the GroupID match within the GroupColumn
                    MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx));
                    
                    % Create a group
                    if isempty(hDatasetGroup{dIdx,axIdx})
                        % Un-parent if not-selected
                        if isempty(origAxIdx) || isnan(origAxIdx)
                            ThisParent = matlab.graphics.GraphicsPlaceholder.empty();
                        else
                            ThisParent = hAxes(axIdx);
                        end
                        
                        hDatasetGroup{dIdx,axIdx} = hggroup(ThisParent,...
                            'Tag','Data',...
                            'DisplayName',regexprep(sprintf('%s [Data]',ThisDisplayName),'_','\\_'),...
                            'UserData',dIdx,...
                            'HitTest','off');
                        set(get(get(hDatasetGroup{dIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
                        % Add dummy line for legend
                        line(nan,nan,'Parent',hDatasetGroup{dIdx,axIdx},...
                            'LineStyle','none',...
                            'Marker',ThisMarker,...
                            'Tag','DummyLine',...
                            'Color',[0 0 0],...
                            'UserData',dIdx);
                    end
                    
                    FullDisplayName = sprintf('%s %s',ThisDisplayName,SelectedItemNames{gIdx});
                    
                    % Plot but remove from the legend
                    hThis = plot(hDatasetGroup{dIdx,axIdx},TimeColumn(MatchIdx),cell2mat(OptimData(MatchIdx,ColumnIdx)),...
                        'Color',SelectedItemColors(gIdx,:),...
                        'LineStyle','none',...
                        'Marker',ThisMarker,...
                        'MarkerSize',obj.PlotSettings(axIdx).DataSymbolSize,...
                        'UserData',[dIdx,gIdx],...
                        'HitTest','off',...
                        'DisplayName',regexprep(sprintf('%s [Data]',FullDisplayName),'_','\\_')); % For export % 'DisplayName',regexprep(ThisName,'_','\\_'));
                    set(get(get(hThis,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                    set(hThis,'Visible',uix.utility.tf2onoff(IsVisible));
                    
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
        
    end %if StatusOk
end %if any


%% Legend

% Force a drawnow, to avoid legend issues
drawnow;

[hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup);


%% Turn off hold

for index = 1:numel(hAxes)
    title(hAxes(index),obj.PlotSettings(index).Title,...
        'FontSize',obj.PlotSettings(index).TitleFontSize,...
        'FontWeight',obj.PlotSettings(index).TitleFontWeight); % sprintf('Plot %d',index));
    xlabel(hAxes(index),obj.PlotSettings(index).XLabel,...
        'FontSize',obj.PlotSettings(index).XLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).XLabelFontWeight); % 'Time');
    ylabel(hAxes(index),obj.PlotSettings(index).YLabel,...
        'FontSize',obj.PlotSettings(index).YLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).YLabelFontWeight); % 'States');
    set(hAxes(index),...
        'XGrid',obj.PlotSettings(index).XGrid,...
        'YGrid',obj.PlotSettings(index).YGrid,...
        'XMinorGrid',obj.PlotSettings(index).XMinorGrid,...
        'YMinorGrid',obj.PlotSettings(index).YMinorGrid);
    set(hAxes(index).XAxis,...
        'FontSize',obj.PlotSettings(index).XTickLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).XTickLabelFontWeight);    
    set(hAxes(index).YAxis,...
        'FontSize',obj.PlotSettings(index).YTickLabelFontSize,...
        'FontWeight',obj.PlotSettings(index).YTickLabelFontWeight);
    set(hAxes(index),'YScale',obj.PlotSettings(index).YScale);
    
    hold(hAxes(index),'off')
     % Reset zoom state
    hFigure = ancestor(hAxes(index),'Figure');
    if ~isempty(hFigure) && strcmpi(obj.PlotSettings(index).XLimMode,'auto') && strcmpi(obj.PlotSettings(index).YLimMode,'auto')
        set(hFigure,'CurrentAxes',hAxes(index)) % This causes the legend fontsize to reset: axes(hAxes(index));
        try
            zoom(hFigure,'out');
            zoom(hFigure,'reset');        
        catch ME
            warning(ME.message);
        end
    end
end
