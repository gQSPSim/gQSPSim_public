function OutPaths = DefinePaths(varargin)
% DefinePaths - Set up the MATLAB path
% -------------------------------------------------------------------------
% Abstract: This function prepares the MATLAB path
%
% Syntax:
%           DefinePaths()
%
% Inputs:
%           EchoOutput - true to echo paths to command window (optional,
%           default true)
%
% Outputs:
%           none
%
% Examples:
%           DefinePaths;
%
% Notes: This function must reside in the root directory for the tools.
%

% Copyright 2013 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 312 $  $Date: 2016-09-08 13:06:09 -0400 (Thu, 08 Sep 2016) $
% ---------------------------------------------------------------------

if nargin < 1
    EchoOutput = true;
else
    if islogical(varargin{1})
        EchoOutput = varargin{1};
    else
        EchoOutput = true;
    end       
end

if nargin==2
    doAdd = varargin{2};
else
    doAdd = true;
end

% Disable warnings
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
warning('off','MATLAB:Java:DuplicateClass');
warning('off','MATLAB:javaclasspath:jarAlreadySpecified')

if EchoOutput
    disp('Initializing MATLAB paths');
    disp('---------------------------------------------------');
end

% Get the root directory, based on the path of this file
RootPath = fileparts(mfilename('fullpath'));


%% Set up the paths to add to the MATLAB path

%************ EDIT BELOW %************

% The true/false argument specifies whether the given directory should
% include children (true) or just itself (false)

rootDirs={...
    fullfile(RootPath,'app'),true;... %root folder with children
    fullfile(RootPath,'utilities'),true;... %root folder with children
    fullfile(RootPath,'FromGenentech'),true;... %root folder with children
    
    };

OutPaths = [ genpath(fullfile(RootPath,'app')), genpath(fullfile(RootPath,'utilities')), genpath(fullfile(RootPath,'FromGenentech')) ];

%************ EDIT ABOVE %************

pathCell = regexp(path, pathsep, 'split');

%% Loop through the paths and add the necessary subfolders to the MATLAB path
for pCount = 1:size(rootDirs,1)
    
    rootDir=rootDirs{pCount,1};
    if rootDirs{pCount,2}
        % recursively add all paths
        rawPath=genpath(rootDir);
        rawPathCell=textscan(rawPath,'%s','delimiter',';');
        rawPathCell=rawPathCell{1};
        
    else
        % Add only that particular directory
        rawPath = rootDir;
        rawPathCell = {rawPath};
    end
    
    % remove undesired paths
    svnFilteredPath=strfind(rawPathCell,'.svn');
    slprjFilteredPath=strfind(rawPathCell,'slprj');
    sfprjFilteredPath=strfind(rawPathCell,'sfprj');
    rtwFilteredPath=strfind(rawPathCell,'_ert_rtw');
    
    % loop through path and remove all the .svn entries
    for pCount=1:length(svnFilteredPath), %#ok<FXSET>
        filterCheck=[svnFilteredPath{pCount},...
            slprjFilteredPath{pCount},...
            sfprjFilteredPath{pCount},...
            rtwFilteredPath{pCount}];
        if isempty(filterCheck)
            if EchoOutput
                disp(['Adding ',rawPathCell{pCount}]);
            end
            if ispc  % Windows is not case-sensitive
                if ~any(strcmpi(rawPathCell{pCount}, pathCell))
                    thisPath = rawPathCell{pCount};
                    if doAdd
                        addpath(thisPath); %#ok<MCAP>
                    end
                    OutPaths = [OutPaths, thisPath];
                end
            else
                if ~any(strcmp(rawPathCell{pCount}, pathCell))
                    thisPath = rawPathCell{pCount};         
                    if doAdd
                        addpath(thisPath); %#ok<MCAP>
                    end
                    OutPaths = [OutPaths, thisPath];                    
                end
            end
        else
            % ignore
        end
    end
    
end


%% Add java class paths

addpath(genpath('GUI_Layout_Toolbox'));

if EchoOutput
    disp('Initializing Java paths for UI Widgets');
    disp('---------------------------------------------------');
end

% Tree controls and XLWRITE
Paths = {
    fullfile(RootPath,'app','+uix','+resource','UIExtrasTable.jar')
    fullfile(RootPath,'app','+uix','+resource','UIExtrasTree.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','poi-3.8-20120326.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','poi-ooxml-3.8-20120326.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','poi-ooxml-schemas-3.8-20120326.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','xmlbeans-2.3.0.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','dom4j-1.6.1.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','stax-api-1.0.1.jar')
    };

% Display
if EchoOutput
    fprintf('%s\n',Paths{:});
end

% Add paths
javaaddpath(Paths);

if EchoOutput
    disp('---------------------------------------------------');
end
