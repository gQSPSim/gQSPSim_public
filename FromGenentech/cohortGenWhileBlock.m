function [Vpop, isValid, Results, ViolationTable, nPat, nSim, StatusOK, Message] = cohortGenWhileBlock(obj, args, hWbar, q_vp, stopFile)
    
nPat = 0;
nSim = 0;
nError = 0;

StatusOK = true;
Message = '';


% unpack args
LB = args.LB;
UB = args.UB;
fixedParams = args.fixedParams;
fixedParamNames = args.fixedParamNames;
perturbParamNames = args.perturbParamNames;
logInds = args.logInds;
unqGroups = args.unqGroups;
groupVec = args.groupVec;
Groups = args.Groups;
Species = args.Species;
ixSpecies = args.ixSpecies;
Time = args.Time;
LB_accCrit = args.LB_accCrit;
UB_accCrit = args.UB_accCrit;
ICTable = args.ICTable;
Mappings = args.Mappings;
P0_1 = args.P0_1;
CV = args.CV;
normInds = args.normInds;
tune_param = obj.MCMCTuningParam;

nItems = size(obj.TaskGroupItems,1);

%% set up for validation of each virtual patient
nGroups = length(unqGroups) ;
taskObj = cell(1,nItems);
Species_grp = cell(1,nItems);
Time_grp = cell(1,nItems);
LB_grp = cell(1,nItems);
UB_grp = cell(1,nItems);
OutputTimes =  cell(1,nItems);
ICs = cell(1,nItems);
nIC = zeros(1,nItems);

LB_violation = [];
UB_violation = [];
ViolationTable = [];


if ~isempty(setdiff(groupVec,cellfun(@str2num, obj.TaskGroupItems(:,2))))
    StatusOK = false;
    Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
    delete(hWbar)
    return
end


% loop over the task items defined for the cohort generation
for itemIdx = 1:length(obj.Item)    
    currGrpStr = obj.TaskGroupItems{itemIdx,2};
    currGrp = str2num(currGrpStr);

    if nnz(itemIdx) > 1
        StatusOK = false;
        Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
        delete(hWbar)
        return
    end
    
    % get task object for this item based on name
    tskInd = strcmp(obj.Item(itemIdx).TaskName,{obj.Settings.Task.Name});
    taskObj{itemIdx} = obj.Settings.Task(tskInd);

    % indices of data points in acc. crit. matching this group
    grpInds = find(Groups == currGrp);

    % get group information
    Species_grp{itemIdx} = Species(grpInds);
    Time_grp{itemIdx} = Time(grpInds);
    LB_grp{itemIdx} = LB_accCrit(grpInds);
    UB_grp{itemIdx} = UB_accCrit(grpInds);

    % change output times for the exported model
    OutputTimes{itemIdx} = sort(unique(Time_grp{itemIdx}));    
    
     % set the initial conditions to the value in the IC file if specified
    if ~isempty(ICTable)
        ICs{itemIdx} = ICTable.data(groupVec==currGrp, ixSpecies );
        IC_species = ICTable.colheaders(ixSpecies);
        nIC(itemIdx) = size(ICs{itemIdx},1);       
    else
        nIC(itemIdx) = 1;
        ICs{itemIdx} = [];
        IC_species = {};
    end
    
    % cached results
    Results{itemIdx}.Data = [];
    Results{itemIdx}.VpopWeights = [];
    Results{itemIdx}.Time = OutputTimes{itemIdx};
    
    if ~isempty(taskObj{itemIdx}.ActiveSpeciesNames)
        Results{itemIdx}.SpeciesNames = taskObj{itemIdx}.ActiveSpeciesNames;
    else
        Results{itemIdx}.SpeciesNames = taskObj{itemIdx}.SpeciesNames;
    end       
    
end

grpData = {'taskObj', 'Species_grp', 'Time_grp', 'LB_grp', 'UB_grp', 'OutputTimes', 'ICs', 'nIC', 'IC_species', 'grpInds'};
grpData = cell2struct( cellfun(@(s) evalin('caller',s), grpData, 'UniformOutput', false), grpData, 2);

