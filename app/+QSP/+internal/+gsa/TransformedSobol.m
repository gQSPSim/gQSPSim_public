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
                numEntries = obj.gQSPSimProperties.Scenarios.NumberOfEntries;
                for i = 1:numEntries
                    scenarios = obj.gQSPSimProperties.Scenarios.updateEntry(i, 'NumberSamples', numSamples);
                end
                samples = scenarios.generate();
                samples = [samples{:,1:2:m}; samples{:,2:2:m}];
                for i = 1:numEntries
                    if obj.gQSPSimProperties.Scaling(i)
                        samples(:,i) = exp(samples(:,i));
                    end
                end
            end
        end
    end
end