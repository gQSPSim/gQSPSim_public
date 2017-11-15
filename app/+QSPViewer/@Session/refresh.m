function refresh(vObj)
% redraw - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           redraw(vObj)
%
% Inputs:
%           vObj - The viewer object
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
%   $Author: rjackey $
%   $Revision: 281 $  $Date: 2016-09-01 09:27:14 -0400 (Thu, 01 Sep 2016) $
% ---------------------------------------------------------------------

if isscalar(vObj.Data)
    RootDir = vObj.Data.RootDirectory;
    RelativeResultsPath = vObj.Data.RelativeResultsPath;
    RelativeFunctionsPath = vObj.Data.RelativeFunctionsPath;
else
    RootDir = '';
    RelativeResultsPath = '';
    RelativeFunctionsPath = '';
end

vObj.h.RootDirSelector.Value = RootDir;
vObj.h.ResultsDirSelector.RootDirectory = RootDir;
vObj.h.ResultsDirSelector.Value = RelativeResultsPath;
vObj.h.FunctionsDirSelector.RootDirectory = RootDir;
vObj.h.FunctionsDirSelector.Value = RelativeFunctionsPath;
