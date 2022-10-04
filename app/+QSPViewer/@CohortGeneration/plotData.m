function plotData(vObj)
% plotData - plots all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function plots all parts of the viewer display
%
% Syntax:
%           plotData(vObj)
%
% Inputs:
%           vObj - QSPViewer.CohortGeneration vObject
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

% Reset xticks and xticklabelmode since Diagnostic plot sets custom
% xticklabels
set(vObj.h.MainAxes,'XTickMode','auto','XTickLabelMode','auto');
    
% Plot
[vObj.h.SpeciesGroup,vObj.h.DatasetGroup,vObj.h.AxesLegend,vObj.h.AxesLegendChildren] = ...
    plotCohortGeneration(vObj.Data,vObj.h.MainAxes);
%                 catch ME
%                     hDlg = errordlg(sprintf('Cannot plot. %s',ME.message),'Invalid','modal');
%                     uiwait(hDlg);
%                 end


