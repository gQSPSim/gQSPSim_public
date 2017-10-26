function [StatusOK,Message,ResultFileNames,varargout] = simulationRunHelper(obj,varargin)
% Function that performs the simulations using the (Task,
% VirtualPopulation) pairs listed in the simulation object "obj".
% Simulates the model using the variants, doses, rules, reactions, and 
% species specified in each Task for each set of parameters in the 
% corresponding VirtualPopulation.

StatusOK = true;
Message = '';
paramNames_i = {};

if isempty(obj)
    nItems = 0;
else
    nItems = length(obj.Item);
end
if nItems == 0
    StatusOK = false;
    ThisMessage = sprintf('There are no simulation items.');
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end
ResultFileNames = cell(nItems,1);
% Cell containing all results
output = cell(1,nItems);

Pin = [];
if nargin == 3
    Pin = varargin{1};
    Pin = reshape(Pin,1,[]); % row vector
    paramNames = varargin{2};
else
    paramNames = {};
end

% allow for manual specification of output times to be included on top of
% the task-specific output times
if nargin==4
    extraOutputTimes = varargin{3};
else
    extraOutputTimes = [];
end

% Get the simulation object name
simName = obj.Name;

% Extract the names of all tasks and vpops %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allTaskNames = {obj.Settings.Task.Name};
allVpopNames = {obj.Settings.VirtualPopulation.Name};


% If Pin is empty, check that all Vpops have nonempty name and FilePath
if isempty(Pin)
    for ii = 1:nItems
        vpopName = obj.Item(ii).VPopName;
        if ~isempty(vpopName)
            vObj_i = obj.Settings.VirtualPopulation(strcmp(vpopName,allVpopNames));
            if isempty(vObj_i.FilePath)
                StatusOK = false;
%                 ThisMessage = sprintf('The virtual population named %s is incomplete.',vpopName);
%                 Message = sprintf('%s\n%s\n',Message,ThisMessage);
                error('The virtual population named %s is incomplete.', vpopName)
                break
            end % if
        else
            StatusOK = false;
            ThisMessage = sprintf('A virtual population is missing a name.');
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            break
        end % if
        
    end % for
end % if

% Define a structure to contain exported models and other information
% relevant to simulation
ItemModels = [];
% ItemModels = struct('Task',zeros(nItems,1),'Vpop',zeros(nItems,1),...
%     'ExportedModel',zeros(nItems,1),'ICs',zeros(nItems,1),...
%     'Doses',zeros(nItems,1),'VPopParams',zeros(nItems,1),...
%     'VPopSpeciesICs',zeros(nItems,1),'VpopSpeciesInds',zeros(nItems,1), 'nPatients', zeros(nItems,1));

% Initialize waitbar
Title1 = sprintf('Configuring models...');
hWbar1 = uix.utility.CustomWaitbar(0,Title1,'',false);

