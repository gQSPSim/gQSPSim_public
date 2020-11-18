
function [StatusOK,Message,isValid,Vpop,Results,nPat,nSim, bCancelled]  = cohortGenerationRunHelper_par(obj, args)

StatusOK = true;
Message = '';
isValid = false;
Vpop = [];
nPat = 0;
nSim = 0;
Results = [];
bCancelled = false;

unqGroups = args.unqGroups;
groupVec = args.groupVec;

batchMode = args.batchMode;

 % keep only the unique groups in the acceptance criteria that are also
 % identified with items
isMapped = ismember(arrayfun(@num2str, unqGroups, 'UniformOutput', false), {obj.Item.GroupID});
unqGroups = unqGroups(isMapped);

% check that the tasks are assigned only to one group
nMappings = arrayfun( @(g) nnz(strcmp(g, num2str(unqGroups))), {obj.Item.GroupID});
if any(nMappings>1)
    StatusOK = false;
    Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
%     delete(hWbar)
    return
end

% check that the groups specified in the IC file are assigned to tasks
for currGrp = unqGroups
    if ~any(groupVec==currGrp)
        StatusOK = false;
        Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
%         delete(hWbar)
        return
    end
end

% set up parallel pool

p = gcp('nocreate');
if ~batchMode % don't create a pool when in batch mode
    if isempty(p) 
        try
            p = parpool(obj.Session.ParallelCluster, ...
                'AttachedFiles', obj.Session.UserDefinedFunctionsDirectory);
        catch ME
            StatusOK = false;
            Message = sprintf('Failed to start parallel pool.\n%s', ME.message);
            return
        end
           
    elseif ~strcmp(p.Cluster.Profile,obj.Session.ParallelCluster)
        delete(gcp('nocreate'))
        try
            p = parpool(obj.Session.ParallelCluster, ...
                'AttachedFiles', obj.Session.UserDefinedFunctionsDirectory);
        catch ME
            StatusOK = false;
            Message = sprintf('Failed to start parallel pool.\n%s', ME.message);
            return
        end
    end
% else
%     tmp = mfilename('fullpath');
%     paths(cellfun(@isempty,paths)) = [];                                
%     
%     addAttachedFiles(p, paths);
%     updateAttachedFiles(p);
%     
%     fprintf('Attached files to parallel pool\n')
% %     listAutoAttachedFiles(p)
%     fprintf('All attached files: %s\n', strjoin(p.AttachedFiles, '\n') )
    

end


% batchMode = false; % EXPERIMENT


% q = parallel.pool.DataQueue;
q_vp = parallel.pool.DataQueue;

if obj.Session.ShowProgressBars
    hWbar = uix.utility.CustomWaitbar(0,'Virtual cohort generation','Generating virtual cohort...',true);
end


Results_all = cell(1,length(unqGroups));
for ixGrp = 1:length(unqGroups)
    Results_all{ixGrp}.Data = [];
end

stopFile = tempname;

function updateData(hWbar, data)
%     allPat = allPat + data.Valid; % 0 or 1
    allSim = allSim + 1;    
    allPat = allPat + data(end); % 0 or 1
    
%     vPop_all = [vPop_all; data.Values];
%     isValid_all = [isValid_all; data.Valid];
%     
% %     vPop_all = [vPop_all; data(1:end-1)];
% %     isValid_all = [isValid_all; data(end)];    
% %     
%     for ixGrp = 1:length(data.Results)
%         % grow results
%         Results_all{ixGrp}.Data = [Results_all{ixGrp}.Data, data.Results{ixGrp}.Data];
%     end
%     
%     lastResults = data.Results;
%     ViolationTable = [ViolationTable; data.ViolationTable];
    
    if ~isempty(hWbar)
        thisStatusOK = uix.utility.CustomWaitbar(allPat/obj.MaxNumVirtualPatients,hWbar,sprintf('Succesfully generated %d/%d vpatients. (%d/%d Failed)',  ...
            allPat, obj.MaxNumVirtualPatients, allSim-allPat, allSim ));
        if ~thisStatusOK
            % create stop file
            fid=fopen(stopFile,'w');
            fclose(fid);
            addAttachedFiles(p, stopFile);
            bCancelled = true;
        end
        
        if mod(allSim,100)==0
            t=toc-t;
            fprintf('Generated 100 samples in %0.02f seconds\n', t)
        end
    end
    
    if allPat > obj.MaxNumVirtualPatients || allSim  > obj.MaxNumSimulations
%         send(workerQueueClient, true)
%         cancel(F);
        
        % create stop file
        if ~exist(stopFile,'file')
            fid=fopen(stopFile,'w');        
            fclose(fid);
            addAttachedFiles(p, stopFile);        
            fprintf('Terminating cohort generation\n');
        end
