function refresh(vObj)
% refresh - Updates all parts of the VirtualPopulationGeneration viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the VirtualPopulationGeneration viewer display
%
% Syntax:
%           refresh(vObj)
%
% Inputs:
%           vObj - The VirtualPopulationGeneration vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%


%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);


%% Invoke update

update(vObj);



