function [Results, simOK, errMessage] = simulateOne(taskObj,Names,theseValues,times,options)
    try 
        Results = [];
        simOK = true;
        errMessage = '';
        
        [simData,simOK,errMessage]  = taskObj.simulate(...
                'Names', Names, ...
                'Values', theseValues, ...
                'OutputTimes', times, ...
                'Waitbar', options.WaitBar);    
        if simOK
            % extract active species data, if specified
            if ~isempty(taskObj.ActiveSpeciesNames)
                [~,Results] = selectbyname(simData,taskObj.ActiveSpeciesNames);
            else
                [~,Results] = selectbyname(simData,taskObj.SpeciesNames);
            end

        end
        
    catch err% simulation
        % If the simulation fails, store NaNs
        warning(err.identifier, 'simulationRunHelper: %s', err.message)
        simOK = false;
        errMessage = err.message;
    end % try 
end