function [allValid, allViolations ] = validateVpop(obj, vpopName)

StatusOK = true;
Message = '';



%% get the vpop
vpopObj = obj.Session.getVPopItem(vpopName);
[StatusOK,Message,Names,Values] = importData(vpopObj, vpopObj.FilePath);

if ~StatusOK
    Message = sprintf('%s\nCould not load vpop data %s', Message, vpopObj.Name);
    return
end


[Mappings, accCritData, ICTable, groupVec] = setupCohortGen(obj);

%% check that each vpatient is valid

isValid = true(1,size(Values,1));
allViolations = [];

for ixVP = 1:size(Values,1)    
    [StatusOK, Message, isValid(ixVP), ~, thisViolation] = obj.checkVPatientIsValid( Names, Values(ixVP,:), accCritData, ICTable, groupVec, Mappings);
    allViolations = [allViolations; thisViolation];
end

allValid = all(isValid);




end