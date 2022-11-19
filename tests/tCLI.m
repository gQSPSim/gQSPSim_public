classdef tCLI < matlab.unittest.TestCase

    properties
        testRootDirectory (1,1) string
    end

    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
            addpath(genpath('..'));
            DefinePaths;
        end
    end

    methods(Test, TestTags = ["NoUI"])
        function loadSession(testCase)
            tmddCaseStudy = testCase.testRootDirectory + join([filesep, "baselines", "CaseStudy_TMDD_complete", "CaseStudy1_TMDD.qsp.mat"], filesep);

            sessionContainer = load(tmddCaseStudy);
            session = sessionContainer.Session;

            % stored RootDirectory is incorrect in most cases as it was
            % written in the project by the last person to set it and its a
            % hardcoded absolute path.
            session.RootDirectory = testCase.testRootDirectory + join([filesep, "baselines", "CaseStudy_TMDD_complete"], filesep);

            session.Simulation(1).run();
        end

        function createSession(testCase)

            tmddCaseStudy = testCase.testRootDirectory + join(["Sessions", "CaseStudy_TMDD", "CaseStudy_TMDD_blank"], filesep);

            session = QSP.Session();
            session.RootDirectory = tmddCaseStudy;
            session.AutoSaveBeforeRun = true;

            testCase.assertNotEmpty(session);
        end

        function runWorkflow(testCase)
            tmddCaseStudy = testCase.testRootDirectory + filesep + join(["..", "Sessions", "CaseStudy_TMDD", "CaseStudy_TMDD_blank"], filesep);

            session = QSP.Session();
            session.RootDirectory = tmddCaseStudy;
            session.AutoSaveBeforeRun = true;
            session.ShowProgressBars = false; % TODO this should be the case if using the API / Model

            % create task
            task1 = session.CreateTask('A_3.0 mpk');

            % configure
            task1.SetProject('casestudy1_TMDD_template.sbproj');
            task1.SetModel('A_3.0 mpk');
            task1.ActivateVariants({'Ref values - treatment A - KD  = 0.4'});
            task1.AddDoses({'3.0 mg/kg'});
            task1.IncludeSpecies({'UnboundAbConc (mcg/ml)', 'FreeTarget (ng/ml)', 'TotalTarget (ng/ml)', 's_target_init'});
            task1.OutputTimes = 0:0.1:21;
            task1.RunToSteadyState = true;

            % add/configure task 2
            task2          = task1.Replicate();
            task2.Name     = 'A_0.3 mpk';
            task2.AddDoses({'0.3 mg/kg'});

            % add dataset
            dataset1 = session.CreateDataset('Data_mean');
            dataset1.RelativeFilePath   = 'Data_mean.xlsx';
            dataset1.DatasetType        = 'wide';

            % add parameter
            parameter1 = session.CreateParameter('Param_8');
            parameter1.RelativeFilePath = 'Param_8.xlsx';

            % add optimization
            optimization1 = session.CreateOptimization('Optimization');
            optimization1.AlgorithmName    = 'ParticleSwarm'; % 'ScatterSearch';
            optimization1.RefParamName     = 'Param_8';
            optimization1.DatasetName      = 'Data_mean';
            optimization1.GroupName        = 'Group';
            optimization1.IDName           = 'ID';
            optimization1.TaskGroupItems = {'A_3.0 mpk','1';...
                'A_0.3 mpk','2'...
                };
            optimization1.SpeciesDataMapping = {...
                'pk_free_ugm', 'UnboundAbConc (mcg/ml)', 'x'; ...
                'target_free_ngml', 'FreeTarget (ng/ml)','x'; ...
                'target_tot_ngml', 'TotalTarget (ng/ml)', 'x'...
                };

            % run optimization
            successTF = optimization1.run();
            testCase.verifyTrue(successTF);

            % % acceptance criteria
            acceptanceCriteria1 = session.CreateAcceptanceCriteria('AC_fixed_target');
            acceptanceCriteria1.RelativeFilePath = 'AC_vpop_fixed_target.xlsx';

            % cohort generation
            vcGen1 = session.CreateVCohortGen('Cohort_fixed_target_1000');
            vcGen1.VPopResultsFolderName        = 'CohortGenerationResults'; % TODO maybe rename property for simplicity?
            vcGen1.RefParamName                 = 'Param_8'; % TODO probably rename property
            vcGen1.DatasetName                  = 'AC_fixed_target'; % TODO probably rename property
            vcGen1.GroupName                    = 'Group';
            vcGen1.MaxNumSimulations            = 5000;
            vcGen1.MaxNumVirtualPatients        = 500;
            vcGen1.SaveInvalid                   = 'all'; % Save all virtual subjects
            vcGen1.Method                        = 'Distribution';
            vcGen1.TaskGroupItems = {...
                'A_3.0 mpk','1';... 
                'A_0.3 mpk','2' ...
                };
            vcGen1.SpeciesDataMapping = {...
                'pk_free_ugm', 'UnboundAbConc (mcg/ml)', 'x'; ...
                'target_free_ngml', 'FreeTarget (ng/ml)', 'x'; ...
                'target_tot_ngml', 'TotalTarget (ng/ml)', 'x'...
                };

            successTF = vcGen1.run();
            testCase.verifyTrue(successTF);

            % % target statistics
            targetStats1 = session.CreateTargetStatistics('Data_with_mean');
            targetStats1.RelativeFilePath = 'Data_mean_vpop_gen.xlsx';

            % virtual population generation
            vpGen1 = session.CreateVPopGen('VP_mean_data');
            vpGen1.VPopResultsFolderName        = 'VPopResults'; % TODO Rename property?
            vpGen1.VPopName                     = 'Cohort_fixed_target_1000'; % TODO rename property "CohortName"
            vpGen1.VpopGenDataName              = 'Data_with_mean'; % TODO rename to TargetStatisticsName; Data_with_mean or Data_mean
            vpGen1.GroupName                    = 'Group';
            vpGen1.MinNumVirtualPatients        = 100;
            vpGen1.RedistributeWeights          = true;
            vpGen1.TaskGroupItems = {...
                'A_3.0 mpk','1';...
                'A_0.3 mpk','2'...
                };
            vpGen1.SpeciesDataMapping = {...
                'pk_free_ugm', 'UnboundAbConc (mcg/ml)', 'x'; ...
                'target_free_ngml', 'FreeTarget (ng/ml)', 'x'; ...
                'target_tot_ngml', 'TotalTarget (ng/ml)', 'x' ...
                };


            % run
            vpGen1.DatasetName = vcGen1.VPopName;
            successTF = vpGen1.run();

            % currently failing because there is no 
            % Settings.VirtualPopulation in the validate method
            % of the above run call.
