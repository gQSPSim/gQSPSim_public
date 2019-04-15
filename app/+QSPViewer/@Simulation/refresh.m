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
%   $Revision: 255 $  $Date: 2016-08-24 15:25:10 -0400 (Wed, 24 Aug 2016) $
% ---------------------------------------------------------------------


%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);


%% Invoke update

update(vObj);


%% Resize

resize(vObj);

