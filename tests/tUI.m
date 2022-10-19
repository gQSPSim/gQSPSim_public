classdef tUI < matlab.uitest.TestCase
    
    properties
        testRootDirectory string
        ctrl QSPViewerNew.Application.Controller
    end
    
    properties (TestParameter)        
        functionalities = {'Simulation', 'Optimization', 'VirtualPopulationGeneration', 'CohortGeneration'};%, 'GlobalSensitivityAnalysis'};
    end

    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));

            testCase.ctrl = QSPappN();
            testCase.addTeardown(@delete, testCase.ctrl);            

            % Due to RootDirectory issues we cannot simply use the
            % controller's api. As a workaround use a direct mat file load
            % and add the loaded session to the controller.
            % ctrl.loadSession('tests/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat');            
            sessionPath = testCase.testRootDirectory + filesep + "baselines" + filesep + "CaseStudy_TMDD_complete" + filesep + "CaseStudy1_TMDD.qsp.mat";
            SessionContainer = load(sessionPath);
            rootDirectory = testCase.testRootDirectory + filesep + "baselines" + filesep + "CaseStudy_TMDD_complete";
            SessionContainer.Session.RootDirectory = rootDirectory;
            testCase.ctrl.addSession(SessionContainer.Session);
        end
    end

    methods(TestClassTeardown)
        function cleanup(testCase)
            delete(testCase.ctrl);
        end
    end
    
    methods(Test, TestTags = ["RequiresUserInterface"])
        function pressGitButton(testCase)
            % Pick any functionality and press on it in the tree.
            testCase.choose(findobj(testCase.ctrl.OuterShell.TreeCtrl, 'Tag', 'Simulation').Children(1));

            gitButton = testCase.ctrl.OuterShell.paneToolbar.gitButton;
            testCase.press(gitButton);
            testCase.verifyEqual(testCase.ctrl.Sessions.AutoSaveGit, true);

            parallelButton = testCase.ctrl.OuterShell.paneToolbar.parallelButton;
            testCase.press(parallelButton);
            testCase.verifyEqual(testCase.ctrl.Sessions.UseParallel, true);
        end

        function instanceContextMenusFunctionalities(testCase, functionalities)

            functionality = findobj(testCase.ctrl.OuterShell.TreeCtrl, 'Tag', functionalities);

            preNumberOfFunctionalities = numel(testCase.ctrl.Sessions.(functionalities));

            % Must select a node before using its context menu. This might
            % be a bug in the chooseContextMenu functionality.
            testCase.choose(functionality.Children(1));
            
            testCase.chooseContextMenu(functionality.Children(1), findobj(functionality.Children(1).ContextMenu, 'Text', 'Duplicate'));

            % Expect one more from the duplicate
            testCase.verifyNumElements(testCase.ctrl.Sessions.(functionalities), preNumberOfFunctionalities + 1);

            % Get all children
            items = [functionality.Children.NodeData];
            itemNames = string({items.Name});
            
            testCase.verifyTrue(itemNames(1)+"_1" == itemNames(end));            
        end

        function deletedItemsContextMenus(testCase)
            disp('todo');
        end

    end
end
