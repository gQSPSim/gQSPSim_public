function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updatePlots - Redraws the legend
% -------------------------------------------------------------------------
% Abstract: Redraws the legend
%
% Syntax:
%           updatePlots(aObj,hAxes)
%
% Inputs:
%           obj - QSP.Simulation object
%
%           hSpeciesGroup
%
%           hDatasetGroup
%
% Outputs:
%           hLegend
%
%           hLegendChildren
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

NumAxes = numel(hAxes);
hLegend = cell(1,NumAxes);
hLegendChildren = cell(1,NumAxes);

p = inputParser;
p.KeepUnmatched = false;

% Define defaults and requirements for each parameter
p.addParameter('AxIndices',1:NumAxes); %#ok<*NVREPL>
p.addParameter('RedrawLegend',true);

p.parse(varargin{:});

AxIndices = p.Results.AxIndices;
RedrawLegend = p.Results.RedrawLegend;


for axIndex = AxIndices(:)'
    
    
    %---------------------------------------------------------------------%
    % Process Species Group
    %---------------------------------------------------------------------%
    
    ItemIndices = cell2mat(obj.PlotItemTable(:,1));
    VisibleItemIndices = find(ItemIndices);
    InvisibleItemIndices = find(~ItemIndices);
    
    % Get all children
    TheseSpeciesGroups = [hSpeciesGroup{:,axIndex}];

    try
        ch = get(TheseSpeciesGroups,'Children');
        if iscell(ch)
            ch = vertcat(ch{:});
        end
    catch err      
        warning(err.message)
        return
    end
    
    % Set SpeciesGroup - DisplayName
    SelectedUserData = get(TheseSpeciesGroups,'UserData'); % Just sIdx
    if iscell(SelectedUserData)
        SelectedUserData = vertcat(SelectedUserData{:});
    end
    TheseItems = TheseSpeciesGroups;
    for thisIdx = 1:numel(TheseItems)
        sIdx = SelectedUserData(thisIdx);
        FormattedFullDisplayName = regexprep(obj.PlotSpeciesTable{sIdx,4},'_','\\_'); % For export, use patch since line width is not applied
        set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);
    end
    
    
    if ~isempty(ch)
        % Set DummyLine - LineStyle for UI
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
        TheseDummyLines = ch(IsDummyLine);
        SelectedUserData = get(TheseDummyLines,'UserData'); % Just sIdx
        if iscell(SelectedUserData)
            SelectedUserData = vertcat(SelectedUserData{:});
        end
        for thisIdx = 1:numel(TheseDummyLines)
            sIdx = SelectedUserData(thisIdx);
            ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
            set(TheseDummyLines(thisIdx),'LineStyle',ThisLineStyle);
        end
        
        
        % Get all Traces and Quantiles
        TheseChildren = ch(~IsDummyLine);
        ChildrenUserData = get(TheseChildren,'UserData');
        if iscell(ChildrenUserData)
            ChildrenUserData = vertcat(ChildrenUserData{:});
        end
        
        IsItemVisible = ismember(ChildrenUserData(:,2),VisibleItemIndices);
        
        IsTrace = strcmpi(get(TheseChildren,'Tag'),'TraceLine');
        chTrace = TheseChildren(IsTrace);
        chTraceVisible = TheseChildren(IsTrace & IsItemVisible);
        
        IsQuantile = strcmpi(get(TheseChildren,'Tag'),'MeanLine');
        chQuantile = TheseChildren(IsQuantile);
        chQuantileVisible = TheseChildren(IsQuantile & IsItemVisible);
        
        IsBoundaryLine = strcmpi(get(TheseChildren,'Tag'),'BoundaryLine');
        chIsBoundaryLine = TheseChildren(IsBoundaryLine);
        chIsBoundaryLineVisible = TheseChildren(IsBoundaryLine & IsItemVisible);
        
        IsBoundaryPatch = strcmpi(get(TheseChildren,'Tag'),'BoundaryPatch');
        chBoundaryPatch = TheseChildren(IsBoundaryPatch);
        chBoundaryPatchVisible = TheseChildren(IsBoundaryPatch & IsItemVisible);
        
        
        % Toggle Visibility for items based on ShowTraces, ShowQuantiles, and
        % Selected/Unselected items
        if obj.bShowTraces(axIndex)
            set(chTraceVisible,'Visible','on')
        else
            set(chTrace,'Visible','off')
        end
        if obj.bShowQuantiles(axIndex)
            set(chQuantileVisible,'Visible','on')
            set(chIsBoundaryLineVisible,'Visible','on')
            set(chBoundaryPatchVisible,'Visible','on')
        else
            set(chQuantile,'Visible','off')
            set(chIsBoundaryLine,'Visible','off')
            set(chBoundaryPatch,'Visible','off')
        end
        MatchIdx = ismember(ChildrenUserData(:,2),InvisibleItemIndices);
        TheseMatches = TheseChildren(MatchIdx);
        set(TheseMatches,'Visible','off')
        
        
        % Update Display Name and LineStyles for Children of SpeciesGroup
        
        % Turn off displayname for all traces and quantiles
        set(chTrace,'DisplayName','');
        set(chQuantile,'DisplayName','');
        
        % Get one type of child - either trace OR quantile
        TheseItems = [];
        if obj.bShowTraces(axIndex) && ~isempty(chTrace)
            % Process trace to only set ONE display name per unique entry
            TheseItems = chTrace;
            
        elseif ~obj.bShowTraces(axIndex) && ~isempty(chQuantile)
            % Process quantile to only set ONE display name per unique entry
            TheseItems = chQuantile;
        end
        
        % Process species related content
        if ~isempty(TheseItems)
            
            % Get user data
            SelectedUserData = get(TheseItems,'UserData'); % Just [sIdx,itemIdx]
            if iscell(SelectedUserData)
                SelectedUserData = vertcat(SelectedUserData{:});
            end
            % Find only unique entries (by [sIdx, itemIdx] combinations)
            [~,UniqueIdx] = unique(SelectedUserData,'rows');
            
            for thisIdx = UniqueIdx(:)'
                % Extract sIdx and itemIdx from UserData
                ThisUserData = SelectedUserData(thisIdx,:);
                sIdx = ThisUserData(1);
                itemIdx = ThisUserData(2);
                
                % Now create formatted display name
                ThisDisplayName = obj.PlotSpeciesTable{sIdx,4};
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotItemTable{itemIdx,6});
                FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
                
                % Get line style
                ThisLineStyle = obj.PlotSpeciesTable{sIdx,2};
                % Set display name for selection only
                set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName,'LineStyle',ThisLineStyle);
            end
        end
    end %if ~isempty(ch)
    
    %---------------------------------------------------------------------%
    % Process Data Group
    %---------------------------------------------------------------------%
    
    % Get all children
    TheseDataGroups = [hDatasetGroup{:,axIndex}];
    ch = get(TheseDataGroups,'Children');
    if iscell(ch)
        ch = vertcat(ch{:});
    end
    
    % Set DataGroup - DisplayName
    SelectedUserData = get(TheseDataGroups,'UserData'); % Just dIdx
    if iscell(SelectedUserData)
        SelectedUserData = vertcat(SelectedUserData{:});
    end
    TheseItems = TheseDataGroups;
    for thisIdx = 1:numel(TheseItems)
        dIdx = SelectedUserData(thisIdx);
        FormattedFullDisplayName = regexprep(obj.PlotDataTable{dIdx,4},'_','\\_'); % For export, use patch since line width is not applied
        set(TheseItems(thisIdx),'DisplayName',FormattedFullDisplayName);
    end
    
    if ~isempty(ch)
        
        % Set DummyLine - MarkerStyle
        IsDummyLine = strcmpi(get(ch,'Tag'),'DummyLine');
        TheseDummyLines = ch(IsDummyLine);
        SelectedUserData = get(TheseItems,'UserData'); % Just sIdx
        if iscell(SelectedUserData)
            SelectedUserData = vertcat(SelectedUserData{:});
        end
        for thisIdx = 1:numel(TheseDummyLines)
            dIdx = SelectedUserData(thisIdx);
            ThisMarkerStyle = obj.PlotDataTable{dIdx,2};
            set(TheseDummyLines(thisIdx),'Marker',ThisMarkerStyle);
        end
        
        TheseChildren = ch(~IsDummyLine);
        
        % Process dataset related content
        if ~isempty(TheseChildren)
            
            % Get user data
            SelectedUserData = get(TheseChildren,'UserData'); % Just [sIdx,itemIdx]
            if iscell(SelectedUserData)
                SelectedUserData = vertcat(SelectedUserData{:});
            end
            % Find only unique entries (by [sIdx, itemIdx] combinations)
            [~,UniqueIdx] = unique(SelectedUserData,'rows');
            
            for thisIdx = UniqueIdx(:)'
                % Extract sIdx and itemIdx from UserData
                ThisUserData = SelectedUserData(thisIdx,:);
                dIdx = ThisUserData(1);
                itemIdx = ThisUserData(2);
                
                % Now create formatted display name
                ThisDisplayName = obj.PlotDataTable{dIdx,4};
                FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.PlotGroupTable{itemIdx,4});
                FormattedFullDisplayName = regexprep(FullDisplayName,'_','\\_'); % For export, use patch since line width is not applied
                
                % Get marker style
                ThisMarkerStyle = obj.PlotDataTable{dIdx,2};
                % Set display name for selection only
                set(TheseChildren(thisIdx),'DisplayName',FormattedFullDisplayName,'Marker',ThisMarkerStyle);
            end
            
            % Toggle visibility
            ItemIndices = cell2mat(obj.PlotGroupTable(:,1));
            VisibleItemIndices = find(ItemIndices);
            InvisibleItemIndices = find(~ItemIndices);
            
            % Set visible on
            MatchIdx = ismember(SelectedUserData(:,2),VisibleItemIndices);
            set(TheseChildren(MatchIdx),'Visible','on');
            % Set visible off
            MatchIdx = ismember(SelectedUserData(:,2),InvisibleItemIndices);
            set(TheseChildren(MatchIdx),'Visible','off');
            
        end
    end %if ~isempty(ch)
    
    
    % Append
    LegendItems = [horzcat(hSpeciesGroup{:,axIndex}) horzcat(hDatasetGroup{:,axIndex})];
    
    if RedrawLegend
        
        % Filter based on what is plotted (non-empty parent) and what is
        % valid
        if ~isempty(LegendItems)
            HasParent = ~cellfun(@isempty,{LegendItems.Parent});
            IsValid = isvalid(LegendItems);
            LegendItems = LegendItems(HasParent & IsValid);
        else
            LegendItems = [];
        end
        
        if ~isempty(LegendItems)
            try 
                % Add legend
                [hLegend{axIndex},hLegendChildren{axIndex}] = legend(hAxes(axIndex),LegendItems);
                
                % Color, FontSize, FontWeight
                for cIndex = 1:numel(hLegendChildren{axIndex})
                    if isprop(hLegendChildren{axIndex}(cIndex),'FontSize')
                        hLegendChildren{axIndex}(cIndex).FontSize = obj.PlotSettings(axIndex).LegendFontSize;
                    end
                    if isprop(hLegendChildren{axIndex}(cIndex),'FontWeight')
                        hLegendChildren{axIndex}(cIndex).FontWeight = obj.PlotSettings(axIndex).LegendFontWeight;
                    end
                end
                
                set(hLegend{axIndex},...
                    'EdgeColor','none',...
                    'Visible',obj.PlotSettings(axIndex).LegendVisibility,...
                    'Location',obj.PlotSettings(axIndex).LegendLocation,...
                    'FontSize',obj.PlotSettings(axIndex).LegendFontSize,...
                    'FontWeight',obj.PlotSettings(axIndex).LegendFontWeight);
            catch ME
                warning('Cannot draw legend')
            end
        else
            Siblings = get(get(hAxes(axIndex),'Parent'),'Children');
            IsLegend = strcmpi(get(Siblings,'Type'),'legend');
            
            if any(IsLegend)
                if isvalid(Siblings(IsLegend))
                    delete(Siblings(IsLegend));
                end
            end
            
            hLegend{axIndex} = [];
            hLegendChildren{axIndex} = [];
        end
    end %if RedrawLegend
end %for axIndex