classdef tCLI < matlab.unittest.TestCase

    properties
        testRootDirectory (1,1) string
    end

    methods(TestClassSetup)
        function setup(testCase)
            testCase.testRootDirectory = fileparts(mfilename('fullpath'));
            addpath(genpath('..'));
            DefinePaths(false);
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
            session.RootDirectory = testCase.testRootDirectory + filesep + join(["baselines", "CaseStudy_TMDD_complete"], filesep);

            session.Simulation(1).run();
        end

        function createSession(testCase)

            tmddCaseStudy = testCase.testRootDirectory + filesep + join(["Sessions", "CaseStudy_TMDD", "CaseStudy_TMDD_blank"], filesep);

            session = QSP.Session();
            session.RootDirectory = tmddCaseStudy;
            session.AutoSaveBeforeRun = true;

            testCase.assertNotEmpty(session);
        end

        function runTMDDCaseStudy(testCase)
            %% Case Study: TMDD
            %% Create and configure Session

            tmddCaseStudy = testCase.testRootDirectory + filesep + join(["..", "Sessions", "CaseStudy_TMDD", "CaseStudy_TMDD_blank"], filesep);

            % create new Session
            Session = QSP.Session();

            % configure Session
            Session.Name = 'CaseStudy1_TMDD';
            Session.RootDirectory = tmddCaseStudy;
            Session.AutoSaveBeforeRun = true;
            Session.ShowProgressBars = false;            

            %% Create and configure Session dependencies
            % Create tasks

            % create task
            T1 = Session.CreateTask('A_3.0 mpk');

            % configure
            T1.SetProject('casestudy1_TMDD_template.sbproj');
            T1.SetModel('A_3.0 mpk');
            T1.ActivateVariants({'Ref values - treatment A - KD  = 0.4'});
            T1.AddDoses({'3.0 mg/kg'});
            T1.IncludeSpecies({'UnboundAbConc (mcg/ml)', 'FreeTarget (ng/ml)', 'TotalTarget (ng/ml)', 's_target_init'});
            T1.OutputTimes = 0:0.1:21;
            T1.RunToSteadyState = true;

            % add/configure task 2
            T2          = T1.Replicate();
            T2.Name     = 'A_0.3 mpk';
            T2.AddDoses({'0.3 mg/kg'});

            % Create dataset

            % add dataset
            Dataset1 = Session.CreateDataset('Data_mean');
            %             Dataset1.RelativeFilePath_new   = 'Data_mean.xlsx';
            Dataset1.RelativeFilePath   = 'Data_mean.xlsx';
            Dataset1.DatasetType        = 'wide';

            % Create parameter

            % add parameter
            Parameter1 = Session.CreateParameter('Param_8');
            Parameter1.RelativeFilePath = 'Param_8.xlsx';

            %% Configure optimization
            % Create optimization

            % add optimization
            Optim1 = Session.CreateOptimization('Optimization');
            Optim1.AlgorithmName    = 'ScatterSearch';
            Optim1.RefParamName     = 'Param_8';
            Optim1.DatasetName      = 'Data_mean';
            Optim1.GroupName        = 'Group';
            Optim1.IDName           = 'ID';
            Optim1.TaskGroupItems = {...
                'A_3.0 mpk','1';...
                'A_0.3 mpk','2'...
                };
            Optim1.SpeciesDataMapping = {...
                'pk_free_ugm', 'UnboundAbConc (mcg/ml)', 'x'; ...
                'target_free_ngml', 'FreeTarget (ng/ml)','x'; ...
                'target_tot_ngml', 'TotalTarget (ng/ml)', 'x'...
                };
            % Run optimization

            % run optimization
            Optim1.run()

            % % change algorithm
            % Optim1.AlgorithmName = 'ParticleSwarm';
            % % run again
            % Optim1.run()

            %% Generate cohort
            % Create acceptance criteria

            % acceptance criteria
            AC1 = Session.CreateAcceptanceCriteria('AC_fixed_target');
            AC1.RelativeFilePath = 'AC_vpop_fixed_target.xlsx';

            % Create cohort

            % cohort generation
            VCGen1 = Session.CreateVCohortGen('Cohort_fixed_target_1000');
            VCGen1.VPopResultsFolderName        = 'CohortGenerationResults'; % TODO maybe rename property for simplicity?
            VCGen1.RefParamName                 = 'Param_8'; % TODO probably rename property
            VCGen1.DatasetName                  = 'AC_fixed_target'; % TODO probably rename property
            VCGen1.GroupName                    = 'Group';
            VCGen1.MaxNumSimulations            = 5000;
            VCGen1.MaxNumVirtualPatients        = 500;
            VCGen1.SaveInvalid                   = 'all';
            VCGen1.Method                        = 'Distribution';
            VCGen1.TaskGroupItems = {...
                'A_3.0 mpk','1';...
                'A_0.3 mpk','2' ...
                };
            VCGen1.SpeciesDataMapping = {...
                'pk_free_ugm', 'UnboundAbConc (mcg/ml)', 'x'; ...
                'target_free_ngml', 'FreeTarget (ng/ml)', 'x'; ...
                'target_tot_ngml', 'TotalTarget (ng/ml)', 'x'...
                };

            % Run cohort generation

            VCGen1.run()
            %% Generate virtual population
            % Create target statistics and prepare virtual population generation

            % target statistics
            TS1 = Session.CreateTargetStatistics('Data_with_mean');
            TS1.RelativeFilePath = 'Data_mean_vpop_gen.xlsx';

            % virtual population generation
            VPGen1 = Session.CreateVPopGen('VP_mean_data');
            VPGen1.VPopResultsFolderName        = 'VPopResults'; % TODO Rename property?
            VPGen1.VPopName                     = 'Cohort_fixed_target_1000'; % TODO rename property "CohortName"
            VPGen1.VpopGenDataName              = 'Data_with_mean'; % TODO rename to TargetStatisticsName; Data_with_mean or Data_mean
            VPGen1.GroupName                    = 'Group';
            VPGen1.MinNumVirtualPatients        = 100;
            VPGen1.RedistributeWeights          = true;
            VPGen1.TaskGroupItems = {...
                'A_3.0 mpk','1';...
                'A_0.3 mpk','2'...
                };
            VPGen1.SpeciesDataMapping = {...
                'pk_free_ugm', 'UnboundAbConc (mcg/ml)', 'x'; ...
                'target_free_ngml', 'FreeTarget (ng/ml)', 'x'; ...
                'target_tot_ngml', 'TotalTarget (ng/ml)', 'x' ...
                };

            % Run virtual population generation

            % run
            VPGen1.DatasetName = VCGen1.VPopName;
            VPGen1.run()

            % get name of the results produced from running the Vpop generation
            vpopName = VPGen1.VPopName;

            %% Simulate
            % Create tasks

            % task 3
            T3                  = T1.Replicate();
            T3.Name             = 'A_0.3 mpk_S';
            T3.ActiveDoseNames  = {'0.3 mg/kg'};
            T3.OutputTimes      = 0:0.1:49;

            % task 4
            T4      = T1.Replicate();
            T4.Name = 'A_3 mpk_S';
            T4.ActiveDoseNames  = {'3.0 mg/kg'};
            T4.OutputTimes      = 0:0.1:49;

            % task 5
            T5                  = T1.Replicate();
            T5.Name             = 'A_1 mpk_M';
            T5.ActiveDoseNames  = {'1.0 mg/kg_3'};
            T5.OutputTimes      = 0:0.1:49;

            % task 6
            T6                  = T1.Replicate();
            T6.Name             = 'A_10 mpk_M';
            T6.ActiveDoseNames  = {'10.0 mg/kg_3'};
            T6.OutputTimes      = 0:0.1:49;

            % Simulate

            % create simulation
            Sim1 = Session.CreateSimulation('Sim_Cohort_fixed_target_1000 VP');
            Sim1.DatasetName    = 'Data_mean';
            Sim1.GroupName      = 'Group';

            Sim1.TaskVPopItems = {...
                'A_0.3 mpk_S', vpopName, ''; ...
                'A_3 mpk_S', vpopName, ''; ...
                'A_1 mpk_M', vpopName, ''; ...
                'A_10 mpk_M', vpopName, '' ...
                };

            % run
            Sim1.run()

            %% Run virtual cohort generation
            % Create parameter and acceptance criteria

            % supplementary figures
            Parameter2 = Session.CreateParameter('Param_7');
            Parameter2.RelativeFilePath = 'Param_7.xlsx';

            % acceptance criteria
            AC2 = Session.CreateAcceptanceCriteria('AC_var_target');
            AC2.RelativeFilePath = 'AC_vpop_var_target.xlsx';

            % Create virtual cohort

            VCGen2              = VCGen1.Replicate();
            VCGen2.Name         = 'short_VC'; 'Cohort_variable_target_1000';
            VCGen2.RefParamName = 'Param_7';
            VCGen2.DatasetName  = 'AC_var_target';
            VCGen2.TaskGroupItems = {
                'A_3.0 mpk','4'; ...
                'A_0.3 mpk','5'...
                };
            VCGen2.ICFileName = 'Data_vpop_init_val.xlsx';

            % Run

            VCGen2.run()

            vpopName2 = VCGen2.VPopName;

            %% Simulate

            % sim 2

            Sim2 = Sim1.Replicate();
            Sim2.Name           = 'Sim_model_default';
            Sim2.DatasetName    = 'Data_mean';
            Sim2.GroupName      = 'Group';
            Sim2.TaskVPopItems = {...
                'A_3.0 mpk', 'ModelDefault', ''; ...
                'A_0.3 mpk', 'ModelDefault', '' ...
                };
            Sim2.run()

            % sim 3
            Sim3 = Sim2.Replicate();
            Sim3.Name           = 'Sim_VP_group';
            Sim3.DatasetName    = 'Data_mean';
            Sim3.GroupName      = 'Group';
            Sim3.TaskVPopItems = {...
                'A_3.0 mpk', vpopName2, '4'; ...
                'A_0.3 mpk', vpopName2, '5' ...
                };
            Sim3.run()
        end

