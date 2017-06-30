function [StatusOK,Message,ResultsFileNames,VpopNames] = optimizationRunHelper(obj)
% Sets up and runs the optimization contained in the Optimization object
% "obj".

StatusOK = true;
Message = '';

if isempty(obj.SpeciesIC)
    ResultsFileNames = cell(1,1);
    VpopNames = cell(1,1);
else
    ResultsFileNames = cell(1+length(obj.Item),1);
    VpopNames = cell(1+length(obj.Item),1);
end

%% Load Parameters
Names = {obj.Settings.Parameters.Name};
MatchIdx = strcmpi(Names,obj.RefParamName);
if any(MatchIdx)
    pObj = obj.Settings.Parameters(MatchIdx);
    [ThisStatusOk,ThisMessage,~,paramData] = importData(pObj,pObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    paramData = {};
end

if ~isempty(paramData)
    % parse paramData
    
    % remove any NaNs at bottom of file
    paramData = paramData(~strcmp('NaN',paramData(:,1)),:);
    
    % check that an initial guess is given
    if size(paramData,2)<6
    StatusOK = false;
        ThisMessage = 'No initial guess for the parameter values was given. Make sure sure the P0_1 column of the selected parameter file is filled out.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        return
    elseif any(any(isnan(cell2mat(paramData(:,6:end)))))
        StatusOK = false;
        ThisMessage = 'Parameter file is missing information.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        return
    end
    
    % separate into estimated parameters and fixed parameters
    estParamData = paramData(strcmpi('Yes',paramData(:,1)),:);
    fixedParamData = paramData(strcmpi('No',paramData(:,1)),:);
    if isempty(estParamData)
        StatusOK = false;
        ThisMessage = 'No parameters included in optimization.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        return
    end
    
    % record indices of parameters that will be log-scaled
    logInds = find(strcmp('log',estParamData(:,3)));
    % extract parameter names
    estParamNames = estParamData(:,2);
    fixedParamNames = fixedParamData(:,2);
    % extract numeric data
    estParamData = cell2mat(estParamData(:,4:end));
    fixedParamData = cell2mat(fixedParamData(:,6));
    % transform log-scaled parameters
    estParamData(logInds,:) = log10(estParamData(logInds,:));
    
    
else
    StatusOK = false;
    ThisMessage = 'The selected Parameter file is empty.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
    return
end



%% Load data
Names = {obj.Settings.OptimizationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    odObj = obj.Settings.OptimizationData(MatchIdx);
    DestFormat = 'wide';
    [ThisStatusOk,ThisMessage,optimHeader,optimData] = importData(odObj,odObj.FilePath,DestFormat);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    optimHeader = {};
    optimData = {};
end

if ~isempty(optimHeader) && ~isempty(optimData)
    % parse optimData
    Groups = cell2mat(optimData(:,strcmp(obj.GroupName,optimHeader)));
    IDs = cell2mat(optimData(:,strcmp(obj.IDName,optimHeader)));
    Time = cell2mat(optimData(:,strcmp('Time',optimHeader)));
    % find columns corresponding to species data and initial conditions
    dataInds = [];
    for ii = 1:length(optimHeader)
        if any(strcmp(optimHeader{ii},{obj.SpeciesData.DataName}))
            dataInds = [dataInds; ii];
        elseif any(strcmp(optimHeader{ii},{obj.SpeciesIC.DataName}))
            dataInds = [dataInds; ii];
        end % if
    end % for ii
    % convert optimData into a matrix of species data
    optimData = cell2mat(optimData(:,dataInds));
    % save only the headers for the data columns
    dataNames = optimHeader(:,dataInds);
    
    % remove data for groups that are not currently being used in optimization
    optimGrps = zeros(length(obj.Item),1);
    for ii = 1:length(obj.Item)
        optimGrps(ii) = str2double(obj.Item(ii).GroupID);
    end % for ii
    uniqueGrps = unique(Groups);
    for ii = 1:length(uniqueGrps)
        if ~any(uniqueGrps(ii)==optimGrps)
            optimData(Groups==uniqueGrps(ii),:) = [];
            Time(Groups==uniqueGrps(ii)) = [];
            IDs(Groups==uniqueGrps(ii)) = [];
            Groups(Groups==uniqueGrps(ii)) = [];
        end % if
    end % for ii
    uniqueGrps = unique(Groups);
    
    % process data so that if there are multiple measurements for a given time
    % point, replace with the average of those measurements
    for grp1 = 1:length(uniqueGrps)
        % find times and IDs associated with group
        Time_grp1 = Time(Groups==uniqueGrps(grp1));
        IDs_grp1 = IDs(Groups==uniqueGrps(grp1));
        uniqueIDs_grp1 = unique(IDs_grp1);
        for id1 = 1:length(uniqueIDs_grp1)
            % find unique times associated with this ID
            Time_id1 = Time_grp1(IDs_grp1==uniqueIDs_grp1(id1));
            uniqueTime_id = unique(Time_id1);
            
            for t1 = 1:length(uniqueTime_id)
                % for each unique time in this ID, find where that time value
                % occurs in the larger Time vector, conditional that it also
                % belongs to the current Group and ID
                repInds = find(Time==uniqueTime_id(t1) & Groups==uniqueGrps(grp1) & IDs==IDs_grp1(id1));
                
                % if this time value occurs more than once in this Group and ID
                if length(repInds)>1
                    % set the values of the data at the first instance of the
                    % time value, for all species, to the nanmean of all
                    % measurements at this time value
                    optimData(repInds(1),:) = nanmean(optimData(repInds,:),1);
                    
                    % remove the remaining data for the time value, and remove
                    % the corresponding Time, ID, and Group info
                    optimData(repInds(2:end),:) = [];
                    Time(repInds(2:end),:) = [];
                    IDs(repInds(2:end),:) = [];
                    Groups(repInds(2:end),:) = [];
                end % if
            end % for % t1
        end % for id1
    end % for grp1
else
    
    StatusOK = false;
    Message = 'The selected Data for Optimization file is empty.';
    return
end

% At this point, the data contains measurements only for unique time values


%% Generate structure containing pertinent Task information to pass to the
% objective function
% do this up-front so that it isn't done on every call to the objective
% function
nItems = length(obj.Item);
ItemModels = struct('TaskName',zeros(nItems,1),'RunToSteadyState',zeros(nItems,1),...
    'ExportedModel',zeros(nItems,1),'SpeciesInds',zeros(nItems,1),...
    'DefaultIC',zeros(nItems,1),'Doses',zeros(nItems,1),...
    'TimeToSteadyState',zeros(nItems,1),...
    'EstParamInds',zeros(nItems,1));

% Initialize waitbar
Title1 = sprintf('Configuring models...');
hWbar1 = uix.utility.CustomWaitbar(0,Title1,'',false);

% for each task-group item
for ii = 1:nItems
    % update waitbar
    uix.utility.CustomWaitbar(ii/nItems,hWbar1,sprintf('Configuring model for task %d of %d...',ii,nItems));
    
    % get the task obj from the settings obj
    tskInd = find(strcmp(obj.Item(ii).TaskName,{obj.Settings.Task.Name}));
    tObj_i = obj.Settings.Task(tskInd);
    
    % load the model in that task
    AllModels = sbioloadproject(tObj_i.RelativeFilePath);
    AllModels = cell2mat(struct2cell(AllModels));
    model_i = sbioselect(AllModels,'Name',tObj_i.ModelName,'type','sbiomodel');
    
    % apply the active variants (if specified)
    if ~isempty(tObj_i.ActiveVariantNames)
        % turn off all variants
        varObj_i = getvariant(model_i);
        for jj = 1 : length(varObj_i);
            varObj_i(jj).Active = false;
        end % for
        
        % combine active variants in order into a new variant, add to the
        % model and activate
        clear varObj_i
        for jj = 1 : length(tObj_i.ActiveVariantNames)
            varObj_i(jj) = model_i.variant(strcmp(tObj_i.ActiveVariantNames{jj},tObj_i.VariantNames));
        end % for
        [model_i,varSpeciesObj_i] = CombineVariants(model_i,varObj_i);
    else
        varSpeciesObj_i = [];
    end % if
    
    % inactivate reactions (if specified)
    if ~isempty(tObj_i.InactiveReactionNames)
        % turn on all reactions
        for jj = 1:length(model_i.Reactions)
            model_i.Reactions(jj).Active = true;
        end % for
        % turn off inactive reactions
        for jj = 1 : length(tObj_i.InactiveReactionNames)
            model_i.Reactions(strcmp(tObj_i.InactiveReactionNames{jj},tObj_i.ReactionNames)).Active = false;
        end % for
    end % if
    
    % inactivate rules (if specified)
    if ~isempty(tObj_i.InactiveRuleNames)
        % turn on all rules
        for jj = 1 : length(model_i.Rules);
            model_i.Rules(jj).Active = true;
        end % for
        % turn off inactive rules
        for jj = 1 : length(tObj_i.InactiveRuleNames)
            model_i.Reactions(strcmp(tObj_i.InactiveRuleNames{jj},tObj_i.RuleNames)).Active = false;
        end % for
    end % if
    
    % assume all parameters are present in all models
    clear est_pObj_i fixed_pObj_i
    for jj = 1:length(estParamNames)
        est_pObj_i(jj) = sbioselect(model_i,'Name',estParamNames{jj});
    end % for
    
    for jj = 1:length(fixedParamNames)
        fixed_pObj_i(jj) = sbioselect(model_i,'Name',fixedParamNames{jj});
    end % for
    
    % grab the default initial conditions from the model
    IC_i = zeros(1,length(model_i.Species));
    for jj = 1:length(model_i.Species)
        IC_i(jj) = model_i.Species(jj).InitialAmount;
    end % for
    
    % if variants affect the initial conditions, we must include them in the
    % IC_i vector so that those variants do not get overwritten by the
    % model defaults when IC_i is input to the exported model
    
    % first, get the names of all species in the model
    modelSpeciesNames_i = cell(length(model_i.Species),1);
    for jj = 1:length(model_i.Species)
        modelSpeciesNames_i{jj} = model_i.Species(jj).Name;
    end
    if ~isempty(varSpeciesObj_i)
        nVarSpec = length(varSpeciesObj_i.Content);
        for jj = 1:nVarSpec;
            % get the species name
            var_speciesName_j = varSpeciesObj_i.Content{jj}{2};
            % get its initial amount
            var_speciesIC_j = varSpeciesObj_i.Content{jj}{4};
            % apply the initial amount to the correct index of IC_i
            ind = strcmp(var_speciesName_j,modelSpeciesNames_i);
            IC_i(ind) = var_speciesIC_j;
        end
    end % if
    ItemModels(ii).DefaultICs = IC_i;
    
    % find the indices of each measured species in the model
    speciesInds_i = [];
    for jj = 1:length(obj.SpeciesIC)
        speciesInds_i = [speciesInds_i;find(strcmp(obj.SpeciesIC(jj).SpeciesName,modelSpeciesNames_i))];
    end
    ItemModels(ii).SpeciesInds = speciesInds_i;
    
    % run model to steady state?
    ItemModels(ii).RunToSteadyState = tObj_i.RunToSteadyState;
    
    % Export model, allowing all initial conditions and the parameters to vary
    if isempty(fixedParamNames)
        exp_model_i = export(model_i, [model_i.Species', est_pObj_i]);
    else
        exp_model_i = export(model_i, [model_i.Species', est_pObj_i, fixed_pObj_i]);
    end % if
    
    % set MaxWallClockTime in the exported model
    if ~isempty(tObj_i.MaxWallClockTime)
        exp_model_i.SimulationOptions.MaximumWallClock = tObj_i.MaxWallClockTime;
    else
        exp_model_i.SimulationOptions.MaximumWallClock = tObj_i.DefaultMaxWallClockTime;
    end % if
    
    % for the run to steady state option, get the user-provided time to
    % reach steady state
    ItemModels(ii).TimeToSteadyState = tObj_i.TimeToSteadyState;
    
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
    
end % for ii = ...

% close waitbar
uix.utility.CustomWaitbar(1,hWbar1,'Done.');
if ~isempty(hWbar1) && ishandle(hWbar1)
    delete(hWbar1);
end

%% Call optimization program
switch obj.AlgorithmName
    case 'ScatterSearch'
        [VpopParams,StatusOK,ThisMessage] = run_ss(@(est_p) objectiveFun(est_p,logInds,fixedParamData,ItemModels,Groups,IDs,Time,optimData,dataNames,obj),estParamData);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        
        if ~StatusOK
            return
        end
        
    case 'ParticleSwarm'
        
        %     case 'Local'
        %         % parameter bounds
        %         LB = paramData(:,1);
        %         UB = paramData(:,2);
        %
        %         % options
        %         LSQopts = optimoptions(@lsqnonlin,'MaxFunctionEvaluations',1e4,'MaxIterations',1e4,'UseParallel',false,'FunctionTolerance',1e-5,'StepTolerance',1e-3);
        %
        %         % fit
        %         p0 = paramData(:,3);
        %         VpopParams = lsqnonlin(@(p) objectiveFun(p,logInds,ItemModels,Groups,IDs,Time,optimData,dataNames,obj),p0,LB,UB,LSQopts);
        %         VpopParams = VpopParams';
end % switch

% VpopParams is a matrix of patients and varying parameter values
% patients run along the rows, parameters along the columns
% VpopParams only contains the parameters that were varied for
% optimization

%% Parse and save outputs
% transform parameters back
VpopParams(:,logInds) = 10.^VpopParams(:,logInds);

% fix timestamp
timeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');

% if if necessary, replicate parameters for each initial condition
if isempty(obj.SpeciesIC)
    % if no initial condition data is specified
    % make a single Vpop with default group ICs for each patient
    Vpop = VpopParams;
    ICspecNames = {};
else
    % if initial condition data is specified
    % Replicate parameters and match with initial conditions from data
    % Only include initial conditions measured in the data
    % If an initial condition is missing for a given ID or group, use model
    % default instead
    
    % get names of all species for which there is initial condition data,
    % across groups
    ICspecNames = {};
    for i = 1:length(obj.SpeciesIC)
        ICspecNames = [ICspecNames,obj.SpeciesIC(i).SpeciesName];
    end
    
    % get indices of all species for which there is initial condition data,
    % across groups. need to do this so that the Vpops for each group are
    % of the same size and can be concatentated
    allSpeciesInds = [];
    for grp1 = 1:length(ItemModels)
        allSpeciesInds = union(allSpeciesInds,ItemModels(grp1).SpeciesInds);
    end
    
    % prepare for a concatenated Vpop
    Vpop = [];
    nPatients = size(VpopParams,1);
    
    % make a Vpop for each group
    for grp1 = 1:length(obj.Item)
        Vpop_grp = [];
        
        % get indices of relevant rows
        grpInds1 = find(Groups == str2double(obj.Item(grp1).GroupID));
        
        % grab group data
        IDs_grp1 = IDs(grpInds1);
        Time_grp1 = Time(grpInds1);
        optimData_grp1 = optimData(grpInds1,:);
        
        % for each ID (varying initial conditions and time points in the same model)
        uniqueIDs_grp1 = unique(IDs_grp1);
        
        for pat = 1:nPatients
            for id1 = 1:length(uniqueIDs_grp1)
                % get time and data values for this ID
                optimData_id1 = optimData_grp1(IDs_grp1 == uniqueIDs_grp1(id1),:);
                Time_id1 = Time_grp1(IDs_grp1 == uniqueIDs_grp1(id1));
                % get default initial conditions for this group (uses model
                % plus variants in the corresponding task)
                IC_id1 = ItemModels(grp1).DefaultICs;
                
                % get IC values from data
                for spec1 = 1:length(obj.SpeciesIC)
                    % get species values for t<=0
                    IC_spec1 = optimData_id1(Time_id1<=0,strcmp(obj.SpeciesIC(spec1).DataName,dataNames));
                    
                    try
                        % transform values, take the mean
                        IC_spec1 = nanmean(obj.SpeciesIC(spec1).evaluate(IC_spec1));
                    catch ME
                        StatusOK = false;
                        ThisMessage = sprintf('There is an error in one of the function expressions in the SpeciesInitialConditions mapping. %s', ME.message);
                        Message = sprintf('%s\n%s\n',Message,ThisMessage);
                        return
                    end % try
                    
                    % check that the IC from data is not NaN
                    if ~isnan(IC_spec1)
                        % if not, replace the entry corresponding  to that
                        % that species in the default ICs
                        IC_id1(ItemModels(grp1).SpeciesInds(spec1)) = IC_spec1;
                    end % if
                end % for spec1 = ...
                
                % keep only those ICs that are measured in the data
                IC_id1 = IC_id1(allSpeciesInds);
                
                % Add VP parameters and data ICs for this ID to the Vpop
                Vpop_grp = [Vpop_grp;VpopParams(pat,:),IC_id1];

            end % for id1 = ...
        end % for pat = ...
        
        Vpop = [Vpop;Vpop_grp];
        
        % add headers to current group's Vpop
        Vpop_grp = [[estParamNames',ICspecNames]; num2cell(Vpop_grp)];

        % save current group's Vpop
        SaveFlag = true;
        SaveFilePath = fullfile(obj.Session.RootDirectory,obj.OptimResultsFolderName);
        if ~exist(SaveFilePath,'dir')
            [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
            if ~ThisStatusOk
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
                SaveFlag = false;
            end
        end
        
        if SaveFlag
            VpopNames{grp1} = ['Results - Optimization = ' obj.Name ' - Group = ' obj.Item(grp1).GroupID ' - Date = ' timeStamp];
            ResultsFileNames{grp1} = [VpopNames{grp1} '.xls'];
            xlswrite(fullfile(SaveFilePath,ResultsFileNames{grp1}),Vpop_grp);
            
        else
            StatusOK = false;
            ThisMessage = 'Unable to save results to Excel file.';
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
        end
    end % for grp1 = ...
    
    
end % if


% PWeight = ones(length(Vpop_grp),1)/length(Vpop_grp);
% Vpop = [[estParamNames',specNames,{'PWeight'}]; num2cell([Vpop,PWeight])];

% add headers to final Vpop
Vpop = [[estParamNames',ICspecNames]; num2cell(Vpop)];

% save final Vpop
SaveFlag = true;
SaveFilePath = fullfile(obj.Session.RootDirectory,obj.OptimResultsFolderName);
if ~exist(SaveFilePath,'dir')
    [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
    if ~ThisStatusOk
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        SaveFlag = false;
    end
end

if SaveFlag
    VpopNames{end} = ['Results - Optimization = ' obj.Name ' - Date = ' timeStamp];
    ResultsFileNames{end} = [VpopNames{end} '.xls'];
    xlswrite(fullfile(SaveFilePath,ResultsFileNames{end}),Vpop);
else
    StatusOK = false;
    ThisMessage = 'Unable to save results to Excel file.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end


%% Objective function
    function [objective,varargout] = objectiveFun(est_p,logInds,fixed_p,ItemModels,Groups,IDs,Time,optimData,dataNames,obj)
        tempStatusOK = true;
        tempMessage = '';
        
        inputStr = '(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)';
        
        if size(logInds,2)>size(logInds,1)
            logInds = logInds';
        end
        est_p(logInds) = 10.^(est_p(logInds));
        objectiveVec = [];
        
        % added property ObjectiveName to SpeciesData class
        objective_handles = cell(length(obj.SpeciesData),1);
        for spec = 1:length(obj.SpeciesData)
            objective_handles{spec} = str2func(['@' inputStr ' ' obj.SpeciesData(spec).ObjectiveName inputStr]);
        end
        SpeciesData = obj.SpeciesData;
        SpeciesIC = obj.SpeciesIC;
        
        % try calculating the objective
        try
            
            % for each Group (varying experiments)
            for grp = 1:length(obj.Item)
                
                % get indices of relevant rows
                currGrp = str2double(obj.Item(grp).GroupID);
                grpInds = find(Groups == currGrp);
                
                % grab group data
                IDs_grp = IDs(grpInds);
                Time_grp = Time(grpInds);
                optimData_grp = optimData(grpInds,:);
                
                % for each ID (varying initial conditions (animals) and time points in the same experiment)
                uniqueIDs_grp = unique(IDs_grp);
                for id = 1:length(uniqueIDs_grp)
                    currID = uniqueIDs_grp(id);
                    % get time and data values for this ID
                    optimData_id = optimData_grp(IDs_grp == currID,:);
                    Time_id = Time_grp(IDs_grp == currID);
                    
                    % change output times for the exported model
                    ItemModels(grp).ExportedModel.SimulationOptions.OutputTimes = sort(unique(Time_id(Time_id>=0)));
                    
                    % update initial conditions of each measured species using
                    % the data
                    IC_id = ItemModels(grp).DefaultICs;
                    
                    
                    %get species IC values from data
                    for spec = 1:length(SpeciesIC)
                        % get species values for t<=0
                        IC_spec = optimData_id(Time_id<=0,strcmp(SpeciesIC(spec).DataName,dataNames));
                        
                        try
                            % transform values, take the mean
                            IC_spec = nanmean(SpeciesIC(spec).evaluate(IC_spec));
                        catch tempME
                            tempStatusOK = false;
                            tempThisMessage = sprintf('There is an error in one of the function expressions in the SpeciesInitialConditions mapping. %s', tempME.message);
                            tempMessage = sprintf('%s\n%s\n',tempMessage,tempThisMessage);
                            
                            if nargout>1
                                varargout{1} = tempStatusOK;
                                varargout{2} = tempMessage;
                            end
                            return
                        end % try
                        
                        % check that the IC from data is not just NaN
                        if ~isnan(IC_spec)
                            IC_id(ItemModels(grp).SpeciesInds(spec)) = IC_spec;
                        end % if
                    end % for spec = ...
                    
                    
                    % run to steady state if checked for this group
                    if ItemModels(grp).RunToSteadyState
                        % set time to reach steady state
                        ItemModels(grp).ExportedModel.SimulationOptions.OutputTimes = [];
                        ItemModels(grp).ExportedModel.SimulationOptions.StopTime = ItemModels(grp).TimeToSteadyState;
                        % simulate model
                        [~,RTSSdata] = simulate(ItemModels(grp).ExportedModel,[IC_id,est_p',fixed_p']);
                        % record steady state values
                        IC_id = RTSSdata(end,1:length(IC_id));
                        % update output times
                        ItemModels(grp).ExportedModel.SimulationOptions.OutputTimes = sort(unique(Time_id(Time_id>=0)));
                        ItemModels(grp).ExportedModel.SimulationOptions.StopTime = max(Time_id(Time_id>=0));
                    end % if
                    
                    % simulate experiment for this ID
                    simData_id = simulate(ItemModels(grp).ExportedModel,[IC_id,est_p',fixed_p'],ItemModels(grp).Doses);
                    
                    % generate elements of objective vector by comparing model
                    % outputs to data
                    for spec = 1:length(SpeciesData)
                        % name of current species in the dataset
                        currDataName = SpeciesData(spec).DataName;
                        
                        % grab each model output for the measured species
                        [simTime_spec,simData_spec] = selectbyname(simData_id,SpeciesData(spec).SpeciesName);
                        
                        % transform to match the format of the measured data
                        try
                            simData_spec = SpeciesData(spec).evaluate(simData_spec);
                        catch tempME
                            tempStatusOK = false;
                            tempThisMessage = sprintf('There is an error in one of the function expressions in the SpeciesData mapping. %s', tempME.message);
                            tempMessage = sprintf('%s\n%s\n',tempMessage,tempThisMessage);
                            
                            if nargout>1
                                varargout{1} = tempStatusOK;
                                varargout{2} = tempMessage;
                            end
                            return                    
                        end % try
                        
                        % compare model outputs to data and concatenate onto the
                        % objective vector, keeping only time points for which
                        % there is data for that species
                        optimData_spec = optimData_id(Time_id>=0,strcmp(SpeciesData(spec).DataName,dataNames));
                        simData_spec = simData_spec(~isnan(optimData_spec));
                        dataTime_spec = sort(Time_id(Time_id>=0));
                        dataTime_spec = dataTime_spec(~isnan(optimData_spec));
                        
                        % simTime was set to be the unique list of times for
                        % this ID, therefore it should be the same length
                        % as the output of sort(Time_id(Time_id>=0))
                        simTime_spec = simTime_spec(~isnan(optimData_spec));
                        
                        % remove NaNs from optimData_spec
                        optimData_spec = optimData_spec(~isnan(optimData_spec));
                        
                        % optimData_spec, simData_spec, and dataTime_spec
                        % should now be vectors of the same length and contain
                        % no nans
                        
                        % Inputs are '(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)'
                        % or           (simData_spec,optimData_spec,simTime_spec,dataTime_spec,optimData(:,strcmp(currDataName,dataNames)),IDs,Groups,currID,currGrp)
                        objectiveVec = [objectiveVec; objective_handles{spec}(simData_spec,optimData_spec,simTime_spec,dataTime_spec,optimData(:,strcmp(currDataName,dataNames)),IDs,Groups,currID,currGrp)];
                        
                    end % for spec = ...
                    
                end % for id = ...
                
            end % for grp = ...
            
        catch
            % if objective calculation fails
            objectiveVec = [];
            for grp = 1:length(obj.Item)
                
                % get indices of relevant rows
                currGrp = str2double(obj.Item(grp).GroupID);
                grpInds = find(Groups == currGrp);
                
                % grab group data
                IDs_grp = IDs(grpInds);
                optimData_grp = optimData(grpInds,:);
                
                % for each ID
                uniqueIDs_grp = unique(IDs_grp);
                for id = 1:length(uniqueIDs_grp)
                    currID = uniqueIDs_grp(id);
                    % get data values for this ID
                    optimData_id = optimData_grp(IDs_grp == currID,:);
                    
                    %
                    for spec = 1:length(SpeciesData)
                        optimData_spec = optimData_id(Time_id>=0,strcmp(SpeciesData(spec).DataName,dataNames));
                        objectiveVec = [objectiveVec; 1e6*ones(length(optimData_spec(~isnan(optimData_spec))),1)];
                    end % for spec = ...
                end % for id
            end % for grp
        end % try
        
        
        switch obj.AlgorithmName
            case 'ScatterSearch'
                % sum objectiveVec entries to get the current objective value
                objective = sum(objectiveVec);
                
            case 'ParticleSwarm'
                % sum objectiveVec entries to get the current objective value
                objective = sum(objectiveVec);
                
                %             case 'Local'
                %                 % requires that the selected ObjectiveName is localObj
                %                 objective = objectiveVec;
                
        end % switch
        
        if nargout>1
            varargout{1} = tempStatusOK;
            varargout{2} = tempMessage;
        end
        
    end % function


end % function

