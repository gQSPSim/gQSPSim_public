function StatusOk = loadSessionFromFile(obj,FilePath)
% loadSessionFromFile
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user user wants to load a
% session from a file
%

% Copyright 2016 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 226 $  $Date: 2016-08-02 16:46:16 -0400 (Tue, 02 Aug 2016) $
% ---------------------------------------------------------------------

StatusOk = true;

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
    Session = s.Session;
catch err
    StatusOk = false;
    Message = sprintf(['The file %s did not contain a valid '...
        'Session object:\n%s'], FileName, err.message);
end

if StatusOk
    
    % Add the session to the app
    obj.createNewSession(Session);
    
    % Start timer
    initializeTimer(Session);
    
    % check the session root
    if ~exist(Session.RootDirectory, 'dir') && strcmp(questdlg('Session root directory is invalid. Select a new root directory?', 'Select root directory', 'Yes'),'Yes')        
        rootDir = uigetdir(Session.RootDirectory, 'Select valid session root directory');
        if rootDir ~= 0
            Session.RootDirectory = rootDir;
        end
    end
else
    hDlg = errordlg(Message,'Open File','modal'); uiwait(hDlg);
end