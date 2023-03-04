function plotData(vObj)
% plotData - plots all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function plots all parts of the viewer display
%
% Syntax:
%           plotData(vObj)
%
% Inputs:
%           vObj - QSPViewer.VirtualPopulationGeneration vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

%                 try
% Plot
[vObj.h.SpeciesGroup,vObj.h.DatasetGroup,vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = ...
    plotVirtualPopulationGeneration(vObj.Data,vObj.h.MainAxes);
%                 catch ME
%                     hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                     uiwait(hDlg);
%                 end


