classdef tgQSPSim < matlab.unittest.TestCase
    
%     methods(TestMethodTeardown)
%         function tcleanup(testCase)
%             disp('test method tear down called');
%             close all force
%             sbioreset;
%         end
%     end
    properties
        rootDirectory string
    end
    
    properties (TestParameter)
        caseStudy = {"Sessions/CaseStudy_aPCSK9/aPCSK9_v7_MES_complete/CaseStudy2_aPCSK9.qsp.mat", ... 
                     "Sessions/CaseStudy_TMDD/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat"};                 
    end
    
    methods(TestClassSetup)
        function foo(testCase)
            % This gets called when pwd is 'tests' in the RootDirectory
            testCase.rootDirectory = string(pwd) + "/..";
        end
    end
    
    methods(TestMethodSetup)
    end
        
    methods(Test)
        function tSimulations(testCase, caseStudy)
            absolutePath = testCase.rootDirectory + "/" + caseStudy;
            obj = gQSPSimTester(absolutePath);
            testCase = obj.runSimulations(testCase);
            delete(obj);
        end
        
        %function tOptimizations(testCase)
        %    tester = gQSPSimTester; % make this a testParameter TODO
        %    [a, e] = tester.Session.Optimization(1).run;
        %    testCase.verifyTrue(a);
        %end
    end
    
end