% Configure models for each (task, vpop) pair (i.e. for each simulation
% item) %%
for ii = 1:nItems
    % update waitbar
    uix.utility.CustomWaitbar(ii/nItems,hWbar1,sprintf('Configuring model for task %d of %d...',ii,nItems));
    
    % grab the names of the task and vpop for the i'th simulation
    taskName = obj.Item(ii).TaskName;
    vpopName = obj.Item(ii).VPopName;
    
    % find the relevant task and vpop objects in the settings object
    tObj_i = obj.Settings.Task(strcmp(taskName,allTaskNames));
    
    if isempty(tObj_i)
        warning('Error loading task %s. Skipping...', taskName)
        continue
    end
    
    ItemModels(ii).Task = tObj_i;
    vObj_i = [];
    if ~isempty(vpopName)
        vObj_i = obj.Settings.VirtualPopulation(strcmp(vpopName,allVpopNames));
    end
    ItemModels(ii).Vpop = vObj_i;
    
    % load the model in that task
    AllModels = sbioloadproject(tObj_i.FilePath);
    AllModels = cell2mat(struct2cell(AllModels));
    model_i = sbioselect(AllModels,'Name',tObj_i.ModelName,'type','sbiomodel');
    
    % apply the active variants (if specified)
    varSpeciesObj_i = [];
    if ~isempty(tObj_i.ActiveVariantNames)
        % turn off all variants
        varObj_i = getvariant(model_i);
        set(varObj_i,'Active',false);

        % combine active variants in order into a new variant, add to the
        % model and activate
        [~,tmp]=ismember(tObj_i.ActiveVariantNames, tObj_i.VariantNames);
        varObj_i = model_i.variant(tmp);
        [model_i,varSpeciesObj_i] = CombineVariants(model_i,varObj_i);
    end % if
    
    % inactivate reactions (if specified)
    if ~isempty(tObj_i.InactiveReactionNames)
        % turn on all reactions
        set(model_i.Reactions,'Active',true);
        % turn off inactive reactions
        set(model_i.Reactions(ismember(tObj_i.ReactionNames, tObj_i.InactiveReactionNames)),'Active',false);
    end % if
    
    % inactivate rules (if specified)
    if ~isempty(tObj_i.InactiveRuleNames)        
        % turn on all rules
        set(model_i.Rules,'Active',true);
        % turn off inactive rules
        set(model_i.Rules(ismember(tObj_i.RuleNames,tObj_i.InactiveRuleNames)),'Active',false);
    end % if
    