%         delete(listener)
    end
    
end

listener = afterEach(q_vp, @(data) updateData(hWbar, data) );
% vPop_all = [];
% isValid_all = [];
bCancelled = false;
allPat = 0;
allSim = 0;

% F = parfevalOnAll(p, @cohortGenWhileBlock, 7, obj, args, [], q_vp, workerQueueConstant);
% F = parfevalOnAll(p, @cohortGenWhileBlock, 7, obj, args, [], q_vp, workerQueueClient);
% 
% 
% if batchMode
%     % dont send the data queue
%     % not possible to interrupt
%     F = parfevalOnAll(p, @cohortGenWhileBlock, 9, obj, args, [], []);   
% else

%fprintf('stopfile = %s\n', stopFile);

tic
t=0;

F = parfevalOnAll(p, @cohortGenWhileBlock, 9, obj, args,  [], q_vp, stopFile);
% end
% cohortGenWhileBlock(obj, args, hWbar);

orig_state = warning('off', 'parallel:lang:pool:IgnoringAlreadyAttachedFiles');
fprintf('waiting...\n')
wait(F)
fprintf('Generated %d vpatients (%d valid)\n', allSim, allPat)
warning(orig_state);

% [Vpop, isValid, Results, ViolationTable, nPat, nSim, bCancelled] = fetchOutputs(F, 'UniformOutput', false);
if obj.Session.ShowProgressBars
    delete(hWbar)
end

% reconstruct results from the data passed over the data queue if in batch
% mode
% if ~batchMode
% 
%     isValid = isValid_all;
%     Vpop = vPop_all;
%     Results = Results_all;
% 
%     disp(lastResults)
%     
%     for ixGrp=1:length(unqGroups)
%         Results{ixGrp}.VpopWeights = isValid;
%         Results{ixGrp}.Time = lastResults{ixGrp}.Time;
%         Results{ixGrp}.SpeciesNames = lastResults{ixGrp}.SpeciesNames;    
%     end
% else
try
[Vpop, isValid, Results, ViolationTable, nPat, nSim, bCancelled, StatusOK, Message] = fetchOutputs(F, 'UniformOutput', false);
catch error
    Message = sprintf('Error encountered with parallel cohort generation.\n%s', error.message)
    StatusOK = false;
    return
end

% concatenate results
Vpop = vertcat(Vpop{:});
isValid = horzcat(isValid{:});
ViolationTable = vertcat(ViolationTable{:});
Results_all = cell(1,length(unqGroups));

for ixGrp=1:length(unqGroups)
    Results_all{ixGrp}.Data = [];
    Results_all{ixGrp}.VpopWeights = [];
    for k=1:length(Results)
        Results_all{ixGrp}.Data = [Results_all{ixGrp}.Data, Results{k}{ixGrp}.Data];
        Results_all{ixGrp}.VpopWeights = [Results_all{ixGrp}.VpopWeights; Results{k}{ixGrp}.VpopWeights];
    end
    Results_all{ixGrp}.Time = Results{k}{ixGrp}.Time;
    Results_all{ixGrp}.SpeciesNames = Results{k}{ixGrp}.SpeciesNames;
end
Results = Results_all;

StatusOK = any(vertcat(StatusOK{:})); % && nnz(isValid) >= obj.MaxNumVirtualPatients;

bCancelled = any(vertcat(bCancelled{:}));

%     Message = strjoin([Message{:}],'\n');
Message = strjoin(Message,'\n');
    
% end


if nnz(isValid) > obj.MaxNumVirtualPatients
    % in case parallel went past last vpatient
    ixLast = find(cumsum(isValid)==obj.MaxNumVirtualPatients,1,'first');
    isValid = isValid(1:ixLast);
    Vpop = Vpop(1:ixLast,:);
end


nSim = size(Vpop,1);
nPat = nnz(isValid);

ThisMessage = [num2str(nPat) ' virtual subjects generated in ' num2str(nSim) ' simulations.'];
if nnz(isValid) < obj.MaxNumVirtualPatients
    ThisMessage = sprintf('%s\nDid not produce target number of virtual subjects.', ThisMessage);
end   

Message = sprintf('%s\n%s\n',Message,ThisMessage);


% if ~isempty(ViolationTable)
%     g = findgroups(ViolationTable.Task, ViolationTable.Species, cell2mat(ViolationTable.Time), ViolationTable.Type);
%     ViolationSums = splitapply(@length, ViolationTable.Type, g);
%     [~,ix] = unique(g);
%     ViolationSumsTable = [ViolationTable(ix,:), table(ViolationSums, 'VariableNames', {'Count'})];
%     disp(ViolationSumsTable)
% end

fprintf('Summary of acceptance criteria violations:\n')
disp(ViolationTable)

end

