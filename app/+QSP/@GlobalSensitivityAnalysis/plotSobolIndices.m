function [hLines,hLegend,hLegendChildren] = plotSobolIndices(obj,hAxes,mode)
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

        cla(hAxes(index), 'reset');
        legend(hAxes(index),'off')    

        hold(hAxes(index),'on')        
    end

    hLines = cell(1,2);
    hLegend = [];
    hLegendChildren = [];
    maxXLim = zeros(1,numAxes);
    axContainsVariancePlot = false(1,numAxes);

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

            alphaValues = linspace(0.2, 1, numel(obj.Item(itemIdx).Results));
            
            if obj.ShowIterations
                plotAlphaRange = 1:numel(alphaValues);
            else
                plotAlphaRange = numel(alphaValues);
            end
            
            for i = plotAlphaRange
                switch obj.PlotSobolIndex(tableIdx).Type
                    case 'unexpl. frac.'
                        results = 1;
                        for j = 1:numel(obj.PlotInputs)
                            results = results - ...
                                reshape(obj.Item(itemIdx).Results(i).SobolIndices(j,outputIdx).FirstOrder, 1, []);
                        end
                    case 'variance'
                        results = obj.Item(itemIdx).Results(i).Variances{:,outputIdx};
                        axContainsVariancePlot(axIdx) = true;
                    case 'first order'
                        results = obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).FirstOrder;
                    case 'total order'
                        results = obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).TotalOrder;
                end
                if mode == 1
                    hLine = plot(hAxes(axIdx), time, results, ...
                        'Color', [obj.Item(itemIdx).Color, alphaValues(i)], ...
                        'LineStyle', lineStyle);      
                    maxXLim(axIdx) = max(time);
                else
                    barValue = getBarValue(results, mode);
                    scatter(hAxes(axIdx), xIdx, barValue, 100, 'd', ...
                        'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                        'MarkerFaceColor', obj.Item(itemIdx).Color, ...
                        'MarkerFaceAlpha', alphaValues(i), ...
                        'MarkerEdgeAlpha', alphaValues(i));
                    if i == plotAlphaRange(end)
                        meanStatistics{axIdx, xIdx} = ...
                        [meanStatistics{axIdx, xIdx}, barValue];
                    end
                    maxXLim(axIdx) = max(maxXLim(axIdx), xIdx);
                end
            end
            
        end                
    end 
    
	for axIdx = 1:numAxes
        
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
            
        if mode == 1
            yLimValues = [-0.1, 1.1];
            xLimValues = [0, max(maxXLim(axIdx),1)];
            if ~axContainsVariancePlot(axIdx)
                plot(hAxes(axIdx),xLimValues,[0, 0],'k:');
                plot(hAxes(axIdx),xLimValues,[1, 1],'k:');
            end
            set(hAxes(axIdx), 'XTickMode', 'auto', 'XTickLabelMode', 'auto');
            
        else
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
        end
        set(hAxes(axIdx),'XLim',xLimValues);
        if mode > 1 || ~axContainsVariancePlot(axIdx) 
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

function barValue = getBarValue(sobolIndices, mode)
    switch mode
        case 2
            barValue = mean(sobolIndices);
        case 3
            barValue = median(sobolIndices);
        case 4
            barValue = max(sobolIndices);
        case 5
            barValue = min(sobolIndices);
    end
end