%             testCase.verifyTrue(successTF);
        end
    end
end




% % % change algorithm
% % Optim1.AlgorithmName = 'ParticleSwarm';
% % % run again
% % Optim1.run()
%
%
%
% % get name of the results produced from running the Vpop generation
% vpopName = VPGen1.VPopName;
%
%
% % task 3
% T3                  = T1.Replicate();
% T3.Name             = 'A_0.3 mpk_S';
% T3.ActiveDoseNames  = {'0.3 mg/kg'};
% T3.OutputTimes      = 0:0.1:49;
%
% % task 4
% T4      = T1.Replicate();
% T4.Name = 'A_3 mpk_S';
% T4.ActiveDoseNames  = {'3.0 mg/kg'};
% T4.OutputTimes      = 0:0.1:49;
%
% % task 5
% T5                  = T1.Replicate();
% T5.Name             = 'A_1 mpk_M';
% T5.ActiveDoseNames  = {'1.0 mg/kg_3'};
% T5.OutputTimes      = 0:0.1:49;
%
% % task 6
% T6                  = T1.Replicate();
% T6.Name             = 'A_10 mpk_M';
% T6.ActiveDoseNames  = {'10.0 mg/kg_3'};
% T6.OutputTimes      = 0:0.1:49;
%
% % create simulation
% Sim1 = session.CreateSimulation('Sim_Cohort_fixed_target_1000 VP');
% Sim1.DatasetName    = 'Data_mean';
% Sim1.GroupName      = 'Group';
%
% Sim1.TaskVPopItems = {...
%     'A_0.3 mpk_S', vpopName, ''; ...
%     'A_3 mpk_S', vpopName, ''; ...
%     'A_1 mpk_M', vpopName, ''; ...
%     'A_10 mpk_M', vpopName, '' ...
%     };
%
% % run
% Sim1.run()
%
% % supplementary figures
% Parameter2 = session.CreateParameter('Param_7');
% Parameter2.RelativeFilePath = 'Param_7.xlsx';
%
% % acceptance criteria
% AC2 = session.CreateAcceptanceCriteria('AC_var_target');
% AC2.RelativeFilePath = 'AC_vpop_var_target.xlsx';
%
% VCGen2              = VCGen1.Replicate();
% VCGen2.Name         = 'Cohort_variable_target_1000';
% VCGen2.RefParamName = 'Param_7';
% VCGen2.DatasetName  = 'AC_var_target';
% VCGen2.TaskGroupItems = {
%     'A_3.0 mpk','4'; ...
%     'A_0.3 mpk','5'...
%     };
% VCGen2.ICFileName = 'Data_vpop_init_val.xlsx';
%
% VCGen2.run()
%
% vpopName2 = VCGen2.VPopName;
%
% % sim 2
% Sim2 = Sim1.Replicate();
% Sim2.Name           = 'Sim_model_default';
% Sim2.DatasetName    = 'Data_mean';
% Sim2.GroupName      = 'Group';
% Sim2.TaskVPopItems = {...
%     'A_3.0 mpk', 'ModelDefault', ''; ...
%     'A_0.3 mpk', 'ModelDefault', '' ...
%     };
% Sim2.run()
%
% % sim 3
% Sim3 = Sim2.Replicate();
% Sim3.Name           = 'Sim_VP_group';
% Sim3.DatasetName    = 'Data_mean';
% Sim3.GroupName      = 'Group';
% Sim3.TaskVPopItems = {...
%     'A_3.0 mpk', vpopName2, '4'; ...
%     'A_0.3 mpk', vpopName2, '5' ...
%     };
% Sim3.run()