%%
% Relative Prevalence options
options_RP=saoptimset('ObjectiveLimit',0.005,'TolFun',1e-5,'Display','iter',...
    'ReannealInterval',500,'InitialTemperature',0.5,'MaxIter',400,'TemperatureFcn',...
    @temperatureboltz,'AnnealingFcn', @annealingboltz,'AcceptanceFcn',@acceptancesa);

% function checkCancelled(data)
%     waitStatus = false;
%     disp('interrupt received')
% end

% callback for cancellation interrupt
% if ~isempty(workerQueueConstant)
%     disp('add listener')
%     listener = afterEach(workerQueueConstant.Value, @(data) checkCancelled(data) );
%     listener = afterEach(workerQueueConstant.Value, @(data) checkCancelled(data)  );
    
%     listener = afterEach(workerQueueConstant, @(data) checkCancelled(data) );
% end


waitStatus = true;

% normally distrbuted variables


LocalResults = cell(obj.MaxNumSimulations, length(unqGroups));
for ixGrp = 1:length(obj.Item)
    NS(ixGrp) = length(grpData.taskObj{ixGrp}.ActiveSpeciesNames);
    NT(ixGrp) = length(grpData.OutputTimes{ixGrp});
    Results{ixGrp}.Data = zeros( NT(ixGrp) , NS(ixGrp) * obj.MaxNumSimulations);
end
VpopWeights = zeros(1,obj.MaxNumSimulations);
Vpop = zeros(obj.MaxNumSimulations, length(perturbParamNames) + length(fixedParamNames));
isValid = zeros(1,obj.MaxNumSimulations);

% if ~isempty(getCurrentWorker) 
%     warning('stopfile on worker = %s (exists = %d)\n', stopFile, exist(stopFile))

if ~isempty(stopFile)
    [~,stopName] = fileparts(stopFile);

    newStopFileFolder = getAttachedFilesFolder(stopFile);
    if ~isempty(newStopFileFolder)
        stopFile = fullfile(newStopFileFolder, stopName);
        warning('stopfile on worker (modified) = %s (exists = %d)\n', stopFile, exist(stopFile))        
    end    
end

param_candidate_old = P0_1;

while nSim<obj.MaxNumSimulations && nPat<obj.MaxNumVirtualPatients % && gop(@plus, nPat) < obj.MaxNumVirtualPatients && gop(@plus,nSim) < obj.MaxNumSimulations
    
%     fH = fopen(stopFile,'r');
%     stop = fread(fH);
%     if ~isempty(stop)
%         break
%     end
%     fclose(fH);
    
    if exist(stopFile,'file')
        break
    end
    nSim = nSim+1; % tic up the number of simulations
    
    if strcmp(obj.Method, 'Distribution') || strcmp(obj.Method, 'Relative Prevalence')
        % produce sample uniformly sampled between LB & UB
        param_candidate(~normInds) = unifrnd(LB(~normInds),UB(~normInds));        
        param_candidate(normInds) = normrnd(P0_1(normInds), P0_1(normInds).*CV(normInds));
        
    elseif strcmp(obj.Method, 'MCMC')
        param_candidate = param_candidate_old + (UB-LB).*(2*rand(size(LB))-1)*tune_param;              
    end
    param_candidate = reshape(param_candidate,[],1);
    
    param_candidate = max(param_candidate, LB); 
    param_candidate = min(param_candidate, UB);
        
    P = param_candidate;
    P(logInds) = 10.^P(logInds);    
    Values0 = [P; fixedParams];
    Names0 = [perturbParamNames; fixedParamNames];
    
    if strcmp(obj.Method, 'Relative Prevalence')
        % need to stochastically optimize the virtual patient
