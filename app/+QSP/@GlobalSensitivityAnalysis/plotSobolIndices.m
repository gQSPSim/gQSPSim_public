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
    tfAxesVisible = false(numAxes, 1);
    for index = 1:numAxes
        if ~isempty(hAxes(index).Parent) && ...
                ~isa(hAxes(index).Parent, 'matlab.graphics.shape.internal.AxesLayoutManager')
            cla(hAxes(index));
            set(hAxes(index), 'XLimMode', 'auto', 'YLimMode', 'auto');
            legend(hAxes(index),'off')
            hold(hAxes(index),'on')
            tfAxesVisible(index) = true;
        end
    end

    hLines = cell(1,2);
    hLegend = [];
    hLegendChildren = [];
    maxXLim = zeros(1,numAxes);
    minXLim = inf(1,numAxes);
    axContainsVariancePlot = false(1,numAxes);
    axContainsWorstCaseConvergencePlot = false(1,numAxes);
    mode = cell(1, numAxes);

    % Store plot labels : text and line handles
    plotLabelInfo  = cell(2,numAxes);
    % Store mean bar height in bar plots for multiple tasks
    %  1 - mean value
    %  2 - x location of bar
    %  3 - width of bar
    meanStatistics = cell(numAxes);
    
    %% Plot Simulation Items

    for tableIdx = 1:numel(obj.PlotSobolIndex)
        
        axIdx = str2double(obj.PlotSobolIndex(tableIdx).Plot);
        if ~any([obj.Item.Include]) || isnan(axIdx) || ~tfAxesVisible(axIdx)
            continue;
        end
        
        metric      = obj.PlotSobolIndex(tableIdx).Metric;
        style       = obj.PlotSobolIndex(tableIdx).Style;
        display     = obj.PlotSobolIndex(tableIdx).Display;
        mode{axIdx} = obj.PlotSobolIndex(tableIdx).Mode;
        
        outputs    = obj.PlotSobolIndex(tableIdx).Outputs;
        inputs     = obj.PlotSobolIndex(tableIdx).Inputs;
        
        numInputs = numel(inputs);
        numOutputs = numel(outputs);
        
        borderWidth = 0.1;
        totalWidth = 1-2*borderWidth;
        barWidth = 2*totalWidth/(3*numInputs*numOutputs);
        spaceWidth = barWidth/2;
                        
        xIdx = tableIdx - 0.5 + borderWidth - (barWidth+spaceWidth)/2;
        
        for outIdx = 1:numOutputs

            for inIdx = 1:numInputs
                
                input  = inputs{inIdx};
                output = outputs{outIdx};

                [~, inputIdx]  = ismember(input, obj.PlotInputs);

                xIdx = xIdx + (barWidth+spaceWidth);
                
                currentLabel = display;
                if isempty(currentLabel)
                    if ismember(obj.PlotSobolIndex(tableIdx).Type, {'variance', 'unexpl. frc.'})
                        currentLabel = [output, ' (', obj.PlotSobolIndex(tableIdx).Type, ')';];
                    else
                        currentLabel = [output, '/', input, ' (', obj.PlotSobolIndex(tableIdx).Type, ')';];
                    end
                end
                plotLabelInfo{1, axIdx} = [plotLabelInfo{1, axIdx}, {currentLabel}];
                if ~strcmp(mode{axIdx}, 'bar plot')
                    legendHandle = plot(hAxes(axIdx), nan, nan, 'Color', [0, 0, 0], 'LineStyle', style{1});
                    plotLabelInfo{2, axIdx} = [plotLabelInfo{2, axIdx}, legendHandle];
                end
                
                meanStatistics{axIdx} = [meanStatistics{axIdx}; {[], xIdx, barWidth}];
 
                for itemIdx = 1:numel(obj.Item)

                    if ~obj.Item(itemIdx).Include || isempty(obj.Item(itemIdx).Results)
                        continue;
                    end
                    allOutputs = {obj.Item(itemIdx).Results(1).SobolIndices(1,:).Observable};
                    [tfOutputExists, outputIdx] = ismember(output, allOutputs);
                    if ~tfOutputExists
                        continue;
                    end

                    % All times are equal, so just get the first time vector.
                    time = obj.Item(itemIdx).Results(1).Time; 

                    numResults = numel(obj.Item(itemIdx).Results);

                    if strcmp(mode{axIdx}, 'limit value') || strcmp(mode{axIdx}, 'convergence')
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
                        plot(hAxes(axIdx), time, results{1}, ...
                            'Color', obj.Item(itemIdx).Color, ...
                            'LineStyle', style{1}, ...
                            'LineWidth', obj.PlotSettings(axIdx).LineWidth);
                        maxXLim(axIdx) = max(time);
                    elseif strcmp(mode{axIdx}, 'bar plot')
                        barValue = getBarValue(obj, results{1}, metric);
                        plot(hAxes(axIdx), xIdx, barValue, style{2}, ...
                            'MarkerSize', 10, ...
                            'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceColor', obj.Item(itemIdx).Color);
                        if i == resultsRange(end)
                            meanStatistics{axIdx}{end,1} = ...
                            [meanStatistics{axIdx}{end,1}, barValue];
                        end
                        maxXLim(axIdx) = max(maxXLim(axIdx), xIdx);
                    elseif strcmp(mode{axIdx}, 'convergence')
                        axContainsWorstCaseConvergencePlot(axIdx) = ...
                            axContainsWorstCaseConvergencePlot(axIdx) || strcmp(metric, 'max');
                        numSamplesPerIteration = [obj.Item(itemIdx).Results.NumberSamples];
                        barValue(1) = getBarValue(obj, results{1}, metric);
                        for i = resultsRange(1:end-1)
                            barValue(i+1) = getBarValue(obj, results{i+1}, metric);
                            barValue(i) = abs(barValue(i+1) - barValue(i));
                        end
                        plot(hAxes(axIdx), numSamplesPerIteration(2:end), barValue(1:end-1), ...
                            'LineStyle', style{1}, ...
                            'LineWidth', obj.PlotSettings(axIdx).LineWidth, ...
                            'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceColor', obj.Item(itemIdx).Color, ...
                            'Color', obj.Item(itemIdx).Color);
                        maxXLim(axIdx) = max(maxXLim(axIdx), obj.Item(itemIdx).Results(end).NumberSamples);
                        minXLim(axIdx) = min(minXLim(axIdx), obj.Item(itemIdx).Results(1).NumberSamples);
                    elseif strcmp(mode{axIdx}, 'limit value')
                        for i = resultsRange 
                            barValue(i) = getBarValue(obj, results{i}, metric);
                        end
                        plot(hAxes(axIdx), [obj.Item(itemIdx).Results.NumberSamples], barValue, ...
                            'LineStyle', style{1}, ...
                            'LineWidth', obj.PlotSettings(axIdx).LineWidth, ...
                            'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceColor', obj.Item(itemIdx).Color, ...
                            'Color', obj.Item(itemIdx).Color);
                        maxXLim(axIdx) = max(maxXLim(axIdx), obj.Item(itemIdx).Results(end).NumberSamples);
                        minXLim(axIdx) = min(minXLim(axIdx), obj.Item(itemIdx).Results(1).NumberSamples);
                    end

                end
            end
        end
    end 
    
	for axIdx = 1:numAxes
        
        if ~tfAxesVisible(axIdx)
            continue;
        end
        
        for idx = 1:size(meanStatistics{axIdx}, 1)
            if isempty(meanStatistics{axIdx}{idx, 1})
                break;
            end
            xLoc = meanStatistics{axIdx}{idx, 2};
