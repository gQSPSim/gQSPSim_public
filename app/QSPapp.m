function app = QSPapp()

warning('off','uix:ViewPaneManager:NoView')
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

if ~isdeployed
    
    % Verify GUI Layout Toolbox
    if isempty(ver('layout')) || verLessThan('layout','2.1')
        
        % Toolbox is missing. Prompt to download
        hDlg = errordlg(['<html>Unable to locate GUI Layout Toolbox 2.1 or '...
            'greater. Please find and install "GUI Layout Toolbox" on '...
            'the MATLAB Add-On Explorer or File Exchange. '],...
            'WindowStyle','modal');
        uiwait(hDlg);
        
        if verLessThan('matlab','R2015b')
            % Launch Web Browser to GUI Layout Toolbox  (prior to R2016a)
            web('https://www.mathworks.com/matlabcentral/fileexchange/47982','-browser');
        elseif verLessThan('matlab','R2016a')
            % Launch Add-On Browser to GUI Layout Toolbox (R2016a only)
            matlab.internal.language.introspective.showAddon('e5af5a78-4a80-11e4-9553-005056977bd0');
        else
            % Launch Add-On Browser to GUI Layout Toolbox
            com.mathworks.addons.AddonsLauncher.showDetailPageInExplorerFor('e5af5a78-4a80-11e4-9553-005056977bd0','AO_CONSULTING')
        end
        
    end
    
end %if ~isdeployed

%% Add java class paths

% Disable warnings
warning('off','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame')
warning('off','MATLAB:Java:DuplicateClass');
warning('off','MATLAB:javaclasspath:jarAlreadySpecified')
EchoOutput = true;

if EchoOutput
    disp('Initializing Java paths for UI Widgets');
    disp('---------------------------------------------------');
end

% Get the root directory, based on the path of this file
RootPath = fileparts(mfilename('fullpath'));

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
fprintf('%s\n',Paths{:});

% Add paths
javaaddpath(Paths);

if EchoOutput
    disp('---------------------------------------------------');
end

% Instantiate the application
app = QSPViewer.App();

end
