function [statusOk, message] = runHelper(obj, progressCallback)
% Helper method to perform global sensitivity analysis.
%
%  Input:
%   obj             : QSP.GlobalSensitivityAnalysis object
%   progressCallback: callback function for progress updates
%
%  Output:
%   statusOk        : logical scalar indicating success of analysis
%   message         : character vector containing a description of the 
%                     global sensitivity analysis computation
%   resultFileNames : character vector of the mat file containing the
%                     global sensitivity analysis results

% Copyright 2020 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks
%   $Author: faugusti $
%   $Revision: 1 $  $Date: Sat, 07 Nov 2020 $
% ---------------------------------------------------------------------

    modelObj = obj.Settings.Model.mObj;
    
    numberItems = numel(obj.Item);
    
    allVariants   = getvariant(modelObj);
    allDoses      = getdose(modelObj);

    [statusOk, message, sensitivityInputs, transformations, ...
        distributionNames, samplingInfo] = obj.getParameterInfo();
    if ~statusOk
        return;
    end
    
    tfVerAtLeastR2021b = ~verLessThan('matlab','9.11');
    
    for i = 1:numberItems

        % Call callback to reset progress indication for next item.
        progressCallback(true, i, [], [], []);

        iterationInfo = obj.Item(i).IterationInfo;
        numberOfSamplesPerIteration = iterationInfo(1);
        results = [];
        
        for loopOverIterations = 1:iterationInfo(2)

            if any(obj.Item(i).IterationInfo == 0)
                obj.Item(i).IterationInfo(2) = 0;
                break;
            end
            
            % Call callback for progress indication
            tfStoppingToleranceMet = updateProgressStatus(obj, progressCallback, i, ...
                iterationInfo, numberOfSamplesPerIteration);
            if tfStoppingToleranceMet
                obj.Item(i).IterationInfo(2) = 0;
            end

            if obj.Item(i).IterationInfo(2) > 0
                
                if ~isempty(results)
                    results = addsamples(results, numberOfSamplesPerIteration);
                    plotItems = struct('Time', results.Time, ...
                           'SobolIndices', results.SobolIndices, ...
                           'Variances', results.Variance, ...
                           'NumberSamples', obj.Item(i).NumberSamples+numberOfSamplesPerIteration);  
                elseif obj.Item(i).NumberSamples > 0
                    loadedResults = load(fullfile(obj.Settings.Session.RootDirectory, ...
                        obj.ResultsFolder, obj.Item(i).MATFileName));
                    results = loadedResults.results.addsamples(numberOfSamplesPerIteration);
                    clear loadedResults
                    plotItems = struct('Time', results.Time, ...
                           'SobolIndices', results.SobolIndices, ...
                           'Variances', results.Variance, ...
                           'NumberSamples', obj.Item(i).NumberSamples+numberOfSamplesPerIteration);
                else
                    task = obj.getObjectsByName(obj.Settings.Task, obj.Item(i).TaskName);
                    sensitivityOutputs = task.ActiveSpeciesNames;
                    doseObjs = obj.getObjectsByName(allDoses, task.ActiveDoseNames);
                    variantObjs = obj.getObjectsByName(allVariants, task.ActiveVariantNames);

                    options = struct( ...
                        'OutputTimes'   , eval(task.OutputTimesStr), ...
                        'UseParallel'   , obj.Settings.Session.UseParallel, ...
                        'ShowWaitbar'   , false);
                    if ~isempty(doseObjs)
                        options.Doses = doseObjs;
                    end
                    if ~isempty(variantObjs)
                        options.Variants = variantObjs;
                    end

                    if tfVerAtLeastR2021b
                        % Use sbiosobol starting with Matlab release R2021b.
                        scenarios = SimBiology.Scenarios();
                        for j = 1:numel(distributionNames)
                            probDistribution = QSP.internal.gsa.SamplingInformation.getSamplingInfo(distributionNames{j}, transformations{j}, samplingInfo(j,:));
                            scenarios = scenarios.add('elementwise', sensitivityInputs{j}, probDistribution, 'SamplingMethod', 'lhs', ...
                                'SamplingOptions', struct('UseLhsdesign', true), 'Number', numberOfSamplesPerIteration);
                        end
                        results = sbiosobol(modelObj, scenarios, sensitivityOutputs, options);
                    else
                        % Use custom object to compute Sobol indices in 
                        % Matlab releases prior to R2021b.
                        results = QSP.internal.gsa.TransformedSobol(modelObj, ...
                            sensitivityInputs, sensitivityOutputs, transformations, ...
                            distributionNames, samplingInfo, 'NumberSamples', numberOfSamplesPerIteration, options);
                    end

                    plotItems = struct('Time', results.Time, ...
                                       'SobolIndices', results.SobolIndices, ...
                                       'Variances', results.Variance, ...
                                       'NumberSamples', numberOfSamplesPerIteration);  

                end

                obj.addResults(i, plotItems);        
                obj.Item(i).IterationInfo(2) = obj.Item(i).IterationInfo(2) - 1;
                
            end
            
            if  obj.Item(i).IterationInfo(2) == 0 && ~isempty(results)
                resultFileName = ['Results - GSA = ' obj.Name, ...
                                  ' - Task = ', obj.Item(i).TaskName, ...
                                  ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];

                save(fullfile(obj.Settings.Session.RootDirectory, ...
                    obj.ResultsFolder, resultFileName), 'results');
                
                % Update MATFileName in the GSA items
                obj.Item(i).MATFileName = resultFileName;
                
                break;
            end


        end
    end        
