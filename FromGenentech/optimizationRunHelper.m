function [StatusOK,Message,ResultsFileNames,VpopNames] = optimizationRunHelper(obj)
% Sets up and runs the optimization contained in the Optimization object
% "obj".

StatusOK = true;
Message = '';

% store path & add all subdirectories of root directory
myPath = path;
addpath(genpath(obj.Session.RootDirectory));


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
        path(myPath);
        return
    end
else
    warning('Could not find match for specified parameter file')
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
        path(myPath);
        return
    elseif any(any(isnan(cell2mat(paramData(:,6:end)))))
        StatusOK = false;
        ThisMessage = 'Parameter file is missing information.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    end
    
    % separate into estimated parameters and fixed parameters
    idxEstimate = strcmpi('Yes',paramData(:,1));
    if ~any(idxEstimate)
        StatusOK = false;
        ThisMessage = 'No parameters included in optimization.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        path(myPath);
        return
    end
    
    % record indices of parameters that will be log-scaled
    logInds = find(strcmpi('log',paramData(idxEstimate,3)));
    % extract parameter names
    estParamNames = paramData(idxEstimate,2);
    fixedParamNames = paramData(~idxEstimate,2);
    % extract numeric data
    estParamData = cell2mat(paramData(idxEstimate,4:end));
    if ~isempty(fixedParamNames)
        fixedParamData = cell2mat(paramData(~idxEstimate,6));
    else
        fixedParamData = {};
    end
    % transform log-scaled parameters
    estParamData(logInds,:) = log10(estParamData(logInds,:));
    
    paramObj.estParamNames = estParamNames;
    paramObj.fixedParamNames = fixedParamNames;
    paramObj.fixedParamData = fixedParamData;
    paramObj.logInds = logInds;
    
else
    StatusOK = false;
    ThisMessage = 'The selected Parameter file is empty.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
    path(myPath);
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
    [~, dataInds] = ismember({obj.SpeciesData.DataName}, optimHeader);
    
    
    % convert optimData into a matrix of species data
    optimData = cell2mat(optimData(:,dataInds));
    % save only the headers for the data columns
    dataNames = optimHeader(:,dataInds);
    
    % remove data for groups that are not currently being used in optimization
    optimGrps = cell2mat(cellfun(@str2num, {obj.Item.GroupID}, 'UniformOutput', false));
    include = ismember(Groups, optimGrps);
    optimData = optimData(include,:);
    Time = Time(include,:);
    IDs = IDs(include,:);
    Groups = Groups(include,:);
    
    % process data so that if there are multiple measurements for a given time
    % point, replace with the average of those measurements
    [~,ia,G] = unique([Groups, IDs, Time], 'rows');
    optimData = splitapply(@(X) nanmean(X,1), optimData, G );
    Time = Time(ia,:);
    IDs = IDs(ia,:);
    Groups = Groups(ia,:);
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

% for each task-group item
for ii = 1:nItems

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
    
    ItemModels.Task(ii) = tObj_i;
end % for ii = ...


