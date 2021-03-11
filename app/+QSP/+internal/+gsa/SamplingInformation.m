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
                                           'Distributions', []);
            % The input samplingInfo is a numeric matrix with two
            % columns. For (log-)uniform distributions, each row
            % contains the lower and upper bounds. For (log-)normal
            % distributions, each row contains mu and sigma.
            % Use lhsdesign for all distributions.
            probDistributions = cell(1, numel(distributions));
            for i = 1:numel(distributions)
                [probDistributions{i}, obj.gQSPSimProperties.Scaling(i)] = ...
                    QSP.internal.gsa.SamplingInformation.getSamplingInfo(...
                    distributions{i}, scaling{i}, samplingInfo(i,:));
            end
            obj.gQSPSimProperties.Distributions = [probDistributions{:}];
        end
    end
    methods (Static)
        function [distObj, useScaling] = getSamplingInfo(distribution, scaling, samplingInfo)
            useScaling = false;
            if strcmp(distribution, 'uniform') 
                if nargout >= 2
                    if strcmp(scaling, 'log')
                        useScaling = true;
                        samplingInfo = log(samplingInfo);
                    end
                    distObj = makedist('uniform', 'lower', samplingInfo(1), 'upper', samplingInfo(2));
                else
                    distObj = makedist('loguniform', 'lower', samplingInfo(1), 'upper', samplingInfo(2));
                end
            elseif strcmp(distribution, 'normal')
                if strcmp(scaling, 'linear')
                    distObj = makedist('normal');
                else
                    distObj = makedist('lognormal');
                end
                distObj.mu = samplingInfo(1);
                distObj.sigma = samplingInfo(2);
            else
                assert(false, "Internal error: unknown probability distribution");
            end
        end
    end
end