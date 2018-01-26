function [StatusOK,Message,ResultsFileName,VpopName] = vpopGenerationRunHelper(obj)
% Function that generates a Virtual population by sampling parameter space,
% running simulations, and comparing the outputs to Acceptance Criteria.

StatusOK = true;
Message = '';
ResultsFileName = '';
VpopName = '';

%% update path to include everything in subdirectories of the root folder
myPath = path;
addpath(genpath(obj.Session.RootDirectory));



%% Check number of items

if numel(obj.Item) == 0
    StatusOK = false;
    Message = 'The number of items is 0.';
    path(myPath);
    return
end

%% Load Acceptance Criteria

Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);
    
    [ThisStatusOk,ThisMessage,accCritHeader,accCritData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    accCritHeader = {};
    accCritData = {};
end

%% Prepare species-data Mappings
Mappings = cell(length(obj.SpeciesData),2);
for ii = 1:length(obj.SpeciesData)
    Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
    Mappings{ii,2} = obj.SpeciesData(ii).DataName;
end


if ~isempty(accCritHeader) && ~isempty(accCritData)
    
    % filter out any acceptance criteria that are not included
    includeIdx = accCritData(:,strcmp('Include',accCritHeader));
    if ~isempty(includeIdx)
        tmp = cell2mat(includeIdx);
        accCritData = accCritData(tmp==1,:);
    end
    
    spIdx = ismember( accCritData(:,3), Mappings(:,2));
    % [Group, Species, Time, LB, UB]
    Groups = cell2mat(accCritData(spIdx,strcmp('Group',accCritHeader)));
    Time = cell2mat(accCritData(spIdx,strcmp('Time',accCritHeader)));
    Species = accCritData(spIdx,strcmp('Data',accCritHeader));
    LB_accCrit = cell2mat(accCritData(spIdx,strcmp('LB',accCritHeader)));
    UB_accCrit = cell2mat(accCritData(spIdx,strcmp('UB',accCritHeader)));
else
    
    StatusOK = false;
    Message = 'The selected Acceptance Criteria file is empty.';
    path(myPath);
    return
end



%% Load Parameters
Names = {obj.Settings.Parameters.Name};
MatchIdx = strcmpi(Names,obj.RefParamName);
if any(MatchIdx)
    pObj = obj.Settings.Parameters(MatchIdx);
    [ThisStatusOk,ThisMessage,paramHeader,paramData] = importData(pObj,pObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    paramHeader = {};
    paramData = {};
end

if ~isempty(paramHeader) && ~isempty(paramData)
    % [Include, Name, Scale, LB, UB, P0_1, ...]
    paramNames = paramData(:,strcmp('Name',paramHeader));
    Scale = paramData(:,strcmp('Scale',paramHeader));
    LB_params = cell2mat(paramData(:,strcmp('LB',paramHeader)));
    UB_params = cell2mat(paramData(:,strcmp('UB',paramHeader)));
    
    logInds = [];
    for ii = 1:length(paramNames)
        if strcmp(Scale{ii},'log')
            logInds = [logInds;ii];
        end
    end
    
    LB_params(logInds) = log10(LB_params(logInds));
    UB_params(logInds) = log10(UB_params(logInds));
else
    %     LB_params = [];
    %     UB_params = [];
    StatusOK = false;
    Message = 'The selected Parameter file is empty.';
    path(myPath);
    return
end





%% For each task/group, load models and prepare for simulations
ItemModels = struct('ExportedModel',zeros(length(obj.Item),1),...
    'Doses',zeros(length(obj.Item),1),...
    'ICs',zeros(length(obj.Item),1)); % used only when running to steady state

% Initialize waitbar
Title1 = sprintf('Configuring models...');
hWbar1 = uix.utility.CustomWaitbar(0,Title1,'',false);

nItems = length(obj.Item);

obj.SimResults = {}; %cell(1,nItems);

for ii = 1:nItems
    % update waitbar
    uix.utility.CustomWaitbar(ii/nItems,hWbar1,sprintf('Configuring model for task %d of %d...',ii,nItems));
    
    % get the task obj from the settings obj
    tskInd = find(strcmp(obj.Item(ii).TaskName,{obj.Settings.Task.Name}));
    tObj_i = obj.Settings.Task(tskInd);
    
    % Validate
    [ThisStatusOk,ThisMessage] = validate(tObj_i,false);    
    if isempty(tObj_i)
        continue
    elseif ~ThisStatusOk
        warning('Error loading task %s. Skipping [%s]...', taskName,ThisMessage)
        continue
    end
    
    % load the model in that task
    AllModels = sbioloadproject(fullfile(tObj_i.Session.RootDirectory, tObj_i.RelativeFilePath));
    AllModels = cell2mat(struct2cell(AllModels));
    model_i = sbioselect(AllModels,'Name',tObj_i.ModelName,'type','sbiomodel');
    
    % apply the active variants (if specified)
    if ~isempty(tObj_i.ActiveVariantNames)
        % turn off all variants
        varObj_i = getvariant(model_i); % reference to variant objects      
        set(varObj_i, 'Active', false); 
        
        % combine active variants in order into a new variant, add to the
        % model and activate
        [~,ix] = ismember(tObj_i.ActiveVariantNames, tObj_i.VariantNames);
        varObj_i = model_i.variant(ix);
        [model_i,varSpeciesObj_i] = CombineVariants(model_i,varObj_i);
        
    else
        varSpeciesObj_i = [];
    end % if
    
    % inactivate reactions (if specified)
    if ~isempty(tObj_i.InactiveReactionNames)
        % turn on all reactions
        set(model_i.Reactions, 'Active', true);
        % turn off inactive reactions
        [~,ix] = ismember(tObj_i.InactiveReactionNames,tObj_i.ReactionNames);
        set(model_i.Reactions(ix), 'Active', false);
    end % if
    
    % inactivate rules (if specified)
    if ~isempty(tObj_i.InactiveRuleNames)
        % turn on all rules
        for jj = 1 : length(model_i.Rules)
            model_i.Rules(jj).Active = true;
        end % for        
        % turn off inactive rules
        [~,ix] = ismember(tObj_i.InactiveRuleNames,tObj_i.RuleNames);
        set(model_i.Rules(ix), 'Active', false);
    end % if
    
    % assume all parameters are present in all models. varying species
    % initial conditions must be set as parameters and then linked to the
    % species by a rule in the model
    clear pObj_i
    for jj = 1:length(paramNames)
        pObj_i(jj) = sbioselect(model_i,'Name',paramNames{jj});
    end % for
    
    % Export model, allowing all initial conditions and the parameters to vary
    if tObj_i.RunToSteadyState
        % if running to steady state, need to export model with all species
        % ICs editable
        clear sObj_i
        for jj = 1:length(model_i.Species)
            sObj_i(jj) = sbioselect(model_i,'Name',model_i.Species(jj).Name);
        end % for
        
        exp_model_i = export(model_i, [sObj_i, pObj_i]);
        
        % get default initial conditions from the model
        IC_i = cell2mat(get(model_i.Species,'InitialAmount'));
       
        % update ICs with variants
        if ~isempty(varSpeciesObj_i)
            allSpecNames = [get(sObj_i, 'Name')];
            tmp = get(varSpeciesObj_i, 'Content');
            if size(tmp,1) > 1 % fix for simbio inconsistent formatting
                tmp = cellfun(@(X) X{1}, tmp, 'UniformOutput', false);
                tmp = vertcat(tmp{:,1});
            else
                tmp = [tmp{:}];
            end
            
            [~,ix] = ismember(tmp(:,2), allSpecNames);
            IC_i(ix) = [tmp{ix,4}];
            
        end % if
        
        ItemModels(ii).ICs = IC_i;
        
    else
        % otherwise export model with just the parameters editable
        exp_model_i = export(model_i, pObj_i);
        
    end % if
    
    % set MaxWallClockTime in the exported model
    if ~isempty(tObj_i.MaxWallClockTime)
        exp_model_i.SimulationOptions.MaximumWallClock = tObj_i.MaxWallClockTime;
    else
        exp_model_i.SimulationOptions.MaximumWallClock = tObj_i.DefaultMaxWallClockTime;
    end % if
    
    % select active doses (if specified)
    exp_doses_i = [];
    if ~isempty(tObj_i.ActiveDoseNames)
        for jj = 1 : length(tObj_i.ActiveDoseNames)
            exp_doses_i = [exp_doses_i, getdose(exp_model_i, tObj_i.ActiveDoseNames{jj})];
        end % for
    end % if
    ItemModels(ii).Doses = exp_doses_i;
    
    % accelerate model
    try
        accelerate(exp_model_i)
    catch ME
        StatusOK = false;
        ThisMessage = sprintf('Model acceleration failed. Check that you have a compiler installed and setup. %s', ME.message);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end % try
    
    ItemModels(ii).ExportedModel = exp_model_i;
    
    
end % for

% close waitbar
uix.utility.CustomWaitbar(1,hWbar1,'Done.');
if ~isempty(hWbar1) && ishandle(hWbar1)
    delete(hWbar1);
end

%% Sample parameter sets, simulate, compare to acceptance criteria
nSim = 0;
nPat = 0;
Vpop = zeros(obj.MaxNumVirtualPatients,length(LB_params));
isValid = zeros(obj.MaxNumVirtualPatients,1);
% while the total number of simulations and number of virtual patients are
% less than their respective maximum values...
while nSim<obj.MaxNumSimulations && nPat<obj.MaxNumVirtualPatients
    nSim = nSim+1; % tic up the number of simulations
    
    param_candidate = LB_params + (UB_params-LB_params).*rand(size(LB_params));
    param_candidate(logInds) = 10.^param_candidate(logInds);
    
    % generate a long vector of model outputs to compare to the acceptance
    % criteria
    model_outputs = [];
    time_outputs = [];
    LB_outputs = [];
    UB_outputs = [];
    
    for grp = 1:nItems
        % grab the task object
        tskInd = find(strcmp(obj.Item(grp).TaskName,{obj.Settings.Task.Name}));
        tObj_grp = obj.Settings.Task(tskInd);
        
        grpInds = find(Groups == str2double(obj.Item(grp).GroupID));
        
        % get group information
        Species_grp = Species(grpInds);
        Time_grp = Time(grpInds);
        LB_grp = LB_accCrit(grpInds);
        UB_grp = UB_accCrit(grpInds);
        
        % change output times for the exported model
        ItemModels(grp).ExportedModel.SimulationOptions.OutputTimes = sort(unique(Time_grp));
        
        % simulate
        try
            % if running to steady state
            if tObj_grp.RunToSteadyState
                % set time to reach steady state
                ItemModels(grp).ExportedModel.SimulationOptions.OutputTimes = [];
                ItemModels(grp).ExportedModel.SimulationOptions.StopTime = tObj_grp.TimeToSteadyState;
                % simulate model
                [~,RTSSdata] = simulate(ItemModels(grp).ExportedModel,[ItemModels(grp).ICs', param_candidate']);
                % record steady state values
                IC_ss = RTSSdata(end,1:length(ItemModels(grp).ICs));
                % update output times
                ItemModels(grp).ExportedModel.SimulationOptions.OutputTimes = sort(unique(Time_grp));
                ItemModels(grp).ExportedModel.SimulationOptions.StopTime = max(Time_grp);
                
                simData_grp = simulate(ItemModels(grp).ExportedModel,[IC_ss, param_candidate'],ItemModels(grp).Doses);
                
            else
                simData_grp = simulate(ItemModels(grp).ExportedModel,param_candidate',ItemModels(grp).Doses);
                
            end % end
            
            % for each species in this grp acc crit, find the corresponding
            % model output, grab relevant time points, compare
            uniqueSpecies_grp = unique(Species_grp);
            for spec = 1:length(uniqueSpecies_grp)
                % find the data species in the Species-Data mapping
                specInd = strcmp(uniqueSpecies_grp(spec),Mappings(:,2));
                
                % grap data for the corresponding model species from the simulation results
                [simT,simData_spec] = selectbyname(simData_grp,Mappings(specInd,1));
                
                try
                    % transform the model outputs to match the data
                    simData_spec = obj.SpeciesData(specInd).evaluate(simData_spec);
                catch ME
                    StatusOK = false;
                    ThisMessage = sprintf('There is an error in one of the function expressions in the SpeciesData mapping. Validate that all Mappings have been specified for each unique species in dataset. %s', ME.message);
                    Message = sprintf('%s\n%s\n',Message,ThisMessage);
                    path(myPath);
                    return                    
                end % try
                
                % grab all acceptance criteria time points for this species in this group
                ix_grp_spec = strcmp(uniqueSpecies_grp(spec),Species_grp);
                Time_grp_spec = Time_grp(ix_grp_spec);
                LB_grp_spec = LB_grp(ix_grp_spec);
                UB_grp_spec = UB_grp(ix_grp_spec);
                
                % select simulation time points for which there are acceptance criteria
                [bSim,okInds] = ismember(simT,Time_grp_spec);
                simData_spec = simData_spec(okInds(bSim));
                
                % save model outputs
                model_outputs = [model_outputs;simData_spec];
                time_outputs = [time_outputs;Time_grp_spec];
                
                LB_outputs = [LB_outputs; LB_grp_spec];
                UB_outputs = [UB_outputs; UB_grp_spec];
                
            end % for spec
        catch ME2
            % if the simulation fails, replace model outputs with Inf so
            % that the parameter set fails the acceptance criteria
            model_outputs = [model_outputs;Inf*ones(length(grpInds),1)];
            LB_outputs = [LB_outputs;NaN(length(grpInds),1)];            
            UB_outputs = [UB_outputs;NaN(length(grpInds),1)];
        end
        
    end % for grp
    
    % at this point, model_outputs should be the same length as the vectors
    % LB_accCrit and UB_accCrit
    
    % compare model outputs to acceptance criteria
    if ~isempty(model_outputs) 
        Vpop(nSim,:) = param_candidate'; % store the parameter set
        isValid(nSim) = double(all(model_outputs>=LB_outputs) && all(model_outputs<=UB_outputs));
        if isValid(nSim)
            nPat = nPat+1; % if conditions are satisfied, tick up the number of virutal patients
        end
    end      
end % while

% in case nPat is less than the maximum number of virtual patients...
% Vpop = Vpop(isValid==1,:); % removes extra zeros in Vpop

%% Outputs

ThisMessage = [num2str(nPat) ' virtual patients generated in ' num2str(nSim) ' simulations.'];
Message = sprintf('%s\n%s\n',Message,ThisMessage);

if nPat == 0
    StatusOK = false;
    ThisMessage = 'No virtual patients generated.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end

% Save the Vpop
if StatusOK
    
    SaveFlag = true;
    % add prevalence weight
    Vpop = [[paramNames; 'PWeight']'; [num2cell(Vpop), num2cell(isValid)]];
    % save prevalence weight to object
    obj.PrevalenceWeights = isValid;
    
    % save results
    SaveFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName);
    if ~exist(SaveFilePath,'dir')
        [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
        if ~ThisStatusOk
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            SaveFlag = false;
        end
    end
    
    obj.SimFlag = isValid;
    
    if SaveFlag
        VpopName = ['Results - Vpop Generation = ' obj.Name ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS')];
        ResultsFileName = [VpopName '.xlsx'];
        if ispc
            [ThisStatusOk,ThisMessage] = xlswrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
        else
            [ThisStatusOk,ThisMessage] = xlwrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
        end
        if ~ThisStatusOk
            StatusOK = false;
            Message = sprintf('%s\n%s\n',Message,ThisMessage.message);
        end
    else
        StatusOK = false;
        ThisMessage = 'Could not save the output of virtual population generation.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
        
end

% restore path
path(myPath);
end

