classdef tgQSPSim < matlab.unittest.TestCase
    
%     methods(TestMethodTeardown)
%         function tcleanup(testCase)
%             disp('test method tear down called');
%             close all force
%             sbioreset;
%         end
%     end
    
%     methods
%         function delete(obj)
%             disp('tgQSPSim delete called');
%             dbstack
%         end
%     end
    
%     methods(TestClassSetup)
%         function foo(testCase)
%             rootDirectory = string(pwd) + "/../Sessions/CaseStudy_aPCSK9/aPCSK9_v7_MES_complete/";
%             filename = rootDirectory + "CaseStudy2_aPCSK9.qsp.mat";
%             testCase.loadSessionFromFile(filename, false);
%             testCase.Session.RootDirectory = char(rootDirectory);
%             testCase.Session.UseParallel = false;
%             testCase.Session.AutoSaveBeforeRun = false;
%         end
%     end
    
    methods(TestMethodSetup)
    end
        
    methods(Test)
        function tSimulations(testCase)
            obj = gQSPSimTester;
            testCase = obj.runSimulations(testCase);
        end
        
        %function tOptimizations(testCase)
        %    tester = gQSPSimTester; % make this a testParameter TODO
        %    [a, e] = tester.Session.Optimization(1).run;
        %    testCase.verifyTrue(a);
        %end
    end
    
end




