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
            % Test for add/remove method for adding/removing GSA items.

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
        
        function tChangeParameters(testCase)
            % Test if sensitivity inputs are updated when changing input
            % parameters.
            
            % Get GlobalSensitivityAnalysis object
            gsa = testCase.getGSAObject();
            % Test setup: add new GSA item (contains two parameters)
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
            
            % Change parameters: contains four parameters
            gsa.ParametersName = 'Test1';
            testCase.verifyNumElements(gsa.Item, 1);
            expectedItem = testCase.ExpectedGSAItemTemplate;
            expectedItem.TaskName = 'TestTask1';
            testCase.verifyGSAItemFields(gsa, 1, expectedItem);
            % Verify that plot information for sensitivity inputs/outputs has
            % been updated.
            testCase.verifyEqual(gsa.PlotInputs, {'y1'; 'y2'; 'x'; 'z'});
            testCase.verifyEqual(gsa.PlotOutputs, {'y1'; 'y2'});
            % Verify no plot items have been added
            testCase.verifyEmpty(gsa.PlotSobolIndex);
            testCase.verifyEmpty(gsa.Plot2TableMap);
            
        end
        
        function tUpdateGSAItem(testCase)
            % Test for update method for updating GSA items.

            % Get GlobalSensitivityAnalysis object
            gsa = testCase.getGSAObject();

            % Test setup: add new GSA item (contains two parameters)
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
            
            % Set Parameters 'Test1': contains four parameters
            gsa.ParametersName = 'Test1';
            item = gsa.Item(1);
            item.IterationInfo = [500, 2];
            gsa.updateItem(1, item);
            testCase.verifyNumElements(gsa.Item, 1);
            expectedItem = testCase.ExpectedGSAItemTemplate;
            expectedItem.TaskName = 'TestTask1';
            expectedItem.IterationInfo = [500, 2];
            testCase.verifyGSAItemFields(gsa, 1, expectedItem);
            % Verify that plot information for sensitivity inputs/outputs has
            % been updated.
            testCase.verifyEqual(gsa.PlotInputs, {'y1'; 'y2'; 'x'; 'z'});
            testCase.verifyEqual(gsa.PlotOutputs, {'y1'; 'y2'});
            % Verify no plot items have been added
            testCase.verifyEmpty(gsa.PlotSobolIndex);
            testCase.verifyEmpty(gsa.Plot2TableMap);
            
        end

        function tSensitivityInputs(testCase)
            % Test if sampling information and names for sensitivity inputs are
            % handled correctly.

            % Get GlobalSensitivityAnalysis object
            gsa = testCase.getGSAObject();

            % Set Parameters 'Test1': contains four parameters with all
            % different distributions and scales.
            gsa.ParametersName = 'Test1';
            % Get parameter information:
            %  - names of sensitivity inputs
            %  - transformations (linear/log)
            %  - distribution names (uniform/normal)
            %  - samplingInfo:
            %     - lower/upper bounds for (log-)uniform distributions
            %     - mu/sigma for (log-) normal distributions
            [statusOk, message, sensitivityInputs, transformations, ...
                distributionNames, samplingInfo] = hGSAObject.executeMethodHelper(...
                gsa, "getParameterInfo");
            testCase.verifyTrue(statusOk);
            testCase.verifyEmpty(message);
            testCase.verifyEqual(sensitivityInputs, {'y1'; 'y2'; 'x'; 'z'});
            testCase.verifyEqual(transformations, {'linear'; 'log'; 'linear'; 'log'});
            testCase.verifyEqual(distributionNames, {'uniform'; 'uniform'; 'normal'; 'normal'});
            testCase.verifyEqual(samplingInfo, [850, 900; 910, 930; 1, 0.1; 2, 0.2]);

            % Set Parameters 'Test2': uses default distriubtions, but lb/ub are
            % missing for two parameters
            gsa.ParametersName = 'Test2';
            [statusOk, message, sensitivityInputs, transformations, ...
                distributionNames, samplingInfo] = hGSAObject.executeMethodHelper(...
                gsa, "getParameterInfo");
            testCase.verifyFalse(statusOk);
            testCase.verifyEqual(message, 'All parameter values must be finite, real numeric values.');
            testCase.verifyEqual(sensitivityInputs, {'y1'; 'y2'; 'x'; 'z'});
            testCase.verifyEqual(transformations, {'linear'; 'linear'; 'linear'; 'linear'});
            testCase.verifyEqual(distributionNames, {'uniform'; 'uniform'; 'uniform'; 'uniform'});
            testCase.verifyEmpty(samplingInfo);

            % Set Parameters 'Test3': uses default distributions and scaling
            gsa.ParametersName = 'Test3';
            [statusOk, message, sensitivityInputs, transformations, ...
                distributionNames, samplingInfo] = hGSAObject.executeMethodHelper(...
                gsa, "getParameterInfo");
            testCase.verifyTrue(statusOk);
            testCase.verifyEmpty(message);
            testCase.verifyEqual(sensitivityInputs, {'y1'; 'y2'; 'x'; 'z'});
            testCase.verifyEqual(transformations, {'linear'; 'linear'; 'linear'; 'linear'});
            testCase.verifyEqual(distributionNames, {'uniform'; 'uniform'; 'uniform'; 'uniform'});
            testCase.verifyEqual(samplingInfo, [850, 900; 910, 930; 0, 1; 0, 1]);

            % Set Parameters 'Test4': lower bounds larget than upper bound
            gsa.ParametersName = 'Test4';
            [statusOk, message, sensitivityInputs, transformations, ...
                distributionNames, samplingInfo] = hGSAObject.executeMethodHelper(...
                gsa, "getParameterInfo");
            testCase.verifyFalse(statusOk);
            testCase.verifyEqual(message, 'Lower bounds of uniform distributions must be smaller than upper bounds.');
            testCase.verifyEqual(sensitivityInputs, {'y1'; 'y2'; 'x'; 'z'});
            testCase.verifyEqual(transformations, {'linear'; 'linear'; 'linear'; 'linear'});
            testCase.verifyEqual(distributionNames, {'uniform'; 'uniform'; 'uniform'; 'normal'});
            testCase.verifyEqual(samplingInfo, []);


        end

        function tRunGSA(testCase)
            % Test for running the GSA.
            % Method: QSP.GlobalSensitivityAnalysis.runHelper

            % Get GlobalSensitivityAnalysis object
            gsa = testCase.getGSAObject();

            % Add new GSA items
            gsa.add('gsaItem');
            item = gsa.Item(1);
            item.IterationInfo = [10, 3];
            gsa.updateItem(1, item);

            % Get parameter information:
            %  - names of sensitivity inputs
            %  - transformations (linear/log)
            %  - distribution names (uniform/normal)
            %  - samplingInfo:
            %     - lower/upper bounds for (log-)uniform distributions
            %     - mu/sigma for (log-) normal distributions
            [statusOk, message, sensitivityInputs, transformations, ...
                distributionNames, samplingInfo] = hGSAObject.executeMethodHelper(...
                gsa, "getParameterInfo");
            testCase.assertTrue(statusOk);
            testCase.assertEmpty(message);
            testCase.verifyEqual(sensitivityInputs, gsa.PlotInputs);
            testCase.verifyEqual(transformations, {'linear'; 'linear'});
            testCase.verifyEqual(distributionNames, {'uniform'; 'uniform'});
            testCase.verifyEqual(samplingInfo, [850, 950; 870, 930]);

            [statusOK, statusMessage] = gsa.runHelper(...
                @(tfReset, itemIdx, message, samples, data) ...
                testCase.progressCallbackMockup(1, tfReset, itemIdx, message, samples, data));
            testCase.verifyTrue(statusOK);
            testCase.verifyEmpty(statusMessage);
            testCase.verifyNotEmpty(gsa.Item(1).MATFileName);

            testCase.verifyGSAResultsFile(gsa.Item(1).MATFileName, ...
                prod(item.IterationInfo), sensitivityInputs, distributionNames, ...
                transformations, samplingInfo);

            % Remove results for first GSA item.
            gsa.removeResultsFromItem(1);
            
            % Set Parameters 'Test1': contains four parameters with all
            % different distributions and scales.
            gsa.ParametersName = 'Test1';
            item = gsa.Item(1);
            item.IterationInfo = [500, 2];
            gsa.updateItem(1, item);
            
            
            [statusOk, message, sensitivityInputs, transformations, ...
                distributionNames, samplingInfo] = hGSAObject.executeMethodHelper(...
                gsa, "getParameterInfo");
            testCase.assertTrue(statusOk);
            testCase.assertEmpty(message);
            
            [statusOK, statusMessage] = gsa.runHelper(...
                @(tfReset, itemIdx, message, samples, data) ...
                testCase.progressCallbackMockup(1, tfReset, itemIdx, message, samples, data));
            testCase.verifyTrue(statusOK);
            testCase.verifyEmpty(statusMessage);
            testCase.verifyNotEmpty(gsa.Item(1).MATFileName);

            testCase.verifyGSAResultsFile(gsa.Item(1).MATFileName, ...
                prod(item.IterationInfo), sensitivityInputs, distributionNames, ...
                transformations, samplingInfo);
            
        end
    end


end