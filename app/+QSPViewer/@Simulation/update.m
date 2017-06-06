function update(vObj)
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
%   $Revision: 264 $  $Date: 2016-08-30 15:24:41 -0400 (Tue, 30 Aug 2016) $
% ---------------------------------------------------------------------


%% Invoke superclass's update

update@uix.abstract.CardViewPane(vObj);


%% Update Edit View

updateEditView(vObj);


%% Update Visualization View

updateVisualizationView(vObj);


