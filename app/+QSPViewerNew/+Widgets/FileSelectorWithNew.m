classdef FileSelectorWithNew < QSPViewerNew.Widgets.FileSelector 
    % FileSelectorWithNew  - A widget for selecting a file with the option
    % to create a new file with the given template
    %----------------------------------------------------------------------
    % Create a widget that allows you to specify a filename by editable
    % text or by interactive dialog or create a new file
    %-----------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 3/2/20
    
    properties (Access = private)
        FileTemplatePath 
    end
    
    properties (Dependent)
        FileNameTemplate
    end

    properties (Access = private)
        AddButtonHandle  matlab.ui.control.Button
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Public API
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function  obj = FileSelectorWithNew(varargin)
            obj@QSPViewerNew.Widgets.FileSelector(varargin{:});
        end
        
        function setFileTemplate(obj,value)
            [~,~,ext] = fileparts(value);
            if strcmpi(ext,obj.FileExtension)
                obj.FileTemplatePath = value;
            end
        end
        
        function value = get.FileNameTemplate(obj)
            [~,name,~] = fileparts(obj.FileTemplatePath);
            value = name;
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Helpers
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = protected)
        
        function create(obj)
            
            create@QSPViewerNew.Widgets.Abstract.SelectorBase(obj);
            
            % Add room for an extra button
            obj.InternalGrid.ColumnWidth = [obj.InternalGrid.ColumnWidth, {obj.ButtonSize}];
            
            % Create Add Button 
            obj.AddButtonHandle = uibutton(obj.InternalGrid, 'push');
            obj.AddButtonHandle.Layout.Row = 1;
            obj.AddButtonHandle.Layout.Column = 4;
            obj.AddButtonHandle.Icon = QSPViewerNew.Resources.LoadResourcePath('add_24.png');
            obj.AddButtonHandle.ButtonPushedFcn = @obj.onAddButtonPress;
            obj.AddButtonHandle.Text = '';
            obj.AddButtonHandle.Tooltip = {'Click to create new'};
            
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)

        function onAddButtonPress(obj,~,~)
            if ~isempty(obj.FileTemplatePath) 
                selection = uiconfirm(obj.findParentUIFigure(obj.InternalGrid),sprintf('This will create a new Parameters file in %s. Proceed?',obj.RootDirectory),'Confirm new file creation');
                switch selection
                    case'OK'
                        try
                            %Determine the file path of the new file
                            FilesOfSameType = dir(fullfile(obj.RootDirectory,['*',obj.FileExtension]));
                            FilesOfSameType = cellfun(@(f) strrep(f, obj.FileExtension, ''), {FilesOfSameType.name}, 'UniformOutput', false);

                            newFileName = [matlab.lang.makeUniqueStrings(obj.FileNameTemplate, FilesOfSameType),obj.FileExtension];
                            newFilePath = fullfile(obj.RootDirectory,newFileName);
                            
                            % copy the file to the new location
                            copyfile(obj.FileTemplatePath,newFilePath);
                            
                            if ispc
                                winopen(newFilePath)
                            else
                                system(sprintf('open "%s"', newFilePath));
                            end
                            obj.RelativePath = newFileName;
                        catch err
                            uialert(obj.findParentUIFigure(obj.InternalGrid),sprintf('Error encountered creating new file: %s', err.message),'Error')
                        end
                        
                    case 'Cancel'
                        
                end
                obj.update()
                notify(obj,'StateChanged')
            end
            
        end
     
    end
    
    methods(Access = private)
        
        function value = findParentUIFigure(~, graphicsHandle)
            value = ancestor(graphicsHandle,'figure');
        end
        
    end
    
end