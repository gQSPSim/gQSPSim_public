
function [Results, nFailedSims, StatusOK, Message, Cancelled] = simulateVPatients(ItemModel, options, batchMode)  
    Cancelled = false;
    nFailedSims = 0;
    taskObj = ItemModel.Task;
    Message = '';
    
    % clear the results of the previous simulation
    Results = [];
    StatusOK = true;
    
    ParamValues_in = options.Pin;
    
    usePar = options.usePar;
    
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
    NS = length(taskObj.ActiveSpeciesNames);
    Results.Data = NaN( size(Results.Time,1), NS * ItemModel.nPatients );

    % species names
    Results.SpeciesNames = [];
    if ~isempty(taskObj.ActiveSpeciesNames)
        Results.SpeciesNames = taskObj.ActiveSpeciesNames;
    else
        Results.SpeciesNames = taskObj.SpeciesNames;
    end    
    
    nComplete = 0;
    function updateWaitBar(data)
        nComplete = nComplete+1;
        if options.ShowProgressBars && ~isempty(options.WaitBar)
            StatusOK = uix.utility.CustomWaitbar(nComplete/ItemModel.nPatients, options.WaitBar, sprintf('Simulating vpatient %d/%d', nComplete, ItemModel.nPatients));
            if ~StatusOK
                cancel(F);
            end                    
        end                            
    end
        
    if isfield(ItemModel,'nPatients')

        % check for user-input parameter values
        if ~isempty(ParamValues_in)
            Names = options.paramNames;
            Values = ParamValues_in;
        else
            Names = ItemModel.Names;
            Values = ItemModel.Values;
        end                        
        
        if ~usePar
            for jj = 1:ItemModel.nPatients
                if isempty(Values)
                    theseValues = [];
                else
                    theseValues = Values(jj,:);
                end                
                [thisResult, thisStatus, errMessage] = simulateOne(taskObj,Names,theseValues,Results.Time,options);
                nFailedSims = nFailedSims + (thisStatus==false);
                if ~thisStatus
                    warning('Simulation %d failed with error: %s\n', jj, errMessage);
                else
                    Results.Data(:, NS*(jj-1) + (1:NS)) = thisResult;
                end

                if options.ShowProgressBars && ~isempty(options.WaitBar)
                    StatusOK = uix.utility.CustomWaitbar(jj/ItemModel.nPatients, options.WaitBar, sprintf('Simulating vpatient %d/%d', jj, ItemModel.nPatients));
                end
                if ~StatusOK
                    break
                end
            end % for jj = ...
        elseif ~batchMode
            p = gcp('nocreate');
            if isempty(p) 
                try 
                    p = parpool(options.ParallelCluster, ...
                        'AttachedFiles', options.UDF);
                catch ME
                    Message = sprintf('Parallel pool could not be started! Try starting manually.\n%s', ME.message);
                    StatusOK = false;
                    return
                end
            end
            
            
            q = parallel.pool.DataQueue;

            afterEach(q, @updateWaitBar);
            
            F = parfeval(p, @parBlock, 2, taskObj, Names, Values, Results.Time, size(Results.Data), NS, options, q);           
            wait(F)
            try
                [Results.Data, nFailedSims] = fetchOutputs(F);
            catch err
                Message = err.message;
                Cancelled = options.ShowProgressBars && ~isvalid(options.WaitBar);                
                StatusOK = false;
                return
            end
                
        else % cluster
            [Results.Data, nFailedSims] = parBlock(taskObj, Names, Values,  Results.Time, size(Results.Data), NS, options, [] );
            
        end
            
    end % if
   
    Cancelled = options.ShowProgressBars && ~isvalid(options.WaitBar);
end


