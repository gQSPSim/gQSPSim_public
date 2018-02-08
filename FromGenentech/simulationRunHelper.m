function [StatusOK,Message,ResultFileNames,varargout] = simulationRunHelper(obj,varargin)
% Function that performs the simulations using the (Task,
% VirtualPopulation) pairs listed in the simulation object "obj".
% Simulates the model using the variants, doses, rules, reactions, and 
% species specified in each Task for each set of parameters in the 
% corresponding VirtualPopulation.

StatusOK = true;
Message = '';
ResultFileNames = {};
if nargout > 3
    varargout{1} = {};
end

%% update path to include everything in subdirectories of the root folder
myPath = path;
addpath(genpath(obj.Session.RootDirectory));


%% parse inputs and initialize
% [nItems, ResultFileNames, output, Pin, paramNames, extraOutputTimes, simName, allTaskNames, allVpopNames] = parseInputs(obj,varargin);

[options, ThisStatusOK, ThisMessage] = parseInputs(obj,varargin{:});
[ThisStatusOK,ThisMessage] = validatePin(obj, options, ThisStatusOK, ThisMessage);

if ~ThisStatusOK
    StatusOK = false;
    Message = ThisMessage;
    return;
end


VpopWeights = [];
ItemModels = [];

% Initialize waitbar
Title1 = sprintf('Configuring models...');
hWbar1 = uix.utility.CustomWaitbar(0,Title1,'',false);

nItems = options.nItems;

% Configure models for each (task, vpop) pair (i.e. for each simulation item)
for ii = 1:nItems
    % update waitbar
    uix.utility.CustomWaitbar(ii/nItems,hWbar1,sprintf('Configuring model for task %d of %d...',ii,nItems));
    
    % grab the names of the task and vpop for the i'th simulation
    taskName = obj.Item(ii).TaskName;
    vpopName = obj.Item(ii).VPopName;
    
    % Validate
    taskObj = obj.Settings.Task(strcmp(taskName,options.allTaskNames));
    [ThisStatusOK,ThisMessage] = validate(taskObj,false);        
    if isempty(taskObj)
        continue
    elseif ~ThisStatusOK
        StatusOK = false;
        ThisMessage = sprintf('Error loading task "%s". Skipping [%s]...', taskName,ThisMessage);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        continue
    end
    
    % find the relevant task and vpop objects in the settings object
    vpopObj = [];    
    if ~isempty(vpopName) && ~strcmp(vpopName,QSP.Simulation.NullVPop)
        vpopObj = obj.Settings.VirtualPopulation(strcmp(vpopName,options.allVpopNames));
        if isempty(vpopObj)
            ThisStatusOK = false;
            ThisMessage = sprintf('Invalid vpop "%s". VPop does not exist.',vpopName);
        else
            [ThisStatusOK,ThisMessage] = validate(vpopObj,false);
        end
        if ~ThisStatusOK
            StatusOK = false;
            ThisMessage = sprintf('Error loading vpop "%s". Skipping [%s]...', vpopName,ThisMessage);            
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            continue
        end
    end   
    
    % Load the Vpop and parse contents 
   [ThisItemModel, VpopWeights, ThisStatusOK, ThisMessage] = constructVpopItem(taskObj, vpopObj, options, Message);
   if ii == 1
       ItemModels = ThisItemModel;
   else
       ItemModels(ii) = ThisItemModel;
   end
   if ~ThisStatusOK
       StatusOK = false;
       Message = sprintf('%s\n%s\n',Message,ThisMessage);
   end

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

%% Cell containing all results
output = cell(1,nItems);
ResultFileNames = cell(nItems,1);