end


function tfStoppingToleranceMet = updateProgressStatus(obj, progressCallback, i, iterationInfo, numberOfSamplesPerIteration)
    
    [samples, differences] = obj.getConvergenceStats(i);

    messages = cell(7, 1);    
    messages{1} = sprintf('Task: %s', obj.Item(i).TaskName);
    messages{2} = '';
    messages{3} = sprintf('Computing Sobol indices for iteration %d of %d', iterationInfo(2)-obj.Item(i).IterationInfo(2)+1, iterationInfo(2));
    messages{4} = sprintf('Adding %d new sampes', numberOfSamplesPerIteration);
    messages{5} = '';
    if isempty(differences) || isnan(differences(end))
        messages{6} = 'Computing max. diff. between Sobol indices';
        tfStoppingToleranceMet = false;
    else
        messages{6} = sprintf('Max. difference in iteration %d: %g', iterationInfo(2)-obj.Item(i).IterationInfo(2), differences(end));
        tfStoppingToleranceMet = differences(end) <= obj.StoppingTolerance;
    end
    messages{7} = sprintf('Target difference: %d', obj.StoppingTolerance);
    
    progressCallback(false, i, messages, samples, differences);
    
end


function [distributionObjs, samplingMethod] = createDistributions(distributionNames, scaling, samplingInfo)
    distributionObjs = cell(1, numel(distributionNames));
    samplingMethod   = cell(1, numel(distributionNames));
    for i = 1:numel(distributionNames)
        if strcmp(distributionNames{i}, 'uniform') 
            if strcmp(scaling{i}, 'log')
                samplingMethod{i} = 'lhs';
                distributionObjs{i} = makedist('loguniform', 'lower', samplingInfo(i, 1), 'upper', samplingInfo(i, 2));
            else
                samplingMethod{i} = 'Sobol';
                distributionObjs{i} = makedist('uniform', 'lower', samplingInfo(i, 1), 'upper', samplingInfo(i, 2));
            end
            
        elseif strcmp(distributionNames{i}, 'normal')
            if strcmp(scaling{i}, 'linear')
                distributionObjs{i} = makedist('normal', 'mu', samplingInfo(i,1), 'sigma', samplingInfo(i,2));
            else
                distributionObjs{i} = makedist('lognormal', 'mu', samplingInfo(i,1), 'sigma', samplingInfo(i,2));
            end
            samplingMethod{i} = 'lhs';
        else
            assert(false, "Internal error: unknown probability distribution");
        end
        distributionObjs = [distributionObjs{:}];
    end

end


