classdef gQSPSimTester < QSPViewer.App
    methods
        function obj = gQSPSimTester(filename)
            if nargin == 0
                rootDirectory = "/Users/pax/work/gQSPsim/Sessions/CaseStudy_aPCSK9/aPCSK9_v7_MES_complete/";
                filename = rootDirectory + "CaseStudy2_aPCSK9.qsp.mat";
            end
            a = obj.loadSessionFromFile(filename, false);            
            obj.Session.RootDirectory = char(rootDirectory);
            obj.Session.UseParallel = false;
        end
        
        function runSimulations(obj)
            for i = 1:numel(obj.Session.Simulation)                                
                [a, e] = obj.Session.Simulation(i).run;
            end
        end
        
        function runOptimizations(obj)
            for i = 1:numel(obj.Session.Optimization)
                [a, e] = obj.Session.Optimization(i);
            end
        end
    end
end