if ~isempty(ItemModels)
    
    for ii = 1:nItems
        ItemModel = ItemModels(ii);
        
        % update waitbar
        uix.utility.CustomWaitbar(ii/nItems,hWbar2,sprintf('Simulating task %d of %d',ii,nItems));

        % simulate virtual patients
        [Results, nFailedSims, ThisStatusOK, ThisMessage] = simulateVPatients(ItemModel, options, Message);
        if ~ThisStatusOK
            StatusOK = false;
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            continue
        end
        
        %%% Save results of each simulation in different files %%%%%%%%%%%%%%%%%%%%
        SaveFlag = isempty(options.Pin); % don't save if PIn is provided

        % add results to output cell
        output{ii} = Results;

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
            ResultFileNames{ii} = ['Results - Sim = ' options.simName ', Task = ' obj.Item(ii).TaskName ' - Vpop = ' obj.Item(ii).VPopName ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];

            if isempty(VpopWeights)
                save(fullfile(SaveFilePath,ResultFileNames{ii}), 'Results')
            else
                save(fullfile(SaveFilePath,ResultFileNames{ii}), 'Results', 'VpopWeights')
            end
            % right now it's one line of Message per Simulation Item
            if nFailedSims == ItemModel.nPatients
                ThisMessage = 'No simulations were successful. (Check that dependencies are valid.)';
            else
                ThisMessage = [num2str(ItemModel.nPatients-nFailedSims) ' simulations were successful out of ' num2str(ItemModel.nPatients) '.'];
            end
            Message = sprintf('%s\n%s\n',Message,ThisMessage);        
        elseif isfield(options,'Pin') && isempty(options.Pin)
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

% restore path
path(myPath);

end

% [nItems, ResultFileNames, output, Pin, paramNames, extraOutputTimes, simName, allTaskNames, allVpopNames] = parseInputs(obj,varargin)
function [options, StatusOK, Message] = parseInputs(obj, varargin)

StatusOK = true;
Message = '';

%% get number of items to simulate
if ~isempty(obj)
    nItems = length(obj.Item);
else
    nItems = 0;
    StatusOK = false;
    ThisMessage = sprintf('There are no simulation items.');
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end

Pin = []; % input parameters for simulation (empty by default)
paramNames = {}; % parameter names
extraOutputTimes = [];

if nargin == 3
    Pin = varargin{1};
    Pin = reshape(Pin,1,[]); % row vector
    paramNames = varargin{2};
end

% allow for manual specification of output times to be included on top of
% the task-specific output times
if nargin==4
    extraOutputTimes = varargin{3};
end

% Get the simulation object name
simName = obj.Name;

% Extract the names of all tasks and vpops %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
allTaskNames = {obj.Settings.Task.Name};
allVpopNames = {obj.Settings.VirtualPopulation.Name};


%% construct options object
options.nItems = nItems;
options.Pin = Pin;
options.paramNames = paramNames;
options.extraOutputTimes = extraOutputTimes;
options.simName = simName;
options.allTaskNames = allTaskNames;
options.allVpopNames = allVpopNames;

end

function [StatusOK,Message] = validatePin(obj, options, StatusOK, Message)
Pin = options.Pin;
nItems = options.nItems;

if isempty(Pin)
    for ii = 1:nItems
        vpopName = obj.Item(ii).VPopName;
        if strcmp(vpopName,QSP.Simulation.NullVPop)
            % do not create a vpopObj for the model default virtual population
            continue
        end
        if ~isempty(vpopName) 
            tmpObj = obj.Settings.VirtualPopulation(strcmp(vpopName,options.allVpopNames));
            if isempty(tmpObj) 
                StatusOK = false;
                error('The virtual population named %s is invalid.', vpopName) % TODO: Replace with ThisMessage/Message?
                break
            elseif isempty(tmpObj.FilePath)
                StatusOK = false;
%                 ThisMessage = sprintf('The virtual population named %s is incomplete.',vpopName);
%                 Message = sprintf('%s\n%s\n',Message,ThisMessage);
                error('The virtual population named %s is incomplete.', vpopName) % TODO: Replace with ThisMessage/Message?
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

end

