function [simData, statusOK] = simulate(obj, varargin)
    
    statusOK = true;

    p = inputParser;
    p.addOptional('Names', {});
    p.addOptional('Values', {});
    p.addParameter('OutputTimes', obj.OutputTimes);
    p.addParameter('StopTime', obj.TimeToSteadyState);

    parse(p, varargin{:});
    Names = p.Results.Names;
    Values = p.Results.Values;
    
    
    % rebuild model if necessary
    if ~obj.checkModelCurrent()
%         uix.utility.CustomWaitbar(ii/nBuildItems,hWbar1,sprintf('Configuring model for %s', obj.Name);        
        obj.constructModel();
        disp('Rebuilding model')
    end
    
%     [~,idxSpecies] = ismember(Names, obj.SpeciesNames);    
    [~,idxSpecies] = ismember(obj.SpeciesNames, Names);    

    ICSpecies = Names(idxSpecies(idxSpecies>0));      
    ICValues = Values(idxSpecies(idxSpecies>0));
    
    % indices of each specified parameter in the complete list of
    % parameters
    modelParams = sbioselect(obj.VarModelObj,'Type','Parameter'); 

    [hParam, ixParam] = ismember(Names,get(modelParams,'Name'));
    
    pNames = Names(hParam); % parameter names
    pValues = Values(hParam); % parameter values
    ixParam = ixParam(hParam); % keep only indices that are parameters
    
    % get default parameter values for the current variants
    paramValues = cell2mat(get(modelParams,'Value'));
    
    % replace values with the specified values
    paramValues(ixParam) = pValues;   
    
    times = p.Results.OutputTimes;
    StopTime = p.Results.StopTime;
    
    model = obj.ExportedModel;
    
    activeDoses = obj.ActiveDoseNames(:);
    if isempty(activeDoses)
        doses = [];
    else
        allDoses = getdose(model);        
        doses = allDoses(ismember({allDoses.Name}, {obj.ActiveDoseNames{:}}));
    end
    
    % get initial conditions
    if isempty(ICValues)        
        % if not specified, use default values /w variants applied
        ICValues = cell2mat(get(obj.VarModelObj.Species, 'InitialAmount'));
    else 
        % set initial conditions from argument
        [~,spIdx] = ismember(ICSpecies, obj.SpeciesNames);
        ICs_all = cell2mat(get(obj.VarModelObj.Species, 'InitialAmount'));
        idxValid = ~isnan(ICValues);
        ICs_all(spIdx(idxValid)) = ICValues(idxValid);
        ICValues = ICs_all;       
    end
            
%     test = load('test');
%     paramValues = test.paramValues;
    
    if obj.RunToSteadyState
        % Simulate to steady state
        try
            model.SimulationOptions.StopTime = StopTime;
            model.SimulationOptions.OutputTimes = [];            
            [~,RTSSdata,~] = simulate(model,[ICValues; paramValues],[]);
            RTSSdata = max(0,RTSSdata); % replace any negative values with zero
            if any(isnan(RTSSdata(:)))
                ME = MException('Task:simulate', 'Encountered NaN during simulation');
                throw(ME)
            end
            ICValues = reshape(RTSSdata(end,1:length(obj.SpeciesNames)),[],1);
        catch err
            warning(err.identifier, 'simulationRunHelper: %s', err.message)
            statusOK = false;
            simData= [];
            return
        end % try
    end    

    model.SimulationOptions.StopTime = StopTime;
    model.SimulationOptions.OutputTimes = times;
    simData = simulate(model,[ICValues; paramValues],doses);
end




