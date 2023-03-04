function fullpath = LoadResourcePath(fileName)
    % LoadFullTemplatePath - get the full file path from a file located in
    % +QSPViewerNew\+Resources\LoadFullTemplatePath.m
    % ---------------------------------------------------------------------
    % Base properties that should be observed by all subclasses
    %
    % Auth/Revision:
    %   Max Tracy
    %   1/14/20
    % ---------------------------------------------------------------------
    
    % First try normally
    [this_dir,~,~] = fileparts(mfilename('fullpath'));
    fullpath = fullfile(this_dir,fileName);
end