function [model, varSpeciesObj_i] = constructModel(taskObj)

    % load the model in that task
    AllModels = sbioloadproject(taskObj.FilePath);
    AllModels = cell2mat(struct2cell(AllModels));
    model = sbioselect(AllModels,'Name',taskObj.ModelName,'type','sbiomodel');

    % apply the active variants (if specified)
    varSpeciesObj_i = [];
    if ~isempty(taskObj.ActiveVariantNames)
        % turn off all variants
        varObj_i = getvariant(model);
        set(varObj_i,'Active',false);

        % combine active variants in order into a new variant, add to the
        % model and activate
        [~,tmp] = ismember(taskObj.ActiveVariantNames, taskObj.VariantNames);
        varObj_i = model.variant(tmp);
        [model,varSpeciesObj_i] = CombineVariants(model,varObj_i);
    end % if

    % inactivate reactions (if specified)
    if ~isempty(taskObj.InactiveReactionNames)
        % turn on all reactions
        set(model.Reactions,'Active',true);
        % turn off inactive reactions
        set(model.Reactions(ismember(taskObj.ReactionNames, taskObj.InactiveReactionNames)),'Active',false);
    end % if

    % inactivate rules (if specified)
    if ~isempty(taskObj.InactiveRuleNames)        
        % turn on all rules
        set(model.Rules,'Active',true);
        % turn off inactive rules
        set(model.Rules(ismember(taskObj.RuleNames,taskObj.InactiveRuleNames)),'Active',false);
    end % if
end

