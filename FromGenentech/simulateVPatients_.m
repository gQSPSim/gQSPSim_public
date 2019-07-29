
function [Results, nFailedSims, StatusOK, Message, Cancelled] = simulateVPatients_(ItemModel, options, Message)  
    Cancelled = false;
    nFailedSims = 0;
    taskObj = ItemModel.Task;
    
    % clear the results of the previous simulation
    Results = [];
    StatusOK = true;
    
    ParamValues_in = options.Pin;
    
    usePar = options.usePar;
    ParallelCluster = options.ParallelCluster;
    
    if isempty(taskObj) % could not load the task
        StatusOK = false;
        Message = sprintf('%s\n\n%s', 'Failed to run simulation', Message);
        
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
        
        if ~usePar
            for jj = 1:ItemModel.nPatients
    %             disp([' ', num2str(jj),' '])
                % check for user-input parameter values
                if ~isempty(ParamValues_in)
                    Names = options.paramNames;
                    Values = ParamValues_in;
                else
                    Names = ItemModel.Names;
                    Values = ItemModel.Values;
                end


                try 
                    if isempty(Values)
                        theseValues = [];
                    else
                        theseValues = Values(jj,:);
                    end
                    
                    [simData,simOK,errMessage]  = taskObj.simulate(...
                            'Names', Names, ...
                            'Values', theseValues, ...
                            'OutputTimes', Results.Time, ...
                            'Waitbar', options.WaitBar);
                    if ~simOK

    %                     ME = MException('simulationRunHelper:simulateVPatients', 'Simulation failed with error: %s', errMessage );
    %                     throw(ME)
                        StatusOK = false;
                        warning('Simulation %d failed with error: %s\n', jj, errMessage);
                        activeSpec_j = NaN(size(Results.Time,1), length(taskObj.ActiveSpeciesNames));
                    else
                        % extract active species data, if specified
                        if ~isempty(taskObj.ActiveSpeciesNames)
                            [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                        else
                            [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                        end

                    end

                % Add results of the simulation to Results.Data
                Results.Data = [Results.Data,activeSpec_j];
                catch err% simulation
                    % If the simulation fails, store NaNs
                    warning(err.identifier, 'simulationRunHelper: %s', err.message)
                    % pad Results.Data with appropriate number of NaNs
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames))];
                    else
                        Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.SpeciesNames))];
                    end

                    nFailedSims = nFailedSims + 1;

                end % try

                % update wait bar
                if ~isempty(options.WaitBar)
                    StatusOK = uix.utility.CustomWaitbar(jj/ItemModel.nPatients, options.WaitBar, sprintf('Simulating vpatient %d/%d', jj, ItemModel.nPatients));
                end
                if ~StatusOK
                    Cancelled=true;
                    break
                end
            end % for jj = ...
        else
            
            p = gcp('nocreate');
            UDF_files = dir(fullfile(options.UDF,'**','*.m'));
            UDF_files = arrayfun(@(x) fullfile(x.folder,x.name), UDF_files, 'UniformOutput', false);
            if isempty(p)
                p = parpool(ParallelCluster); %, 'AutoAddClientPath', true, 'AttachedFiles', UDF_files);
            elseif ~strcmp(p.Cluster.Profile, taskObj.Session.ParallelCluster)
                delete(gcp('nocreate'))
                p = parpool(obj.Session.ParallelCluster, ...
                 'AttachedFiles', taskObj.Session.UserDefinedFunctionsDirectory);
            end
            
            addAttachedFiles(p, UDF_files);
            
           
            q = parallel.pool.DataQueue;
            listener = afterEach(q, @(jj) updateWaitBar(options.WaitBar, ItemModel, jj) );

            if ~isempty(ParamValues_in)
                Names = options.paramNames;
                Values = ParamValues_in;
            else
                Names = ItemModel.Names;
                Values = ItemModel.Values;
            end
            
            nSim = 0;
            numlabs = p.NumWorkers;
            blockSize = max(100,ceil(ItemModel.nPatients / numlabs));

            for labindex = 1:numlabs
                block = blockSize*(labindex-1) + (1:blockSize);
                block = block(block<=ItemModel.nPatients);
                if isempty(block)
                    break
                end
%                 F(labindex) = parfeval(p, @parBlock, 2, block, Names, Values, taskObj, Results);
                F(labindex) = parfeval(p, @parBlock, 3, block, Names, Values, taskObj, Results);
                
%                 Results = parBlock(block, Names, Values, taskObj, Results);
            end
            wait(F);
            try         
%                 [Results, taskObj] = fetchOutputs(F);
                [Results, StatusOK, Message] = fetchOutputs(F);
                
            catch err
                warning(err.message)
            end
        end
            
    end % if
    
    function updateWaitBar(WaitBar, ItemModel, jj)
        nSim = nSim + 1;
        % update wait bar
        StatusOK = true;
%         fprintf('jj = %d\n', jj)
        if ~isempty(WaitBar)
            StatusOK = uix.utility.CustomWaitbar(nSim/ItemModel.nPatients, WaitBar, sprintf('Simulating vpatient %d/%d', nSim, ItemModel.nPatients));
            if ~StatusOK
                cancel(F)
                delete(listener)
            end
        end

    end

    function [Results, StatusOK, Message] = parBlock(block, Names, Values, taskObj, Results)   
        
    
        nSim = 0;
        Message = '';
        StatusOK = true;
        
%                 disp(block)
        for jj = block
%             disp([' ', num2str(jj),' '])
            % check for user-input parameter values
            
            try 
                if isempty(Values)
                    theseValues = [];
                else
                    theseValues = Values(jj,:);
                end
                                    
                [simData,simOK,errMessage]  = taskObj.simulate(...
                        'Names', Names, ...
                        'Values', theseValues, ...
                        'OutputTimes', Results.Time);
                
                nSim = nSim + 1;                         
                if ~simOK

%                     ME = MException('simulationRunHelper:simulateVPatients', 'Simulation failed with error: %s', errMessage );
%                     throw(ME)
                    StatusOK = false;
                    Message = sprintf('%s\n%s', Message, errMessage);
                    warning('Simulation %d failed with error: %s\n', jj, errMessage);
                    activeSpec_j = NaN(size(Results.Time,1), length(taskObj.ActiveSpeciesNames));
                else
                    % extract active species data, if specified
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                    else
                        [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                    end

                end

            % Add results of the simulation to Results.Data
            Results.Data = [Results.Data,activeSpec_j];
            catch err% simulation
                % If the simulation fails, store NaNs
                warning(err.identifier, 'simulationRunHelper: %s', err.message)
%                 pad Results.Data with appropriate number of NaNs
                if ~isempty(taskObj.ActiveSpeciesNames)
                    Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames))];
                else
                    Results.Data = [Results.Data,NaN*ones(length(Results.Time),length(taskObj.SpeciesNames))];
                end

                nFailedSims = nFailedSims + 1;

            end % try

            send(q, gop(@plus, nSim));                      
        
        end % for jj = ...
    end

    if usePar
        d = [Results.Data];
        t = Results(1).Time;
        s = Results(1).SpeciesNames;
                
        r.Data = d;
        r.Time = t;
        r.SpeciesNames = s;
        Results = r;
               
        nFailedSims = sum([nFailedSims]);
    end
%     Message = vertcat(Message{:});
    Cancelled = ~isvalid(options.WaitBar);
end
