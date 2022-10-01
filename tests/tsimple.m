classdef tsimple < matlab.unittest.TestCase
    
    properties
        testRootDirectory string
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
            registerUnits;
%             currentPWD = pwd;
%             cd('..');
            addpath(genpath('..'));
%             DefinePaths;
%             cd(currentPWD);
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

        function QSPMenu(testCase)            
            a = QSPappN(true);
            a.forDebuggingInit;

            cleanup = onCleanup(@()delete(a));
            
            drawnow;

            testCase.verifyInstanceOf(a, 'QSPViewerNew.Application.Controller', 'ExpectedClass');

            for i = 1:size(a.buildingBlockTypes, 1)
                type = a.builans.dingBlockTypes{i,2};
                before.(type) = string({a.Sessions.Settings.(type).Name});
            end

            for i = 1:size(a.functionalityTypes, 1)
                type = a.functionalityTypes{i,2};
                before.(type) = string({a.Sessions.(type).Name});
            end

            % Get the menu items and run the Add Item callback for each
            QSPMenu = findobj(a.OuterShell.QSPMenu, 'Text', 'Add New Item');
            addItemMenus = QSPMenu.Children;
            for i = 1:numel(addItemMenus)
                addItemMenus(i).MenuSelectedFcn();
            end

            for i = 1:size(a.buildingBlockTypes, 1)
                type = a.buildingBlockTypes{i,2};
                after.(type) = string({a.Sessions.Settings.(type).Name});
            end

            for i = 1:size(a.functionalityTypes, 1)
                type = a.functionalityTypes{i,2};
                after.(type) = string({a.Sessions.(type).Name});
            end

            itemsToCheck = fields(after);

            for i = 1:numel(itemsToCheck)
                result = setdiff(after.(itemsToCheck{i}), before.(itemsToCheck{i}));
                testCase.verifyEqual(result, "New " + a.ItemTypes{i,1});
            end            
        end
    end
end