function [ItemModel, VpopWeights, StatusOK, Message] = constructVpopItem(taskObj, vpopObj, options, Message)
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
    VpopWeights     = [];

    paramNames = options.paramNames;
    
    ItemModel.Vpop = vpopObj;
    ItemModel.Task = taskObj;


    % construct model using variants, reactions, species, etc.
    [thisModel,varSpeciesObj_i] = constructModel(taskObj);
    
    if ~isempty(vpopObj) % AG: TODO: added ~isempty(vpopObj) for function-call from plotOptimization. Need to verify with Genentech
        T_i             = readtable(vpopObj.FilePath);
        vPop_params_i   = table2cell(T_i);         
        paramNames_i    = T_i.Properties.VariableNames;

        % check whether the last column is PWeight
        if strcmp('PWeight',paramNames_i{end})
            VpopWeights     = vPop_params_i(:,end);
            vPop_params_i   = vPop_params_i(:,1:end-1);
            paramNames_i    = paramNames_i(1:end-1);
        end 
        nPatients_i = size(vPop_params_i,1);
        
        % Parse vpop contents further to find species initial conditions that
        % vary in the vpop
        % if a names in paramNames_i matches a species name in the model,
        % change the status of the corresponding Vpop information
        
        [vPop_speciesNames_i,tmp,vPop_species_inds] = intersect(paramNames_i,taskObj.SpeciesNames);
        vPop_speciesIC_i = vPop_params_i(:,tmp);
        [~,vPop_param_inds] = setdiff(paramNames_i,taskObj.SpeciesNames); % indices of parameters
        
        [paramNames_i,tmp] = setdiff(paramNames_i, vPop_speciesNames_i);
        vPop_params_i = vPop_params_i(:,tmp);
        
        % select parameters that vary in the vpop
        if isempty(paramNames_i)
            pObj_i = SimBiology.Parameter;          
        else
            clear pObj_i
        end
        for jj = 1 : length(paramNames_i)
            pObj_i(jj) = sbioselect(thisModel, 'Name', paramNames_i{jj});             
        end % for
        
    else 
        % case 3)        
        nPatients_i = 1; % Question: Should this be 0 or 1? (If 0, Results.Data is empty)
        
        % if we are here, there are no species initial conditions in the
        % Vpop
        % ICs all come from the model and variants
        vPop_speciesNames_i = [];
                
        % select parameters in Pin
        if isempty(paramNames)
            pObj_i = []; 
        else
            clear pObj_i
        end       
        for jj = 1 : length(paramNames)
            pObj_i(jj) = sbioselect(thisModel, 'Name', paramNames{jj});
        end % for
        
        vPop_param_inds = 1:numel(paramNames); % indices of parameters        
    end % if
    
    % select species for which the initial conditions vary in the vpop
    if ~isempty(vPop_speciesNames_i)
        for jj = 1 : length(vPop_speciesNames_i)
            sObj_i(jj) = sbioselect(thisModel, 'Name', vPop_speciesNames_i{jj});
        end % for
    end % if
    
    ItemModel.VPopParams = vPop_params_i;
    ItemModel.VPopParamInds = vPop_param_inds;
    ItemModel.VPopSpeciesICs = vPop_speciesIC_i;
    ItemModel.VpopSpeciesInds = vPop_species_inds;
    ItemModel.nPatients = nPatients_i;    
    
    %%%%% Export model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if taskObj.RunToSteadyState
        % allowing all initial conditions and the parameters in vpop to vary
        exp_model_i = export(thisModel, [thisModel.Species', pObj_i]);        
    else
        % allowing only the parameters and species in vpop to vary
        if isempty(vPop_speciesNames_i)
            exp_model_i = export(thisModel, pObj_i);
        else
            exp_model_i = export(thisModel, [sObj_i, pObj_i]);
        end % if
    end % if
    
    % set MaxWallClockTime in the exported model
    if ~isempty(taskObj.MaxWallClockTime)
        exp_model_i.SimulationOptions.MaximumWallClock = taskObj.MaxWallClockTime;
    else
        exp_model_i.SimulationOptions.MaximumWallClock = taskObj.DefaultMaxWallClockTime;
    end % if
    
    % set the output times
    if ~isempty(taskObj.OutputTimes)
        outputTimes = union(options.extraOutputTimes, taskObj.OutputTimes);
        exp_model_i.SimulationOptions.OutputTimes = outputTimes;
    else
        outputTimes = union(options.extraOutputTimes, taskObj.DefaultOutputTimes);
        exp_model_i.SimulationOptions.OutputTimes = outputTimes;
    end % if
    
    % select active doses (if specified)
    exp_doses_i = [];
    if ~isempty(taskObj.ActiveDoseNames)
        for jj = 1 : length(taskObj.ActiveDoseNames)
            exp_doses_i = [exp_doses_i, getdose(exp_model_i, taskObj.ActiveDoseNames{jj})];
        end % for
    end % if
    ItemModel.Doses = exp_doses_i;
                  
    % if running to steady state, extract the initial conditions
    defaultIC_i = [];
    if taskObj.RunToSteadyState
        defaultIC_i = zeros(1,length(taskObj.SpeciesNames));
        for jj = 1:length(taskObj.SpeciesNames)
            defaultIC_i(jj) = thisModel.Species(jj).InitialAmount;
        end % for
         
        % if variants affect initial conditions, must include them in the
        % IC_i vector so that those variants do not get overwritten by 
        % model defaults when IC_i is input to the exported model
        if ~isempty(varSpeciesObj_i)
            % first, get the names of all species in the model
            modelSpeciesNames_i = cell(length(thisModel.Species),1);
            for jj = 1:length(thisModel.Species)
                modelSpeciesNames_i{jj} = thisModel.Species(jj).Name;
            end
            % get the names and values of all species in the variant
            nVarSpec = length(varSpeciesObj_i.Content);
            for jj = 1:nVarSpec
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
    ItemModel.ICs = defaultIC_i;
    
    % accelerate model
    StatusOK = true;

    try
        accelerate(exp_model_i)
    catch ME
        StatusOK = false;
        ThisMessage = sprintf('Model acceleration failed. Check that you have a compiler installed and setup. %s', ME.message);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end % try
    ItemModel.ExportedModel = exp_model_i;
    
end

function [Results, nFailedSims, StatusOK, Message] = simulateVPatients(ItemModel, options, Message)
    nFailedSims = 0;
    taskObj = ItemModel.Task;
    
    % clear the results of the previous simulation
    Results = [];
    StatusOK = true;
    
    Pin = options.Pin;
    
    if isempty(taskObj) % could not load the task
        StatusOK = false;
        Message = sprintf('%s\n\n%s', 'Failed to run simulation', Message);
        
        path(myPath);
        return
    end

    % store the output times in Results
    if ~isempty(taskObj.OutputTimes)
        taskTimes = taskObj.OutputTimes;
    else
        taskTimes = taskObj.DefaultOutputTimes;
    end        
    Results.Time = union(taskTimes, options.extraOutputTimes);

    % preallocate a 'Data' field in Results structure
    Results.Data = [];

    % species names
    Results.SpeciesNames = [];
    if ~isempty(taskObj.ActiveSpeciesNames)
        Results.SpeciesNames = taskObj.ActiveSpeciesNames;
    else
        Results.SpeciesNames = taskObj.SpeciesNames;
    end    
    

    if isfield(ItemModel,'nPatients')
        for jj = 1:ItemModel.nPatients
            % check for user-input parameter values
            if ~isempty(Pin)
                params = Pin(ItemModel.VPopParamInds);
            elseif ~isempty(ItemModel.VPopParams)
                params = ItemModel.VPopParams(jj,:);
            else
                params = [];
            end
            
            model = ItemModel.ExportedModel;
            doses = ItemModel.Doses;

            %%%%%%% If running the simulation to steady state %%%%%%%%%%%%%%%%%%%%%%%%%
            if taskObj.RunToSteadyState
                % Update initial conditions if species ICs vary in the Vpop by
                % applying the values of the ICs from the Vpop
                ICs = ItemModel.ICs;

                if ~isempty(ItemModel.VpopSpeciesInds)
                    ICs(ItemModel.VpopSpeciesInds) = ItemModel.VPopSpeciesICs(jj,:);
                end % if

                % Set run time using the user-provided time to reach steady state
                model.SimulationOptions.OutputTimes = [];
                model.SimulationOptions.StopTime    = taskObj.TimeToSteadyState;

                % Simulate to steady state
                try
                    % run to steady state without doses
                    [~,RTSSdata,~] = simulate(model, [ICs, params]);
                catch
                    RTSSdata = NaN;
                    nFailedSims = nFailedSims + 1;
                end % try

                % Modify stop time/output times
                if ~isempty(taskObj.OutputTimes)
                    model.SimulationOptions.OutputTimes = taskObj.OutputTimes;
                else
                    model.SimulationOptions.OutputTimes = taskObj.DefaultOutputTimes;
                end % if

                % If simulation to steady state was successful, simulate with
                % the steady state concentrations as initial conditions
                if ~any(isnan(RTSSdata(:)))
                    RTSSdata(end,RTSSdata(end,:)<0)=0; % replace any negative values with zero

                    % Simulate
                    try
                        simData = simulate(model, [RTSSdata(end,1:length(taskObj.SpeciesNames)), params], doses);

                        % extract active species data, if specified
                        if ~isempty(taskObj.ActiveSpeciesNames)
                            [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                        else
                            [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                        end

                        % Add results of the simulation to Results.Data
                        Results.Data = [Results.Data,activeSpec_j];

                    catch % simulation
                        % If the simulation fails, store NaNs

                        % pad Results.Data with appropriate number of NaNs
                        if ~isempty(taskObj.ActiveSpeciesNames)
                            Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames))];
                        else
                            Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.SpeciesNames))];
                        end

                        nFailedSims = nFailedSims + 1;

                    end % try

                    % if run to steady state was unsuccessful, go straight to
                    % padding Results with NaNs
                else
                    % pad Results.Data with appropriate number of NaNs
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames))];
                    else
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.SpeciesNames))];
                    end
                end
                
                %%%%%%% If NOT running to steady state %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            else
                % Simulate
                try
                    if iscell(params)
                        params = cell2mat(params);
                    end
                    if isempty(ItemModel.VPopSpeciesICs)
                        if ~isempty(params)                            
                            simData = simulate(model, params, doses);
                        elseif ~isempty(doses)
                            simData = simulate(model, doses);
                        else
                            simData = simulate(model);
                        end
                    else
                        tmp = ItemModel.VPopSpeciesICs(jj,:);
                        tmp = horzcat(tmp{:});
                        if ~isempty(doses)
                            simData = simulate(model, [tmp, params]);
                        else
                            simData = simulate(model, [tmp, params], doses);
                        end
                    end % if

                    % extract active species data, if specified
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                    else
                        [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                    end % if

                    % Add results of the simulation to Results.Data
                    Results.Data = [Results.Data,activeSpec_j];

                catch exception% simulation
                    % If the simulation fails, store NaNs

                    % Store exception's message
                    ThisMessage = exception.message;
                    Message = sprintf('%s\n%s\n',Message,ThisMessage);

                    % pad Results.Data with appropriate number of NaNs
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames))];
                        %                     Results.SpeciesNames = [Results.SpeciesNames, taskObj.ActiveSpeciesNames];
                    else
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.SpeciesNames))];
                        %                     Results.SpeciesNames = [Results.SpeciesNames, taskObj.SpeciesNames];
                    end % if

                    nFailedSims = nFailedSims + 1;

                end % try

            end % if
        end % for jj = ...
    end % if
    

    
end
