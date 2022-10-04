function create(vObj)
% create - Creates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function creates all parts of the viewer display
%
% Syntax:
%           create(vObj)
%
% Inputs:
%           vObj - QSPViewer.Parameters vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%


%% Parameters

LabelWidth = 80;
HSpace = 5; %Space between controls
WidgetHeight = 30;


%% Invoke super class's create

create@uix.abstract.CardViewPane(vObj);


%% Edit Content

EditLayout = uix.VBox(...
    'Parent',vObj.h.EditContentsPanel,...
    'Padding',0,...
    'Spacing',12);

% File layout
FileHLayout = uix.HBox(...
    'Parent',EditLayout,...
    'Spacing',HSpace);
% Empty
uix.Empty('Parent',EditLayout);
% Sizes
EditLayout.Heights = [WidgetHeight -1];


%%% File Layout
vObj.h.FileLabel = uicontrol(...
    'Parent',FileHLayout,...
    'Style','text',...
    'String','File',...
    'FontSize',10,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

vObj.h.FileSelector = uix.widget.FileSelector(...
    'Parent',FileHLayout,...
    'Value', '', ...
    'Units','pixels',...
    'Pattern', {'*.xlsx;*.xls','Excel File'}, ...
    'Title', 'Parameters XLSX/XLS file:', ...
    'HorizontalAlignment', 'left',...
    'InvalidForegroundColor',[1 0 0],...
    'Callback',@(h,e)onFileSelection(vObj,h,e) );


% new button
vObj.h.FileNew = uicontrol(...
    'Parent', FileHLayout, ...
    'Style','pushbutton',...
    'Callback',@(h,e) onFileNewPress(vObj,h,e) , ...
    'CData', uix.utility.loadIcon( 'add_24.png' ), ...
    'TooltipString', 'Create new Parameters');


% Sizes
FileHLayout.Widths = [LabelWidth -1 30];


