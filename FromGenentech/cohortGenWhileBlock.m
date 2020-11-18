function [Vpop, isValid, Results, ViolationTable, nPat, nSim, bCancelled, StatusOK, Message] = cohortGenWhileBlock(obj, args, hWbar, q_vp, stopFile)
    
nPat = 0;
nSim = 0;
StatusOK = true;
Message = '';
bCancelled = false;

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

%% set up for validation of each virtual patient
nGroups = length(unqGroups) ;
taskObj = cell(1,nGroups);
Species_grp = cell(1,nGroups);
Time_grp = cell(1,nGroups);
LB_grp = cell(1,nGroups);
UB_grp = cell(1,nGroups);
OutputTimes =  cell(1,nGroups);
ICs = cell(1,nGroups);
nIC = zeros(1,nGroups);

LB_violation = [];
UB_violation = [];
ViolationTable = [];

% output
Vpop = [];
isValid = [];
Results = [];


for grpIdx = 1:nGroups
    
    currGrp = unqGroups(grpIdx);

    % get matching taskGroup item based on group ID        
    itemIdx = strcmp({obj.Item.GroupID}, num2str(currGrp));
    if ~any(itemIdx)
        % this group is not part of this vpop generation
        continue
    end

    if nnz(itemIdx) > 1
        StatusOK = false;
        Message = sprintf('%s\nOnly one task may be assigned to any group. Check task group mappings.\n', Message);
        delete(hWbar)
        return
    end
    
    % get task object for this item based on name
    tskInd = strcmp(obj.Item(itemIdx).TaskName,{obj.Settings.Task.Name});
    taskObj{grpIdx} = obj.Settings.Task(tskInd);

    % indices of data points in acc. crit. matching this group
    grpInds = find(Groups == currGrp);

    % get group information
    Species_grp{grpIdx} = Species(grpInds);
    Time_grp{grpIdx} = Time(grpInds);
    LB_grp{grpIdx} = LB_accCrit(grpInds);
    UB_grp{grpIdx} = UB_accCrit(grpInds);

    % change output times for the exported model
    OutputTimes{grpIdx} = sort( union(unique(Time_grp{grpIdx}), taskObj{grpIdx}.OutputTimes) );    
    
     % set the initial conditions to the value in the IC file if specified
    if ~isempty(ICTable)
        ICs{grpIdx} = ICTable.data(groupVec==currGrp, ixSpecies );
        IC_species = ICTable.colheaders(ixSpecies);
        nIC(grpIdx) = size(ICs{grpIdx},1);
        if ~any(groupVec==currGrp)
            StatusOK = false;
            Message = sprintf('%sInitial conditions file specified contains groups for which no task has been assigned.\n', Message);
            delete(hWbar)
            return
        end

    else
        nIC(grpIdx) = 1;
        ICs{grpIdx} = [];
        IC_species = {};
    end
    
    % cached results
    
    Results{grpIdx}.Data = [];
    Results{grpIdx}.VpopWeights = [];
    Results{grpIdx}.Time = OutputTimes{grpIdx};
    
    if ~isempty(taskObj{grpIdx}.ActiveSpeciesNames)
        Results{grpIdx}.SpeciesNames = taskObj{grpIdx}.ActiveSpeciesNames;
    else
        Results{grpIdx}.SpeciesNames = taskObj{grpIdx}.SpeciesNames;
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
for ixGrp = 1:length(unqGroups)
    NS(ixGrp) = length(grpData.taskObj{ixGrp}.ActiveSpeciesNames);
    NT(ixGrp) = length(grpData.OutputTimes{ixGrp});  
    Results{ixGrp}.Data = zeros( NT(ixGrp) , NS(ixGrp) * obj.MaxNumSimulations);
end
VpopWeights = zeros(1,obj.MaxNumSimulations);
Vpop = zeros(obj.MaxNumSimulations, length(perturbParamNames) + length(fixedParams));
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
tune_param = obj.MCMCTuningParam;

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
%         break
        continue
    end
    
    if isValid(nSim)
        nPat = nPat+1; % if conditions are satisfied, tick up the number of virutal patients
        param_candidate_old = param_candidate; % keep new candidate as starting point        
    end
    
    if isValid(nSim) || ~strcmp(obj.SaveInvalid, 'Save valid virtual subjects')  
        % Add results of the simulation to Results.Data
