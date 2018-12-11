function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotSimulation(obj,hAxes)
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
%     XLimMode{index} = get(hAxes(index),'XLimMode');
%     YLimMode{index} = get(hAxes(index),'YLimMode');
    cla(hAxes(index));
    legend(hAxes(index),'off')    
%     set(hAxes(index),'XLimMode',XLimMode{index},'YLimMode',YLimMode{index})
    set(hAxes(index),...
        'XLimMode',obj.PlotSettings(index).XLimMode,...
        'YLimMode',obj.PlotSettings(index).YLimMode);
    if strcmpi(obj.PlotSettings(index).XLimMode,'manual')
        set(hAxes(index),...
            'XLim',obj.PlotSettings(index).CustomXLim);
    end
    if strcmpi(obj.PlotSettings(index).YLimMode,'manual')
        set(hAxes(index),...
            'YLim',obj.PlotSettings(index).CustomYLim);
    end
    
    hold(hAxes(index),'on')        
end

NumAxes = numel(hAxes);
hSpeciesGroup = cell(size(obj.PlotSpeciesTable,1),NumAxes);
hDatasetGroup = cell(size(obj.PlotDataTable,1),NumAxes);


%% Get the selections and MATResultFilePaths

% Get the selected items
IsSelected = obj.PlotItemTable(:,1);
if iscell(IsSelected)
    IsSelected = cell2mat(IsSelected);
end
IsSelected = find(IsSelected);

TaskNames = {obj.Item.TaskName};
VPopNames = {obj.Item.VPopName};
if ~isempty(IsSelected)
    MATFileNames = {};
    for index = IsSelected(:)'
        % Find the match of obj.PlotItemTable back in obj.Item
        ThisTaskName = obj.PlotItemTable{index,3};
        ThisVPopName = obj.PlotItemTable{index,4};
        ThisTask = getValidSelectedTasks(obj.Settings,ThisTaskName);
        ThisVPop = getValidSelectedVPops(obj.Settings,ThisVPopName);        
        
        if ~isempty(ThisTask) && (~isempty(ThisVPop) || strcmp(ThisVPopName,QSP.Simulation.NullVPop))
            MatchIdx = strcmp(ThisTaskName,TaskNames) & strcmp(ThisVPopName,VPopNames);
            if any(MatchIdx)
                ThisFileName = {obj.Item(MatchIdx).MATFileName};
                MATFileNames = [MATFileNames,ThisFileName]; %#ok<AGROW>
            end
        end
    end
    ResultsDir = fullfile(obj.Session.RootDirectory,obj.SimResultsFolderName);
    MATResultFilePaths = cellfun(@(X) fullfile(ResultsDir,X), MATFileNames, 'UniformOutput', false);
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
        fprintf('plotSimulation: Missing results file %s\n',MATResultFilePaths{index});
    end
end

% Get the associated colors

garbage = ~cellfun(@isnumeric,obj.PlotItemTable(IsSelected,2));
colors = obj.PlotItemTable(IsSelected,2);
colors(garbage,:) = {[0 0 0]};
SelectedItemColors = cell2mat(colors);


%% Plot Simulation Items
     
