classdef SelectorBase < handle
    % SelectorBase - A base class for widgets for selecting folders/files
    %----------------------------------------------------------------------
    % Create a widget that allows you to specify a file- or foldername by 
    % editable text or by dialog.
    %-----------------------------------------------------------
    
    properties (Access = private)
        RelativePathParts  = {}
        RootDirectoryParts = {}
        LabelText
        Row 
        Column
    end
    
    properties (Access = protected)
        Parent
    end
    
    properties (Dependent)
        RootDirectory
        RelativePath
        FullPath
    end
    
    properties (Access = private)
        ButtonHandle        matlab.ui.control.Button
        EditTextHandle      matlab.ui.control.EditField
        Label               matlab.ui.control.Label
    end
    
    properties (Access = protected)
        InternalGrid        matlab.ui.container.GridLayout
    end
    
    events
        StateChanged
    end
    
    properties(Constant)
        DescriptionSize = 200
        ButtonSize      = 30
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Abstract methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected)
        % Implement in subclass: return true if FullPath is valid,
        % otherwise return false.
        value = isValid(obj)
        % Implement in subclass: return text to be displayed in edit field.
        text = getDisplayText(obj)
        % Implement folder/file selector in subclass
        selected = startSelector(obj, startFolder);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
        
        function  obj = SelectorBase(parent, row, column, labelText)
            %Check input
            if nargin < 4 || ~isa(parent,'matlab.ui.container.GridLayout')
                error("You need to provide the following: UIgirdlaout parent, row, column, and a label");
            end
            
            %Set the parent
            obj.Parent    = parent;
            obj.Row       = row;
            obj.Column    = column;
            obj.LabelText = labelText;
            
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
            obj.ButtonHandle.Icon = QSPViewerNew.Resources.LoadResourcePath('folder_24.png');
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
            if obj.isValid()
                obj.EditTextHandle.FontColor = 'k';
            else 
                obj.EditTextHandle.FontColor = 'r';
            end
            obj.EditTextHandle.Value = obj.getDisplayText();
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onButtonPress(obj,~,~)
            %Determine if there is a file path to start at
            if exist(obj.FullPath, 'dir') == 7
                startFolder = obj.FullPath;
            elseif exist(obj.RootDirectory,'dir') == 7
                startFolder = obj.RootDirectory;
            else
                startFolder = '';            
            end
            
            selected = obj.startSelector(startFolder);
            
            if ischar(selected)
                obj.RelativePath = uix.utility.getRelativeFilePath(selected, obj.RootDirectory, false);
            end
            
        end
        
        function onEditValueChanged(obj, value)
            % Try to see if 'value' is a relative path
            value = strtrim(value);
            if ~isempty(value)
                absPath = uix.utility.getAbsoluteFilePath(value, obj.RootDirectory);
                if isfolder(absPath)
                    value = uix.utility.getRelativeFilePath(absPath, obj.RootDirectory, false);
                else
                    relPath = uix.utility.getRelativeFilePath(value, obj.RootDirectory, false);
                    if isfolder(uix.utility.getAbsoluteFilePath(relPath, obj.RootDirectory))
                        value = relPath;
                    end
                end
            end
            obj.RelativePath = value;
        end
     
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set/Get
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function value = get.FullPath(obj)
            value = uix.utility.getAbsoluteFilePath(obj.RelativePath, obj.RootDirectory);
        end
        
        function set.RootDirectory(obj, newDir)
            if isfolder(newDir)
%                 % Update relative path with respect to new root directory
%                 if ~isempty(obj.RelativePathParts)
%                     relativePath = uix.utility.getRelativeFilePath(obj.FullPath, newDir, false);
%                     obj.RelativePathParts = strsplit(relativePath, filesep);
%                 end
                obj.RootDirectoryParts = strsplit(newDir, filesep);
                obj.update();
            else
                warning("Valid Directory Not Provided")
            end
        end
        function rootDir = get.RootDirectory(obj)
            rootDir = strjoin(obj.RootDirectoryParts, filesep);
        end
        
        function set.RelativePath(obj, relativePath)
            relativePath = strtrim(relativePath);
            if isempty(relativePath)
                obj.RelativePathParts = {};
            else
                absPath = uix.utility.getAbsoluteFilePath(relativePath, obj.RootDirectory);
                relativePath = uix.utility.getRelativeFilePath(absPath, obj.RootDirectory, false);
                obj.RelativePathParts = strsplit(relativePath, filesep);
            end
            obj.update();
            notify(obj,'StateChanged');
        end
        function relativePath = get.RelativePath(obj)
            relativePath = strjoin(obj.RelativePathParts, filesep);
        end
 

    end
    
end