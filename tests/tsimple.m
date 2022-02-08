classdef tsimple < matlab.unittest.TestCase
    
    properties
        testRootDirectory string
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
        end
    end
    
    methods(Test)        
        function basicFunctionality(testCase)
            % Meant to tests the basics:
            % Load a Session
            % Run a simulation task in the session
            
            tmddCaseStudy = "/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat";
            
            session = load(testCase.testRootDirectory + tmddCaseStudy, 'Session');
            
            testCase.assertNotEmpty(session);                        
        end
    end
end