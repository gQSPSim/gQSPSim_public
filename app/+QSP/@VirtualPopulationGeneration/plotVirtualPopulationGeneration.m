function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotVirtualPopulationGeneration(obj,hAxes)
% plotVirtualPopulationGeneration - plots the virtual population generation
% analysis.
% -------------------------------------------------------------------------
% Abstract: This plots the virtual population generation analysis.
%
% Syntax:
%           plotVirtualPopulationGeneration(aObj,hAxes)
%
% Inputs:
%           obj - QSP.VirtualPopulationGeneration object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%



[hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = QSP.plotVirtualCohortGeneration(obj,hAxes,'Mode','VP');

