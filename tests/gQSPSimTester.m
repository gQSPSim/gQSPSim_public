classdef gQSPSimTester < QSPViewer.App
    methods
        function obj = gQSPSimTester(filename)
            if nargin == 0
                rootDirectory = "/Users/pax/work/gQSPsim/Sessions/CaseStudy_aPCSK9/aPCSK9_v7_MES_complete/";
                filename = rootDirectory + "CaseStudy2_aPCSK9.qsp.mat";
                
                %rootDirectory = "/Users/pax/work/gQSPsim/Sessions/CaseStudy_TMDD/";
                %filename = rootDirectory + "CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat";
            end
            a = obj.loadSessionFromFile(filename, false);            
            obj.Session.RootDirectory = char(rootDirectory);
            %obj.Session.RelativeResultsPath = 'foobar';          
            obj.Session.UseParallel = false;
            obj.Session.AutoSaveBeforeRun = false;
            obj.Session.RelativeResultsPath = '../foobar';
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