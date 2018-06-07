function refreshDataset(vObj)

%% Update DatasetPopup = list of cohorts available
if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.VirtualPopulation.Name};
    Selection = vObj.TempData.DatasetName;
    
    MatchIdx = strcmpi(ThisList,Selection);    
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.VirtualPopulation(MatchIdx));
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
vObj.DatasetPopupItems = FullList;
vObj.DatasetPopupItemsWithInvalid = FullListWithInvalids;
set(vObj.h.CohortPopup,'String',vObj.DatasetPopupItemsWithInvalid,'Value',Value);

%% Update VpopGen Data 
if ~isempty(vObj.TempData)
    ThisList = {vObj.TempData.Settings.VirtualPopulationGenerationData.Name};
    Selection = vObj.TempData.VpopGenDataName;
    
    MatchIdx = strcmpi(ThisList,Selection);    
    if any(MatchIdx)
        ThisStatusOk = validate(vObj.TempData.Settings.VirtualPopulationGenerationData(MatchIdx));
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
vObj.VpopPopupItems = FullList;
vObj.VpopPopupItemsWithInvalid = FullListWithInvalids;
set(vObj.h.VpopPopup,'String',vObj.VpopPopupItemsWithInvalid,'Value',Value);



%% Update GroupNamePopup

if ~isempty(vObj.TempData) && ~isempty(vObj.TempData.DatasetName) && ~isempty(vObj.TempData.Settings.VirtualPopulationGenerationData)
    Names = {vObj.TempData.Settings.VirtualPopulationGenerationData.Name};
    MatchIdx = strcmpi(Names,vObj.TempData.VpopGenDataName);
    
    if any(MatchIdx)
        dObj = vObj.TempData.Settings.VirtualPopulationGenerationData(MatchIdx);
        
        [~,~,VPopHeader,VPopData] = importData(dObj,dObj.FilePath);
    else
        VPopHeader = {};
        VPopData = {};
    end
else
    VPopHeader = {};
    VPopData = {};
end
vObj.DatasetHeader = VPopHeader;
vObj.DatasetData = VPopData;


%% Get 'Species' column from Dataset

if ~isempty(VPopHeader) && ~isempty(VPopData)
    MatchIdx = find(strcmpi(VPopHeader,'Species'));
    if numel(MatchIdx) == 1
        vObj.DatasetDataColumn = unique(VPopData(:,MatchIdx));
    elseif numel(MatchIdx) == 0
        vObj.DatasetDataColumn = {};
        warning('VpopGen Data %s has 0 ''Species'' column names',vpopObj.FilePath);
    else
        vObj.DatasetDataColumn = {};
        warning('VpopGen Data %s has multiple ''Species'' column names',vpopObj.FilePath);
    end
else
    vObj.DatasetDataColumn = {};
end


%% Update GroupNamePopup

updateDataset(vObj);