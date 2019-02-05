function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup)
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

for axIndex = 1:NumAxes
    
    % Append
    if size(hSpeciesGroup,3) > 0
        LegendItems = [horzcat(hSpeciesGroup{:,axIndex,1}) horzcat(hDatasetGroup{:,axIndex})];
    else
        LegendItems = [];
    end
    
    if ~isempty(LegendItems) && all(isvalid(LegendItems))
        try
            % Add legend
            [hLegend{axIndex},hLegendChildren{axIndex}] = legend(hAxes(axIndex),LegendItems);
            set(hLegend{axIndex},...
                'EdgeColor','none',...
                'Visible',obj.PlotSettings(axIndex).LegendVisibility,...
                'Location',obj.PlotSettings(axIndex).LegendLocation,...
                'FontSize',obj.PlotSettings(axIndex).LegendFontSize,...
                'FontWeight',obj.PlotSettings(axIndex).LegendFontWeight);
            
            % Color, FontSize, FontWeight
            for cIndex = 1:numel(hLegendChildren{axIndex})
                if isprop(hLegendChildren{axIndex}(cIndex),'FontSize')
                    hLegendChildren{axIndex}(cIndex).FontSize = obj.PlotSettings(axIndex).LegendFontSize;
                end
                if isprop(hLegendChildren{axIndex}(cIndex),'FontWeight')
                    hLegendChildren{axIndex}(cIndex).FontWeight = obj.PlotSettings(axIndex).LegendFontWeight;
                end
            end
        catch ME
            warning(ME.message)
        end
    else
        hLegend{axIndex} = [];
        hLegendChildren{axIndex} = [];        
    end
end