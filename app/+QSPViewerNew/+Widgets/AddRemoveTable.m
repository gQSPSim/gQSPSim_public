classdef AddRemoveTable < handle
    % AddRemoveTable - Display items in a table with buttons to add and
    % remove items
    %----------------------------------------------------------------------
    % Table sections with dropdown menus should not be able to be edited
    %-----------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 06/01/20
    properties(Access = private)
        Parent
        Row 
        Column
        Title
        Selected =0;
        NewLineValue
        lastChangeRow;
        lastChangedColumn;
        lastChangedValue;
    end
    
    properties (Access = private)
       PanelMain            matlab.ui.container.Panel
       TableMain            matlab.ui.control.Table
       GridMain             matlab.ui.container.GridLayout 
       AddButton            matlab.ui.control.Button 
       RemoveButtonm        matlab.ui.control.Button
    end
    
    events
        NewRowChange
        DeleteRowChange
        EditValueChange
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
        
        function  obj = AddRemoveTable(varargin)
            %Revamp to work with grid layout
            if nargin ~= 4
                error("You need to provide a parent grid, row, column, and title");
            else
                %Temporary input order
                obj.Parent = varargin{1};
                obj.Row = varargin{2};
                obj.Column = varargin{3};
                obj.Title =  varargin{4};
                obj.create();
            end
        end
       
    end
    
    methods (Access = private)
        
        function create(obj)
            ButtonSize = 30;
            pad = 2;

            %Create the uipanel
            obj.PanelMain = uipanel('Parent',obj.Parent);
            obj.PanelMain.Title = obj.Title;
            obj.PanelMain.TitlePosition = 'centertop';
            obj.PanelMain.Layout.Row = obj.Row;
            obj.PanelMain.Layout.Column = obj.Column;

            obj.GridMain = uigridlayout(obj.PanelMain);
            obj.GridMain.ColumnWidth = {ButtonSize,'1x'};
            obj.GridMain.RowHeight = {ButtonSize,ButtonSize,'1x'};
            obj.GridMain.Padding = [pad,pad,pad,pad];
            obj.GridMain.ColumnSpacing = pad;
            obj.GridMain.RowSpacing = pad;

            %Add the left list box
            obj.TableMain = uitable(obj.GridMain);
            obj.TableMain.Layout.Row =[1,3];
            obj.TableMain.Layout.Column =2;
            obj.TableMain.CellSelectionCallback = @obj.onSelectionChange;
            obj.TableMain.CellEditCallback = @obj.onValueChange;
            obj.TableMain.ColumnEditable = false;

            %Add the add  button
            obj.AddButton = uibutton(obj.GridMain,'push');
            obj.AddButton.Layout.Row = 1;
            obj.AddButton.Layout.Column = 1;
            obj.AddButton.Icon = QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.AddButton.Text = '';
            obj.AddButton.Tooltip = 'Add a new row';
            obj.AddButton.ButtonPushedFcn = @obj.onAddItem;

            %Add the remove item button
            obj.RemoveButtonm = uibutton(obj.GridMain,'push');
            obj.RemoveButtonm.Layout.Row = 2;
            obj.RemoveButtonm.Layout.Column = 1;
            obj.RemoveButtonm.Icon = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveButtonm.Text = '';
            obj.RemoveButtonm.Tooltip = 'Delete the highlighted row';
            obj.RemoveButtonm.ButtonPushedFcn = @obj.onRemoveItem;
            obj.refreshButtons();
        end
        
        function refreshButtons(obj)
            if obj.Selected ==0
                obj.RemoveButtonm.Enable = false;
            else
                obj.RemoveButtonm.Enable = true;
            end
        end
       
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

         
        function onAddItem(obj,~,~)
            obj.TableMain.Data = [obj.TableMain.Data;obj.NewLineValue];
            obj.notify('NewRowChange')
            obj.Selected = 0;
            obj.refreshButtons();
        end
        
        function onRemoveItem(obj,~,~)
            obj.TableMain.Data(obj.Selected,:) = [];
            obj.notify('DeleteRowChange')
            obj.Selected = 0;
            obj.refreshButtons();
        end
        
        function onSelectionChange(obj,~,e)
            obj.Selected = e.Indices(1);
            obj.refreshButtons();
        end
        
        function onValueChange(obj,h,e)
            if ~iscell(h.ColumnFormat{e.Indices(2)}) || any(strcmp(h.ColumnFormat{e.Indices(2)},e.NewData))
                obj.lastChangeRow = e.Indices(1);
                obj.lastChangedColumn = e.Indices(2); 
                obj.lastChangedValue = e.NewData;
                obj.notify('EditValueChange')
            else
                %If the column was a dropdown and the user edited the
                %value that was not in the list, we revert
                h.Data{e.Indices(1),e.Indices(2)} = e.PreviousData;
            end
            obj.refreshButtons();
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set/Get
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function value = getData(obj)
            value = obj.TableMain.Data;
        end
        
        function setData(obj,input)
            obj.TableMain.Data = input;
        end
        
        function setNewLineValue(obj,input)
            [~,colsIn] = size(input);
            [~,colsData] = size(obj.TableMain.Data);
            if colsIn == colsData
                obj.NewLineValue = Input;
            else
                error('Could not set new line template. Size Mismatch')
            end
        end
        
        function [row,column,value] = lastChangedElement(obj)
            row = obj.lastChangeRow;
            column = obj.lastChangedColumn;
            value = obj.lastChangedValue;
        end
        
        function [value] = getSelectedRow(obj)
            value = obj.Selected;
        end
        
        function setFormat(obj,input)
             obj.TableMain.ColumnFormat = input;
        end
        
        function setName(obj,input)
             obj.TableMain.ColumnName = input;
        end
       
        function setEditable(obj,input)
             obj.TableMain.ColumnEditable = input;
        end
    end
    
end
