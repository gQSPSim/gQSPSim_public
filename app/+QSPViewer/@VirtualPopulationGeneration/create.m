function create(vObj)
% create - Creates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function creates all parts of the viewer display
%
% Syntax:
%           create(vObj)
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
%   $Revision: 310 $  $Date: 2016-09-07 17:44:13 -0400 (Wed, 07 Sep 2016) $
% ---------------------------------------------------------------------

%% Parameters

LabelWidth = 80;
WidgetHeight = 30;


%% Invoke super class's create

create@uix.abstract.CardViewPane(vObj);


%% Edit Content

EditLayout = uix.VBox(...
    'Parent',vObj.h.EditContentsPanel,...
    'Padding',0,...
    'Spacing',12);

ResultsHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',5);
vObj.h.ResultsDirLabel = uicontrol(...
    'Parent',ResultsHLayout,...
    'Style','text',...
    'String','Results Path',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');
% Results Path
vObj.h.ResultsDirSelector = uix.widget.FolderSelector(...
    'Parent',ResultsHLayout,...
    'Value', '', ...
    'Title', 'Select the results directory', ...
    'Tag', 'RootDirectory', ... %the field the result goes in Session
    'InvalidForegroundColor',[1 0 0],...
    'HorizontalAlignment', 'left',...
    'Callback',@(h,e)onFolderSelection(vObj,h,e) );
ResultsHLayout.Widths = [LabelWidth -1];


GridLayout = uix.Grid(...
    'Parent',EditLayout,...
    'Spacing',10);


% Cohort
vObj.h.CohortPopup = uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'Value',1,...
    'LabelString','Cohort',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'Tag','CohortPopup',...
    'Callback',@(h,e)onCohortPopup(vObj,h,e));

% Virtual Population Generation Data
vObj.h.VpopPopup = uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'Value',1,...
    'LabelString','VpopGen Data',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'Tag','CohortPopup',...
    'Callback',@(h,e)onVpopGenDataPopup(vObj,h,e));

% Minimum No of Virtual Patients
vObj.h.MinNumVirtualPatientsEdit = uix.widget.EditFieldWithLabel(...
    'Parent',GridLayout,...
    'Value','20',...
    'LabelString','Min # of Virt Patients',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelTooltip','Minimum number of virtual patients',...
    'Tag','MinNumVirtualPatientsEdit',...
    'Callback',@(h,e)onMinNumVirtualPatientsEdit(vObj,h,e));

% Group Column
vObj.h.GroupNamePopup = ...
    uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'LabelString','Group Column',...
    'LabelFontSize',10,...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelFontWeight','bold',...
    'Callback',@(h,e)onGroupNamePopup(vObj,h,e));

% Method
vObj.h.MethodPopup = uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'Value',1,...
    'LabelString','Method',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'Tag','CohortPopup',...
    'Callback',@(h,e)onMethodPopup(vObj,h,e),...
    'Enable', 'off'    );

vObj.h.RedistributeWeightsCheck =  matlab.ui.control.UIControl( ...
    'Parent',GridLayout,...
    'Style','checkbox', ...
    'FontSize',10,...
    'String','Maximize vpop diversity',...
    'Callback',@(h,e)onRedistributeWeightsCheck(vObj,h,e));

% add options
set(vObj.h.MethodPopup, 'String', {'Maximum likelihood'; 'Bayesian'}, 'Value', 1);

GridLayout.Heights = [WidgetHeight WidgetHeight WidgetHeight]; % WidgetHeight WidgetHeight];
GridLayout.Widths = [-1 -1];


% Table layout
TableHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',5);


% % Parameters
% vObj.h.ParametersTable = uix.widget.MultiPlatformTable(...
%     'Parent',EditLayout,...
%     'LabelString','Virtual population parameters',...
%     'LabelFontSize',10,...
%     'LabelFontWeight','bold',...
%     'LabelLocation','top',...
%     'UseButtons',false,...
%     'ColumnName',{'Include','Parameter','Scale','Lower Bound','Upper Bound'},...
%     'ColumnEditable',[false,false,false,false,false]);

% Sizes
EditLayout.Heights = [WidgetHeight WidgetHeight*3+10*2 -1 ];


%%% Table Layout
% Group-Task Mapping
vObj.h.ItemsTable = uix.widget.MultiPlatformTable(...
    'Parent',TableHLayout,...
    'LabelString','Virtual Population Items',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',[true true false],...
    'ButtonPosition','left',...
    'ColumnName',{'Task','Group'},...
    'ColumnEditable',[true,true],...
    'ButtonCallback',@(h,e)onTableButtonPressed(vObj,h,e,'OptimItems'),...
    'CellEditCallback',@(h,e)onTableEdit(vObj,h,e,'OptimItems'),...
    'CellSelectionCallback',@(h,e)onTableSelect(vObj,h,e,'OptimItems'));

% Species-Data Items
vObj.h.SpeciesDataTable = uix.widget.MultiPlatformTable(...
    'Parent',TableHLayout,...
    'LabelString','Species-Data Mapping',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',[true true false],...
    'ButtonPosition','left',...    
    'ButtonCallback',@(h,e)onTableButtonPressed(vObj,h,e,'SpeciesData'),...
    'CellEditCallback',@(h,e)onTableEdit(vObj,h,e,'SpeciesData'),...
    'CellSelectionCallback',@(h,e)onTableSelect(vObj,h,e,'SpeciesData'));




%% Visualization Content

VisualizationLayout = uix.VBox(...
    'Parent',vObj.h.PlotSettingsPanel,...
    'Padding',0,...
    'Spacing',10);

% vObj.h.ParameterDistributionDiagnosticsLayout.ButtonSize = [125 30]; % 125

% Species-Data
vObj.h.PlotSpeciesTable = uix.widget.MultiPlatformTable(...
    'Parent',VisualizationLayout,...
    'LabelString','Species-Data',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false,...
    'ColumnName',{'Plot','Style','Species','Data','Display'},...
    'ColumnEditable',[true,true,false,false,true],...
    'CellEditCallback',@(h,e)onSpeciesDataTablePlot(vObj,h,e));

% Virtual Population Items
vObj.h.PlotItemsTable = uix.widget.MultiPlatformTable(...
    'Parent',VisualizationLayout,...
    'LabelString','Virtual Population Items',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false,...
    'ColumnName',{'Include','Color','Task','Group'},...
    'ColumnEditable',[true,true,true,true],...
    'CellSelectionCallback',@(h,e)onItemsTableSelectionPlot(vObj,h,e),...
    'CellEditCallback',@(h,e)onItemsTablePlot(vObj,h,e));

% Sizes
VisualizationLayout.Heights = [150 -1];


%% Resize

% Attach a resize function
vObj.h.EditPanel.ResizeFcn = @(h,e)onResize(vObj,h,e);
vObj.h.VisualizePanel.ResizeFcn = @(h,e)onResize(vObj,h,e);

