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

        numSamplesPerIteration = obj.Item(i).IterationInfo(1);  
        numIterations = obj.Item(i).IterationInfo(2);  
        results = [];
        
        if numSamplesPerIteration == 0 || numIterations == 0
            % Nothing to do
            obj.Item(i).IterationInfo(2) = 0; % reset number of iterations to 0.
            break;
        elseif obj.Item(i).NumberSamples > 0
            % Results already exists; initialize progress status with existing
            % results:
            tfStoppingToleranceMet = updateProgressStatus(obj, progressCallback, i, ...
                numIterations, numSamplesPerIteration);
            if tfStoppingToleranceMet
                % Nothing to do: existing results already satisfy the
                % stopping condition.
                obj.Item(i).IterationInfo(2) = 0;
                break;
            end
        else
            % Display progress message for first iteration in progress
            % window.
            messages = repmat({''}, 7,1);
            messages{1} = sprintf('Task: %s', obj.Item(i).TaskName);
            messages{3} = 'Please wait. Computing first iteration.';
            progressCallback(false, i, messages, [], []);
        end
        
        for loopOverIterations = 1:numIterations

            if obj.Item(i).IterationInfo(2) > 0
                
                if ~isempty(results)
                    results = addsamples(results, numSamplesPerIteration);
                    plotItems = struct('Time', results.Time, ...
                           'SobolIndices', results.SobolIndices, ...
                           'Variances', results.Variance, ...
                           'NumberSamples', obj.Item(i).NumberSamples+numSamplesPerIteration);  
                elseif obj.Item(i).NumberSamples > 0
                    loadedResults = load(fullfile(obj.Settings.Session.RootDirectory, ...
                        obj.ResultsFolder, obj.Item(i).MATFileName));
                    results = loadedResults.results.addsamples(numSamplesPerIteration);
                    clear loadedResults
                    plotItems = struct('Time', results.Time, ...
                           'SobolIndices', results.SobolIndices, ...
                           'Variances', results.Variance, ...
                           'NumberSamples', obj.Item(i).NumberSamples+numSamplesPerIteration);
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
                                'SamplingOptions', struct('UseLhsdesign', true), 'Number', numSamplesPerIteration);
                        end
                        results = sbiosobol(modelObj, scenarios, sensitivityOutputs, options);
                    else
                        % Use custom object to compute Sobol indices in 
                        % Matlab releases prior to R2021b.
                        results = QSP.internal.gsa.TransformedSobol(modelObj, ...
                            sensitivityInputs, sensitivityOutputs, transformations, ...
                            distributionNames, samplingInfo, 'NumberSamples', numSamplesPerIteration, options);
                    end

                    plotItems = struct('Time', results.Time, ...
                                       'SobolIndices', results.SobolIndices, ...
                                       'Variances', results.Variance, ...
                                       'NumberSamples', numSamplesPerIteration);  

                end

                obj.addResults(i, plotItems);        
                obj.Item(i).IterationInfo(2) = obj.Item(i).IterationInfo(2) - 1;
                
                % Call callback for progress indication
                tfStoppingToleranceMet = updateProgressStatus(obj, progressCallback, i, ...
                numIterations, numSamplesPerIteration);
                if tfStoppingToleranceMet
                    obj.Item(i).IterationInfo(2) = 0;
                    break;
                end
                
            end
            
            if  obj.Item(i).IterationInfo(2) == 0 
                if ~isempty(results)
                    resultFileName = ['Results - GSA = ' obj.Name, ...
                                      ' - Task = ', obj.Item(i).TaskName, ...
                                      ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];
    
                    save(fullfile(obj.Settings.Session.RootDirectory, ...
                        obj.ResultsFolder, resultFileName), 'results');
                    
                    % Update MATFileName in the GSA items
                    obj.Item(i).MATFileName = resultFileName;
                end
                break;
            end


        end
    end        
end


function tfStoppingToleranceMet = updateProgressStatus(obj, progressCallback, i, numIterations, numSamplesPerIteration)
    
    [samples, differences] = obj.getConvergenceStats(i);

    messages = cell(7, 1);    
    messages{1} = sprintf('Task: %s', obj.Item(i).TaskName);
    messages{2} = '';
    currentIteration = numIterations-obj.Item(i).IterationInfo(2);
    messages{3} = sprintf('Computed Sobol indices for iteration %d of %d', currentIteration, numIterations);
    messages{4} = sprintf('Added %d new sampes', numSamplesPerIteration*currentIteration);
    messages{5} = '';
    if isempty(differences) || isnan(differences(end))
        messages{6} = 'Computing max. diff. between Sobol indices';
        tfStoppingToleranceMet = false;
    else
        messages{6} = sprintf('Max. difference in iteration %d: %g', numIterations-obj.Item(i).IterationInfo(2), differences(end));
        tfStoppingToleranceMet = differences(end) <= obj.StoppingTolerance;
    end
    if tfStoppingToleranceMet
        messages{3} = sprintf('Stopping criterion met in iteration %d of %d', numIterations-obj.Item(i).IterationInfo(2), numIterations);
        messages{4} = '';        
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


