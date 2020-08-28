function [Results, nFailedSims] = parBlock(taskObj, Names, Values, times, DataSize, NS, options, q )   

if ~isempty(Values)
    N = size(Values,1);
else
    N = 1; % model default
end    

parResults = cell(1,N);
nFailedSims = zeros(1,N);
NT = DataSize(1);

parfor jj = 1:N
    if isempty(Values)
        theseValues = [];
    else
        theseValues = Values(jj,:);
    end     

    [parResults{jj}, thisStatus, errMessage] = simulateOne(taskObj, Names, theseValues,times,options);

    nFailedSims = nFailedSims + (thisStatus==false);
    if ~thisStatus
        warning('Simulation %d failed with error: %s\n', jj, errMessage);
        parResults{jj} = nan(NT, NS);
    end
    
    if ~isempty(q)
        send(q, true)
    end
end 

Results = horzcat(parResults{:});

end