classdef TransformedSobol < QSP.internal.gsa.SamplingInformation & SimBiology.gsa.Sobol

    methods
        function obj = TransformedSobol(modelObj, parameters, observables, scalings, distributions, samplingInfo, varargin)
            obj = obj@QSP.internal.gsa.SamplingInformation(scalings, distributions, samplingInfo);
            obj = obj@SimBiology.gsa.Sobol(modelObj, parameters, observables, varargin{:}); 
        end
    end
    methods(Access=protected)
        %------------------------------------------------------------------
        function samples = sampleParameters(obj, ~, numSamples, ~, ~)
                
            distributions = obj.gQSPSimProperties.Distributions;
            numDistributions = numel(distributions);
            samples = nan(numSamples, 2*numDistributions);

            for i = 1:numDistributions                
                % Get random values from uniform distribution on [0,1]
                currentSamples = lhsdesign(numSamples, 2);
                % Compute random sample by inverting the cdf
                samples(:, i) = icdf(distributions(i), currentSamples(:, 1));
                samples(:, i+numDistributions) = icdf(distributions(i), currentSamples(:, 2));
                if obj.gQSPSimProperties.Scaling(i)
                    samples(:, [i,i+numDistributions]) = ...
                        exp(samples(:, [i,i+numDistributions]));
                end
            end

        end
    end
end