%% Call optimization program
switch obj.AlgorithmName
    case 'ScatterSearch'
        [VpopParams,StatusOK,ThisMessage] = run_ss(@(est_p) objectiveFun(est_p,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj),estParamData);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        
        if ~StatusOK
            path(myPath);
            return
        end
        
    case 'ParticleSwarm'
        N = size(estParamData,1);
        try
            StatusOK = true;
            LB = estParamData(:,1);
            UB = estParamData(:,2);
            options = optimoptions('ParticleSwarm', 'Display', 'iter', 'FunctionTolerance', .1, 'MaxTime', 10, ...
                'UseParallel', false, 'FunValCheck', 'on', 'UseVectorized', false, 'PlotFcn',  @pswplotbestf);
            VpopParams = particleswarm( @(est_p) objectiveFun(est_p',paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj), N, LB, UB, options);
        catch err
            StatusOK = false;
            warning('Encountered error in particle swarm optimization')
            Message = sprintf('%s\n%s\n',Message,err);
            path(myPath);
            return
        end    
        

    case 'Local'
        warning('Local optimization not yet implemented')
        StatusOK = false;
        path(myPath);
        return
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
    ICspecNames = {obj.SpeciesIC.SpeciesName};
    
    % get indices of all species for which there is initial condition data,
    % across groups. need to do this so that the Vpops for each group are
    % of the same size and can be concatentated
    allSpeciesInds = [];
%     for grp1 = 1:length(ItemModels)
%         allSpeciesInds = union(allSpeciesInds,ItemModels(grp1).SpeciesInds);
%     end
    
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
        SpeciesIC = obj.SpeciesIC;

        for pat = 1:nPatients
            for id1 = 1:length(uniqueIDs_grp1)
                % get time and data values for this ID
                optimData_id1 = optimData_grp1(IDs_grp1 == uniqueIDs_grp1(id1),:);
                Time_id1 = Time_grp1(IDs_grp1 == uniqueIDs_grp1(id1));
                
                %get species IC values from data for the current ID
                % use average of values with t <= 0
                [~,spIdx] = ismember({SpeciesIC.DataName},dataNames); % columns in the data table
                IC = optimData_id1(Time_id1<=0,spIdx);
                IC = nanmean(IC,1);
                                
                % Add VP parameters and data ICs for this ID to the Vpop
                Vpop_grp = [Vpop_grp;VpopParams(pat,:),IC];

            end % for id1 = ...
        end % for pat = ...
        
        Vpop = [Vpop;Vpop_grp];
        
        % add headers to current group's Vpop
        Vpop_grp = [[estParamNames', fixedParamNames' ,ICspecNames]; num2cell(Vpop_grp)];

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
            ResultsFileNames{grp1} = [VpopNames{grp1} '.xlsx'];
            if ispc
                xlswrite(fullfile(SaveFilePath,ResultsFileNames{grp1}),Vpop_grp);
            else
                xlwrite(fullfile(SaveFilePath,ResultsFileNames{grp1}),Vpop_grp);
            end
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
    if ispc
        xlswrite(fullfile(SaveFilePath,ResultsFileNames{end}),Vpop);
    else
        xlwrite(fullfile(SaveFilePath,ResultsFileNames{end}),Vpop);
    end
else
    StatusOK = false;
    ThisMessage = 'Unable to save results to Excel file.';
    Message = sprintf('%s\n%s\n',Message,ThisMessage);
end


%% Objective function
    function [objective,varargout] = objectiveFun(est_p,paramObj,ItemModels,Groups,IDs,Time,optimData,dataNames,obj)
        tempStatusOK = true;
        tempMessage = '';
        
%         inputStr = '(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)';
        logInds = reshape( paramObj.logInds, [], 1);
        
        fixed_p = paramObj.fixedParamData;
        estParamNames = paramObj.estParamNames;
        fixedParamNames = paramObj.fixedParamNames;
        
        est_p(logInds) = 10.^(est_p(logInds));
        objectiveVec = [];
        
        % added property ObjectiveName to SpeciesData class
        objective_handles = cell(length(obj.SpeciesData),1);
        for spec = 1:length(obj.SpeciesData)
            objective_handles{spec} = str2func( regexprep(obj.SpeciesData(spec).ObjectiveName, '.m$', ''));
        end
        SpeciesData = obj.SpeciesData;
        SpeciesIC = obj.SpeciesIC;
        
        % try calculating the objective
        try
            
            % for each Group (varying experiments)
            for grpIdx = 1:length(obj.Item)
                
                % get indices of relevant rows
                currGrp = str2double(obj.Item(grpIdx).GroupID);
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
                    
                    %get species IC values from data for the current ID
                    % use average of values with t <= 0
                    [~,spIdx] = ismember({SpeciesIC.DataName},dataNames); % columns in the data table
                    IC = optimData_id(Time_id<=0,spIdx);
                    IC = nanmean(IC,1);
 
                    % simulate experiment for this ID
                    OutputTimes = sort(unique(Time_id(Time_id>=0)));
                    StopTime = max(Time_id(Time_id>=0));
                    
                    simData_id = ItemModels.Task(grpIdx).simulate(...
                        'Names', [{SpeciesIC.SpeciesName}'; estParamNames; fixedParamNames], ...
                        'Values', [IC';est_p;fixed_p], ...
                        'OutputTimes', OutputTimes, ...
                        'StopTime', StopTime );
                    
                    
                    % generate elements of objective vector by comparing model
                    % outputs to data
                    for spec = 1:length(SpeciesData)
                        % name of current species in the dataset
                        currDataName = SpeciesData(spec).DataName;
                        
                        
                        
                        try
                            % grab each model output for the measured species                        
                            [simTime_spec,simData_spec] = selectbyname(simData_id,SpeciesData(spec).SpeciesName);
                            % transform to match the format of the measured data
                            simData_spec = SpeciesData(spec).evaluate(simData_spec);
                        catch tempME
                            tempStatusOK = false;
                            tempThisMessage = sprintf('There is an error in one of the function expressions in the SpeciesData mapping. %s', tempME.message);
                            tempMessage = sprintf('%s\n%s\n',tempMessage,tempThisMessage);
                            
                            if nargout>1
                                varargout{1} = tempStatusOK;
                                varargout{2} = tempMessage;
                            end
                            path(myPath);
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
                        thisObj = objective_handles{spec}(simData_spec,optimData_spec,simTime_spec,dataTime_spec,optimData(:,strcmp(currDataName,dataNames)),IDs,Groups,currID,currGrp);
                        objectiveVec = [objectiveVec; thisObj];
                        
                    end % for spec = ...
                    
                end % for id = ...
                
            end % for grp = ...
            
        catch simErr
            disp(simErr.message)
            % if objective calculation fails
            objectiveVec = [];
            for grpIdx = 1:length(obj.Item)
                
                % get indices of relevant rows
                currGrp = str2double(obj.Item(grpIdx).GroupID);
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
                        try
                        optimData_spec = optimData_id(Time_id>=0,strcmp(SpeciesData(spec).DataName,dataNames));
                        catch err
                            disp(err.message)
                        end
                        objectiveVec = [objectiveVec;inf(length(optimData_spec(~isnan(optimData_spec))),1)];
                    end % for spec = ...
                end % for id
            end % for grp
        end % try
        
        
        switch obj.AlgorithmName
            case 'ScatterSearch'
                % sum objectiveVec entries to get the current objective value
                objective = nansum(objectiveVec);
                
            case 'ParticleSwarm'
                % sum objectiveVec entries to get the current objective value
                objective = nansum(objectiveVec);
                
                %             case 'Local'
                %                 % requires that the selected ObjectiveName is localObj
                %                 objective = objectiveVec;
                
        end % switch
        
        if nargout>1
            varargout{1} = tempStatusOK;
            varargout{2} = tempMessage;
        end
        
    end % function

path(myPath);

end % function