%%%%% Load the Vpop and parse contents %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% they are 1) all full and Pin is empty or 2) all full and Pin is not
    % empty or 3) all empty and Pin is not empty
    % case 1) only need to export model with parameters in the Vpop
    % case 2) need to export model with all parameters and find the
    % locations of each parameter in the Vpop
    % case 3) need to export model with all parameters, but don't need to
    % worry about the Vpop
    vPop_params_i = {};
    vPop_speciesNames_i = {}; % names of species whose ICs vary in the Vpop
    vPop_speciesIC_i = []; % values of those ICs in the Vpop
    vPop_species_inds = []; % indices of those species in the model
    if isempty(Pin) && ~isempty(vObj_i) % AG: TODO: added ~isempty(vObj_i) for function-call from plotOptimization. Need to verify with Genentech
        % case 1)
        T_i = readtable(vObj_i.FilePath);
        vPop_params_i = T_i{1:end,1:end};
        paramNames_i = T_i.Properties.VariableNames;
        % check whether the last column is PWeight
        if strcmp('PWeight',paramNames_i{end})
            VpopWeights = vPop_params_i(:,end);
            vPop_params_i = vPop_params_i(:,1:end-1);
            paramNames_i = paramNames_i(1:end-1);
        else
            VpopWeights = [];
        end % if
        nPatients_i = size(vPop_params_i,1);
        
        % Parse vpop contents further to find species initial conditions that
        % vary in the vpop
        % if a names in paramNames_i matches a species name in the model,
        % change the status of the corresponding Vpop information
        
        [vPop_speciesNames_i,tmp,vPop_species_inds] = intersect(paramNames_i,tObj_i.SpeciesNames);
        vPop_speciesIC_i = vPop_params_i(:,tmp);
        [~,vPop_param_inds] = setdiff(paramNames_i,tObj_i.SpeciesNames); % indices of parameters
        
        [paramNames_i,tmp] = setdiff(paramNames_i, vPop_speciesNames_i);
        vPop_params_i = vPop_params_i(:,tmp);
        
        % select parameters that vary in the vpop
        if isempty(paramNames_i)
            pObj_i = []; 
        else
            clear pObj_i
        end
        for jj = 1 : length(paramNames_i)
            pObj_i(jj) = sbioselect(model_i, 'Name', paramNames_i{jj});             
        end % for
        
    elseif ~isempty(vObj_i)
        % case 2)
        % case 1)
        T_i = readtable(vObj_i.FilePath);
        vPop_params_i = table2array(T_i);
        paramNames_i = T_i.Properties.VariableNames;
        % check whether the last column is PWeight
        if strcmp('PWeight',paramNames_i{end})
            VpopWeights = vPop_params_i(:,end);
            vPop_params_i = vPop_params_i(:,1:end-1);
            paramNames_i = paramNames_i(1:end-1);
        else
            VpopWeights = [];
        end % if
        nPatients_i = size(vPop_params_i,1);
        
        % Parse vpop contents further to find species initial conditions that
        % vary in the vpop
        % if a name in paramNames_i matches a species name in the model,
        % change the status of the corresponding Vpop information
        [vPop_speciesNames_i,tmp,vPop_species_inds] = intersect(paramNames_i,tObj_i.SpeciesNames);
        vPop_speciesIC_i = vPop_params_i(:,tmp);      
        [~,vPop_param_inds] = setdiff(paramNames_i,tObj_i.SpeciesNames); % indices of parameters
        
        [paramNames_i,tmp] = setdiff(paramNames_i, vPop_speciesNames_i);
        vPop_params_i = vPop_params_i(:,tmp);
               
        % if we are here, the parameters in Pin are organized in the same
        % order as those in the Vpops, and all Vpops have the same
        % parameters. ie paramNames should be equal to paramNames_i, after
        % separating out the species initial conditions
        % the parameters in Pin will be the final parameters used in
        % simulation
        % what the Vpop brings is initial conditions information
        
        % select parameters in Pin
        if isempty(paramNames_i)
            pObj_i = []; 
        else
            clear pObj_i
        end 
        for jj = 1 : length(paramNames_i)
            pObj_i(jj) = sbioselect(model_i, 'Name', paramNames_i{jj});
        end % for
        
    elseif isempty(vObj_i)
        % case 3)
        
        nPatients_i = 1;
        
        % if we are here, there are no species initial conditions in the
        % Vpop
        % ICs all come from the model and variants
        vPop_speciesNames_i = [];
                
        % select parameters in Pin
        if isempty(paramNames_i)
            pObj_i = []; 
        else
            clear pObj_i
        end       
        for jj = 1 : length(paramNames)
            pObj_i(jj) = sbioselect(model_i, 'Name', paramNames{jj});
        end % for
        
        vPop_param_inds = 1:numel(paramNames); % indices of parameters

        
    end % if
    
    % select species for which the initial conditions vary in the vpop
    if ~isempty(vPop_speciesNames_i)
        for jj = 1 : length(vPop_speciesNames_i)
            sObj_i(jj) = sbioselect(model_i, 'Name', vPop_speciesNames_i{jj});
        end % for
    end % if
    
    ItemModels(ii).VPopParams = vPop_params_i;
    ItemModels(ii).VPopParamInds = vPop_param_inds;
    ItemModels(ii).VPopSpeciesICs = vPop_speciesIC_i;
    ItemModels(ii).VpopSpeciesInds = vPop_species_inds;
    ItemModels(ii).nPatients = nPatients_i;
