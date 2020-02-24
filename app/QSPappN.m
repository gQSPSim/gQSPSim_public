function varargout = QSPappN()

    if verLessThan('matlab','9.8') % If version < R2018a (9.4) or >= R2018b (9.5)
      ThisVer = ver('matlab');
      warning('QSPAppN is not supported on %s. Use QSPapp instead.', ThisVer.Release);
    end    

    warning('off','uix:ViewPaneManager:NoView')
    warning('off','MATLAB:table:ModifiedAndSavedVarnames');
    warning('off','MATLAB:Axes:NegativeDataInLogAxis')
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
    
    % Get the root directory, based on the path of this file
    filename = mfilename('fullpath');
    filename = regexprep(filename, 'gQSPsim/app/(\.\./app)+', 'gQSPsim/app');
    filename = strrep(filename , '/../app', '');
    
    RootPath = fileparts(filename);
    
    % Set up the paths to add to the MATLAB path
    
    %************ EDIT BELOW %************
    
    % The true/false argument specifies whether the given directory should
    % include children (true) or just itself (false)
    rootDirs={...
        fullfile(RootPath, '..', 'app'),          true; ...
        fullfile(RootPath, '..', 'utilities'),    true; ...
        fullfile(RootPath, '..', 'FromGenentech'),true; ...
        };
    
    %************ EDIT ABOVE %************
    
    pathCell = regexp(path, pathsep, 'split');
    
    % Loop through the paths and add the necessary subfolders to the MATLAB path
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
                if ispc  % Windows is not case-sensitive
                    if ~any(strcmpi(rawPathCell{pCount}, pathCell))
                        addpath(rawPathCell{pCount}); %#ok<MCAP>
                    end
                else
                    if ~any(strcmp(rawPathCell{pCount}, pathCell))
                        addpath(rawPathCell{pCount}); %#ok<MCAP>
                    end
                end
            else
                % ignore
            end
        end
        
    end
    
    % Add java class paths
    
    % Disable warnings
    warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
    warning('off','MATLAB:Java:DuplicateClass');
    warning('off','MATLAB:javaclasspath:jarAlreadySpecified')
    
    % Tree controls and XLWRITE
    Paths = {
        fullfile(RootPath,'+uix','+resource','UIExtrasTable.jar')
        fullfile(RootPath,'+uix','+resource','UIExtrasTree.jar')
        fullfile(RootPath,'20130227_xlwrite','poi_library','poi-3.8-20120326.jar')
        fullfile(RootPath,'20130227_xlwrite','poi_library','poi-ooxml-3.8-20120326.jar')
        fullfile(RootPath,'20130227_xlwrite','poi_library','poi-ooxml-schemas-3.8-20120326.jar')
        fullfile(RootPath,'20130227_xlwrite','poi_library','xmlbeans-2.3.0.jar')
        fullfile(RootPath,'20130227_xlwrite','poi_library','dom4j-1.6.1.jar')
        fullfile(RootPath,'20130227_xlwrite','poi_library','stax-api-1.0.1.jar')
        };
    
    % Add paths
    javaaddpath(Paths);
    
    % run the units script
    registerUnits
    
    app = QSPViewerNew.Application.ApplicationUI;
    if nargout == 1
        varargout{1} = app;
    end
end