%         [model_outputs, StatusOK, Message, LB_outputs, UB_outputs] = checkVPatientVsAC(Values0, Names0, obj, unqGroups, Groups, Species, Time, LB_accCrit, UB_accCrit, ICTable, Mappings );
%         isValid(nSim) = double(all(model_outputs>=LB_outputs) && all(model_outputs<=UB_outputs));        
        
        P = simulannealbnd(@(P) SAobjForRP(P, logInds, fixedParams, perturbParamNames, fixedParamNames, obj, unqGroups, Groups, Species, Time, LB_accCrit, UB_accCrit, ICTable, Mappings ), ...
            param_candidate, LB, UB, options_RP);
        
        P(logInds) = 10.^P(logInds);    
        Values0 = [P; fixedParams];
        Vpop(nSim,:) = Values0'; % store the parameter set

        [model_outputs, StatusOK, Message, LB_outputs, UB_outputs, spec_outputs, taskName_outputs, time_outputs, nIC, D] = checkVPatientVsAC(obj, args, grpData, Names0, Values0);

        if StatusOK
            isValid(nSim) = true;
        end

    else
        % just check this one VP if it is valid
        [model_outputs, StatusOK, Message, LB_outputs, UB_outputs, spec_outputs, taskName_outputs, time_outputs, nIC, D, activeSpecData] = checkVPatientVsAC(obj, args, grpData, Names0, Values0);
        % compare model outputs to acceptance criteria
        if ~isempty(model_outputs) 
            Vpop(nSim,:) = Values0'; % store the parameter set
            isValid(nSim) = double(all(model_outputs>=LB_outputs) && all(model_outputs<=UB_outputs));    
        else
            isValid(nSim) = false; % no output produced
        end
    end


    if ~StatusOK % exit loop if something went wrong
        isValid(nSim) = false;
        warning(Message)
        nError = nError + 1;

        continue     
    end
    
    if isValid(nSim)
        nPat = nPat+1; % if conditions are satisfied, tick up the number of virutal patients
        param_candidate_old = param_candidate; % keep new candidate as starting point        
    end
    
    if isValid(nSim) || ~strcmp(obj.SaveInvalid, 'Save valid vpatients')
        for ixGrp = 1:length(obj.Item)

            dataIdx = (nSim-1)*NT(ixGrp)*NS(ixGrp) + (1:NS(ixGrp)*NT(ixGrp));
            if isempty(activeSpecData{ixGrp})
                thisData = nan(size(dataIdx));
            else
                thisData = activeSpecData{ixGrp};
            end
            Results{ixGrp}.Data( (nSim-1)*NT(ixGrp)*NS(ixGrp) + (1:NS(ixGrp)*NT(ixGrp)) ) = thisData;

            VpopWeights(nSim)= isValid(nSim);
        end            
    end    

    if ~waitStatus
        bCancelled = true;
        break
    end
    
    if ~isempty(hWbar)
        waitStatus = uix.utility.CustomWaitbar(nPat/obj.MaxNumVirtualPatients,hWbar,sprintf('Generated %d/%d vpatients (%d/%d Failed, %d Errored)',  ...
            nPat, obj.MaxNumVirtualPatients, nSim-nPat, nSim, nError ));
    end

    if isempty(LB_violation)
        LB_violation = model_outputs<LB_outputs;
    else
        newTerm = LB_violation + (model_outputs<LB_outputs);
        LB_violation = newTerm;
    end
    
    if isempty(UB_violation)
        UB_violation = (model_outputs>UB_outputs);
    else
        UB_violation = UB_violation + (model_outputs>UB_outputs);
    end
           
    if ~isempty(q_vp)
        send(q_vp, isValid(nSim))
    end
    
end % while


ixUB = find(UB_violation);
ixLB = find(LB_violation);

if StatusOK
    ViolationTable = [ table(taskName_outputs(ixUB), ...
            spec_outputs(ixUB), ...
            num2cell(time_outputs(ixUB)),...
            repmat({'Exceeds UB'},size(ixUB)), ...
            UB_violation(ixUB), ...
            'VariableNames', {'Task','Species','Time','Type','Count'});

            table(taskName_outputs(ixLB), ...
            spec_outputs(ixLB), ...
            num2cell(time_outputs(ixLB)),...
            repmat({'Below LB'},size(ixLB)), ...
            LB_violation(ixLB), ...
            'VariableNames', {'Task','Species','Time','Type','Count'})];
else
    ViolationTable = [];
end

isValid = isValid(1:nSim);
Vpop = Vpop(1:nSim,:);

for ixGrp = 1:length(obj.Item)
%     tmp = [LocalResults{:,ixGrp}];
%     Results{ixGrp}.Data = horzcat(tmp.Data);
    Results{ixGrp}.VpopWeights = reshape(VpopWeights(1:nSim),[],1);
    Results{ixGrp}.Data = Results{ixGrp}.Data(:, 1:(NS(ixGrp)*nSim));
end


    
end
