classdef tsimple < matlab.unittest.TestCase
    
    properties
        testRootDirectory string
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
        end
    end
    
    methods(Test, TestTags = ["NoUI"])
        function basicFunctionality(testCase)
            % Meant to tests the basics:
            % Load a Session
            % Run a simulation task in the session
            
            tmddCaseStudy = "/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat";
            
            session = load(testCase.testRootDirectory + tmddCaseStudy, 'Session');

            
            testCase.assertNotEmpty(session);                        
        end
    end

    methods(Test, TestTags = ["RequiresUserInterace"])
        function QSPMenu(testCase)
            % Test all the menus under QSP menu. These add nodes to the
            % tree.            
            ctrl = QSPappN();
            cleanup = onCleanup(@()delete(ctrl));
            
            % Due to RootDirectory issues we cannot simply use the
            % controller's api. As a workaround use a direct mat file load
            % and add the loaded session to the controller.
            % ctrl.loadSession('tests/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat');            
            sessionPath = testCase.testRootDirectory + filesep + "baselines" + filesep + "CaseStudy_TMDD_complete" + filesep + "CaseStudy1_TMDD.qsp.mat";
            SessionContainer = load(sessionPath);
            rootDirectory = testCase.testRootDirectory + filesep + "baselines" + filesep + "CaseStudy_TMDD_complete";
            SessionContainer.Session.RootDirectory = rootDirectory;
            ctrl.addSession(SessionContainer.Session);
            
            drawnow;

            testCase.verifyInstanceOf(ctrl, 'QSPViewerNew.Application.Controller', 'ExpectedClass');

            for i = 1:size(ctrl.buildingBlockTypes, 1)
                type = ctrl.buildingBlockTypes{i,2};
                before.(type) = string({ctrl.Sessions.Settings.(type).Name});
            end

            for i = 1:size(ctrl.functionalityTypes, 1)
                type = ctrl.functionalityTypes{i,2};
                before.(type) = string({ctrl.Sessions.(type).Name});
            end

            % Get the menu items and run the Add Item callback for each
            QSPMenu = findobj(ctrl.OuterShell.QSPMenu, 'Text', 'Add New Item');
            addItemMenus = QSPMenu.Children;
            for i = 1:numel(addItemMenus)
                addItemMenus(i).MenuSelectedFcn();
            end

            for i = 1:size(ctrl.buildingBlockTypes, 1)
                type = ctrl.buildingBlockTypes{i,2};
                after.(type) = string({ctrl.Sessions.Settings.(type).Name});
            end

            for i = 1:size(ctrl.functionalityTypes, 1)
                type = ctrl.functionalityTypes{i,2};
                after.(type) = string({ctrl.Sessions.(type).Name});
            end

            drawnow;

            itemsToCheck = fields(after);

            for i = 1:numel(itemsToCheck)
                result = setdiff(after.(itemsToCheck{i}), before.(itemsToCheck{i}));
                testCase.verifyEqual(result, "New " + ctrl.ItemTypes{i,1});
            end            
        end
    end
end