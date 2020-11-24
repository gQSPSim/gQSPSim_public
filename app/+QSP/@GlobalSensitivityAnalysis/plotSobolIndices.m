function [hLines,hLegend,hLegendChildren] = plotSobolIndices(obj,hAxes,mode)
% plotSobolIndices - plots the Sobol indices of a global sensitivity analysis
% -------------------------------------------------------------------------
% Abstract: This plots the Sobol indices of a global sensitivity analysis.
%
% Syntax:
%           plotSobolIndices(aObj,hAxes)
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

    hLines = cell(size(obj.PlotFirstOrderInfo,1),2);
    hLegend = [];
    hLegendChildren = [];
    maxXLim = zeros(1,numAxes);

    [statusOk, message, inputs] = obj.getParameterInfo();
    
    barInfo = cell(numAxes,2);
    meanStatistics = cell(numAxes, numel(obj.PlotInputs)*numel(obj.PlotOutputs));
    
    markerSize = 0.1;
    
    %% Plot Simulation Items
    numItems = numel(obj.Item);
    for itemIdx = 1:numItems
        
        if ~obj.Item(itemIdx).Include 
            continue;
        end
        
        task = obj.getObjectsByName(obj.Settings.Task, obj.Item(itemIdx).TaskName);
        outputs = task.ActiveSpeciesNames;
            
        for inputIdx = 1:numel(inputs)
            for outputIdx = 1:numel(outputs)
                                
                [~, plotOutputIdx] = ismember(outputs{outputIdx}, obj.PlotOutputs);
                [~, plotInputIdx]  = ismember(inputs{inputIdx}, obj.PlotInputs);
                idx = obj.getInputOutputIndex(plotInputIdx,plotOutputIdx,numel(obj.PlotInputs));
                
                alphaValues = linspace(0.4, 1, numel(obj.Item(itemIdx).Results));
                
                axIdx = str2double(obj.PlotFirstOrderInfo{idx,1});
                if isnan(axIdx)
                elseif mode == 1
                    for i = 1:numel(alphaValues)
                        hLine = plot(hAxes(axIdx), obj.Item(itemIdx).Results(i).Time, ...
                            obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).FirstOrder, ...
                            'Color', [obj.Item(itemIdx).Color, alphaValues(i)], 'LineStyle', obj.PlotFirstOrderInfo{idx,2}); 
                    end
                    maxXLim(axIdx) = max(maxXLim(axIdx), max(eval(task.OutputTimesStr)));
                else
                    xIdx = find(idx == barInfo{axIdx,1}, 1);
                    if isempty(xIdx)
                        barInfo{axIdx,1} = [barInfo{axIdx,1}, idx];
                        xIdx = numel(barInfo{axIdx,1});
                        currentLabel = obj.PlotFirstOrderInfo{idx,3};
                        if isempty(currentLabel)
                            currentLabel = [outputs{outputIdx}, '/', inputs{inputIdx}, '(first order)'];
                        end
                        barInfo{axIdx,2} = [barInfo{axIdx,2}, {currentLabel}];

                    end
                    for i = 1:numel(alphaValues) 
                        barValue = getBarValue(obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).FirstOrder, mode);
                        scatter(hAxes(axIdx), xIdx, barValue, 100, 'd', ...
                            'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceAlpha', alphaValues(i), ...
                            'MarkerEdgeAlpha', alphaValues(i));
                    end
                    meanStatistics{axIdx, xIdx} = ...
                        [meanStatistics{axIdx, xIdx}, barValue];
                    maxXLim(axIdx) = max(maxXLim(axIdx), xIdx);
                end
                
                axIdx = str2double(obj.PlotTotalOrderInfo{idx,1});
                if isnan(axIdx)
                elseif mode == 1
                    for i = 1:numel(alphaValues)
                        plot(hAxes(axIdx), obj.Item(itemIdx).Results(i).Time, ...
                            obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).TotalOrder, ...
                            'Color', [obj.Item(itemIdx).Color, alphaValues(i)], 'LineStyle', obj.PlotFirstOrderInfo{idx,2}); 
                    end
                    maxXLim(axIdx) = max(maxXLim(axIdx), max(eval(task.OutputTimesStr)));
                else
                    xIdx = find(-idx == barInfo{axIdx},1);
                    if isempty(xIdx)
                        barInfo{axIdx} = [barInfo{axIdx}, -idx];
                        xIdx = numel(barInfo{axIdx});
                        currentLabel = obj.PlotTotalOrderInfo{idx,3};
                        if isempty(currentLabel)
                            currentLabel = [outputs{outputIdx}, '/', inputs{inputIdx}, '(total order)'];
                        end
                        barInfo{axIdx,2} = [barInfo{axIdx,2}, {currentLabel}];
                    end
                    for i = 1:numel(alphaValues) 
                        barValue = getBarValue(obj.Item(itemIdx).Results(i).SobolIndices(inputIdx,outputIdx).TotalOrder, mode);
                        scatter(hAxes(axIdx), xIdx, barValue, 100, 'd', ...
                            'MarkerEdgeColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceColor', obj.Item(itemIdx).Color, ...
                            'MarkerFaceAlpha', alphaValues(i), ...
                            'MarkerEdgeAlpha', alphaValues(i));
                    end
                    meanStatistics{axIdx, xIdx} = ...
                        [meanStatistics{axIdx, xIdx}, barValue];  
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
            set(hAxes(axIdx), 'XTickMode', 'auto', 'XTickLabelMode', 'auto');
            plot(hAxes(axIdx),xLimValues,[0, 0],'k:');
            plot(hAxes(axIdx),xLimValues,[1, 1],'k:');
        else
            yLimValues = [-0.025, 1.1];
            xLimValues = 0.5 + [0, max(maxXLim(axIdx),1)];
            plot(hAxes(axIdx),xLimValues,[0, 0],'k-');
            set(hAxes(axIdx), 'XTick', 1:numel(barInfo{axIdx,2}), ...
                'XTickLabel', barInfo{axIdx,2});
        end
        set(hAxes(axIdx),'XLim',xLimValues);        
        set(hAxes(axIdx),'YLim',yLimValues);
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
