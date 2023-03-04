function updateEditView(vObj)
% updateEditView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateEditView(vObj)
%
% Inputs:
%           vObj - QSPViewer.Simulation vObject
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

%% Update Results directory - vObj.TempData

updateResultsDir(vObj);


%% Refresh dataset

refreshDataset(vObj);


%% Refresh items table

refreshItemsTable(vObj, true);