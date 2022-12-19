function [hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = plotCohortGeneration(obj,hAxes)
% plotCohortGeneration - plots the Cohort Generation visualization
% -------------------------------------------------------------------------
% Abstract: This plots the cohort generation analysis
%
% Syntax:
%           plotCohortGeneration(aObj,hAxes)
%
% Inputs:
%           obj - QSP.CohortGeneration object
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%



[hSpeciesGroup,hDatasetGroup,hLegend,hLegendChildren] = QSP.plotVirtualCohortGeneration(obj,hAxes,'Mode','Cohort');
