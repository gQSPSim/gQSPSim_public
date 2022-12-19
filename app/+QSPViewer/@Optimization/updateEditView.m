function updateEditView(vObj)
% updateEditView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateEditView(vObj)
%
% Inputs:
%           vObj - QSPViewer.Optimization vObject
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

%% Refresh Dataset

refreshDataset(vObj);


%% Update ItemsTable

refreshItemsTable(vObj);


%% Update SpeciesDataTable

refreshSpeciesDataTable(vObj);


%% Update SpeciesICTable

refreshSpeciesICTable(vObj);


%% Update Parameters

refreshParameters(vObj);


%% Update Results directory

updateResultsDir(vObj);


%% Update AlgorithmsPopup

updateAlgorithms(vObj);

%% update RNG
set(vObj.h.RNGSeedEdit, 'Value', vObj.TempData.RNGSeed)
