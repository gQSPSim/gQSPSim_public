function [StatusOK,Message,accStruct] = prepareAcceptanceCriteria(vpopObj, Mappings)

Message = '';
StatusOK = true;

% read the data from the file
[ThisStatusOk,ThisMessage,accCritHeader,accCritData] = importData(vpopObj,vpopObj.FilePath);
if ~ThisStatusOk
    StatusOK = false;
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end


if ~isempty(accCritHeader) && ~isempty(accCritData)
    
    % filter out any acceptance criteria that are not included
    includeIdx = accCritData(:,strcmp('Include',accCritHeader));
    if ~isempty(includeIdx)
        param_candidate = strcmpi(includeIdx,'yes');
        accCritData = accCritData(param_candidate==1,:);
    end
    
    spIdx = ismember( accCritData(:,3), Mappings(:,2));
    % [Group, Species, Time, LB, UB]
    accStruct.Groups = cell2mat(accCritData(spIdx,strcmp('Group',accCritHeader)));
    accStruct.unqGroups = unique(accStruct.Groups);
    accStruct.Time = cell2mat(accCritData(spIdx,strcmp('Time',accCritHeader)));
    accStruct.Species = accCritData(spIdx,strcmp('Data',accCritHeader));
    accStruct.LB_accCrit = cell2mat(accCritData(spIdx,strcmp('LB',accCritHeader)));
    accStruct.UB_accCrit = cell2mat(accCritData(spIdx,strcmp('UB',accCritHeader)));
    
else
    
    StatusOK = false;
    Message = 'The selected Acceptance Criteria file is empty.';
    
end