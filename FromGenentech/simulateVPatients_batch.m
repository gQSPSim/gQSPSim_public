function [Results, StatusOK, Message, nFailedSims] = simulateVPatients_batch(taskObj, ItemModel, options, Results)
    nFailedSims = 0;
    StatusOK = true;
    Message = '';
    ParallelCluster = options.ParallelCluster;
    c = parcluster(ParallelCluster);
    
    
%     
%     p = gcp('nocreate');
% %     p = gcp;
    UDF_files = dir(fullfile(options.UDF,'**','*.m'));
    UDF_files = arrayfun(@(x) fullfile(x.folder,x.name), UDF_files, 'UniformOutput', false);
%     if isempty(p)
%         p = parpool(ParallelCluster); %, 'AutoAddClientPath', true, 'AttachedFiles', UDF_files);
%         p = parpool;
%     elseif ~strcmp(p.Cluster.Profile, taskObj.Session.ParallelCluster)
%         delete(gcp('nocreate'))
%         p = parpool(taskObj.Session.ParallelCluster, ...
%          'AttachedFiles', taskObj.Session.UserDefinedFunctionsDirectory);
%     end
% 
%     addAttachedFiles(p, UDF_files);


    q = parallel.pool.DataQueue;
    progress = 0;
%     listener = afterEach(q, @() updateWaitBar(options.WaitBar, ItemModel) );
    ParamValues_in = options.Pin;

    if ~isempty(ParamValues_in)
        Names = options.paramNames;
        Values = ParamValues_in;
    else
        Names = ItemModel.Names;
        Values = ItemModel.Values;
    end

%     nSim = 0;
%     numlabs = p.NumWorkers;
%     blockSize = max(100,ceil(ItemModel.nPatients / numlabs));
%     
%     for labindex = 1:numlabs
%         block = blockSize*(labindex-1) + (1:blockSize);
%         block = block(block<=ItemModel.nPatients);
%         if isempty(block)
%             break
%         end
% %                 F(labindex) = parfeval(p, @parBlock, 2, block, Names, Values, taskObj, Results);
%         F(labindex) = parfeval(p, @parBlock, 3, block, Names, Values, taskObj, Results);
% 
% %                 Results = parBlock(block, Names, Values, taskObj, Results);
%     end
%     wait(F);
%     try         
%         [Results, StatusOK, Message] = fetchOutputs(F);
% 
%     catch err
%         warning(err.message)
%     end
%     
    block = 1:ItemModel.nPatients;
    RootPath = { fullfile(fileparts(fileparts(mfilename('fullpath'))),'app'), fullfile(fileparts(fileparts(mfilename('fullpath'))),'FromGenentech'), ...
         fullfile(fileparts(fileparts(mfilename('fullpath'))),'utilities')};

    Results = batch(c,@parBlock,1,{block, Names, Values, taskObj, Results}, 'AttachedFiles', [UDF_files, RootPath] );
    wait(Results)
    
    data = fetchOutputs(Results);
    Results = data{1};

%     nFailedSims = sum([nFailedSims]);
    


    function updateWaitBar(WaitBar, ItemModel)
%         nSim = nSim + 1;
        progress = progress + 1;
        % update wait bar
        StatusOK = true;
    %         fprintf('jj = %d\n', jj)
        if ~isempty(WaitBar)
            StatusOK = uix.utility.CustomWaitbar(progress/ItemModel.nPatients, WaitBar, sprintf('Simulating vpatient %d/%d', nSim, ItemModel.nPatients));
            if ~StatusOK
                cancel(F)
                delete(listener)
            end
        end

    end

    function [Results, StatusOK, Message] = parBlock(block, Names, Values, taskObj, Results)   


        nSim = 0;
        Message = cell(1,length(block));
        StatusOK = true(1,length(block));

    %                 disp(block)
        Time = Results.Time;
        parData = cell(1,length(block));
        
        parfor jj = block
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
                        'OutputTimes', Time);

                if ~simOK

    %                     ME = MException('simulationRunHelper:simulateVPatients', 'Simulation failed with error: %s', errMessage );
    %                     throw(ME)
                    StatusOK(jj) = false;
                    Message{jj} = errMessage;
                    warning('Simulation %d failed with error: %s\n', jj, errMessage);
                    activeSpec_j = NaN(size(Time,1), length(taskObj.ActiveSpeciesNames));
                else
                    % extract active species data, if specified
                    if ~isempty(taskObj.ActiveSpeciesNames)
                        [~,activeSpec_j] = selectbyname(simData,taskObj.ActiveSpeciesNames);
                    else
                        [~,activeSpec_j] = selectbyname(simData,taskObj.SpeciesNames);
                    end

                end

            % Add results of the simulation to Results.Data
            parData{jj} = activeSpec_j;
%             Results.Data = [Results.Data,activeSpec_j];
            catch err% simulation
                % If the simulation fails, store NaNs
                warning(err.identifier, 'simulationRunHelper: %s', err.message)
    %                 pad Results.Data with appropriate number of NaNs
                if ~isempty(taskObj.ActiveSpeciesNames)
%                     Results.Data = [Results.Data,];
                    parData{jj} = NaN*ones(length(Results.Time),length(taskObj.ActiveSpeciesNames));
                else
%                     Results.Data = [Results.Data,];
                    parData{jj} = NaN*ones(length(Results.Time),length(taskObj.SpeciesNames));
                end

                nFailedSims = nFailedSims + 1;

            end % try

%             send(q, []);                      

        end % for jj = ...
        
        Results.Data = horzcat(parData{:});
        
    end

end

