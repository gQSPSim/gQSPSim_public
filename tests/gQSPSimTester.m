classdef gQSPSimTester < QSPViewer.App
    methods
        function obj = gQSPSimTester(filename)
            if nargin == 0
                filename = '/Users/pax/work/gQSPSim/Sessions/CaseStudy_aPCSK9/aPCSK9_v7_MES_complete/CaseStudy2_aPCSK9.qsp.mat';
            end
            a = obj.loadSessionFromFile(filename, false);
        end
    end
end