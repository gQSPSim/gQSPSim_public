classdef DoubleSelectBox < handle
    % DoubleSelectBox - Display and choose items in a listbox to be moved to a
    % second listbox
    %----------------------------------------------------------------------
    % This class will be used to describe the graphic used to move items
    % back and forth between 2 list boxes as used in gQSPsim
    %-----------------------------------------------------------

    properties(Access = private)
        Parent
        Row
        Column
        Title
        SelectedRight
        SelectedLeft
    end
    
    properties (Access = private)
       PanelMain              matlab.ui.container.Panel
       GridMain               matlab.ui.container.GridLayout
       GridMiddle             matlab.ui.container.GridLayout
       GridBottom             matlab.ui.container.GridLayout
       ListBoxLeft            matlab.ui.control.ListBox
       ListBoxRight           matlab.ui.control.ListBox
       MoveItemRightButton    matlab.ui.control.Button
       MoveItemUpButton       matlab.ui.control.Button
       MoveItemDownButton     matlab.ui.control.Button
       RemoveItemButton       matlab.ui.control.Button
       GridFilterBottom       matlab.ui.container.GridLayout
       FilterSearchEditField  matlab.ui.control.EditField
       FilterButton           matlab.ui.control.Image
    end
    
    properties (Dependent)
        RightList
        LeftList
    end
    
    properties (Transient = true)
        LeftListItemsAll        % To hold all left list items at the time of object initialization
    end
    
    events
        StateChanged
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
        
        function  obj = DoubleSelectBox(varargin)
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
        
        function setRightListBox(obj,listOfNames)
            obj.ListBoxRight.Items = listOfNames;
            obj.resetIndex();
        end
        
        function setLeftListBox(obj,listOfNames)
            obj.ListBoxLeft.Items = listOfNames;
            obj.LeftListItemsAll = listOfNames;
            obj.resetIndex();
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
            obj.GridMain.ColumnWidth = {'1x',ButtonSize,'1x'};
            obj.GridMain.RowHeight = {'1x',ButtonSize};
            obj.GridMain.Padding = [pad,pad,pad,pad];
            obj.GridMain.ColumnSpacing = pad;
            obj.GridMain.RowSpacing = pad;

            %Add the left list box
            obj.ListBoxLeft = uilistbox(obj.GridMain);
            obj.ListBoxLeft.Layout.Row = 1;
            obj.ListBoxLeft.Layout.Column = 1;
            obj.ListBoxLeft.Multiselect = 'on';
            obj.ListBoxLeft.ValueChangedFcn = @obj.leftListBoxValueChanged;

            %Add the right list box
            obj.ListBoxRight = uilistbox(obj.GridMain);
            obj.ListBoxRight.Layout.Row = 1;
            obj.ListBoxRight.Layout.Column = 3;
            obj.ListBoxRight.Multiselect = 'on';
            obj.ListBoxRight.ValueChangedFcn = @obj.rightListBoxValueChanged;

            %EnterEmptyLists
            obj.setRightListBox({});
            obj.setLeftListBox({});

            %Add the middle grid
            obj.GridMiddle = uigridlayout(obj.GridMain);
            obj.GridMiddle.ColumnWidth = {'1x'};
            obj.GridMiddle.RowHeight = {'1x',ButtonSize,'1x'};
            obj.GridMiddle.Layout.Row = 1;
            obj.GridMiddle.Layout.Column = 2;
            obj.GridMiddle.Padding = [pad,pad,pad,pad];
            obj.GridMiddle.ColumnSpacing = pad;
            obj.GridMiddle.RowSpacing = pad;

            %Add the move over button
            obj.MoveItemRightButton = uibutton(obj.GridMiddle,'push');
            obj.MoveItemRightButton.Layout.Row = 2;
            obj.MoveItemRightButton.Layout.Column = 1;
            obj.MoveItemRightButton.Icon = QSPViewerNew.Resources.LoadResourcePath('arrow_right_24.png');
            obj.MoveItemRightButton.Text = '';
            obj.MoveItemRightButton.ButtonPushedFcn = @obj.moveItemToRight;

            %Add the bottom grid
            obj.GridBottom = uigridlayout(obj.GridMain);
            obj.GridBottom.ColumnWidth = {ButtonSize,ButtonSize,ButtonSize,'1x'};
            obj.GridBottom.RowHeight = {'1x'};
            obj.GridBottom.Layout.Row = 2;
            obj.GridBottom.Layout.Column = 3;
            obj.GridBottom.Padding = [pad,pad,pad,pad];
            obj.GridBottom.ColumnSpacing = pad;
            obj.GridBottom.RowSpacing = pad;


            %Add the move item up button
            obj.MoveItemUpButton = uibutton(obj.GridBottom,'push');
            obj.MoveItemUpButton.Layout.Row = 1;
            obj.MoveItemUpButton.Layout.Column = 1;
            obj.MoveItemUpButton.Icon = QSPViewerNew.Resources.LoadResourcePath('arrow_up_24.png');
            obj.MoveItemUpButton.Text = '';
            obj.MoveItemUpButton.ButtonPushedFcn = @obj.moveItemUp;

             %Add the move item down button
            obj.MoveItemDownButton = uibutton(obj.GridBottom,'push');
            obj.MoveItemDownButton.Layout.Row = 1;
            obj.MoveItemDownButton.Layout.Column = 2;
            obj.MoveItemDownButton.Icon = QSPViewerNew.Resources.LoadResourcePath('arrow_down_24.png');
            obj.MoveItemDownButton.Text = '';
            obj.MoveItemDownButton.ButtonPushedFcn = @obj.moveItemDown;

            %Add the delete button
            obj.RemoveItemButton = uibutton(obj.GridBottom,'push');
            obj.RemoveItemButton.Layout.Row = 1;
            obj.RemoveItemButton.Layout.Column = 3;
            obj.RemoveItemButton.Icon = QSPViewerNew.Resources.LoadResourcePath('delete_24.png');
            obj.RemoveItemButton.Text = '';
            obj.RemoveItemButton.ButtonPushedFcn = @obj.removeItem;
            
            %Add the bottom left grid for filter field
            obj.GridFilterBottom = uigridlayout(obj.GridMain);
            obj.GridFilterBottom.ColumnWidth = {'1x',ButtonSize};
            obj.GridFilterBottom.RowHeight = {'1x'};
            obj.GridFilterBottom.Layout.Row = 2;
            obj.GridFilterBottom.Layout.Column = 1;
            obj.GridFilterBottom.Padding = [pad,pad,pad,pad];
            obj.GridFilterBottom.ColumnSpacing = pad;
            obj.GridFilterBottom.RowSpacing = pad;
            
            %Add the filter edit box
            obj.FilterSearchEditField = uieditfield(obj.GridFilterBottom);
            obj.FilterSearchEditField.Layout.Row = 1;
            obj.FilterSearchEditField.Layout.Column = 1;
            obj.FilterSearchEditField.ValueChangingFcn = @(h,e) obj.updateListLeftItems(h,e);
            obj.FilterSearchEditField.ValueChangedFcn = @(h,e) obj.updateListLeftItems(h,e);
            
            %Add the filter search button
            obj.FilterButton = uiimage(obj.GridFilterBottom);
            obj.FilterButton.Layout.Row = 1;
            obj.FilterButton.Layout.Column = 2;
            obj.FilterButton.ImageSource = QSPViewerNew.Resources.LoadResourcePath('filter_24.png');
            
            obj.setButtonsInteractivity()
        end
        
        function setButtonsInteractivity(obj)
            %If the left box is empty, you cant move anything
            obj.setDownButtonInteractivity();
            obj.setUpButtonInteractivity();
            obj.setRightButtonInteractivity();
            obj.setRemoveButtonInteractivity();
        end
        
        function setRightButtonInteractivity(obj)
           if isempty(obj.ListBoxLeft.Items) || isempty(obj.SelectedLeft)
               obj.MoveItemRightButton.Enable = 'off';
               obj.MoveItemRightButton.BackgroundColor = [.7,.7,.7];
           else
               obj.MoveItemRightButton.Enable = 'on';
               obj.MoveItemRightButton.BackgroundColor = [.96,.96,.96];
           end
        end
        
        function setUpButtonInteractivity(obj)
           if isempty(obj.ListBoxRight.Items) || isempty(obj.SelectedRight)
               obj.MoveItemUpButton.Enable = 'off';
               obj.MoveItemUpButton.BackgroundColor = [.7,.7,.7];
           elseif obj.SelectedRight==1
               obj.MoveItemUpButton.Enable = 'off';
               obj.MoveItemUpButton.BackgroundColor = [.7,.7,.7];
           else
               obj.MoveItemUpButton.Enable = 'on';
               obj.MoveItemUpButton.BackgroundColor = [.96,.96,.96];
           end
        end
        
        function setDownButtonInteractivity(obj)
           if isempty(obj.ListBoxRight.Items) || isempty(obj.SelectedRight)
               obj.MoveItemDownButton.Enable = 'off';
               obj.MoveItemDownButton.BackgroundColor = [.7,.7,.7];
               %Find the index of the right cursor
           elseif obj.SelectedRight==length(obj.ListBoxRight.Items)
               obj.MoveItemDownButton.Enable = 'off';
               obj.MoveItemDownButton.BackgroundColor = [.7,.7,.7];
           else
               obj.MoveItemDownButton.Enable = 'on';
               obj.MoveItemDownButton.BackgroundColor = [.96,.96,.96];
           end
        end
        
        function setRemoveButtonInteractivity(obj)
           if isempty(obj.ListBoxRight.Items) || isempty(obj.SelectedRight)
               obj.RemoveItemButton.Enable = 'off';
               obj.RemoveItemButton.BackgroundColor = [.7,.7,.7];
               %Find the index of the right cursor
           else
               obj.RemoveItemButton.Enable = 'on';
               obj.RemoveItemButton.BackgroundColor = [.96,.96,.96];
           end
        end
        
        function resetIndex(obj)
            obj.ListBoxLeft.ItemsData = 1:length(obj.ListBoxLeft.Items);
            obj.ListBoxRight.ItemsData = 1:length(obj.ListBoxRight.Items);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function leftListBoxValueChanged(obj,~,eventData)
            obj.SelectedLeft = eventData.Value;
            obj.setButtonsInteractivity();
        end
        
        function rightListBoxValueChanged(obj,~,eventData)
            obj.SelectedRight = eventData.Value;
            obj.setButtonsInteractivity(); 
        end
         
        function moveItemToRight(obj,~,~)
            %eventData should be of type ButtonPushedData
            obj.ListBoxRight.Items = horzcat(obj.ListBoxRight.Items,obj.ListBoxLeft.Items{obj.SelectedLeft});
            obj.setButtonsInteractivity();
            obj.resetIndex();
            obj.notify('StateChanged')
        end
        
        function moveItemUp(obj,~,~)
            temporaryValue = obj.ListBoxRight.Items{obj.SelectedRight};
            obj.ListBoxRight.Items{obj.SelectedRight} = obj.ListBoxRight.Items{obj.SelectedRight-1}; 
            obj.ListBoxRight.Items{obj.SelectedRight-1} = temporaryValue;
            obj.resetIndex();
            obj.SelectedRight = obj.SelectedRight-1;
            obj.ListBoxRight.Value = obj.SelectedRight;
            obj.setButtonsInteractivity();
            obj.notify('StateChanged')
        end
        
        function moveItemDown(obj,~,~)
            temporaryValue = obj.ListBoxRight.Items{obj.SelectedRight};
            obj.ListBoxRight.Items{obj.SelectedRight} = obj.ListBoxRight.Items{obj.SelectedRight+1}; 
            obj.ListBoxRight.Items{obj.SelectedRight+1} = temporaryValue;
            obj.resetIndex();
            obj.SelectedRight = obj.SelectedRight+1;
            obj.ListBoxRight.Value = obj.SelectedRight;
            obj.setButtonsInteractivity();
            obj.notify('StateChanged')
        end
        
        function removeItem(obj,~,~)
            obj.ListBoxRight.Value = {};
            obj.ListBoxRight.Items(obj.SelectedRight) = [];
            if isempty(obj.ListBoxRight.Items)
                obj.SelectedRight = {};    
            elseif length(obj.ListBoxRight.Items)==1 || obj.SelectedRight==1
                obj.SelectedRight = 1;
            else
                obj.SelectedRight=obj.SelectedRight-1;
            end
            obj.resetIndex();
            obj.ListBoxRight.Value = obj.SelectedRight;
            obj.setButtonsInteractivity();
            obj.notify('StateChanged')
        end
        
        function updateListLeftItems(obj,~,e)
            findstr = e.Value;
            obj.ListBoxLeft.Items = obj.LeftListItemsAll(contains(obj.LeftListItemsAll, split(findstr), 'IgnoreCase', true));
            obj.resetIndex();
            obj.notify('StateChanged')
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set/Get
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function value = getRightList(obj)
            value = obj.ListBoxRight.Items;
        end
        
        function value = getLeftList(obj)
            value = obj.ListBoxLeft.Items;
        end
        
    end
    
end

