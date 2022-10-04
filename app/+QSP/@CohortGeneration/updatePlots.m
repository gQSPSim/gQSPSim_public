function [hLegend,hLegendChildren] = updatePlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,varargin)
% updatePlots - Updates the plot
% -------------------------------------------------------------------------
% Abstract: Updates the plot
%
% Syntax:
%           updatePlots(aObj,hAxes)
%
% Inputs:
%           obj - QSP.CohortGeneration object
%
%           hAxes
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



[hLegend,hLegendChildren] = QSP.updateVirtualCohortGenerationPlots(obj,hAxes,hSpeciesGroup,hDatasetGroup,'Mode','Cohort',varargin{:});
