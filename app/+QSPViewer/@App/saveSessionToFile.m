function StatusOk = saveSessionToFile(obj,FilePath,idx)
% saveSessionToFile
% -------------------------------------------------------------------------
% Abstract: This method is executed when the user wants to save the current
% session to a file
%


% Save the data to MAT format
StatusOk = true;
try
    s.Session = obj.Session(idx); %#ok<STRNU>
    save(FilePath,'-struct','s');
catch err
    StatusOk = false;
    Message = sprintf('The file %s could not be saved:\n%s',...
        FilePath, err.message);
    hDlg = errordlg(Message,'Save File','modal');
    uiwait(hDlg);
end