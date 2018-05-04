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

% Instantiate the application
app = QSPViewer.App();

end
