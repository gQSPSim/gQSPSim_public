classdef FileSelector < QSPViewerNew.Widgets.Abstract.SelectorBase
    % FileSelector - A widget for selecting a file
    %----------------------------------------------------------------------
    % Create a widget that allows you to specify a filename by editable
    % text or by interactive
    %-----------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 01/16/20
    
    properties (Access = protected)
        FileExtension
    end
    
    methods
        function  obj = FileSelector(varargin)
            obj@QSPViewerNew.Widgets.Abstract.SelectorBase(varargin{:});
        end
        
        function setFileExtension(obj,newExtension)
            obj.FileExtension = newExtension;
        end
    end
    
    methods (Access = protected)
        function value = isValid(obj)
            %Check the the file path exists and the extension is correct.
            if exist(obj.FullPath, 'file') == 2 
                [~,~,ext] = fileparts(obj.FullPath);
                value = strcmp(ext, obj.FileExtension);
            else
                value = false;
            end
        end
        function text = getDisplayText(obj)
            text = obj.RelativePath;
        end
        function selectedFile = startSelector(obj, startDirectory)
            [selectedFile, seletedPath] = uigetfile(obj.FileExtension, startDirectory, 'Select a file');
            if ischar(selectedFile)
                selectedFile = fullfile(seletedPath, selectedFile);
            else
                selectedFile = '';
            end
        end

    end

end