%         if ~isempty(q_vp)
%             % parallel
%             for ixGrp = 1:length(unqGroups)                            
%                 Results{ixGrp}.Data = activeSpecData{ixGrp};
%             end
%         else
            for ixGrp = 1:length(unqGroups)
%                 LocalResults{nSim,ixGrp}.Data = activeSpecData{ixGrp};
%                 Results{ixGrp}.Data = [Results{ixGrp}.Data, activeSpecData{ixGrp}];
%                 LocalResults{nSim,ixGrp}.VpopWeights = isValid(nSim);
%                 Results{ixGrp}.Data(:, (nSim-1)*NS(ixGrp) + (1:NS(ixGrp))) = activeSpecData{ixGrp};
                dataIdx = (nSim-1)*NT(ixGrp)*NS(ixGrp) + (1:NS(ixGrp)*NT(ixGrp));
                if isempty(activeSpecData{ixGrp})
                    thisData = nan(size(dataIdx));
                else
                    thisData = activeSpecData{ixGrp};
                end
                Results{ixGrp}.Data( (nSim-1)*NT(ixGrp)*NS(ixGrp) + (1:NS(ixGrp)*NT(ixGrp)) ) = thisData;
                
%                 Results{ixGrp}.VpopWeights = [Results{ixGrp}.VpopWeights; isValid(nSim)];
            end          
            VpopWeights(nSim)= isValid(nSim);
            
%         end
    end    

    if ~waitStatus
        bCancelled = true;
        break
    end
    
    if obj.Session.ShowProgressBars && ~isempty(hWbar)
        waitStatus = uix.utility.CustomWaitbar(nPat/obj.MaxNumVirtualPatients,hWbar,sprintf('Succesfully generated %d/%d vpatients. (%d/%d Failed)',  ...
            nPat, obj.MaxNumVirtualPatients, nSim-nPat, nSim ));
    end

    if isempty(LB_violation)
        LB_violation = model_outputs<LB_outputs;
    else
        LB_violation = LB_violation + (model_outputs<LB_outputs);
    end
    
    if isempty(UB_violation)
        UB_violation = (model_outputs>UB_outputs);
    else
        UB_violation = UB_violation + (model_outputs>UB_outputs);
    end

%     
%     
%     LBTable = table(taskName_outputs(LB_violation), ...
%         spec_outputs(LB_violation), ...
%         num2cell(time_outputs(LB_violation)),...
%         repmat({'LB'},size(LB_violation)), ...
%         'VariableNames', {'Task','Species','Time','Type'});
%     UBTable = table(taskName_outputs(UB_violation), ...
%         spec_outputs(UB_violation), ...
%         num2cell(time_outputs(UB_violation)),...
%         repmat({'UB'},size(UB_violation)), ...
%         'VariableNames', {'Task','Species','Time','Type'});
           
    if ~isempty(q_vp)
        % parallel (not batch mode), send each result after completion
%         ViolationTable = [LBTable; UBTable];
        
%         data.Values = Values0';
%         data.Valid = isValid(nSim);
%         data.Results = Results;
%         data.ViolationTable = ViolationTable;
%         data.nPat = nPat;
%         data.nSim = nSim;
%         data.bCancelled = bCancelled;
%         
%         send(q_vp, data)
        
        send(q_vp, isValid(nSim))


%     else
%         % grow ViolationTable
%         ViolationTable = [ViolationTable; LBTable; UBTable];
    end
    
%     ViolationTable = [ViolationTable; LBTable; UBTable];


            
end % while


ixUB = find(UB_violation);
ixLB = find(LB_violation);

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
        UB_violation(ixLB), ...
        'VariableNames', {'Task','Species','Time','Type','Count'})];

isValid = isValid(1:nSim);
Vpop = Vpop(1:nSim,:);

for ixGrp = 1:length(unqGroups)
%     tmp = [LocalResults{:,ixGrp}];
%     Results{ixGrp}.Data = horzcat(tmp.Data);
    Results{ixGrp}.VpopWeights = reshape(VpopWeights(1:nSim),[],1);
    Results{ixGrp}.Data = Results{ixGrp}.Data(:, 1:(NS(ixGrp)*nSim));
end


    
end
