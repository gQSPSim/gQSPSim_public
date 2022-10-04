function StatusOk = loadSessionFromFile(obj, FilePath, interactiveTF)
% loadSessionFromFile
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user user wants to load a
% session from a file
%


StatusOk = true;

if nargin == 2
    interactiveTF = true;
end

% Get the filename
[~,FileName] = fileparts(FilePath);

% Load the data
try
    s = load(FilePath,'Session');
    if s.Session.toRemove
        % cancelled
        StatusOk = false;
        return
    end
catch err
    StatusOk = false;
    Message = sprintf('The file %s could not be loaded:\n%s',...
        FileName, err.message);
end

% Validate the file
try
    validateattributes(s.Session,{'QSP.Session'},{'scalar'})
    
    % check the session root
    if ~exist(s.Session.RootDirectory, 'dir')         
        s.Session.RootDirectory = fileparts(FilePath);
%         fprintf('Setting root directory to: %s\n', s.Session.RootDirectory)
        if interactiveTF
            if usejava('jvm') && feature('ShowFigureWindows') % there is a display
                if strcmp(questdlg('Session root directory is invalid. Select a new root directory?', 'Select root directory', 'Yes'),'Yes')        
                    rootDir = uigetdir(fileparts(FilePath), 'Select valid session root directory');
                    if rootDir ~= 0
                        s.Session.RootDirectory = rootDir;
                    end
                end
            end
        end
    end
    
    Session = copy(s.Session);
catch err
    StatusOk = false;
    Message = sprintf(['The file %s did not contain a valid '...
        'Session object:\n%s'], FileName, err.message);
end

if StatusOk
    
    % convert rules and reactions
    
    %Session.validateRulesAndReactions();
    
    
    % Add the session to the app
    obj.createNewSession(Session);
else
    hDlg = errordlg(Message,'Open File','modal'); 
    uiwait(hDlg);
end