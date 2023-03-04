function RelPath = getRelativeFilePath(FullPath, RootPath, FlagRequireSubdir)
% getRelativeFilePath - Return the relative file path within a root
% -------------------------------------------------------------------------
% This function will find the relative file path, given a full absolute
% path and a root path
%
% Syntax:
%       RelPath = uix.utility.getRelativeFilePath(FullPath, RootPath)
%
% Inputs:
%       FullPath - the full absolute path to a file or folder
%       RootPath - the root folder to get a relative path for
%       FlagRequireSubdir - optional flag indicating whether FullPath must
%           be a subdirectory of RootPath [(true)|false]
%
% Outputs:
%       RelPath - the relative path
%
% Examples:
%
%     >> FullPath = 'C:\Program Files\MATLAB\R2016b\toolbox'
%     >> RootPath = 'C:\Program Files\MATLAB'
%     >> RelPath = uix.utility.getRelativeFilePath(FullPath, RootPath)
% 
%     RelPath =
%          \R2016b\toolbox
% 
% Notes:
%   If FullPath is not a subdirectory of RootPath and FlagRequireSubdir is
%   false, the path will contain parent directory separators "..\"
%

% Copyright 2020 The MathWorks, Inc.
%
% Auth/Revision:
%   $Author: Florian Augustin $
%   $Revision: 1 $  
%   $Date: 2020-12-02$
% ---------------------------------------------------------------------

    % Validate inputs
    if nargin<3
        FlagRequireSubdir = true;
    end
    validateattributes(RootPath,{'char'},{})
    validateattributes(FullPath,{'char'},{})
    validateattributes(FlagRequireSubdir,{'logical'},{'scalar'})

    % Helper function that takes an absolute path, absolutePath, as
    % input and returns the corresponding path, relativePath, that
    % is relative to the sessions root directory.
    rootDirectoryParts = strsplit(RootPath, filesep);
    absolutePathParts = strsplit(FullPath, filesep);
    numPathParts = numel(absolutePathParts);
    for i = 1:numPathParts
        if isempty(rootDirectoryParts) || ~strcmp(absolutePathParts{1}, rootDirectoryParts{1})
            break;
        end
        absolutePathParts(1)  = [];
        rootDirectoryParts(1) = [];
    end
    relativePathParts = repmat({'..'}, 1, numel(rootDirectoryParts));
    if isempty(relativePathParts)
        relativePathParts = {'.'};
    end
    RelPath = strjoin([relativePathParts, absolutePathParts], filesep);
    
end %if isempty(RootPath)

