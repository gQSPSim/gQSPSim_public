classdef FolderSelector < QSPViewerNew.Widgets.Abstract.SelectorBase
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
        DisplayFullPath
    end
    
    methods
        
        function  obj = FolderSelector(parent, row, column, labelText, displayFullPath)
            obj@QSPViewerNew.Widgets.Abstract.SelectorBase(parent, row, column, labelText);
            if nargin <= 4
                obj.DisplayFullPath = false;
            else
                obj.DisplayFullPath = displayFullPath;
            end
        end
        
    end
    
    methods (Access = protected)
        function value = isValid(obj)
            value = exist(obj.FullPath, 'dir') == 7; 
        end
        function text = getDisplayText(obj)
            if obj.DisplayFullPath
                text = obj.FullPath;
            else
                text = obj.RelativePath;
            end
        end
        function selected = startSelector(~, startDirectory)
            selected = uigetdir(startDirectory, 'Select a folder');
        end
    end
    
end

