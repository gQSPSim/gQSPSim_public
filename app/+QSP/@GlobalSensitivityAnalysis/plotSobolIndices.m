function [hLines,hLegend,hLegendChildren] = plotSobolIndices(obj,hAxes)
% plotSobolIndices - plots the Sobol indices of a global sensitivity analysis
% -------------------------------------------------------------------------
% Abstract: This plots the Sobol indices of a global sensitivity analysis.
%
% Syntax:
%           plotSobolIndices(Obj,hAxes)
%
% Inputs:
%           obj - QSP.GlobalSensitivityAnalysis object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2020 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks 
%   $Author: faugusti $
%   $Revision: 1 $  $Date: 2020-11-13 16:56$
% ---------------------------------------------------------------------

    %% Turn on hold
    numAxes = numel(hAxes);
    for index = 1:numAxes
        cla(hAxes(index));
        legend(hAxes(index),'off')    

        hold(hAxes(index),'on')        
    end

    hLines = cell(1,2);
    hLegend = [];
    hLegendChildren = [];
    maxXLim = zeros(1,numAxes);
    minXLim = inf(1,numAxes);
    axContainsVariancePlot = false(1,numAxes);
    mode = cell(1, numAxes);

    % Store plot labels : text and color
    plotLabelInfo  = cell(2,numAxes);
    % Store mean bar height in bar plots for multiple tasks
    meanStatistics = cell(numAxes, numel(obj.PlotInputs)*numel(obj.PlotOutputs));
    
    %% Plot Simulation Items

    for tableIdx = 1:numel(obj.PlotSobolIndex)
        
        axIdx = str2double(obj.PlotSobolIndex(tableIdx).Plot);
        if ~any([obj.Item.Include]) || isnan(axIdx)
            continue;
        end
        
        output    = obj.PlotSobolIndex(tableIdx).Output;
        input     = obj.PlotSobolIndex(tableIdx).Input;
        lineStyle = obj.PlotSobolIndex(tableIdx).Style;
        display   = obj.PlotSobolIndex(tableIdx).Display;

        [~, inputIdx]  = ismember(input, obj.PlotInputs);

        xIdx = numel(plotLabelInfo{1,axIdx})+1;
        currentLabel =  display;
        if isempty(currentLabel)
            currentLabel = [output, '/', input, ' (', obj.PlotSobolIndex(tableIdx).Type, ')';];
        end
        plotLabelInfo{1, axIdx} = [plotLabelInfo{1, axIdx}, {currentLabel}];
        mode{axIdx} = obj.PlotSobolIndex(tableIdx).Mode;
        
        for itemIdx = 1:numel(obj.Item)

            if ~obj.Item(itemIdx).Include || isempty(obj.Item(itemIdx).Results)
                continue;
            end

            task = obj.getObjectsByName(obj.Settings.Task, obj.Item(itemIdx).TaskName);
            [tfOutputExists, outputIdx] = ismember(output, task.ActiveSpeciesNames);

            if ~tfOutputExists
                continue;
            end
            
            if isempty(plotLabelInfo{2, axIdx})
                plotLabelInfo{2, axIdx} = obj.Item(itemIdx).Color;
            else
                plotLabelInfo{2, axIdx} = [0,0,0];
            end
            
            % All times are equal, so just get the first time vector.
            time = obj.Item(itemIdx).Results(1).Time; 

            numResults = numel(obj.Item(itemIdx).Results);
            
            if strcmp(mode{axIdx}, 'convergence')
                resultsRange = 1:numResults;
            else
                resultsRange = numResults;
            end
            
            resultsCounter = 0;
            results = cell(1, numel(resultsRange));
            for i = resultsRange
                resultsCounter = resultsCounter + 1;
                switch obj.PlotSobolIndex(tableIdx).Type
                    case 'unexpl. frac.'
                        results{resultsCounter} = 1;
                        for j = 1:numel(obj.PlotInputs)
                            results{resultsCounter} = results{resultsCounter} - ...
                                reshape(obj.Item(itemIdx).Results(i).SobolIndices(j,outputIdx).FirstOrder, 1, []);
                        end
                    case 'variance'
                        results{resultsCounter} = obj.Item(itemIdx).Results(i).Variances{:,outputIdx};
                        axContainsVariancePlot(axIdx) = true;
                    case 'first order'
                        results{resultsCounter} = obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).FirstOrder;
                    case 'total order'
                        results{resultsCounter} = obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).TotalOrder;
                end
            end
            if strcmp(mode{axIdx}, 'time course')
                hLine = plot(hAxes(axIdx), time, results{1}, ...
                    'Color', obj.Item(itemIdx).Color, ...
                    'LineStyle', lineStyle);      
                maxXLim(axIdx) = max(time);
            elseif strcmp(mode{axIdx}, 'bar plot')
                barValue = getBarValue(obj, results{1});
                scatter(hAxes(axIdx), xIdx, barValue, 100, 'd', ...
                    'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                    'MarkerFaceColor', obj.Item(itemIdx).Color);
                if i == resultsRange(end)
                    meanStatistics{axIdx, xIdx} = ...
                    [meanStatistics{axIdx, xIdx}, barValue];
                end
                maxXLim(axIdx) = max(maxXLim(axIdx), xIdx);
            else
                for i = resultsRange 
                    barValue(i) = getBarValue(obj, results{i});
                end
                plot(hAxes(axIdx), [obj.Item(itemIdx).Results.NumberSamples], barValue, ...
                    'LineStyle', lineStyle, ...
                    'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                    'MarkerFaceColor', obj.Item(itemIdx).Color, ...
                    'Color', obj.Item(itemIdx).Color);
                maxXLim(axIdx) = max(maxXLim(axIdx), obj.Item(itemIdx).Results(end).NumberSamples);
                minXLim(axIdx) = min(minXLim(axIdx), obj.Item(itemIdx).Results(1).NumberSamples);
            end
            
        end                
    end 
    
	for axIdx = 1:numAxes
        
        if isempty(mode{axIdx})
            continue;
        end
        
        for idx = 1:numel(obj.PlotInputs)*numel(obj.PlotOutputs)
            if isempty(meanStatistics{axIdx, idx})
                break;
            end
            meanValue = mean(meanStatistics{axIdx, idx});
            width = 0.3;
            color = [0.8, 0.8, 0.8];
            hMeanBar = fill(hAxes(axIdx), idx+[-width,width,width,-width]/2, [0, 0, meanValue, meanValue], ...
                color, 'FaceColor', color, 'FaceAlpha', 0.25, 'EdgeColor', color);
            tf = hMeanBar == hAxes(axIdx).Children;
            hAxes(axIdx).Children = [hAxes(axIdx).Children(~tf); hAxes(axIdx).Children(tf)];
        end
            
        if strcmp(mode{axIdx}, 'time course')
            yLimValues = [-0.1, 1.1];
            xLimValues = [0, max(maxXLim(axIdx),1)];
            if ~axContainsVariancePlot(axIdx)
                plot(hAxes(axIdx),xLimValues,[0, 0],'k:');
                plot(hAxes(axIdx),xLimValues,[1, 1],'k:');
            end
            set(hAxes(axIdx), 'XTickMode', 'auto', 'XTickLabelMode', 'auto');            
        elseif strcmp(mode{axIdx}, 'bar plot')
            if axContainsVariancePlot(axIdx)
                currentYLim = get(hAxes(axIdx),'YLim');
                yLimValues = [-0.025, currentYLim(2)];
            else
                yLimValues = [-0.025, 1.1];
            end
            xLimValues = 0.5 + [0, max(maxXLim(axIdx),1)];
            plot(hAxes(axIdx),xLimValues,[0, 0],'k-');
            set(hAxes(axIdx), 'XTick', 1:numel(plotLabelInfo{1, axIdx}), ...
                'XTickLabel', plotLabelInfo{1, axIdx});
        else
            if axContainsVariancePlot(axIdx)
                currentYLim = get(hAxes(axIdx),'YLim');
                yLimValues = currentYLim;
            else
                yLimValues = [-0.1, 1.1];
            end
            xLimValues = [0, maxXLim(axIdx)+minXLim(axIdx)];
            if ~axContainsVariancePlot(axIdx)
                plot(hAxes(axIdx),xLimValues,[0, 0],'k:');
                plot(hAxes(axIdx),xLimValues,[1, 1],'k:');
            end
            set(hAxes(axIdx), 'XTickMode', 'auto', 'XTickLabelMode', 'auto');

        end
        set(hAxes(axIdx),'XLim',xLimValues);
        if strcmp(mode{axIdx}, 'bar plot') || ~axContainsVariancePlot(axIdx) 
            set(hAxes(axIdx),'YLim',yLimValues);
        end
	end
    
    %% Turn off hold

    for index = 1:numAxes
        
        title(hAxes(index),obj.PlotSettings(index).Title,...
            'FontSize',obj.PlotSettings(index).TitleFontSize,...
            'FontWeight',obj.PlotSettings(index).TitleFontWeight); % sprintf('Plot %d',index));
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
        xlabel(hAxes(index),obj.PlotSettings(index).XLabel,...
            'FontSize',obj.PlotSettings(index).XLabelFontSize,...
            'FontWeight',obj.PlotSettings(index).XLabelFontWeight); % 'Time');
        ylabel(hAxes(index),obj.PlotSettings(index).YLabel,...
            'FontSize',obj.PlotSettings(index).YLabelFontSize,...
            'FontWeight',obj.PlotSettings(index).YLabelFontWeight); % 'States');
        set(hAxes(index),'YScale',obj.PlotSettings(index).YScale);