%%%%% Export model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if tObj_i.RunToSteadyState
        % allowing all initial conditions and the parameters in vpop to vary
        exp_model_i = export(model_i, [model_i.Species', pObj_i]);        
    else
        % allowing only the parameters and species in vpop to vary
        if isempty(vPop_speciesNames_i)
            exp_model_i = export(model_i, pObj_i);
        else
            exp_model_i = export(model_i, [sObj_i, pObj_i]);
        end % if
    end % if
    
    % set MaxWallClockTime in the exported model
    if ~isempty(tObj_i.MaxWallClockTime)
        exp_model_i.SimulationOptions.MaximumWallClock = tObj_i.MaxWallClockTime;
    else
        exp_model_i.SimulationOptions.MaximumWallClock = tObj_i.DefaultMaxWallClockTime;
    end % if
    
    % set the output times
    if ~isempty(tObj_i.OutputTimes)
        outputTimes = union(extraOutputTimes, tObj_i.OutputTimes);
        exp_model_i.SimulationOptions.OutputTimes = outputTimes;
    else
        outputTimes = union(extraOutputTimes, tObj_i.DefaultOutputTimes);
        exp_model_i.SimulationOptions.OutputTimes = outputTimes;
    end % if
    
    % select active doses (if specified)
    exp_doses_i = [];
    if ~isempty(tObj_i.ActiveDoseNames)
        for jj = 1 : length(tObj_i.ActiveDoseNames)
            exp_doses_i = [exp_doses_i, getdose(exp_model_i, tObj_i.ActiveDoseNames{jj})];
        end % for
    end % if
    ItemModels(ii).Doses = exp_doses_i;
                  
    % if running to steady state, extract the initial conditions
    defaultIC_i = [];
    if tObj_i.RunToSteadyState
        defaultIC_i = zeros(1,length(tObj_i.SpeciesNames));
        for jj = 1:length(tObj_i.SpeciesNames)
            defaultIC_i(jj) = model_i.Species(jj).InitialAmount;
        end % for
         
        % if variants affect initial conditions, must include them in the
        % IC_i vector so that those variants do not get overwritten by 
        % model defaults when IC_i is input to the exported model
        if ~isempty(varSpeciesObj_i)
            % first, get the names of all species in the model
            modelSpeciesNames_i = cell(length(model_i.Species),1);
            for jj = 1:length(model_i.Species)
                modelSpeciesNames_i{jj} = model_i.Species(jj).Name;
            end
            % get the names and values of all species in the variant
            nVarSpec = length(varSpeciesObj_i.Content);
            for jj = 1:nVarSpec;
                % get the species name
                var_speciesName_j = varSpeciesObj_i.Content{jj}{2};
                % get its initial amount
                var_speciesIC_j = varSpeciesObj_i.Content{jj}{4};
                % apply the initial amount to the correct index of IC_i
                ind = strcmp(var_speciesName_j,modelSpeciesNames_i);
                defaultIC_i(ind) = var_speciesIC_j;
            end
        end % if
    end % if
    ItemModels(ii).ICs = defaultIC_i;
    
    % accelerate model
    try
        accelerate(exp_model_i)
    catch ME
        StatusOK = false;
        ThisMessage = sprintf('Model acceleration failed. Check that you have a compiler installed and setup. %s', ME.message);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end % try
    ItemModels(ii).ExportedModel = exp_model_i;
end % for ii...

% close waitbar
uix.utility.CustomWaitbar(1,hWbar1,'Done.');
if ~isempty(hWbar1) && ishandle(hWbar1)
    delete(hWbar1);
end


%%%% Simulate each parameter set in the vpop %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize waitbar
Title2 = sprintf('Simulating tasks...');
hWbar2 = uix.utility.CustomWaitbar(0,Title2,'',false);

if ~isempty(ItemModels)
    
    for ii = 1:nItems
        % update waitbar
        uix.utility.CustomWaitbar(ii/nItems,hWbar2,sprintf('Simulating task %d of %d',ii,nItems));

        % clear the results of the previous simulation
        Results = [];
        tObj_i = ItemModels(ii).Task;

        if isempty(tObj_i) % could not load the task
            continue
        end

        % store the output times in Results
        if ~isempty(tObj_i.OutputTimes)
            Results.Time = union(tObj_i.OutputTimes, extraOutputTimes);
        else
            Results.Time = union(tObj_i.DefaultOutputTimes, extraOutputTimes);
        end % if

        % preallocate a 'Data' field in Results structure
        Results.Data = [];

        % species names
        Results.SpeciesNames = [];
        if ~isempty(tObj_i.ActiveSpeciesNames)
            Results.SpeciesNames = tObj_i.ActiveSpeciesNames;
        else
            Results.SpeciesNames = tObj_i.SpeciesNames;
        end

        % keep track of # of failed simulations
        nFailedSims = 0;

        % For each virtual patient:
        for jj = 1 : ItemModels(ii).nPatients
            % check for user-input parameter values
            if ~isempty(Pin)
                params_ij = Pin(ItemModels(ii).VPopParamInds);
            else
                params_ij = ItemModels(ii).VPopParams(jj,:);
            end

            exp_model_i = ItemModels(ii).ExportedModel;
            exp_doses_i = ItemModels(ii).Doses;

            %%%%%%% If running the simulation to steady state %%%%%%%%%%%%%%%%%%%%%%%%%
            if tObj_i.RunToSteadyState
                % Update initial conditions if species ICs vary in the Vpop by
                % applying the values of the ICs from the Vpop
                IC_ij = ItemModels(ii).ICs;

                if ~isempty(ItemModels(ii).VpopSpeciesInds)
                    IC_ij(ItemModels(ii).VpopSpeciesInds) = ItemModels(ii).VPopSpeciesICs(jj,:);
                end % if

                % Set run time using the user-provided time to reach steady state
                exp_model_i.SimulationOptions.OutputTimes = [];
                exp_model_i.SimulationOptions.StopTime = tObj_i.TimeToSteadyState;

                % Grab doses

                % Simulate to steady state
                try
                    % run to steady state without doses
                    [~,RTSSdata,~] = simulate(exp_model_i, [IC_ij, params_ij]);

                catch
                    RTSSdata = NaN;
                    nFailedSims = nFailedSims + 1;
                end % try

                % Modify stop time/output times
                if ~isempty(tObj_i.OutputTimes)
                    exp_model_i.SimulationOptions.OutputTimes = tObj_i.OutputTimes;
                else
                    exp_model_i.SimulationOptions.OutputTimes = tObj_i.DefaultOutputTimes;
                end % if

                % If simulation to steady state was successful, simulate with
                % the steady state concentrations as initial conditions
                if ~any(isnan(RTSSdata(:)))
                    RTSSdata(end,RTSSdata(end,:)<0)=0;

                    % Simulate
                    try 
                        simData_j = simulate(exp_model_i, [RTSSdata(end,1:length(tObj_i.SpeciesNames)), params_ij], exp_doses_i);

                        % extract active species data, if specified
                        if ~isempty(tObj_i.ActiveSpeciesNames)
                            [~,activeSpec_j] = selectbyname(simData_j,tObj_i.ActiveSpeciesNames);
                            %                         Results.SpeciesNames = [Results.SpeciesNames, tObj_i.ActiveSpeciesNames];
                        else
                            [~,activeSpec_j] = selectbyname(simData_j,tObj_i.SpeciesNames);
                            %                         Results.SpeciesNames = [Results.SpeciesNames, tObj_i.SpeciesNames];
                        end % if

                        % Add results of the simulation to Results.Data
                        Results.Data = [Results.Data,activeSpec_j];

                    catch % simulation
                        % If the simulation fails, store NaNs

                        % pad Results.Data with appropriate number of NaNs
                        if ~isempty(tObj_i.ActiveSpeciesNames)
                            Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(tObj_i.ActiveSpeciesNames))];
                            %                         Results.SpeciesNames = [Results.SpeciesNames, tObj_i.ActiveSpeciesNames];
                        else
                            Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(tObj_i.SpeciesNames))];
                            %                         Results.SpeciesNames = [Results.SpeciesNames, tObj_i.SpeciesNames];
                        end % if

                        nFailedSims = nFailedSims + 1;

                    end % try

                    % if run to steady state was unsuccessful, go straight to
                    % padding Results with NaNs
                else
                    % pad Results.Data with appropriate number of NaNs
                    if ~isempty(tObj_i.ActiveSpeciesNames)
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(tObj_i.ActiveSpeciesNames))];
                        %                     Results.SpeciesNames = [Results.SpeciesNames, tObj_i.ActiveSpeciesNames];
                    else
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(tObj_i.SpeciesNames))];
                        %                     Results.SpeciesNames = [Results.SpeciesNames, tObj_i.SpeciesNames];
                    end % if

                end % if


                %%%%%%% If NOT running to steady state %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else
                % Simulate
                try
                    if isempty(ItemModels(ii).VPopSpeciesICs)
                        simData_j = simulate(exp_model_i, params_ij, exp_doses_i);
                    else
                        simData_j = simulate(exp_model_i, [ItemModels(ii).VPopSpeciesICs(jj,:), params_ij], exp_doses_i);
                    end % if

                    % extract active species data, if specified
                    if ~isempty(tObj_i.ActiveSpeciesNames)
                        [~,activeSpec_j] = selectbyname(simData_j,tObj_i.ActiveSpeciesNames);
                        %                     Results.SpeciesNames = [Results.SpeciesNames, tObj_i.ActiveSpeciesNames];
                    else
                        [~,activeSpec_j] = selectbyname(simData_j,tObj_i.SpeciesNames);
                        %                     Results.SpeciesNames = [Results.SpeciesNames, tObj_i.SpeciesNames];
                    end % if

                    % Add results of the simulation to Results.Data
                    Results.Data = [Results.Data,activeSpec_j];

                catch exception% simulation
                    % If the simulation fails, store NaNs

                    % pad Results.Data with appropriate number of NaNs
                    if ~isempty(tObj_i.ActiveSpeciesNames)
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(tObj_i.ActiveSpeciesNames))];
                        %                     Results.SpeciesNames = [Results.SpeciesNames, tObj_i.ActiveSpeciesNames];
                    else
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(tObj_i.SpeciesNames))];
                        %                     Results.SpeciesNames = [Results.SpeciesNames, tObj_i.SpeciesNames];
                    end % if

                    nFailedSims = nFailedSims + 1;

                end % try

            end % if
        end % for jj = ...

    %%% Save results of each simulation in different files %%%%%%%%%%%%%%%%%%%%
        SaveFlag = true;

        % add results to output cell
        output{ii} = Results;

        % don't save the data if Pin is provided
        if ~isempty(Pin)
            SaveFlag = false;
        end

        SaveFilePath = fullfile(obj.Session.RootDirectory,obj.SimResultsFolderName);
        if ~exist(SaveFilePath,'dir')
            [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
            if ~ThisStatusOk
                Message = sprintf('%s\n%s\n',Message,ThisMessage);
                SaveFlag = false;
            end
        end

        if SaveFlag
            % Update ResultFileNames
            ResultFileNames{ii} = ['Results - Sim = ' simName ', Task = ' obj.Item(ii).TaskName ' - Vpop = ' obj.Item(ii).VPopName ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];

            if isempty(VpopWeights)
                save(fullfile(SaveFilePath,ResultFileNames{ii}), 'Results')
            else
                save(fullfile(SaveFilePath,ResultFileNames{ii}), 'Results', 'VpopWeights')
            end
            % right now it's one line of Message per Simulation Item
            ThisMessage = [num2str(jj-nFailedSims) ' simulations were successful out of ' num2str(jj) '.'];
            Message = sprintf('%s\n%s\n',Message,ThisMessage);        
        elseif isempty(Pin)
            StatusOK = false;
            ThisMessage = 'Unable to save results to MAT file.';
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
        end

    end % for ii = ...

end

% close waitbar
uix.utility.CustomWaitbar(1,hWbar2,'Done.');
if ~isempty(hWbar2) && ishandle(hWbar2)
    delete(hWbar2);
end

% output the results of all simulation items if Pin in provided
if nargout == 4
    varargout{1} = output;
end

end

