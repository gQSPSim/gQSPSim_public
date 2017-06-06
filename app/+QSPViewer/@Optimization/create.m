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

% Optimization Algorithm
vObj.h.AlgorithmPopup = ...
    uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'LabelString','Algorithm',...
    'LabelFontSize',10,...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelFontWeight','bold',...
    'Callback',@(h,e)onAlgorithmPopup(vObj,h,e));

% Parameter
vObj.h.ParametersPopup = uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'Value',1,...
    'LabelString','Parameters',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'Tag','ParametersPopup',...
    'Callback',@(h,e)onParametersPopup(vObj,h,e));

uix.Empty('Parent',GridLayout);

% Dataset
vObj.h.DatasetPopup = uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'Value',1,...
    'LabelString','Dataset',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'Tag','DatasetPopup',...
    'Callback',@(h,e)onDatasetPopup(vObj,h,e));

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

% ID Column
vObj.h.IDNamePopup = ...
    uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'LabelString','ID Column',...
    'LabelFontSize',10,...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelFontWeight','bold',...
    'Callback',@(h,e)onIDNamePopup(vObj,h,e));

GridLayout.Heights = [WidgetHeight WidgetHeight WidgetHeight];
GridLayout.Widths = [-1 -1];


% Table layout
TableHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',5);

% Parameters
vObj.h.ParametersTable = uix.widget.MultiPlatformTable(...
    'Parent',EditLayout,...
    'LabelString','Parameters',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false);

% Sizes
EditLayout.Heights = [WidgetHeight WidgetHeight*3+10*2 -1 -1];

%%% Table Layout
% Optimization Items
vObj.h.ItemsTable = uix.widget.MultiPlatformTable(...
    'Parent',TableHLayout,...
    'LabelString','Optimization Items',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',true,...
    'ButtonPosition','left',...
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
    'UseButtons',true,...
    'ButtonPosition','left',...    
    'ButtonCallback',@(h,e)onTableButtonPressed(vObj,h,e,'SpeciesData'),...
    'CellEditCallback',@(h,e)onTableEdit(vObj,h,e,'SpeciesData'),...
    'CellSelectionCallback',@(h,e)onTableSelect(vObj,h,e,'SpeciesData'));

% Species Initial Conditions Items
vObj.h.SpeciesICTable = uix.widget.MultiPlatformTable(...
    'Parent',TableHLayout,...
    'LabelString','Species Initial Conditions',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',true,...
    'ButtonPosition','left',...
    'ButtonCallback',@(h,e)onTableButtonPressed(vObj,h,e,'SpeciesIC'),...
    'CellEditCallback',@(h,e)onTableEdit(vObj,h,e,'SpeciesIC'),...
    'CellSelectionCallback',@(h,e)onTableSelect(vObj,h,e,'SpeciesIC'));


%% Visualization Content

VisualizationLayout = uix.VBox(...
    'Parent',vObj.h.PlotSettingsPanel,...
    'Padding',0,...
    'Spacing',10);

% Species-Data
vObj.h.PlotSpeciesTable = uix.widget.MultiPlatformTable(...
    'Parent',VisualizationLayout,...
    'LabelString','Species-Data',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false,...
    'ColumnName',{'Plot','Species','Data'},...
    'ColumnEditable',[true,false,false],...
    'CellEditCallback',@(h,e)onSpeciesDataTablePlot(vObj,h,e));

% Optimization Items
vObj.h.PlotItemsTable = uix.widget.MultiPlatformTable(...
    'Parent',VisualizationLayout,...
    'LabelString','Optimization Items',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false,...
    'ColumnName',{'Include','Color','Task','Group'},...
    'ColumnEditable',[true,true,true,true],...
    'CellSelectionCallback',@(h,e)onItemsTableSelectionPlot(vObj,h,e),...
    'CellEditCallback',@(h,e)onItemsTablePlot(vObj,h,e));

% Source
vObj.h.PlotSourcePopup = ...
    uix.widget.PopupFieldWithLabel(...
    'Parent',VisualizationLayout,...
    'String',{'-'},...
    'LabelString','Source',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'Callback',@(h,e)onPlotSourcePopup(vObj,h,e));

% Parameters
vObj.h.PlotParametersTable = uix.widget.MultiPlatformTable(...
    'Parent',VisualizationLayout,...
    'LabelString','Parameters',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false,...
    'CellEditCallback',@(h,e)onParametersTablePlot(vObj,h,e));

% Sizes
VisualizationLayout.Heights = [-1 -1 WidgetHeight -1];

