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
    
    items = obj.Item;
    numberItems = numel(items);
    
    resultFileNames = cell(numberItems, 1);
    
    allVariants   = getvariant(modelObj);
    allDoses      = getdose(modelObj);
    
    if obj.NumberSamples == 0
        statusOk = false;
        message = 'Set number of samples to a value greater than zero.';
        return
    elseif obj.NumberIterations > obj.NumberSamples
        statusOk = false;
        message = 'The number of iterations cannot be larger than the number of samples.';
        return
    end    
    numberSamples = linspace(0, obj.NumberSamples, obj.NumberIterations+1);
    numberSamples = unique(ceil(numberSamples(2:end)), 'stable');
    
    hWaitBar = uiprogressdlg(figureHandle, 'Indeterminate','on',...
        'Title', sprintf('Running %s',obj.Name));
    cleanupObj = onCleanup(@()delete(hWaitBar));

    [statusOk, message, sensitivityInputs, transformations, ...
        distributions, samplingInfo] = obj.getParameterInfo();
    if ~statusOk
        return;
    end
    
    for i = 1:numberItems
        
        hWaitBar.Message = sprintf('Task: %s', items(i).TaskName);
        
        plotItems = cell(1, numel(numberSamples));
        
        if ~items(i).Include
            continue;
        elseif items(i).NumberSamples > 0
            loadedResults = load(fullfile(obj.Settings.Session.RootDirectory, ...
                obj.ResultsFolderName, obj.Item(i).MATFileName));
            results = loadedResults.results.addsamples(numberSamples(1));
            clear loadedResults
        else
            
            task = obj.getObjectsByName(obj.Settings.Task, items(i).TaskName);
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
            
            results = QSP.internal.gsa.TransformedSobol(modelObj, ...
                sensitivityInputs, sensitivityOutputs, transformations, ...
                distributions, samplingInfo, 'NumberSamples', numberSamples(1), options);
            
        end
        
        if isempty(items(i).Results)
            existingNumberSamples = 0;
        else
            existingNumberSamples = items(i).Results(end).NumberSamples; 
        end
        
        plotItems{1} = struct('Time', results.Time, ...
                              'SobolIndices', results.SobolIndices, ...
                              'Variances', results.Variance, ...
                              'NumberSamples', existingNumberSamples+numberSamples(1));  

        for iteration = 2:numel(numberSamples)
            results = addsamples(results, numberSamples(iteration));
            plotItems{iteration} = struct('Time', results.Time, ...
                                          'SobolIndices', results.SobolIndices, ...
                                          'Variances', results.Variance, ...
                                          'NumberSamples', existingNumberSamples+numberSamples(iteration));

        end
        
        resultFileNames{i} = ['Results - GSA = ' obj.Name, ...
                              ' - Task = ', items(i).TaskName, ...
                              ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS') '.mat'];

        save(fullfile(obj.Settings.Session.RootDirectory, ...
            obj.ResultsFolderName, resultFileNames{i}), 'results');
        
        obj.Item(i).NumberSamples = ...
            items(i).NumberSamples + numberSamples(end);
        
        obj.addResults(i, [plotItems{:}]);

    end
    
    obj.NumberSamples = 0;
    
end


