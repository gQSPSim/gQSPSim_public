function update(vObj)
% update - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           update(vObj)
%
% Inputs:
%           vObj - QSPViewer.OptimizationData vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%


%% Invoke superclass's update

update@uix.abstract.CardViewPane(vObj);

%% File

if ~isempty(vObj.TempData)
    set(vObj.h.FileSelector,...
        'RootDirectory',vObj.TempData.Session.RootDirectory,...
        'Value',vObj.TempData.RelativeFilePath)
else
    set(vObj.h.FileSelector,'Value','')
end


%% Dataset Type

DatasetTypeOptions = get(vObj.h.DatasetPopup,'String');

if ~isempty(vObj.TempData)
    Value = find(strcmpi(vObj.TempData.DatasetType,DatasetTypeOptions));
    set(vObj.h.DatasetPopup,'Value',Value);
end


