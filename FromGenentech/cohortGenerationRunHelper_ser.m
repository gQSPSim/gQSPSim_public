
function [StatusOK,Message,isValid,Vpop,Results,nPat,nSim, bCancelled] = cohortGenerationRunHelper_ser(obj, args)
Message = '';
StatusOK = true;
    
% generate the virtual patients    
hWbar = uix.utility.CustomWaitbar(0,'Virtual cohort generation','Generating virtual cohort...',true);

[Vpop, isValid, Results, ViolationTable, nPat, nSim, bCancelled] = cohortGenWhileBlock(obj, args, hWbar, []);


if ~isempty(hWbar) && ishandle(hWbar)
    delete(hWbar)
end
% in case nPat is less than the maximum number of virtual patients...
% Vpop = Vpop(isValid==1,:); % removes extra zeros in Vpop


%% DEBUG: output all the violations of the constraints
if ~isempty(ViolationTable)
    g = findgroups(ViolationTable.Task, ViolationTable.Species, cell2mat(ViolationTable.Time), ViolationTable.Type);
    ViolationSums = splitapply(@length, ViolationTable.Type, g);
    [~,ix] = unique(g);
    ViolationSumsTable = [ViolationTable(ix,:), table(ViolationSums, 'VariableNames', {'Count'})];
    disp(ViolationSumsTable)
end
%% Outputs

ThisMessage = [num2str(nPat) ' virtual patients generated in ' num2str(nSim) ' simulations.'];
Message = sprintf('%s\n%s\n',Message,ThisMessage);

isValid = isValid(1:nSim);
Vpop = Vpop(1:nSim,:);



end
