function [statusOk, message, resultFileNames] = runHelper(obj, figureHandle, ax)
% Helper method to perform global sensitivity analysis.
%
%  Input:
%   obj             : QSP.GlobalSensitivityAnalysis object
%   figureHandle    : uiFigure for progress indicator overlay
%   ax              : first figure axes for plotting GSA results
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
    
    resultFileNames = cell(numberItems, 1);
    resultsCell     = cell(numberItems, 1);
    maxDiff         = inf(numberItems, 1);
    
    allVariants   = getvariant(modelObj);
    allDoses      = getdose(modelObj);
    
    iterationsInfo = vertcat(obj.Item.IterationInfo);
    if all(iterationsInfo(:,1).*iterationsInfo(:,2) == 0)
        statusOk = false;
        message = 'Set number of samples and iteration to be added to a value greater than zero for at least one task.';
        return
    end    
    
    hWaitBar = uiprogressdlg(figureHandle, 'Indeterminate','on',...
        'Title', sprintf('Running %s',obj.Name));
    cleanupObj = onCleanup(@()delete(hWaitBar));

    [statusOk, message, sensitivityInputs, transformations, ...
        distributions, samplingInfo] = obj.getParameterInfo();
    if ~statusOk
        return;
    end
    
    for looopOverIterations = 1:max(iterationsInfo(:,2))
    
        for i = 1:numberItems

            if any(obj.Item(i).IterationInfo == 0)
                obj.Item(i).IterationInfo(2) = 0;
                continue;
            end
            
            numberOfSamplesPerIteration = obj.Item(i).IterationInfo(1);

            hWaitBar.Message = sprintf(['Task: %s\n\n', ...
                                        'Iteration: %d of %d\nAdding %d new samples.'], ...
                obj.Item(i).TaskName, ...
                iterationsInfo(i,2)-obj.Item(i).IterationInfo(2)+1, ...
                iterationsInfo(i,2), numberOfSamplesPerIteration);
            if obj.StoppingTolerance > 0
                if numel(obj.Item(i).Results) > 1
                    difference = reshape(abs([([obj.Item(i).Results(end).SobolIndices(:).FirstOrder] - ...
                        [obj.Item(i).Results(end-1).SobolIndices(:).FirstOrder]); ...
                        ([obj.Item(i).Results(end).SobolIndices(:).TotalOrder] - ...
                        [obj.Item(i).Results(end-1).SobolIndices(:).TotalOrder])]), [], 1);
                    difference(isnan(difference)) = [];
                    if isempty(difference)
                        obj.Item(i).IterationInfo(2) = 0;
                    else
                        maxDiff = max(difference);
                        if maxDiff < obj.StoppingTolerance
                            obj.Item(i).IterationInfo(2) = 0;
                        end
                    end
                    hWaitBar.Message = sprintf('%s\n\nMax. difference in previous iteration: %g\nTarget difference: %g', hWaitBar.Message, ...
                        maxDiff, obj.StoppingTolerance);
                else
                    hWaitBar.Message = sprintf('%s\n\nComputing max. difference for previous iteration.\nTarget difference: %g', hWaitBar.Message, ...
                        obj.StoppingTolerance);
                end
            end

            if obj.Item(i).IterationInfo(2) > 0
                
                if ~isempty(resultsCell{i})
                    resultsCell{i} = addsamples(resultsCell{i}, numberOfSamplesPerIteration);
                    plotItems = struct('Time', resultsCell{i}.Time, ...
                           'SobolIndices', resultsCell{i}.SobolIndices, ...
                           'Variances', resultsCell{i}.Variance, ...
                           'NumberSamples', obj.Item(i).NumberSamples+numberOfSamplesPerIteration);  
                elseif obj.Item(i).NumberSamples > 0
                    loadedResults = load(fullfile(obj.Settings.Session.RootDirectory, ...
                        obj.ResultsFolder, obj.Item(i).MATFileName));
                    resultsCell{i} = loadedResults.results.addsamples(numberOfSamplesPerIteration);
                    clear loadedResults
                    plotItems = struct('Time', resultsCell{i}.Time, ...
                           'SobolIndices', resultsCell{i}.SobolIndices, ...
                           'Variances', resultsCell{i}.Variance, ...
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

                    resultsCell{i} = QSP.internal.gsa.TransformedSobol(modelObj, ...
                        sensitivityInputs, sensitivityOutputs, transformations, ...
                        distributions, samplingInfo, 'NumberSamples', numberOfSamplesPerIteration, options);

                    plotItems = struct('Time', resultsCell{i}.Time, ...
                                       'SobolIndices', resultsCell{i}.SobolIndices, ...
                                       'Variances', resultsCell{i}.Variance, ...
                                       'NumberSamples', numberOfSamplesPerIteration);  

                end

                obj.addResults(i, plotItems);        
                obj.Item(i).IterationInfo(2) = obj.Item(i).IterationInfo(2) - 1;
                
            end
            
            if  obj.Item(i).IterationInfo(2) == 0
                resultFileNames{i} = ['Results - GSA = ' obj.Name, ...
                                      ' - Task = ', obj.Item(i).TaskName, ...
                                      ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];

                results = resultsCell{i};
                save(fullfile(obj.Settings.Session.RootDirectory, ...
                    obj.ResultsFolder, resultFileNames{i}), 'results');
                clear results 
                resultsCell{i} = [];
            end


        end
    end        
end


