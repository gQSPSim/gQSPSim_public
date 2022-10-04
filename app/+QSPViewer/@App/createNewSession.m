function createNewSession(obj,Session)
% createNewSession
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user creates a new session
%


% Was a session provided? If not, make a new one
if nargin<2
    Session = QSP.Session();
end

% Add the session to the tree
hRoot = obj.h.SessionTree.Root;
obj.createTree(hRoot, Session);


%% Update the app state

% Which session is this?
newIdx = obj.NumSessions + 1;

% Add the session to the app
obj.Session(newIdx,1) = Session;

% Start timer
initializeTimer(Session);