%             width = meanStatistics{axIdx}{idx, 3};
            width = min([meanStatistics{axIdx}{:, 3}]);
            meanValue = mean(meanStatistics{axIdx}{idx, 1});
            color = [0.8, 0.8, 0.8];
            
            hMeanBar = fill(hAxes(axIdx), xLoc+[-width,width,width,-width]/2, [0, 0, meanValue, meanValue], ...
                color, 'FaceColor', color, 'FaceAlpha', 0.25, 'EdgeColor', color);
            
            tf = hMeanBar == hAxes(axIdx).Children;
            hAxes(axIdx).Children = [hAxes(axIdx).Children(~tf); hAxes(axIdx).Children(tf)];
        end
            
        if strcmp(mode{axIdx}, 'time course')
            if axContainsVariancePlot(axIdx)
                currentYLim = get(hAxes(axIdx),'YLim');
                yLimValues = currentYLim;
            else
                yLimValues = [-0.1, 1.1];
            end
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
            xLimValues = 0.5 + [0, max(floor(maxXLim(axIdx)),1)];
            plot(hAxes(axIdx),xLimValues,[0, 0],'k-');
            xTickValues = [meanStatistics{axIdx}{:, 2}];
            set(hAxes(axIdx), 'XTick', xTickValues, ...
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
            if axContainsWorstCaseConvergencePlot(axIdx) && ...
                    ~obj.HideConvergenceLine
                plot(hAxes(axIdx),xLimValues,obj.StoppingTolerance*[1, 1],'r--');
            end            
            set(hAxes(axIdx), 'XTickMode', 'auto', 'XTickLabelMode', 'auto');
        end
        if ~isempty(plotLabelInfo{2, axIdx}) && ...
                strcmp(obj.PlotSettings(axIdx).LegendVisibility, 'on')
            legend(hAxes(axIdx), plotLabelInfo{2, axIdx}, ...
                plotLabelInfo{1, axIdx}, ...
                'Location', obj.PlotSettings(axIdx).LegendLocation, ...
                'FontSize', obj.PlotSettings(axIdx).LegendFontSize, ...
                'FontWeight',obj.PlotSettings(axIdx).LegendFontWeight);
        end
        set(hAxes(axIdx),'XLim',xLimValues);
        if strcmp(mode{axIdx}, 'bar plot') || ~axContainsVariancePlot(axIdx) 
            set(hAxes(axIdx),'YLim',yLimValues);
        end
	end
    
    %% Turn off hold

    for index = 1:numAxes
        
        if isempty(mode{axIdx})
            continue;
        end
        
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
    drawnow;
end

function barValue = getBarValue(~, sobolIndices, metric)
    switch metric
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

