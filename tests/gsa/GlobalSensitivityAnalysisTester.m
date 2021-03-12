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
end

methods 
    function gsaObject = getGSAObject(testCase)
        gsaObject = testCase.QSPSession.GlobalSensitivityAnalysis;
    end
end
end