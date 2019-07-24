
function [StatusOK,Message,isValid,Vpop,nPat,nSim, bCancelled]  = cohortGenerationRunHelper_par(obj, args)

StatusOK = true;
Message = '';

unqGroups = args.unqGroups;
groupVec = args.groupVec;

 % keep only the unique groups in the acceptance criteria that are also
 % identified with items
isMapped = ismember(arrayfun(@num2str, unqGroups, 'UniformOutput', false), {obj.Item.GroupID});
unqGroups = unqGroups(isMapped);

% check that the tasks are assigned only to one group
nMappings = arrayfun( @(g) nnz(strcmp(g, num2str(unqGroups))), {obj.Item.GroupID});
if any(nMappings>1)
    StatusOK = false;
    Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
    delete(hWbar)
    return
end

% check that the groups specified in the IC file are assigned to tasks
for currGrp = unqGroups
    if ~any(groupVec==currGrp)
        StatusOK = false;
        Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
        delete(hWbar)
        return
    end
end

% set up parallel pool

p = gcp('nocreate');
if isempty(p) 
    p = parpool(obj.Session.ParallelCluster, ...
        'AttachedFiles', obj.Session.UserDefinedFunctionsDirectory);
elseif  ~strcmp(p.Cluster.Profile,obj.Session.ParallelCluster)
    delete(gcp('nocreate'))
    p = parpool(obj.Session.ParallelCluster, ...
     'AttachedFiles', obj.Session.UserDefinedFunctionsDirectory);
end

% q = parallel.pool.DataQueue;
q_vp = parallel.pool.DataQueue;

hWbar = uix.utility.CustomWaitbar(0,'Virtual cohort generation','Generating virtual cohort...',true);


function updateData(hWbar, data)
    allPat = allPat + data(end); % 0 or 1
    allSim = allSim + 1;
    
    vPop_all = [vPop_all; data(1:end-1)];
    isValid_all = [isValid_all; data(end)];
    
    if ~isempty(hWbar)
        thisStatusOK = uix.utility.CustomWaitbar(allPat/obj.MaxNumVirtualPatients,hWbar,sprintf('Succesfully generated %d/%d vpatients. (%d/%d Failed)',  ...
            allPat, obj.MaxNumVirtualPatients, allSim-allPat, allSim ));
        if ~thisStatusOK
            cancel(F);
            bCancelled = true;
        end
    end
    
    if allPat > obj.MaxNumVirtualPatients || allSim  > obj.MaxNumSimulations
        cancel(F);
        delete(listener)
    end
    
end

listener = afterEach(q_vp, @(data) updateData(hWbar, data) );
vPop_all = [];
isValid_all = [];
bCancelled = false;
allPat = 0;
allSim = 0;

F = parfevalOnAll(p, @cohortGenWhileBlock, 6, obj, args, [], q_vp);

% cohortGenWhileBlock(obj, args, hWbar);

fprintf('waiting...\n')
wait(F)
fprintf('Generated %d vpatients (%d valid)\n', size(vPop_all,1), nnz(isValid_all))


delete(hWbar)

isValid = isValid_all;
Vpop = vPop_all;



if nnz(isValid) > obj.MaxNumVirtualPatients
    % in case parallel went past last vpatient
    ixLast = find(cumsum(isValid)==obj.MaxNumVirtualPatients,1,'first');
    isValid = isValid(1:ixLast);
    Vpop = Vpop(1:ixLast,:);
end

nSim = size(Vpop,1);
nPat = nnz(isValid);

ThisMessage = [num2str(nPat) ' virtual patients generated in ' num2str(nSim) ' simulations.'];
Message = sprintf('%s\n%s\n',Message,ThisMessage);


bProceed = true;


end