for sIdx = 1:size(obj.PlotSpeciesTable,1)
    axIdx = str2double(obj.PlotSpeciesTable{sIdx,1});
    ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
    ThisName = obj.PlotSpeciesTable{sIdx,3};
    ThisDisplayName = obj.PlotSpeciesTable{sIdx,4};
    if ~isempty(axIdx) && ~isnan(axIdx)
        for itemIdx = 1:numel(Results)
            % Plot the species from the simulation item in the appropriate
            % color
            
            FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,5});
            % Get the match in Sim 1 (Virtual Patient 1) in this VPop
            ColumnIdx = find(strcmp(Results(itemIdx).SpeciesNames,ThisName), 1); % keep only first in case of duplicate
            if isempty(ColumnIdx), continue, end
            
            % Update ColumnIdx to get species for ALL virtual patients
            NumSpecies = numel(Results(itemIdx).SpeciesNames);
            if ~isempty(Results(itemIdx).VpopWeights)
                ColumnIdx = ColumnIdx + (find(Results(itemIdx).VpopWeights)-1)*NumSpecies ;
            else
                ColumnIdx = ColumnIdx:NumSpecies:size(Results(itemIdx).Data,2);
            end
            
            if isempty(hSpeciesGroup{sIdx,axIdx})
                hSpeciesGroup{sIdx,axIdx} = hggroup(hAxes(axIdx),...
                    'Tag','Species',...
                    'DisplayName',regexprep(ThisDisplayName,'_','\\_')); 
                set(get(get(hSpeciesGroup{sIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
                % Add dummy line for legend
                line(nan,nan,'Parent',hSpeciesGroup{sIdx,axIdx},...
                    'LineStyle',ThisLineStyle,...
                    'Color',[0 0 0],...
                    'Tag','DummyLine');
            end
            
            % Plot
            if ~isnumeric(SelectedItemColors(itemIdx,:))
                error('Invalid color selected!')                
            end
            
            thisTraceAnnotation = [];
            thisQuantileAnnotation = [];
            hThisTrace = [];
            SE = [];
            
            if obj.bShowTraces(axIdx)
                hThisTrace = plot(hSpeciesGroup{sIdx,axIdx},Results(itemIdx).Time,Results(itemIdx).Data(:,ColumnIdx),...
                    'Color',SelectedItemColors(itemIdx,:),...
                    'LineStyle',ThisLineStyle,...
                    'LineWidth',obj.PlotSettings(axIdx).LineWidth);
                thisTraceAnnotation = get(hThisTrace,'Annotation');
            end
            
            if obj.bShowQuantiles(axIdx)
                axes(get(hSpeciesGroup{sIdx,axIdx},'Parent'))
%                 q50 = quantile(Results(itemIdx).Data(:,ColumnIdx),0.5,2);
%                 q75 = quantile(Results(itemIdx).Data(:,ColumnIdx),0.75,2);
%                 q25 = quantile(Results(itemIdx).Data(:,ColumnIdx),0.25,2);
               
                w0 = Results(itemIdx).VpopWeights;
                w0 = w0(w0>0); % filter out the zero weight simulations
                if isempty(w0)
                    w0 = ones(1, size(Results(itemIdx).Data,2)/length(Results(itemIdx).SpeciesNames));
                end
                w0 = w0./sum(w0); % renormalization

%                 NT = size(Results(itemIdx).Data,1);
%                 q50 = zeros(1,NT);
%                 q025 = zeros(1,NT);
%                 q975 = zeros(1,NT);
%                 for tIdx = 1:NT
%                     y = Results(itemIdx).Data(tIdx,ColumnIdx);
%                     [y,ix] = sort(y, 'Ascend');
%                     w = w0(ix);
%                     q50(tIdx) = y(find(cumsum(w)>=0.5, 1, 'first'));
%                     q025(tIdx) = y(find(cumsum(w)>=0.025, 1, 'first'));
%                     idx975 = find(cumsum(w)>=0.975, 1, 'first');
%                     if isempty(idx975)
%                         idx975 = length(y);
%                     end
%                     q975(tIdx) = y(idx975);
%                     
%                 end


                
%                 Results(itemIdx).Data
                
                if length(Results(itemIdx).Time') > 1
%                     SE=shadedErrorBar(Results(itemIdx).Time', q50, [q975-q50;q50-q025]);
%                     set(SE.mainLine,'Color',SelectedItemColors(itemIdx,:),...
%                         'LineStyle',ThisLineStyle);
%                     set(SE.patch,'FaceColor',SelectedItemColors(itemIdx,:));
%                     set(SE.edge,'Color',SelectedItemColors(itemIdx,:),'LineWidth',2);
                    x = Results(itemIdx).Data(:,ColumnIdx);
                    SE = weightedQuantilePlot(Results(itemIdx).Time, x, w0, SelectedItemColors(itemIdx,:), ...
                        'linestyle',ThisLineStyle,...
                        'meanlinewidth',obj.PlotSettings(axIdx).MeanLineWidth,...
                        'boundarylinewidth',obj.PlotSettings(axIdx).BoundaryLineWidth,...
                        'parent',hSpeciesGroup{sIdx,axIdx});
                    thisQuantileAnnotation = get([SE.mainLine,SE.edge,SE.patch],'Annotation');                    
                else
                    % NOTE: Justin - code does not enter here (i.e. q50,
                    % etc are not computed)
                    h = errorbar(Results(itemIdx).Time', q50', q50-q025, q975-q50, 'Color', SelectedItemColors(itemIdx,:), ...
                        'LineStyle',ThisLineStyle);
                    thisQuantileAnnotation = get(h,'Annotation');
                end
            end
            
            % Only allow one display name between traces and quantiles
            FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
            if obj.bShowTraces(axIdx)
                set(hThisTrace(1),'DisplayName',FormattedFullDisplayName);                
            elseif ~isempty(SE) && isstruct(SE) && isfield(SE,'patch')
                set(SE.patch,'DisplayName',FormattedFullDisplayName);
            end
            
            
            % Process this trace
            if iscell(thisTraceAnnotation)
                thisLegendInformation = get([thisTraceAnnotation{:}],'LegendInformation');
            else
                thisLegendInformation = get(thisTraceAnnotation,'LegendInformation');
            end
            if iscell(thisLegendInformation)
                set([thisLegendInformation{:}],'IconDisplayStyle','off');
            else
                set(thisLegendInformation,'IconDisplayStyle','off');
            end
            
            % Process this quantile
            if iscell(thisQuantileAnnotation)
                thisLegendInformation = get([thisQuantileAnnotation{:}],'LegendInformation');
            else
                thisLegendInformation = get(thisQuantileAnnotation,'LegendInformation');
            end
            if iscell(thisLegendInformation)
                set([thisLegendInformation{:}],'IconDisplayStyle','off');
            else
                set(thisLegendInformation,'IconDisplayStyle','off');
            end

        end %for itemIdx = 1:numel(Results)
    end %if ~isempty
end %for sIdx = 1:size(obj.PlotSpeciesTable,1)


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
            Time = OptimData(:,strcmp(OptimHeader,'Time'));
            
            for dIdx = 1:size(obj.PlotDataTable,1)
                axIdx = str2double(obj.PlotDataTable{dIdx,1});
                ThisMarker = obj.PlotDataTable{dIdx,2};
                ThisName = obj.PlotDataTable{dIdx,3};
                ThisDisplayName = obj.PlotDataTable{dIdx,4};
                
                ColumnIdx = find(strcmp(OptimHeader,ThisName));
                
                if ~isempty(ColumnIdx) && ~isempty(axIdx) && ~isnan(axIdx)
                    for gIdx = 1:numel(SelectedGroupIDs)
                        % Find the GroupID match within the GroupColumn
                        MatchIdx = (GroupColumn == SelectedGroupIDs(gIdx));
                        
                        % Create a group
                        if isempty(hDatasetGroup{dIdx,axIdx})
                            hDatasetGroup{dIdx,axIdx} = hggroup(hAxes(axIdx),...
                                'Tag','Data',...
                                'DisplayName',regexprep(ThisDisplayName,'_','\\_'));
                            set(get(get(hDatasetGroup{dIdx,axIdx},'Annotation'),'LegendInformation'),'IconDisplayStyle','on')
                            % Add dummy line for legend
                            line(nan,nan,'Parent',hDatasetGroup{dIdx,axIdx},...
                                'LineStyle','none',...
                                'Marker',ThisMarker,...
                                'Tag','DummyLine',...
                                'Color',[0 0 0]);
                        end

                        % Plot but remove from the legend
                        hThis = plot(hDatasetGroup{dIdx,axIdx},cell2mat(Time(MatchIdx)),cell2mat(OptimData(MatchIdx,ColumnIdx)),...
                            'Color',SelectedGroupColors(gIdx,:),...
                            'LineStyle','none',...
                            'Marker',ThisMarker,...
                            'MarkerSize',obj.PlotSettings(axIdx).DataSymbolSize,...
                            'DisplayName',regexprep(sprintf('%s %s',ThisDisplayName,SelectedGroupIDs(gIdx)),'_','\\_')); % For export
                        set(get(get(hThis,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                            
                    end %for gIdx
                end %if
            end %for dIdx
        end %if any(IsSelected)
    end %if StatusOk
end %if any(MatchIdx)


%% Legend
drawnow

[hLegend,hLegendChildren] = redrawLegend(obj,hAxes,hSpeciesGroup,hDatasetGroup);


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
        axes(hAxes(index));
        try
            zoom(hFigure,'out');
            zoom(hFigure,'reset');        
        catch ME
            warning(ME.message);
        end        
    end
end
