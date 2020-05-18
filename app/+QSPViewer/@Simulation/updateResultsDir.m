function updateResultsDir(vObj)

if ~isempty(vObj.TempData)
    set(vObj.h.ResultsDirSelector,...
        'RootDirectory',vObj.TempData.Session.RootDirectory,...
        'Value',vObj.TempData.SimResultsFolderName_new)
else
    ResultsDir = '';
    vObj.h.ResultsDirSelector.Value = ResultsDir;
end