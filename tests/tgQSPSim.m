classdef tgQSPSim < matlab.unittest.TestCase
    
    methods(TestMethodTeardown)
        function tcleanup(testCase)
            close all force
            sbioreset;
        end
    end
    
    methods(Test)
        function tSimulations(testCase)
            tester = gQSPSimTester; % make this a testParameter TODO            
            %for i = 1:numel(tester.Session.Simulation)
            for i = 1:0
                [a, e] = tester.Session.Simulation(i).run;
                testCase.verifyTrue(a);
                %testCase.verifyEmpty(e);
            end            
        end
        
        function tOptimizations(testCase)
            tester = gQSPSimTester; % make this a testParameter TODO
            [a, e] = tester.Session.Optimization(1).run;
            testCase.verifyTrue(a);
        end
    end
    
end