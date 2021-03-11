classdef TransformedSobol < QSP.internal.gsa.SamplingInformation & SimBiology.gsa.Sobol

    methods
        function obj = TransformedSobol(modelObj, parameters, observables, scalings, distributions, samplingInfo, varargin)
            obj = obj@QSP.internal.gsa.SamplingInformation(scalings, distributions, samplingInfo);
            obj = obj@SimBiology.gsa.Sobol(modelObj, parameters, observables, varargin{:}); 
        end
    end
    methods(Access=protected)
        %------------------------------------------------------------------
        function samples = sampleParameters(obj, m, numSamples, bounds, method)
            if isempty(obj.gQSPSimProperties.Scenarios)
                samples = sampleParameters@SimBiology.gsa.Sobol(obj, m, numSamples, bounds, method);
            else
                
                distributions = obj.gQSPSimProperties.Distributions;
                numDistributions = numel(distributions);
                samples = nan(numSamples, numDistributions);
                
                % Get random values from uniform distribution on [0,1]
                for i = 1:numDistributions                
                    currentSamples = lhsdesign(numDistributions, 2);
                    currentSamples = bounds(i,1) + currentSamples * diff(bounds(i,:));
                    if obj.gQSPSimProperties.Scaling(i)
                        currentSamples = exp(currentSamples);
                    end
                    % Compute random sample by inverting the cdf
                    samples(:, i) = icdf(distributions(i), currentSamples(:, 1));
                    samples(:, i+numDistributions) = icdf(distributions(i), currentSamples(:, 2));
                end

            end
        end
    end
end