%         function runPCSK9CaseStudy(testCase)
%             %% Case Study 2: PCSK9 Pseudocode
%             % Monica's comments - New in this case study: creating new virtual subject -
%             % New in this case study: adding Rule to deactivate in the functionality - I think
%             % it will be very useful if we can assign a string of filename for the output
%             % optimization result or cohort or vpop so that we can programmatically call it
%             % later on in the code
%             %% create new session
%             pcsk9CaseStudy = testCase.testRootDirectory + filesep + join(["..", "Sessions", "CaseStudy_aPCSK9", "aPCSK9_v7_MES_blank"], filesep);
%             Session = QSP.Session();
%             Session.ShowProgressBars = false;
% 
%             % configure session
%             Session.Name = 'CaseStudy2_PCSK9';
%             Session.RootDirectory = pcsk9CaseStudy;
%             Session.AutoSaveBeforeRun = true;
%             %% 2.1.Simulation to find time to steady state
% 
%             % create & configure task
%             T1 = Session.CreateTask('No Dose');
%             T1.SetProject('antiPCSK9_gadkar_v3.sbproj');
%             T1.ActivateVariants({'TMDD_calibration'});
%             T1.IncludeSpecies({'total_pcsk9', 'LDLch',});
%             T1.OutputTimes = 0:1:1000;
%             T1.RunToSteadyState = false;
% 
%             % create virtual subject(s)
%             VS1 = Session.CreateVirtualSubjects('VPOP_100VS_CheckSS');  % TODO -- NEW
%             % TODOpax
%             %VS1.RelativeFilePath = 'VPopFiles\VPOP_100Random_Check_SteadyState_range.xls';  % TODO -- NEW
%             VS1.RelativeFilePath = char(join(["VPopFiles", "VPOP_100Random_Check_SteadyState_range.xls"], filesep));
% 
%             % create simulation
%             Sim1 = Session.CreateSimulation('CheckSS');
%             Sim1.TaskVPopItems = {...
%                 'No Dose', VS1.Name, '' ...
%                 };
%             %run simulation
%             Sim1.run()
%             %% 2.2. Parameter optimization
% 
%             % create dataset
%             Dataset_singledose = Session.CreateDataset('data_allsingledose');
%             % TODOpax
% %             Dataset_singledose.RelativeFilePath   = 'DataFiles\data_allsingledose.xlsx';
%             Dataset_singledose.RelativeFilePath   = char(join(["DataFiles", "data_allsingledose.xlsx"], filesep));
%             Dataset_singledose.DatasetType        = 'wide';
% 
%             % create parameters
%             Parameter_optim = Session.CreateParameter('Parameters for Optimization');
%             % TODOpax
% %             Parameter_optim.RelativeFilePath = 'ParamFiles\Parameters_foroptim.xlsx';
%             Parameter_optim.RelativeFilePath = char(join(["ParamFiles", "Parameters_foroptim.xlsx"], filesep));
% 
%             %create 6 tasks
%             %create the first one
%             T2_1 = Session.CreateTask('10mg_ss');
%             T2_1.SetProject('antiPCSK9_gadkar_v3.sbproj');
%             T2_1.ActivateVariants({'TMDD_calibration'});
%             T2_1.AddDoses({'10mg anti-PCSK9'}); %
%             T2_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch'});
%             T2_1.OutputTimes = 0:1:100;
%             T2_1.RunToSteadyState = true;
%             T2_1.TimeToSteadyState = 300;  % TODO -- NEW
% 
%             %replicate and edit dose for the rest of the tasks
%             T2_2          = T2_1.Replicate(); % TODO
%             T2_2.Name     = '40mg_ss';
%             T2_2.AddDoses({'40mg anti-PCSK9'});
% 
%             T2_3          = T2_1.Replicate(); % TODO
%             T2_3.Name     = '150mg_ss';
%             T2_3.AddDoses({'150mg anti-PCSK9'});
% 
%             T2_4          = T2_1.Replicate(); % TODO
%             T2_4.Name     = '300mg_ss';
%             T2_4.AddDoses({'300mg anti-PCSK9'});
% 
%             T2_5          = T2_1.Replicate(); % TODO
%             T2_5.Name     = '600mg_ss';
%             T2_5.AddDoses({'600mg anti-PCSK9'});
% 
%             T2_6          = T2_1.Replicate(); % TODO
%             T2_6.Name     = '800mg_ss';
%             T2_6.AddDoses({'800mg anti-PCSK9'});
% 
%             % create optimization
%             Optim1 = Session.CreateOptimization('Optimization_singledose’');
%             Optim1.AlgorithmName    = 'ScatterSearch';
%             Optim1.RefParamName     = 'Parameters for Optimization';
%             Optim1.DatasetName      = 'data_allsingledose';
%             Optim1.GroupName        = 'Group';
%             Optim1.IDName           = 'ID';
%             Optim1.TaskGroupItems = {...
%                 '10mg_ss', '10'; ...
%                 '40mg_ss', '40'; ...
%                 '150mg_ss', '150'; ...
%                 '300mg_ss', '300'; ...
%                 '600mg_ss', '600'; ...
%                 '800mg_ss', '800'; ...
%                 }; % TODO requires constructing a TaskGroup object
%             Optim1.SpeciesDataMapping = {...
%                 'PK', 'total_antipcsk9', 'x';...
%                 'Totalpcsk9', 'total_pcsk9', 'x'; ...
%                 'LDL', 'LDLch', 'x'}; % TODO requires constructing SpeciesData object
% 
%             % run optimization
%             Optim1.run()
%             %% 2.3 Virtual Cohort Generation
% 
%             % Create acceptance criteria
%             AC1 = Session.CreateAcceptanceCriteria('AC_allsingledose');
%             % TODOpax
% %             AC1.RelativeFilePath = 'ACFiles\AC_alldose_v8.xlsx';
%             AC1.RelativeFilePath = char(join(["ACFiles", "AC_alldose_v8.xlsx"], filesep));
% 
%             % create parameters
%             Parameter_cohortgen = Session.CreateParameter('Parameters for Cohort Gen'); % TODO
% %             Parameter_cohortgen.RelativeFilePath = 'ParamFiles\Parameters_forCohortGen.xlsx';
%             Parameter_cohortgen.RelativeFilePath = char(join(["ParamFiles", "Parameters_forCohortGen.xlsx"], filesep));
% 
%             %create 7 tasks
%             %create the first one
%             T3_1 = Session.CreateTask('10mg_ss_RuleOff');
%             T3_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
%             T3_1.ActivateVariants({'TMDD_calibration'}); % TODO
%             T3_1.AddDoses({'10mg anti-PCSK9'}); % TODO
%             T3_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
%             T3_1.InactiveRuleNames = {'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}; %TODO  -- NEW
%             T3_1.OutputTimes = [0:1:100];  % TODO
%             T3_1.RunToSteadyState = true;
%             T3_1.TimeToSteadyState = 300;  % TODO -- NEW
% 
% 
%             %replicate and edit dose for the other five  tasks
%             T3_2          = T3_1.Replicate(); % TODO
%             T3_2.Name     = '40mg_ss_RuleOff';
%             T3_2.AddDoses({'40mg anti-PCSK9'});
% 
%             T3_3          = T3_1.Replicate(); % TODO
%             T3_3.Name     = '150mg_ss_RuleOff';
%             T3_3.AddDoses({'150mg anti-PCSK9'});
% 
%             T3_4          = T3_1.Replicate(); % TODO
%             T3_4.Name     = '300mg_ss_RuleOff';
%             T3_4.AddDoses({'300mg anti-PCSK9'});
% 
%             T3_5          = T3_1.Replicate(); % TODO
%             T3_5.Name     = '600mg_ss_RuleOff';
%             T3_5.AddDoses({'600mg anti-PCSK9'});
% 
%             T3_6          = T3_1.Replicate(); % TODO
%             T3_6.Name     = '800mg_ss_RuleOff';
%             T3_6.AddDoses({'800mg anti-PCSK9'});
% 
%             %create statin effect task
%             T3_7          = T3_1.Replicate(); % TODO
%             T3_7.Name     = 'StatinContinuous_ss_RuleOff';
%             T3_7.AddDoses({'statin_continuous_dosing'});
% 
%             % cohort generation
%             VCGen1 = Session.CreateVCohortGen('CohortGen_SingleDose'); % TODO
%             VCGen1.VPopResultsFolderName        = 'VirtualPatientsResults'; % TODO maybe rename property for simplicity?
%             VCGen1.RefParamName                 = 'Parameters for Cohort Gen'; % TODO probably rename property
%             VCGen1.DatasetName                  = 'AC_allsingledose'; % TODO probably rename property
%             VCGen1.GroupName                    = 'Group';
%             VCGen1.MaxNumSimulations            = 2000;
%             VCGen1.MaxNumVirtualPatients        = 200;
%             VCGen1.SaveInvalid                   = 'all';
%             VCGen1.Method                        = 'Distribution';
%             VCGen1.TaskGroupItems = {...
%                 '10mg_ss_RuleOff', '10'; ...
%                 '40mg_ss_RuleOff', '40'; ...
%                 '150mg_ss_RuleOff', '150'; ...
%                 '300mg_ss_RuleOff', '300'; ...
%                 '600mg_ss_RuleOff', '600'; ...
%                 '800mg_ss_RuleOff', '800'; ...
%                 'StatinContinuous_ss_RuleOff', '9999'; ...
%                 };
%             VCGen1.SpeciesDataMapping = {...
%                 'PK', 'total_antipcsk9', 'x';...
%                 'TotalPCSK9', 'total_pcsk9', 'x';...
%                 'LDL', 'LDLch', 'x'}; % TODO
%             VCGen1.run()
%             %% 2.4. Virtual Population Generation
% 
%             % create target statistics
%             TS1 = Session.CreateTargetStatistics('vpopgen_data_mean_std'); % TODO
%             % TODOpax
% %             TS1.RelativeFilePath = 'TargetStatsFiles\Data_mean_std_vpop_gen_v2.xlsx';
%             TS1.RelativeFilePath = char(join(["TargetStatsFiles", "Data_mean_std_vpop_gen_v2.xlsx"], filesep));
% 
%             %I am supposed to rename the cohort generated from the previous step VirtualCohort_Generation_Results
%             Session.Settings.VirtualPopulation(3).Name = 'VirtualCohort_Generation_Results';
% 
%             % create task
%             T4 = Session.CreateTask('NoDose_ss_RuleOff');
%             T4.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
%             T4.ActivateVariants({'TMDD_calibration'}); % TODO
%             T4.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
%             T4.InactiveRuleNames = {'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}; %TODO  -- NEW
%             T4.OutputTimes = [0:1:100];  % TODO
%             T4.RunToSteadyState = true;
%             T4.TimeToSteadyState = 300;  % TODO -- NEW
% 
%             % virtual population generation
%             VPGen1 = Session.CreateVPopGen('VPopGen_baseline'); % TODO
%             VPGen1.VPopResultsFolderName        = 'VirtualPatientsResults'; % TODO Rename property?
%             VPGen1.VPopName                     = ''; % Session.Settings.VirtualPopulation(3).Name; % TODO: AG:; % TODO rename property "CohortName"
%             VPGen1.VpopGenDataName              = 'vpopgen_data_mean_std'; % TODO rename to TargetStatisticsName
%             VPGen1.GroupName                    = 'Group';
%             VPGen1.MinNumVirtualPatients        = 50;
%             VPGen1.RedistributeWeights          = true;
%             VPGen1.TaskGroupItems = {
%                 'NoDose_ss_RuleOff', '1'
%                 };
%             VPGen1.SpeciesDataMapping = {...
%                 'LDLch', 'LDLch', 'x'; ...
%                 'total_pcsk9', 'total_pcsk9', 'x'; ...
%                 }; % TODO see above
% 
%             % run
%             VPGen1.DatasetName = 'VirtualCohort_Generation_Results';
%             VPGen1.run()
%             %% 2.5. Simulation for model validation
% 
%             % create tasks
%             T5_1 = Session.CreateTask('validation_40mg');
%             T5_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
%             T5_1.ActivateVariants({'TMDD_calibration'}); % TODO
%             T5_1.AddDoses({'40mg_weeklydose_4x delay Model Validation'}); % TODO
%             T5_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
%             T5_1.InactiveRuleNames = {'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}; %TODO  -- NEW
%             T5_1.OutputTimes = [0:1:250];  % TODO
%             T5_1.RunToSteadyState = true;
%             T5_1.TimeToSteadyState = 300;  % TODO -- NEW
% 
% 
%             %replicate and edit dose for the other five  tasks
%             T5_2          = T5_1.Replicate(); % TODO
%             T5_2.Name     = 'validation_40mg_statin';
%             T5_2.AddDoses({'40mg_weeklydose_4x delay Model Validation', 'statin_5wk_afterPCSK9'});
% 
%             T5_3          = T5_1.Replicate(); % TODO
%             T5_3.Name     = 'validation_150mg';
%             T5_3.AddDoses({'150mg_weeklydose_2x delay Model Validation'});
% 
%             T5_4          = T5_1.Replicate(); % TODO
%             T5_4.Name     = 'validation_150mg_statin';
%             T5_4.AddDoses({'150mg_weeklydose_2x delay Model Validation', 'statin_2wk_afterPCSK9'});
% 
%             %I am supposed to rename the vpop generated from the previous step VirtualPopulation_Results
%             % AG: TODO
%             Session.Settings.VirtualPopulation(end).Name = 'VirtualPopulation_results';
% 
%             % create simulation
%             Sim2 = Session.CreateSimulation('Validation_Sim'); % TODO
%             Sim2.TaskVPopItems = {...
%                 'validation_40mg', 'VirtualPopulation_results', ''; ...
%                 'validation_40mg_statin', 'VirtualPopulation_results', ''; ...
%                 'validation_150mg', 'VirtualPopulation_results', ''; ...
%                 'validation_150mg_statin', 'VirtualPopulation_results', ''; ...
%                 }; % TODO
%             %run simulation
%             Sim2.run()
%             %% 2.6. Simulation for model prediction
% 
%             % create tasks
%             T6_1 = Session.CreateTask('prediction_400mg_Q4W');
%             T6_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
%             T6_1.ActivateVariants({'TMDD_calibration'}); % TODO
%             T6_1.AddDoses({'400mgQ4W anti-PCSK9'}); % TODO
%             T6_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
%             T6_1.InactiveRuleNames = {'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}; %TODO  -- NEW
%             T6_1.OutputTimes = [0:1:100];  % TODO
%             T6_1.RunToSteadyState = true;
%             T6_1.TimeToSteadyState = 300;  % TODO -- NEW
% 
%             %replicate and edit dose for the other five  tasks
%             T6_2          = T6_1.Replicate(); % TODO
%             T6_2.Name     = 'prediction_200mg_Q8W';
%             T6_2.AddDoses({'200mgQ8W anti-PCSK9'});
% 
%             T6_3          = T6_1.Replicate(); % TODO
%             T6_3.Name     = 'prediction_400mg_Q8W';
%             T6_3.AddDoses({'400mgQ8W anti-PCSK9'});
% 
%             T6_4          = T6_1.Replicate(); % TODO
%             T6_4.Name     = 'prediction_800mg_Q8W';
%             T6_4.AddDoses({'800mgQ8W anti-PCSK9'});
% 
%             % create simulation
%             Sim3 = Session.CreateSimulation('Prediction_Sim'); % TODO
%             Sim3.TaskVPopItems = {...
%                 'prediction_400mg_Q4W', 'VirtualPopulation_results', ''; ...
%                 'prediction_200mg_Q8W', 'VirtualPopulation_results', ''; ...
%                 'prediction_400mg_Q8W', 'VirtualPopulation_results', ''; ...
%                 'prediction_800mg_Q8W', 'VirtualPopulation_results', ''; ...
%                 }; % TODO
%             %run simulation
%             Sim3.run()
%         end
    end
end
