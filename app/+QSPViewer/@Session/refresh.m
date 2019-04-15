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
%     RelativeFunctionsPath = vObj.Data.RelativeFunctionsPath;
    RelativeObjectiveFunctionsPath = vObj.Data.RelativeObjectiveFunctionsPath;
    RelativeUserDefinedFunctionsPath = vObj.Data.RelativeUserDefinedFunctionsPath;
    RelativeAutoSavePath = vObj.Data.RelativeAutoSavePath;
    
    UseAutoSave = vObj.Data.UseAutoSave;
    AutoSaveFrequency = vObj.Data.AutoSaveFrequency;
    AutoSaveBeforeRun = vObj.Data.AutoSaveBeforeRun;
else
    RootDir = '';
    RelativeResultsPath = '';
    RelativeUserDefinedFunctionsPath = '';
    RelativeObjectiveFunctionsPath = '';
    RelativeAutoSavePath = '';
    
    UseAutoSave = false;
    AutoSaveFrequency = 1;
    AutoSaveBeforeRun = false;
end

vObj.h.RootDirSelector.Value = RootDir;
vObj.h.ResultsDirSelector.RootDirectory = RootDir;
vObj.h.ResultsDirSelector.Value = RelativeResultsPath;
vObj.h.FunctionsDirSelector.RootDirectory = RootDir;
vObj.h.ObjectiveFunctionsDirSelector.Value = RelativeObjectiveFunctionsPath;
vObj.h.UserDefinedFunctionsDirSelector.Value = RelativeUserDefinedFunctionsPath;

vObj.h.UseAutoSaveCheckbox.Value = UseAutoSave;
vObj.h.AutoSaveDirSelector.RootDirectory = RootDir;
vObj.h.AutoSaveDirSelector.Value = RelativeAutoSavePath;
vObj.h.AutoSaveFrequencyEdit.String = num2str(AutoSaveFrequency);
vObj.h.AutoSaveBeforeRunCheckbox.Value = AutoSaveBeforeRun;

% Toggle enable
set(vObj.h.AutoSaveDirSelector,'Enable',uix.utility.tf2onoff(UseAutoSave));
set(vObj.h.AutoSaveFrequencyEdit,'Enable',uix.utility.tf2onoff(UseAutoSave));
set(vObj.h.AutoSaveBeforeRunCheckbox,'Enable',uix.utility.tf2onoff(UseAutoSave));
