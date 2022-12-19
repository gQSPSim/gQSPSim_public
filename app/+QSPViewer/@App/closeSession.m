function StatusOk = closeSession(obj,idx)
% saveSessionToFile
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user wants to save the current
% session to a file
%


StatusOk = true;

% Delete timer
deleteTimer(obj.Session(idx));

% remove the session's UDF from the path
obj.SelectedSession.removeUDF();

% Delete the session's tree node
delete(obj.SessionNode(idx));

% Remove the session object
obj.Session(idx) = [];

