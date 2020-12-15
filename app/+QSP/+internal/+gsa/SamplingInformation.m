classdef SamplingInformation 
    properties
        % Scope properties to avoid namespace collision with 
        % SimBiology.gsa.Sobol or SimBiology.gsa.GSA.
        gQSPSimProperties 
    end 
    methods
        function obj = SamplingInformation(scaling, distributions, samplingInfo)
            % Initialize properties to support non-uniform sampling in gQSPSim.
            obj.gQSPSimProperties = struct('Scaling', false(1, numel(distributions)), ...
                'SamplingInfo', samplingInfo, 'Scenarios', []);
            uniqueDistributions = unique(distributions);
            % Use standard sampling by sbiosobol (indicated by empty
            % obj.gQSPSimProperties.Scenarios) if all distributions are
            % uniform ...
            if numel(uniqueDistributions) > 1 || strcmp(uniqueDistributions, 'normal')
                % ... in all other cases (log-uniform, normal and log-normal
                % distributions), use SimBiology.Scenarios for sampling.
                % The input samplingInfo is a numeric matrix with two
                % columns. For (log-)uniform distributions, each row
                % contains the lower and upper bounds. For (log-)normal
                % distributions, each row contains mu and sigma.
                % Use the Sobol sampling method for uniform distributions
                % and lhs for all other distributions.
                obj.gQSPSimProperties.Scenarios = SimBiology.Scenarios();
                for i = 1:numel(distributions)
                    if strcmp(distributions{i}, 'uniform') 
                        pd = makedist('uniform');
                        if strcmp(scaling{i}, 'log')
                            obj.gQSPSimProperties.Scaling(i) = true;
                            samplingInfo(i, :) = log(samplingInfo(i, :));
                            samplingMethod = 'lhs';
                        else
                            samplingMethod = 'Sobol';
                        end
                        if bounds(i, 1) < pd.upper
                            pd.lower = samplingInfo(i, 1);
                            pd.upper = samplingInfo(i, 2);
                        else
                            pd.upper = samplingInfo(i, 2);
                            pd.lower = samplingInfo(i, 1);
                        end                        
                    elseif strcmp(distributions{i}, 'normal')
                        if strcmp(scaling{i}, 'linear')
                            pd = makedist('normal');
                        else
                            pd = makedist('lognormal');
                        end
                        pd.mu = samplingInfo(i, 1);
                        pd.sigma = samplingInfo(i, 2);
                        samplingMethod = 'lhs';
                    else
                        assert(false, "Internal error: unknown probability distribution");
                    end
                    % We need two sets of samples; duplicate each entry
                    % into two subentries that whose samples are drawn 
                    % jointly but independently.
                    obj.gQSPSimProperties.Scenarios = obj.gQSPSimProperties.Scenarios.add(...
                        {num2str(i), num2str(-i)}, [pd, pd], 'SamplingMethod', samplingMethod);
                end
            end
        end
    end
end