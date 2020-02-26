classdef tgQSPSim < matlab.unittest.TestCase
    
    methods(TestMethodTeardown)
        function tcleanup(testCase)
            close all force
            sbioreset;
        end
    end
    
    methods(Test)
        function tPCSK9(testCase)
            t = gQSPSimTester;
            [a, e] = t.Session.Simulation(1).run;
            testCase.verifyTrue(a);
            testCase.verifyEmpty(e);
        end
    end
    
end