function refresh(vObj)
% redraw - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           redraw(vObj)
%
% Inputs:
%           vObj - The MyPackageViewer.Empty vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2014-2015 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 314 $  $Date: 2016-09-08 18:22:09 -0400 (Thu, 08 Sep 2016) $
% ---------------------------------------------------------------------


%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);


%% Clear the visualization source and parameters table

if ~isempty(vObj.Data)
    vObj.Data.PlotParametersSource = 'N/A';
    vObj.Data.PlotParametersData = cell(0,2);
end


%% Invoke update

update(vObj);

