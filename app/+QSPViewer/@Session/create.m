function create(vObj)
% create - Creates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function creates all parts of the viewer display
%
% Syntax:
%           create(vObj)
%
% Inputs:
%           vObj - QSPViewer.Session vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2014-2019 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 282 $  $Date: 2016-09-01 10:04:43 -0400 (Thu, 01 Sep 2016) $
% ---------------------------------------------------------------------


create@uix.abstract.CardViewPane(vObj);

%% Main Panel and layout

vObj.h.SessionVbox = uix.VBox(...
    'Parent', vObj.h.EditContentsPanel,...
    'Padding',5,...
    'Spacing',10);

vObj.h.SessionLayout = uix.Grid(...
    'Parent',vObj.h.SessionVbox,...
    'Padding',5,...
    'Spacing',10);


%% Directory Selectors

% Labels

vObj.h.RootDirLabel = uicontrol(...
    'Parent',vObj.h.SessionLayout,...
    'Style','text',...
    'String','Root Directory:',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');


vObj.h.ObjectiveFunctionsDirLabel = uicontrol(...
    'Parent',vObj.h.SessionLayout,...
    'Style','text',...
    'String','Objective Functions Directory:',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');


vObj.h.CustomFunctionsDirLabel = uicontrol(...
    'Parent',vObj.h.SessionLayout,...
    'Style','text',...
    'String','User-defined Functions Directory:',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');


% Selectors

vObj.h.RootDirSelector = uix.widget.FolderSelector(...
    'Parent',vObj.h.SessionLayout,...
    'Value', '', ...
    'Title', 'Select the root directory', ...
    'Tag', 'RootDirectory', ... %the field the result goes in Session
    'HorizontalAlignment', 'left',...
    'InvalidForegroundColor',[1 0 0],...
    'Callback',@(h,e)onFileSelection(vObj,h,e) );

vObj.h.ObjectiveFunctionsDirSelector = uix.widget.FolderSelector(...
    'Parent',vObj.h.SessionLayout,...
    'Value', '', ...
    'Title', 'Select the objective functions directory', ...
    'Tag', 'RelativeObjectiveFunctionsPath_new', ... %the field the result goes in Session
    'HorizontalAlignment', 'left',...
    'InvalidForegroundColor',[1 0 0],...
    'Callback',@(h,e)onFileSelection(vObj,h,e) );

vObj.h.UserDefinedFunctionsDirSelector = uix.widget.FolderSelector(...
    'Parent',vObj.h.SessionLayout,...
    'Value', '', ...
    'Title', 'Select the user-defined functions directory', ...
    'Tag', 'RelativeUserDefinedFunctionsPath_new', ... %the field the result goes in Session
    'HorizontalAlignment', 'left',...
    'InvalidForegroundColor',[1 0 0],...
    'Callback',@(h,e)onUDFSelection(vObj,h,e) );


%% parallel

vObj.h.ParallelPanel = uix.Panel(...
    'Parent', vObj.h.SessionVbox, ...
    'FontSize',10,...
    'Title', 'Parallel options'...
);

info = ver;
if ismember('Parallel Computing Toolbox', {info.Name})
    par_enable = 'on';
    cluster_profiles = parallel.clusterProfiles;
    par_on = 1;
else
    par_enable = 'off';
    cluster_profiles = '';
    par_on = 0;
end


vObj.h.ParallelVbox = uix.VBox(...
    'Parent', vObj.h.ParallelPanel,...
    'Padding',5,...
    'Spacing',10);

vObj.h.UseParallelCheckbox = uicontrol(...
    'Parent', vObj.h.ParallelVbox, ...
    'Style', 'checkbox', ...
    'HorizontalAlignment','left',...
    'String', 'Use parallel toolbox', ...
    'FontSize',10,...
    'Enable', 'on', ...
    'Value', par_on, ...
    'Callback', @(h,evt) onParallelCheckbox(vObj,h,evt) ...
); 

vObj.h.ParallelCluster = uix.widget.PopupFieldWithLabel(...
    'Parent', vObj.h.ParallelVbox, ...
    'String', cluster_profiles,...
    'Enable', par_enable,...
    'LabelString', 'Parallel cluster',...
    'HorizontalAlignment', 'left', ...
    'Callback', @(h,evt) onParallelClusterPopup(vObj,h,evt) ...
    );

%% autosave options
vObj.h.AutoSavePanel = uix.Panel(...
    'Parent', vObj.h.SessionVbox, ...
    'FontSize',10,...
    'Title', 'Autosave options'...
);

vObj.h.AutoSaveLayout = uix.Grid(...
    'Parent',vObj.h.AutoSavePanel,...
    'Padding',10,...
    'Spacing',10);

% Autosave dir label                edit
% use autosave timer checkbox       frequency edit
% autosave before run checkbox

vObj.h.AutoSaveDirLabel = uicontrol(...
    'Parent',vObj.h.AutoSaveLayout,...
    'Style','text',...
    'String','Autosave directory:',...
    'FontSize',10,...
    'HorizontalAlignment','left');

vObj.h.UseAutosaveTimerCheckbox = uicontrol(...
    'Parent', vObj.h.AutoSaveLayout, ...
    'Style', 'checkbox', ...
    'HorizontalAlignment','left',...
    'FontSize',10,...
    'String', 'Autosave periodically', ...
    'Enable', 'on', ...
    'Value', false, ...
    'Callback', @(h,evt) onAutosaveTimerCheckbox(vObj,h,evt) ...
);

vObj.h.AutoSaveBeforeRunCheckbox = uicontrol(...
    'Parent',vObj.h.AutoSaveLayout,...
    'Style','checkbox',...
    'String','Before Run',...
    'FontSize',10,...
    'Enable', 'on', ...
    'Value', 1,...
    'HorizontalAlignment','left',...
    'Callback', @(h,evt) onAutoSaveBeforeRunChecked(vObj,h,evt) ...    
);


vObj.h.AutoSaveDirSelector = uix.widget.FolderSelector(...
    'Parent',vObj.h.AutoSaveLayout,...
    'Value','', ...
    'Title','Select the auto-save directory', ...
    'Tag','RelativeAutoSavePath_new', ... %the field the result goes in Session
    'HorizontalAlignment', 'left',...
    'InvalidForegroundColor',[1 0 0],...
    'Callback',@(h,e)onFileSelection(vObj,h,e) );


vObj.h.AutosaveTimerHbox = uix.HBox(...
    'Parent', vObj.h.AutoSaveLayout,...
    'Padding',0,...
    'Spacing',10);


vObj.h.AutoSaveFrequencyLabel = uicontrol(...
    'Parent',vObj.h.AutosaveTimerHbox,...
    'Style','text',...
    'String','Autosave frequency (min):',...
    'FontSize',10,...
    'HorizontalAlignment','left');

vObj.h.AutoSaveFrequencyEdit = uicontrol(...
    'Parent',vObj.h.AutosaveTimerHbox,...
    'Style','edit',...
    'HorizontalAlignment','left',...
    'FontSize',10,...
    'Callback',@(h,e)onAutoSaveFrequencyEdited(vObj,h,e));

uix.Empty(...
    'Parent', vObj.h.AutosaveTimerHbox);

% Sizes
vObj.h.SessionLayout.Heights = [25 25 25];
vObj.h.SessionLayout.Widths = [250 -1];

vObj.h.AutoSaveLayout.Heights = [25 25 25];
vObj.h.AutoSaveLayout.Widths = [250 -1];

vObj.h.SessionVbox.Heights = [100, 100, 150];
vObj.h.AutosaveTimerHbox.Widths = [175 75 -1];



