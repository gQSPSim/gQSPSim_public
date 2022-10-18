classdef tUI < matlab.uitest.TestCase
    
    properties
        testRootDirectory string
    end
    
    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
        end
    end
    
    methods(Test, TestTags = ["RequiresUserInterface"])
        function pressGitButton(testCase)
            ctrl = QSPappN();
            testCase.addTeardown(@delete, ctrl);            

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

            % Pick any functionality and press on it in the tree.
            testCase.choose(findobj(ctrl.OuterShell.TreeCtrl, 'Tag', 'Simulation').Children(1));

            gitButton = ctrl.OuterShell.paneToolbar.gitButton;
            testCase.press(gitButton);
            testCase.verifyEqual(ctrl.Sessions.AutoSaveGit, true);

            parallelButton = ctrl.OuterShell.paneToolbar.parallelButton;
            testCase.press(parallelButton);
            testCase.verifyEqual(ctrl.Sessions.UseParallel, true);
        end

        function instanceContextMenus(testCase)
            ctrl = QSPappN();
            testCase.addTeardown(@delete, ctrl);            

            % Due to RootDirectory issues we cannot simply use the
            % controller's api. As a workaround use a direct mat file load
            % and add the loaded session to the controller.
            % ctrl.loadSession('tests/baselines/CaseStudy_TMDD_complete/CaseStudy1_TMDD.qsp.mat');            
            sessionPath = testCase.testRootDirectory + filesep + "baselines" + filesep + "CaseStudy_TMDD_complete" + filesep + "CaseStudy1_TMDD.qsp.mat";
            SessionContainer = load(sessionPath);
            rootDirectory = testCase.testRootDirectory + filesep + "baselines" + filesep + "CaseStudy_TMDD_complete";
            SessionContainer.Session.RootDirectory = rootDirectory;
            ctrl.addSession(SessionContainer.Session);

            OptimizationFunctionality = findobj(ctrl.OuterShell.TreeCtrl, 'Tag', 'Optimization');

            % Must select a node before using its context menu. This might
            % be a bug in the chooseContextMenu functionality.
            testCase.choose(OptimizationFunctionality.Children(1));
            
            testCase.chooseContextMenu(OptimizationFunctionality.Children(1), findobj(OptimizationFunctionality.Children(1).ContextMenu, 'Text', 'Duplicate'));

            testCase.verifyNumElements(ctrl.Sessions.Optimization, 2);
            testCase.verifyEqual({ctrl.Sessions.Optimization.Name}, {'Optimization', 'Optimization_1'});

        end

        function deletedItemsContextMenus(testCase)
            disp('todo');
        end

    end
end
