classdef GlobalSensitivityAnalysisTester < matlab.unittest.TestCase
    % Base class for testing backend functionality for global sensitivity analysis

    properties (Access = private)
        TestRootDirectory string
        QSPSession
        CaseStudy = {"lotka", "lotka.qsp.mat"}; %#ok<CLARRSTR>
        ExistingSimBiologyModels
    end

    methods(TestClassSetup)
        function setupTestRootDirectory(testCase)
            testCase.TestRootDirectory = fileparts(mfilename("fullpath"));
        end
        function setupExistingSimBiologyModels(testCase)
            SimBiologyRoot = sbioroot;
            testCase.ExistingSimBiologyModels = SimBiologyRoot.Models;
        end
    end

    methods (TestMethodSetup)
        function createGSAObject(testCase)
            absolutePath = fullfile(testCase.TestRootDirectory, testCase.CaseStudy{:});
            loadStruct = load(absolutePath);
            testCase.QSPSession = loadStruct.Session;
        end
    end

    methods (TestClassTeardown)
        function deleteModelsCreatedDuringTests(testCase)
            % Cleanup: delete newly created SimBiology models
            SimBiologyRoot = sbioroot;
            simBiologyModelsOnRoot = SimBiologyRoot.Models;
            newlyCreatedSimBiologyModels = setdiff(simBiologyModelsOnRoot, ...
                testCase.ExistingSimBiologyModels);
            if ~isempty(newlyCreatedSimBiologyModels)
                delete(newlyCreatedSimBiologyModels);
            end
        end
        function cleanupResultsFolder(testCase)
            % Delete results files that have been created during tests.
            gsaResults = fullfile(testCase.TestRootDirectory, "lotka", "gsaResults", "*.mat");
            delete(gsaResults)
        end
    end

    methods

        function gsaObject = getGSAObject(testCase)
            gsaObject = testCase.QSPSession.GlobalSensitivityAnalysis;
        end

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

        function verifyGSAResultsFile(testCase, resultsFilename, expNumSamples, ...
                sensitivityInputs, distributionNames, transformations, samplingInfo)
            % Verification helper for computed GSA results file.

            % Load computed results
            resultsFile = fullfile(testCase.TestRootDirectory, "lotka", "gsaResults", resultsFilename);
            loadStruct = load(resultsFile);
            testCase.assertTrue(isfield(loadStruct, "results"));
            results = loadStruct.results;
            tfVerAtLeastR2021b = ~verLessThan('matlab','9.11');
            if tfVerAtLeastR2021b
                testCase.assertClass(results, "SimBiology.gsa.Sobol");
            else
                testCase.assertClass(results, "QSP.internal.gsa.TransformedSobol");
            end

            % Verify expected parameter samples
            numSensitivityInputs = numel(sensitivityInputs);
            testCase.verifyEqual(results.ParameterSamples.Properties.VariableDescriptions, sensitivityInputs');
            testCase.verifySize(results.ParameterSamples, [expNumSamples, numSensitivityInputs]);
            % Verify paraemter bounds
            samples = [results.ParameterSamples; results.SimulationInfo.SupportSamples];
            for i = 1:numSensitivityInputs
                if strcmp(distributionNames{i}, 'uniform')
                    testCase.verifyTrue(all(samples{:,i} >= samplingInfo(i,1)), ...
                        "Uniform parameter samples for parameter " + i + " must be larger than or equal to the lower bound.");
                    testCase.verifyTrue(all(samples{:,i} <= samplingInfo(i,2)), ...
                        "Uniform parameter samples for parameter " + i + " must be smaller than or equal to the upper bound.");
                else
                    if strcmp(transformations{i}, 'log')
                        % Compute mean and std of lognormal distributed
                        % random variable
                        mu = samplingInfo(i,1);
                        v = samplingInfo(i,2)^2;
                        samplingInfo(i,1) = exp(mu + v/2);
                        samplingInfo(i,2) = sqrt(exp(2*mu + v)*(exp(v)-1));
                    end
                    % Verification of (log-)normal samples?
                    testCase.verifyEqual(mean(samples{:,i}), samplingInfo(i,1), "AbsTol", 0.02, ...
                        "Normally distributed samples for parameter " + i + " do not match the mean value.")
                    testCase.verifyEqual(std(samples{:,i}), samplingInfo(i,2), "AbsTol", 0.02, ...
                        "Normally distributed samples for parameter " + i + " have unexpected standard deviation value.")
                end
            end

        end

        function progressCallbackMockup(testCase, expectedItemIdx, tfReset, itemIdx, message, samples, data)
            testCase.verifyEqual(itemIdx, expectedItemIdx);
            if tfReset
                testCase.verifyEmpty(message);
                testCase.verifyEmpty(samples);
                testCase.verifyEmpty(data);
            else
                testCase.verifyClass(message, "cell");
                testCase.verifySize(message, [7,1]);
                testCase.verifyClass(samples, "double");
                testCase.verifyClass(data, "double");
                testCase.verifySize(data, size(samples));
            end
        end
    end

end