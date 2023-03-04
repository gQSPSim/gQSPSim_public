classdef GridFlex < handle
    % GridFlex - A widget for a flexible grid. The grid has 2 sides that
    % can be resized.
    %----------------------------------------------------------------------

    properties (Access = private)
        Parent
        OuterGrid matlab.ui.container.GridLayout
        InnerAxis matlab.ui.control.UIAxes
        ChangeModeTF = false;
        PreviousX = 0;
        PreviousY = 0;
        Ratio = .33;
        Tag = '';
        ButtonDownFunctionHandle;
        ButtonUpFunctionHandle;
        ButtonMoveFunctionHandle;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = GridFlex(varargin)
            %Check input
            if nargin ==1 && (isa(varargin{1},'matlab.ui.container.Panel') || isa(varargin{1},'matlab.ui.Figure'))
                obj.Parent = varargin{1};
            else
                error("Incorrect Input")
            end
            
            obj.create();
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function create(obj)
            %Setup outer grid
            obj.OuterGrid = uigridlayout(obj.Parent);
            obj.OuterGrid.Padding = [0,0,0,0];
            obj.OuterGrid.RowHeight = {'1x'};
            obj.OuterGrid.ColumnWidth = {'33x',20,'67x'};
            obj.OuterGrid.RowSpacing = 0;
            obj.OuterGrid.ColumnSpacing = 0;
            
            %setup inner panel
            obj.InnerAxis = uiaxes(obj.OuterGrid);
            obj.InnerAxis.Layout.Row = 1;
            obj.InnerAxis.Layout.Column = 2;
            obj.InnerAxis.YColor = 'none';
            obj.InnerAxis.XColor = 'none';
            obj.InnerAxis.Color = 'none';
            obj.InnerAxis.Toolbar.Visible = 'off';
            obj.InnerAxis.Color = [0,0,0];
            disableDefaultInteractivity(obj.InnerAxis);
            
            %Create function handles
            obj.ButtonUpFunctionHandle = @(h,e) obj.buttonUpFcn(e.Source.CurrentPoint);
            obj.ButtonDownFunctionHandle = @(h,e) obj.buttonDownFcn(e.Source.CurrentPoint,e.Source.CurrentAxes);
        end
       
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % CallBacks. These need to be public so the app can refer to these.
    % This is due to a limiation in app designer
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = public)
    
        function buttonDownFcn(obj,coordinates,objectHandle)
            %Detemine if the object selected is our axis
            if obj.InnerAxis == objectHandle
                obj.ChangeModeTF = true;
                obj.PreviousX = coordinates(1);
            end
        end
       
        function buttonUpFcn(obj,coordinates)
            %When the user lifts their cursor
            if obj.ChangeModeTF
                ChangeInX = coordinates(1) - obj.PreviousX;
                Length = obj.Parent.Position(3);
                %Determine new values of window length
                Left = round((obj.Ratio*Length) + ChangeInX);
                Right = Length - Left;
                %Check if we are out of bounds
                if Left<0 
                    Left = .01;
                    Right = .99;
                    obj.Ratio = .01;
                elseif Right<0
                    Left = .99;
                    Right = .01;
                    obj.Ratio = .99;
                else
                    obj.Ratio = Left/Length;
                end
                
                %convert this ratio to char input for a grid layout;
                LeftChar = [num2str(Left),'x'];
                RightChar = [num2str(Right),'x'];
                obj.OuterGrid.ColumnWidth = {LeftChar,20,RightChar};
                obj.PreviousX = coordinates(1);
                obj.ChangeModeTF = false;
                drawnow();
            end
        end
        
    end
   
    methods(Access = public)
        
        function [functionHandle] = getButtonDownCallback(obj)
            functionHandle = obj.ButtonDownFunctionHandle;
        end
        
        function [functionHandle] = getButtonUpCallback(obj)
            functionHandle = obj.ButtonUpFunctionHandle;
        end
        
        function [functionHandle] = getButtonMoveCallback(obj)
            functionHandle = obj.ButtonMoveFunctionHandle;
        end
        
        function [gridHandle] = getGridHandle(obj)
            gridHandle = obj.OuterGrid;
        end
    end
end

