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

%% Invoke superclass's refresh

refresh@uix.abstract.CardViewPane(vObj);



if isscalar(vObj.Data)
    RootDir = vObj.Data.RootDirectory;
    RelativeObjectiveFunctionsPath = vObj.Data.RelativeObjectiveFunctionsPath;
    RelativeUserDefinedFunctionsPath = vObj.Data.RelativeUserDefinedFunctionsPath;
    set(vObj.h.ObjectiveFunctionsDirSelector,'RootDirectory',RootDir)
    set(vObj.h.UserDefinedFunctionsDirSelector,'RootDirectory',RootDir)
    
    set(vObj.h.UseParallelCheckbox, 'Value', vObj.Data.UseParallel);
    if vObj.Data.UseParallel
        enable_cluster = 'on';
    else
        enable_cluster = 'off';
    end
    
    set(vObj.h.ParallelCluster, 'String', vObj.Data.ParallelCluster, 'Enable', enable_cluster);

else
    RootDir = '';
%     RelativeResultsPath = '';
    RelativeUserDefinedFunctionsPath = '';
    RelativeObjectiveFunctionsPath = '';
    vObj.h.UseParallelCheckbox.Value = 0;
%     info = ver;
%     if ismember('Parallel Computing Toolbox', {info.Name})
%         vObj.h.ParallelCluster.String = parallel.clusterProfiles;
%     else
%         vObj.h.ParallelCluster.String = {''};
%     end
end

vObj.h.RootDirSelector.Value = RootDir;
vObj.h.ResultsDirSelector.RootDirectory = RootDir;
% vObj.h.ResultsDirSelector.Value = RelativeResultsPath;
vObj.h.FunctionsDirSelector.RootDirectory = RootDir;
vObj.h.ObjectiveFunctionsDirSelector.Value = RelativeObjectiveFunctionsPath;
vObj.h.UserDefinedFunctionsDirSelector.Value = RelativeUserDefinedFunctionsPath;

%% Invoke update

update(vObj);

