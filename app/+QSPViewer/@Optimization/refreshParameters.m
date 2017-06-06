function refreshParameters(vObj)

% Parameters
if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.Parameters.Name};
    Selection = vObj.TempData.RefParamName;
    
    MatchIdx = strcmpi(ThisList,Selection);
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.Parameters(MatchIdx));
        ForceMarkAsInvalid = ~ThisStatusOk;
    else
        ForceMarkAsInvalid = false;
    end
    
    % Invoke helper
    [FullListWithInvalids,FullList,Value] = QSP.highlightInvalids(ThisList,Selection,ForceMarkAsInvalid);
else
    FullList = {'-'};
    FullListWithInvalids = {QSP.makeInvalid('-')};
    Value = 1;
end
vObj.ParameterPopupItems = FullList;
vObj.ParameterPopupItemsWithInvalid = FullListWithInvalids;
set(vObj.h.ParametersPopup,'String',vObj.ParameterPopupItemsWithInvalid,'Value',Value);


%% Update ParametersTable

vObj.ParametersHeader = {};
vObj.ParametersData = {};

% Import if specified
if ~isempty(vObj.TempData) && ~isempty(vObj.TempData.RefParamName)
    Names = {vObj.TempData.Settings.Parameters.Name};
    MatchIdx = strcmpi(Names,vObj.TempData.RefParamName);
    if any(MatchIdx)
        pObj = vObj.TempData.Settings.Parameters(MatchIdx);
        [StatusOk,Message,vObj.ParametersHeader,vObj.ParametersData] = importData(pObj,pObj.FilePath);
        if ~StatusOk
            vObj.ParametersHeader = {};
            vObj.ParametersData = {};
        end
    end
end

set(vObj.h.ParametersTable,...
    'ColumnName',vObj.ParametersHeader,...
    'Data',vObj.ParametersData);
