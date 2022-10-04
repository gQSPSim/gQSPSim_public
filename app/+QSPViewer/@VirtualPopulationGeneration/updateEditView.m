function updateEditView(vObj)
% updateEditView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateEditView(vObj)
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


if vObj.Selection ~= 2
    return;
end

%% Update Results directory

updateResultsDir(vObj);


%% Refresh dataset

refreshDataset(vObj);


%% Refresh Items Table

refreshItemsTable(vObj);


%% Update MinNumVirtualPatients

updateMinNumVirtualPatients(vObj);


%% Refresh SpeciesData Table

refreshSpeciesDataTable(vObj);


