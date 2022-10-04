function update(vObj)
% update - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           update(vObj)
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



%% Update plot layout

if ~isempty(vObj.Data)
    vObj.SelectedPlotLayout = vObj.Data.SelectedPlotLayout;
end


%% Invoke superclass's update

update@uix.abstract.CardViewPane(vObj);


%% Update Edit View

if vObj.Selection == 2
    updateEditView(vObj);
end


%% Update Visualization View

if vObj.Selection == 3
    updateVisualizationView(vObj);
end


