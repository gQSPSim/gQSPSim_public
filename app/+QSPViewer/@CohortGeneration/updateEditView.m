function updateEditView(vObj)
% updateEditView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateEditView(vObj)
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


if vObj.Selection ~= 2
    return;
end

%% Update Results directory

updateResultsDir(vObj);


%% Refresh dataset

refreshDataset(vObj);


%% Refresh Items Table

refreshItemsTable(vObj);


%% Refresh SpeciesData Table

refreshSpeciesDataTable(vObj);


%% Update ParametersPopup

refreshParameters(vObj);


%% Update MaxNumSimulations

updateMaxNumSims(vObj);


%% Update MaxNumVirtualPatients

updateMaxNumVirtualPatients(vObj);


%% Update SaveInvalidPopup

updateSaveInvalid(vObj);


%% update RNG
set(vObj.h.RNGSeedEdit, 'Value', vObj.TempData.RNGSeed)

%% set initial conditions file
if ~isempty(vObj.Data)
    set(vObj.h.ICFileSelector,'Value',vObj.Data.ICFileName);
end
