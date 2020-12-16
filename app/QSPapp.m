function varargout = QSPapp()

if verLessThan('matlab','9.4') 
    ThisVer = ver('matlab');
    warning('gQSPSim has not been tested in versions prior to R2018a (9.4). This MATLAB release %s may not be supported for gQSPSim',ThisVer.Release);
end

EchoOutput = false;

warning('off','uix:ViewPaneManager:NoView');
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
warning('off','MATLAB:Axes:NegativeDataInLogAxis');
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');

% Check for the Text Analytics Toolbox install state. If it is around we have 
% a conflict with the use of the POI java library so warn the user (or error?)
installedProducts = ver;
if any(string({installedProducts.Name}) == "Text Analytics Toolbox")
    error("The Text Analytics Toolbox conflicts with some of the functionality in gQSPSim.\n Please uninstall Text Analytics Toolbox to proceed%s", ".");
end

% Check the long file name setting in the registry.
if ispc
    try
        longFileNameEnabledTF = winqueryreg('HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Control\FileSystem', 'LongPathsEnabled');
        if longFileNameEnabledTF == 0
            installPath = string(fileparts(which(mfilename))).extractBefore("\app");
            warnString = sprintf('Proper operation of gQSPsim requires long filename support to be enabled.\nLong filename support can be enabled with Remove_260_Character_Path_Limit.reg in:\n%s\\utilities', installPath);
            warndlg(warnString);
            % Adding the message to the command line so that people can cut and paste the path.
            warning(warnString);
        end
    catch 
        % Don't want this code producing an error.
    end
end

if ~isdeployed
    
    % Verify GUI Layout Toolbox
    if isempty(ver('layout')) || verLessThan('layout','2.3.4')
        installPath = string(fileparts(which(mfilename))).extractBefore(filesep + "app");
        guiLayoutToolboxFile = installPath + filesep + "GUI Layout Toolbox 2.3.4.mltbx";            
        
        installedGUILayoutToolbox = matlab.addons.toolbox.installToolbox(guiLayoutToolboxFile);
        if isempty(installedGUILayoutToolbox)
            hDlg = errordlg('Exiting QSPapp.', 'WindowStyle','modal');
            uiwait(hDlg);
            return
        end
    end
       
    if isempty(mex.getCompilerConfigurations('C','Supported'))
        hDlg = errordlg(['Unable to locate C compiler. Please install a compatible compiler before launching. '...
            'See www.mathworks.com for more details.'],...
            'WindowStyle','modal');
        uiwait(hDlg);
        return
    end

end %if ~isdeployed


% Get the root directory, based on the path of this file
filename = mfilename('fullpath');
filename = regexprep(filename, 'gQSPsim/app/(\.\./app)+', 'gQSPsim/app');
filename = strrep(filename , '/../app', '');

RootPath = fileparts(filename);


%% Set up the paths to add to the MATLAB path

%************ EDIT BELOW %************

% The true/false argument specifies whether the given directory should
% include children (true) or just itself (false)

rootDirs={...
    fullfile(RootPath,'..','app'),true;... %root folder with children
    fullfile(RootPath,'..','utilities'),true;... %root folder with children
    fullfile(RootPath,'..','FromGenentech'),true;... %root folder with children
    fullfile(RootPath,'..'),false;
    };

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
    for pCount=1:length(svnFilteredPath) %#ok<FXSET>
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

%% Add java class paths

% Disable warnings
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
warning('off','MATLAB:Java:DuplicateClass');
warning('off','MATLAB:javaclasspath:jarAlreadySpecified')

if EchoOutput
    disp('Initializing Java paths for UI Widgets');
    disp('---------------------------------------------------');
end

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

% Display
if EchoOutput
    fprintf('%s\n',Paths{:});
end

% Add paths
javaaddpath(Paths);

if EchoOutput
    disp('---------------------------------------------------');
end

% run the units script
registerUnits;

% Check for product dependencies. 
dependentProducts = {'statistics_toolbox', 'simbiology'};
dependencyAvailable = false(size(dependentProducts));
for i = 1:numel(dependentProducts)    
    dependencyAvailable(i) = license('test', dependentProducts{i});
end

if any(~dependencyAvailable)
    fprintf('Required product(s) not found.\n'); 
    error('Missing: %s\n', dependentProducts{present});
end       

if nargout == 1
    varargout{1} = QSPViewer.App();
else
    QSPViewer.App();
end

end
