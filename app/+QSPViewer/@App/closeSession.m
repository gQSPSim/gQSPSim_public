function StatusOk = closeSession(obj,idx)
% saveSessionToFile
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user wants to save the current
% session to a file
%

% Copyright 2016 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 240 $  $Date: 2016-08-10 13:01:21 -0400 (Wed, 10 Aug 2016) $
% ---------------------------------------------------------------------

StatusOk = true;

% Delete the session's tree node
delete(obj.SessionNode(idx));

% Remove the session object
obj.Session(idx) = [];

