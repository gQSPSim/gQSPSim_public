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


if isscalar(vObj.TempData)
    RootDir = vObj.TempData.RootDirectory;
    RelativeObjectiveFunctionsPath = vObj.TempData.RelativeObjectiveFunctionsPath;
    RelativeUserDefinedFunctionsPath = vObj.TempData.RelativeUserDefinedFunctionsPath;

    RelativeAutoSavePath = vObj.TempData.RelativeAutoSavePath;    
    UseAutoSave = vObj.TempData.UseAutoSave;
    AutoSaveFrequency = vObj.TempData.AutoSaveFrequency;
    AutoSaveBeforeRun = vObj.TempData.AutoSaveBeforeRun;

else
    RootDir = '';
    RelativeUserDefinedFunctionsPath = '';
    RelativeObjectiveFunctionsPath = '';
    RelativeAutoSavePath = '';
    
    UseAutoSave = false;
    AutoSaveFrequency = 1;
    AutoSaveBeforeRun = false;
end

vObj.h.RootDirSelector.Value = RootDir;
vObj.h.ResultsDirSelector.RootDirectory = RootDir;
% vObj.h.ResultsDirSelector.Value = RelativeResultsPath;
vObj.h.FunctionsDirSelector.RootDirectory = RootDir;
vObj.h.ObjectiveFunctionsDirSelector.RootDirectory = RootDir;
vObj.h.ObjectiveFunctionsDirSelector.Value = RelativeObjectiveFunctionsPath;
vObj.h.UserDefinedFunctionsDirSelector.RootDirectory = RootDir;
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

