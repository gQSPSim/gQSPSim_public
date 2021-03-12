classdef tGlobalSensitivityAnalysis < GlobalSensitivityAnalysisTester
% Tests for backend functionality for global sensitivity analysis

properties
    ExpectedGSAItemTemplate = struct("TaskName", '', ...
                                     "NumberSamples", 0, ...
                                     "IterationInfo", [200, 5], ...
                                     "Include", true, ...
                                     "MATFileName", [], ...
                                     "Description", [], ...
                                     "Results", []);
end

methods(Test)
    function tProperties(testCase)
        % Basic property tests for default constructed
        % GlobalSensitivityAnalysis object.
        
        gsaObj = QSP.GlobalSensitivityAnalysis();
        
        testCase.verifyEmpty(gsaObj.PlotSobolIndex);
        testCase.verifyFalse(gsaObj.HideConvergenceLine);
        testCase.verifyEmpty(gsaObj.RandomSeed);
        testCase.verifyEqual(gsaObj.StoppingTolerance, 0);
        
        testCase.verifyClass(gsaObj.PlotInputs, 'cell');
        testCase.verifyEmpty(gsaObj.PlotInputs);
        testCase.verifyClass(gsaObj.PlotOutputs, 'cell');
        testCase.verifyEmpty(gsaObj.PlotOutputs);
        testCase.verifyClass(gsaObj.Plot2TableMap, 'cell');
        testCase.verifyEmpty(gsaObj.Plot2TableMap);
        
    end
    
    function tAddRemoveGSAItem(testCase)
        % Test for add method for adding GSA items.

        % Get GlobalSensitivityAnalysis object
        gsa = testCase.getGSAObject();
        
        % Add new GSA items
        gsa.add('gsaItem');
        testCase.verifyNumElements(gsa.Item, 1);
        expectedItem = testCase.ExpectedGSAItemTemplate;
        expectedItem.TaskName = 'TestTask1';
        testCase.verifyGSAItemFields(gsa, 1, expectedItem);
        % Verify that plot information for sensitivity inputs/outputs has
        % been updated.
        testCase.verifyEqual(gsa.PlotInputs, {'y1'; 'y2'});
        testCase.verifyEqual(gsa.PlotOutputs, {'y1'; 'y2'});
        % Verify no plot items have been added
        testCase.verifyEmpty(gsa.PlotSobolIndex);
        testCase.verifyEmpty(gsa.Plot2TableMap);
        
        % Add a second GSA item
        gsa.add('gsaItem');
        testCase.verifyNumElements(gsa.Item, 2);
        expectedItem.TaskName = 'TestTask1';
        testCase.verifyGSAItemFields(gsa, 1, expectedItem);
        expectedItem.TaskName = 'TestTask2';
        testCase.verifyGSAItemFields(gsa, 2, expectedItem);
        % Verify that plot information for sensitivity inputs/outputs has
        % been updated.
        testCase.verifyEqual(gsa.PlotInputs, {'y1'; 'y2'});
        testCase.verifyEqual(gsa.PlotOutputs, {'y1'; 'y2'; 'x'; 'z'});
        % Verify no plot items have been added
        testCase.verifyEmpty(gsa.PlotSobolIndex);
        testCase.verifyEmpty(gsa.Plot2TableMap);

        % Remove first GSA item
        gsa.remove('gsaItem', 1);
        testCase.verifyNumElements(gsa.Item, 1);
        expectedItem = testCase.ExpectedGSAItemTemplate;
        expectedItem.TaskName = 'TestTask2';
        testCase.verifyGSAItemFields(gsa, 1, expectedItem);
        % Verify that plot information for sensitivity inputs/outputs has
        % been updated.
        testCase.verifyEqual(gsa.PlotInputs, {'y1'; 'y2'});
        testCase.verifyEqual(gsa.PlotOutputs, {'x'; 'y1'; 'y2'; 'z'});
        % Verify no plot items have been added
        testCase.verifyEmpty(gsa.PlotSobolIndex);
        testCase.verifyEmpty(gsa.Plot2TableMap);
        
        % Remove last GSA item
        gsa.remove('gsaItem', 1);
        testCase.verifyEmpty(gsa.Item);
        % Verify that plot information for sensitivity inputs/outputs has
        % been updated.
        testCase.verifyEqual(gsa.PlotInputs, cell(0,1));
        testCase.verifyEqual(gsa.PlotOutputs, cell(0,1));
        % Verify no plot items have been added
        testCase.verifyEmpty(gsa.PlotSobolIndex);
        testCase.verifyEmpty(gsa.Plot2TableMap);
        
    end
end

methods
    
    function verifyGSAItemFields(testCase, gsaObject, idx, expectedValues)
        fieldNames = fields(expectedValues);
        for i = 1:numel(fieldNames)
            testCase.assertTrue(isfield(gsaObject.Item(idx), fieldNames{i}), ...
                "The GSA item is missing the expected field " + fieldNames{i});
            testCase.verifyEqual(gsaObject.Item(idx).(fieldNames{i}), ...
                expectedValues.(fieldNames{i}), "Unexpected value of field " + ...
                fieldNames{i} + " in GSA item number " + idx);
        end
    end
    
end

end