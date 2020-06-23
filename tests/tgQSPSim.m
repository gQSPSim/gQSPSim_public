classdef tgQSPSim < matlab.unittest.TestCase
    
    properties
        testRootDirectory string
    end
    
    properties (TestParameter)
        caseStudy = {"baselines/aPCSK9_v7_MES_complete/CaseStudy2_aPCSK9.qsp.mat", ...
                     "baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat"};
    end
    
    methods(TestClassSetup)
        function foo(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
        end
    end
    
    methods(TestMethodSetup)
    end
        
    methods(Test)
        function tSimulations(testCase, caseStudy)
            absolutePath = testCase.testRootDirectory + "/" + caseStudy;
            obj = gQSPSimTester(absolutePath);
            obj.runSimulations(testCase);
            delete(obj);
        end
        
        function tOptimizations(testCase, caseStudy)
            absolutePath = testCase.testRootDirectory + "/" + caseStudy;
           tester = gQSPSimTester(absolutePath); % make this a testParameter TODO
           [a, e] = tester.Session.Optimization(1).run;
           testCase.verifyTrue(a);
        end
    end
    
end