%         set(hAxes(index),...
%             'XLimMode',obj.PlotSettings(index).XLimMode,...
%             'YLimMode',obj.PlotSettings(index).YLimMode);
%         if strcmpi(xLimMode{index,1},'manual')
%             tmp = obj.PlotSettings(index).CustomXLim;
%             if ischar(tmp), tmp = str2num(tmp); end         %#ok<ST2NM>
%             set(hAxes(index), 'XLim', tmp);
%         end
%         if strcmpi(obj.PlotSettings(index).YLimMode,'manual')
%             tmp = obj.PlotSettings(index).CustomYLim;
%             if ischar(tmp), tmp = str2num(tmp); end         %#ok<ST2NM>
%             set(hAxes(index), 'YLim', tmp);
%         end        
        
        hold(hAxes(index),'off')
         % Reset zoom state
%         hFigure = ancestor(hAxes(index),'Figure');
%         if ~isempty(hFigure) && strcmpi(obj.PlotSettings(index).XLimMode,'auto') && strcmpi(obj.PlotSettings(index).YLimMode,'auto')
%             set(hFigure,'CurrentAxes',hAxes(index)) % This causes the legend fontsize to reset: axes(hAxes(index));
%             try
%                 zoom(hFigure,'out');
%                 zoom(hFigure,'reset');        
%             catch ME
%                 warning(ME.message);
%             end        
%         end

    end
    
end

function barValue = getBarValue(obj, sobolIndices)
    switch obj.SummaryType
        case 'mean'
            barValue = mean(sobolIndices);
        case 'median'
            barValue = median(sobolIndices);
        case 'max'
            barValue = max(sobolIndices);
        case 'min'
            barValue = min(sobolIndices);
    end
end

