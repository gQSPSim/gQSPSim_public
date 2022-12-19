function AbsPath = getAbsoluteFilePath(RelPath, RootPath)
arguments
    RelPath  (1,:) char
    RootPath (1,:) char
end
% getAbsoluteFilePath - Return the absolute file path
% -------------------------------------------------------------------------
% This function will find the absolute file path, given a relative path
% and a root path
%
% Syntax:
%       AbsPath = uix.utility.getAbsoluteFilePath(RelPath, RootPath)
%
% Inputs:
%       RelPath - the relative path
%       RootPath - the root folder to get a relative path for
%
% Outputs:
%       FullPath - the full absolute path to a file or folder
%
% Examples:
%
%     >> RelPath  = '..\R2016b\toolbox'
%     >> RootPath = 'C:\Program Files\MATLAB\WorkDir'
%     >> AbsPath  = uix.utility.getAbsoluteFilePath(RelPath, RootPath)
% 
%     AbsPath =
%          C:\Program Files\MATLAB\R2016b\toolbox
% 

% Copyright 2020 The MathWorks, Inc.
%
% Auth/Revision:
%   $Author: Florian Augustin $
%   $Revision: 1$  
%   $Date: 2020-12-02 14:31$
% ---------------------------------------------------------------------


    % Remove leading '..' or '.' from relative path if necessary, and 
    % adjust root path accordingly.
    rootDirectoryParts = strsplit(RootPath, filesep);
    relativePathParts  = strsplit(RelPath, filesep);
    if ~isempty(relativePathParts) && strcmp(relativePathParts{1}, '.')
        % Remove the leading '.'
       relativePathParts(1) = []; 
    end
    numDotDots = sum(ismember(relativePathParts, '..'));
    relativePathParts = relativePathParts(numDotDots+1:end);
    rootDirectoryParts = rootDirectoryParts(1:end-numDotDots);
    if ~isempty(relativePathParts) && isempty(relativePathParts{1})
        relativePathParts = relativePathParts(2:end);
    end

    % Append relative path to root path
    AbsPath = strjoin([rootDirectoryParts, relativePathParts], filesep);

end