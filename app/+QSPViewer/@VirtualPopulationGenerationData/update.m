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
%   $Revision: 285 $  $Date: 2016-09-02 13:08:51 -0400 (Fri, 02 Sep 2016) $
% ---------------------------------------------------------------------


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