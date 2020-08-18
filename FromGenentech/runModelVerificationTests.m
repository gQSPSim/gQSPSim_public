function runTests(S, tests, AC, Mappings, ICTable)

k = 1;

simObj = S.Session.getSimulationItem(tests(k));
S.Session.AutoSaveBeforeRun = false;

% get AC data
ACobj = S.Session.getACItem(AC);

[StatusOK,Message,accStruct] = prepareAcceptanceCriteria(ACobj, Mappings);

nItems = length(simObj.Item);

groupVec = 1:length(nItems);

for ixTask = 1:length(simObj.Item)
    % pull out the vpop name for each task in this simulation item

	taskName=simObj.Item(ixTask).TaskName;
    vpopName = simObj.Item(ixTask).VPopName;

    % get the vpop object and data
    vpopObj = S.Session.getVPopItem(vpopName);
    [StatusOK,Message,Names,Values] = importData(vpopObj, vpopObj.FilePath);
    
    checkVPatientIsValid(Names, Values, accStruct, simObj, ICTable, groupVec, Mappings)

% run the simulation
% simObj.run()

% simData = GetData(simObj);
    
end


    
% end