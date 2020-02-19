classdef FolderSelector < handle
    % FolderSelector - A widget for selecting a filename
    %----------------------------------------------------------------------
    % Create a widget that allows you to specify a filename by editable
    % text or by dialog.
    %-----------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 01/16/20
    
    properties (Access = private)
        LabelText;
        RelativePath ='';
        LastValidPath = '';
        RootDirectory ='';
        Parent 
        Row 
        Column
    end
    
    properties (Dependent)
        IsValid;
        FullPath;
    end

    properties (Access = private)
        ButtonHandle        matlab.ui.control.Button
        EditTextHandle      matlab.ui.control.EditField
        InternalGrid        matlab.ui.container.GridLayout
        Label               matlab.ui.control.Label
    end
    
    events
        StateChanged
    end
    
    properties(Constant = true)
        DescriptionSize = 200;
        ButtonSize = 30;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
        
        function  obj = FolderSelector(varargin)
            %Check input
            if nargin ~= 4 && ~isa(varargin{1},'matlab.ui.container.GridLayout')
                error("You need to provide the following: UIgirdlaout parent, row, column, and a label");
            end
            %Set the parent
            obj.Parent = varargin{1};
            obj.Row = varargin {2};
            obj.Column = varargin{3};
            obj.LabelText = varargin{4};
            
            %create the uiobjects
            obj.create();
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Helpers
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = protected)
        
        function create(obj)
            %Create GridLayout2
            obj.InternalGrid = uigridlayout(obj.Parent);
            obj.InternalGrid.ColumnWidth = {obj.DescriptionSize,'1x',obj.ButtonSize};
            obj.InternalGrid.RowHeight = {obj.ButtonSize};
            obj.InternalGrid.Padding = [0,0,0,0];
            obj.InternalGrid.ColumnSpacing = 0;
            obj.InternalGrid.Layout.Row = obj.Row;
            obj.InternalGrid.Layout.Column = obj.Column;
            
            
            % Create Button
            obj.ButtonHandle = uibutton(obj.InternalGrid, 'push');
            obj.ButtonHandle.Layout.Row = 1;
            obj.ButtonHandle.Layout.Column = 3;
            obj.ButtonHandle.Icon = '+QSPViewerNew\+Resources\folder_24.png';
            obj.ButtonHandle.ButtonPushedFcn = @obj.onButtonPress;
            obj.ButtonHandle.Text = '';
            obj.ButtonHandle.Tooltip = {'Click to browse'};
            
            %Create Description
            obj.Label = uilabel(obj.InternalGrid);
            obj.Label.Layout.Row = 1;
            obj.Label.Layout.Column = 1;
            obj.Label.Text = obj.LabelText;

            % Create EditField
            obj.EditTextHandle = uieditfield(obj.InternalGrid, 'text');
            obj.EditTextHandle.Tooltip = {'Edit the path'};
            obj.EditTextHandle.Layout.Row = 1;
            obj.EditTextHandle.Layout.Column = 2;
            obj.EditTextHandle.ValueChangedFcn = @(h,e) obj.onEditValueChanged(e.Value);
        end

        function update(obj)
            if obj.IsValid
                obj.EditTextHandle.FontColor = 'k';
            else 
                obj.EditTextHandle.FontColor = 'r';
            end
            obj.EditTextHandle.Value = obj.RelativePath;
            
            notify(obj,'StateChanged')
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onButtonPress(obj,~,~)
            
            %Determine if there is a file path to start at
            if exist(obj.RootDirectory,'dir')
                foldername = uigetdir(obj.FullPath,'Select a folder' );
            elseif exist(obj.LastValidPath,'dir')
                foldername = uigetdir(obj.LastValidPath,'Select a folder' );
            else
                foldername = uigetdir('','Select a folder' );
            end
            
            if foldername ~=0
                obj.RelativePath = erase(foldername,obj.RootDirectory);
            end
            
            obj.update();
        end
        
        function onEditValueChanged(obj,newValue)
            obj.RelativePath = newValue;
            obj.update();
        end
     
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set/Get
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        function value = get.FullPath(obj)
            if isempty(obj.RootDirectory)
                value = obj.RelativePath;
            elseif ismac || isunix
                value = [obj.RootDirectory,'/',obj.RelativePath];
            else
                value = [obj.RootDirectory,'\',obj.RelativePath];
            end
        end
             
        function value = get.IsValid(obj)
            value = exist(obj.FullPath,'dir'); 
        end
        
        function set.RootDirectory(obj,newDir)
            if isfolder(newDir)
                obj.RootDirectory = newDir;
                obj.update();
            else
                warning("Valid Directory Not Provided")
            end
        end
        
    end
end

