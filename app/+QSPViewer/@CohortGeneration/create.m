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

% Max No of Simulations
vObj.h.MaxNumSimulationsEdit = uix.widget.EditFieldWithLabel(...
    'Parent',GridLayout,...
    'Value','5000',...
    'LabelString','Max # of Sims',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelTooltip','Max number of simulations',...
    'Tag','MaxNumSimulationsEdit',...
    'Callback',@(h,e)onMaxNumSimulationsEdit(vObj,h,e));

% Max No of Virtual Patients
vObj.h.MaxNumVirtualPatientsEdit = uix.widget.EditFieldWithLabel(...
    'Parent',GridLayout,...
    'Value','500',...
    'LabelString','Max # of Virt Patients',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelTooltip','Max number of virtual patients',...
    'Tag','MaxNumVirtualPatientsEdit',...
    'Callback',@(h,e)onMaxNumVirtualPatientsEdit(vObj,h,e));

% Dataset
vObj.h.DatasetPopup = uix.widget.PopupFieldWithLabel(...
    'Parent',GridLayout,...
    'String',{'-'},...
    'Value',1,...
    'LabelString','Acceptance Criteria',...
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

vObj.h.MethodHBox = uix.HBox(...
    'Parent', GridLayout);

vObj.h.MethodPopup = ...
    uix.widget.PopupFieldWithLabel(...
    'Parent',vObj.h.MethodHBox,...
    'String',{'Distribution','MCMC'},...
    'LabelString','Search Method',...
    'LabelFontSize',10,...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelFontWeight','bold',...
    'Callback',@(h,e)onMethodPopup(vObj,h,e));

vObj.h.MCMCTuningEdit = uix.widget.EditFieldWithLabel(...
    'Parent',vObj.h.MethodHBox,...
    'Value',0.15,...
    'LabelString','MCMC tuning parameter',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','left',...
    'LabelWidth',LabelWidth+2,...
    'LabelTooltip','Relative perturbation size for MCMC',...
    'Tag','MCMCTuningEdit',...
    'Enable', 'off',...
    'Callback',@(h,e)onMCMCTuningEdit(vObj,h,e));


% uix.Empty('Parent',GridLayout);

GridLayout.Heights = [WidgetHeight WidgetHeight WidgetHeight];
GridLayout.Widths = [-1 -1];


% Table layout
TableHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',5);

% Initial Conditions input
ICHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',5);
vObj.h.ICDirLabel = uicontrol(...
    'Parent',ICHLayout,...
    'Style','text',...
    'String','Initial Conditions Path',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');
% IC Path
vObj.h.ICFileSelector = uix.widget.FileSelector(...
    'Parent',ICHLayout,...
    'Pattern',{'*.xlsx', 'Excel file';'*.*','All files'},...
    'Value', '', ...
    'Title', 'Select the initial conditions file', ...
    'Tag', 'RootDirectory', ... 
    'InvalidForegroundColor',[1 0 0],...
    'HorizontalAlignment', 'left',...
    'Callback',@(h,e)onICFileSelection(vObj,h,e) );
ICHLayout.Widths = [LabelWidth -1];

% Parameters
vObj.h.ParametersTable = uix.widget.MultiPlatformTable(...
    'Parent',EditLayout,...
    'LabelString','Parameters',...
    'LabelFontSize',10,...
    'LabelFontWeight','bold',...
    'LabelLocation','top',...
    'UseButtons',false,...
    'ColumnName',{'Include','Parameter','Scale','Lower Bound','Upper Bound'},...
    'ColumnEditable',[false,false,false,false,false]);

% Sizes
EditLayout.Heights = [WidgetHeight WidgetHeight*3+10*2 -1 WidgetHeight -1];


%%% Table Layout
% Optimization Items
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

% Plot type
vObj.h.PlotTypeRadioButtonGroup = uibuttongroup(...
    'Parent',VisualizationLayout,...
    'FontSize',10,...
    'BorderType','none',...
    'FontWeight','bold',...
    'Units','pixels',...
    'Title','Plot Type',...
    'Position',[0 0 300 80],...
    'SelectionChangeFcn',@(h,e)onEditTypePlot(vObj,h,e));
vObj.h.NormalPlotTypeRadioButton = uicontrol(...
    'Parent',vObj.h.PlotTypeRadioButtonGroup,...
    'Style','radiobutton',...
    'String','Normal',...
    'TooltipString','Plot Type: Normal',...
    'Tag','Normal',...
    'FontSize',10,...
    'Units','pixels',...
    'Position',[100 25 300 20]);
vObj.h.DiagnosticPlotTypeRadioButton = uicontrol(...
    'Parent',vObj.h.PlotTypeRadioButtonGroup,...
    'Style','radiobutton',...
    'String','Diagnostic',...
    'TooltipString','Plot Type: Diagnostic',...
    'Tag','Diagnostic',...
    'FontSize',10,...
    'Units','pixels',....
    'Position',[100 5 300 20]);

vObj.h.ParameterDistributionDiagnosticsLayout = uix.HButtonBox(...
    'Parent',VisualizationLayout);
vObj.h.ParameterDistributionDiagnosticsButton = uicontrol(...
    'Parent',vObj.h.ParameterDistributionDiagnosticsLayout,...
    'Style','pushbutton',...
    'Tag','ParameterDistributionDiagnostics',...
    'String','Parameter Distribution Diagnostics',...
    'TooltipString','Plot parameter distribution diagnosticss',...
    'FontSize',10,...
    'Callback',@(h,e)onPlotParameterDistributionDiagnostics(vObj,h,e));
vObj.h.ParameterDistributionDiagnosticsLayout.ButtonSize = [225 30]; % 125

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

% Show Invalid Virtual Patients
vObj.h.ShowInvalidVirtualPatientsCheckbox = matlab.ui.control.UIControl( ...
    'Parent',VisualizationLayout,...
    'Style','checkbox', ...
    'FontSize',10,...
    'String','Show Invalid Virtual Patients',...
    'Callback',@(h,e)onShowInvalidVirtualPatients(vObj,h,e));

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
VisualizationLayout.Heights = [70 40 -1 30 -1];

