%% Case Study 2: PCSK9 Pseudocode
% Monica's comments
% - New in this case study: creating new virtual subject
% - New in this case study: adding Rule to deactivate in the functionality
% - I think it will be very useful if we can assign a string of filename for the output optimization result or cohort or vpop so that we can programmatically call it later on in the code


%% create new session
session = QSP.Session();

% configure session
session.Name = 'CaseStudy2_PCSK9';
session.RootDirectory = 'G:\My Drive\Monica_Workspace\gQSPSim_MES\API_Pseudocode\PCSK9';
session.AutoSaveBeforeRun = true; 

%% 2.1.Simulation to find time to steady state 

% create & configure task
T1 = session.CreateTask('No Dose');
T1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
T1.ActivateVariants({'TMDD_calibration'}); % TODO
T1.IncludeSpecies({'total_pcsk9', 'LDLch',}); % TODO
T1.OutputTimes = [0:1:1000];  % TODO
T1.RunToSteadyState = false;

% create virtual subject(s)
VS1 = session.CreateVirtualSubjects('VPOP_100VS_CheckSS');  % TODO -- NEW
VS1.RelativeFilePath = 'VPopFiles\VPOP_100Random_Check_SteadyState_range.xlsx';  % TODO -- NEW

% create simulation 
Sim1 = session.CreateSimulation('CheckSS'); % TODO
Sim1.SetItems({...
    {'No Dose', [], []} ...
    }); % TODO
%run simulation
Sim1.run()

%% 2.2. Parameter optimization

% create dataset 
Dataset_singledose = session.CreateDataset('data_allsingledose'); % TODO
Dataset_singledose.RelativeFilePath   = 'DataFiles\data_allsingledose.xlsx'; 
Dataset_singledose.DatasetType        = 'wide';

% create parameters
Parameter_optim = session.CreateParameter('Parameters for Optimization'); % TODO
Parameter_optim.RelativeFilePath = 'ParamFiles\Parameters_foroptim.xlsx ';

%create 6 tasks
%create the first one
T2_1 = session.CreateTask('10mg_ss');
T2_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
T2_1.ActivateVariants({'TMDD_calibration'}); % TODO
T2_1.AddDoses({'10mg anti-PCSK9 '}); % TODO
T2_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
T2_1.OutputTimes = [0:1:100];  % TODO
T2_1.RunToSteadyState = true;
T2_1.TimeToSteadyState = 300;  % TODO -- NEW

%replicate and edit dose for the rest of the tasks
T2_2          = T2_1.Replicate(); % TODO
T2_2.Name     = '40mg_ss';
T2_2.AddDoses({'40mg anti-PCSK9'}); 

T2_3          = T2_1.Replicate(); % TODO
T2_3.Name     = '150mg_ss';
T2_3.AddDoses({'150mg anti-PCSK9'}); 

T2_4          = T2_1.Replicate(); % TODO
T2_4.Name     = '300mg_ss';
T2_4.AddDoses({'300mg anti-PCSK9'}); 

T2_5          = T2_1.Replicate(); % TODO
T2_5.Name     = '600mg_ss';
T2_5.AddDoses({'600mg anti-PCSK9'}); 

T2_6          = T2_1.Replicate(); % TODO
T2_6.Name     = '800mg_ss';
T2_6.AddDoses({'800mg anti-PCSK9'}); 

% create optimization 
Optim1 = session.CreateOptimization('Optimization_singledose’');
Optim1.AlgorithmName    = 'ScatterSearch';
Optim1.RefParamName     = 'Parameters for Optimization';
Optim1.DatasetName      = 'data_allsingledose';
Optim1.GroupName        = 'Group';
Optim1.IDName           = 'ID';
Optim1.SetOptimizationItems( {{'10mg_ss', 1}, ...
                              {'40mg_ss', 2}, ...
                              {'150mg_ss', 3}, ...
                              {'300mg_ss', 4}, ...
                              {'600mg_ss', 5}, ...
                              {'800mg_ss', 6}, ...
                              } ); % TODO requires constructing a TaskGroup object
Optim1.SetSpeciesDataMapping( {...
    'PK', 'total_antipcsk9', ...
    'Totalpcsk9', 'total_pcsk9', ...
    'LDL', 'LDLch'}); % TODO requires constructing SpeciesData object

% run optimization
Optim1.run()


%% 2.3 Virtual Cohort Generation

% Create acceptance criteria
AC1 = session.CreateAcceptanceCriteria('AC_allsingledose');
AC1.RelativeFilePath = 'ACFiles\AC_alldose_v8.xlsx';

% create parameters
Parameter_cohortgen = session.CreateParameter('Parameters for Cohort Gen'); % TODO
Parameter_cohortgen.RelativeFilePath = 'ParamFiles\Parameters_forCohortGen.xlsx ';

%create 7 tasks
%create the first one
T3_1 = session.CreateTask('10mg_ss_RuleOff');
T3_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
T3_1.ActivateVariants({'TMDD_calibration'}); % TODO
T3_1.AddDoses({'10mg anti-PCSK9'}); % TODO
T3_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
T3_1.RulesToDeactivate({'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}); %TODO  -- NEW
T3_1.OutputTimes = [0:1:100];  % TODO
T3_1.RunToSteadyState = true;
T3_1.TimeToSteadyState = 300;  % TODO -- NEW


%replicate and edit dose for the other five  tasks
T3_2          = T3_1.Replicate(); % TODO
T3_2.Name     = '40mg_ss_RuleOff';
T3_2.AddDoses({'40mg anti-PCSK9'}); 

T3_3          = T3_1.Replicate(); % TODO
T3_3.Name     = '150mg_ss_RuleOff';
T3_3.AddDoses({'150mg anti-PCSK9'}); 

T3_4          = T3_1.Replicate(); % TODO
T3_4.Name     = '300mg_ss_RuleOff';
T3_4.AddDoses({'300mg anti-PCSK9'}); 

T3_5          = T3_1.Replicate(); % TODO
T3_5.Name     = '600mg_ss_RuleOff';
T3_5.AddDoses({'600mg anti-PCSK9'}); 

T3_6          = T3_1.Replicate(); % TODO
T3_6.Name     = '800mg_ss_RuleOff';
T3_6.AddDoses({'800mg anti-PCSK9'}); 

%create statin effect task 
T3_7          = T3_1.Replicate(); % TODO
T3_7.Name     = 'StatinContinuous_ss_RuleOff';
T3_7.AddDoses({'statin_continuous_dosing'}); 

% cohort generation
VCGen1 = session.CreateVCohortGen('CohortGen_SingleDose'); % TODO
VCGen1.VPopResultsFolderName        = 'VirtualPatientsResults'; % TODO maybe rename property for simplicity?
VCGen1.RefParamName                 = 'Parameters for Cohort Gen'; % TODO probably rename property
VCGen1.DatasetName                  = 'AC_allsingledose'; % TODO probably rename property
VCGen1.GroupName                    = 'Group';
VCGen1.MaxNumSimulations            = 2000;
VCGen1.MaxNumVirtualPatients        = 200; 
VCGen.SaveInvalid                   = 'Save valid virtual subjects'; % TODO probably simplify options to 'valid' and 'all'?
VCGen.Method                        = 'Distribution';
VCGen.SetItems( {{'10mg_ss_RuleOff', 1}, ...
                 {'40mg_ss_RuleOff', 2}, ...
                 {'150mg_ss_RuleOff', 3}, ...
                 {'300mg_ss_RuleOff', 4}, ...
                 {'600mg_ss_RuleOff', 5}, ...
                 {'800mg_ss_RuleOff', 6}, ...
                 {'StatinContinuous_ss_RuleOff', 7}, ...
                 } ); % TODO
VCGen.SetSpeciesDataMapping({...
    'PK', 'total_antipcsk9', ...
    'Totalpcsk9', 'total_pcsk9', ...
    'LDL', 'LDLch'}); % TODO 
VCGen1.run()

%% 2.4. Virtual Population Generation

% create target statistics
TS1 = session.CreateTargetStatistics('vpopgen_data_mean_std'); % TODO
TS1.RelativeFilePath = 'TargetStatsFiles\Data_mean_std_vpop_gen_v2.xlsx';

%I am supposed to rename the cohort generated from the previous step VirtualCohort_Generation_Results 

% create task 
T4 = session.CreateTask('NoDose_ss_RuleOff');
T4.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
T4.ActivateVariants({'TMDD_calibration'}); % TODO
T4.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
T4.RulesToDeactivate({'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}); %TODO  -- NEW
T4.OutputTimes = [0:1:100];  % TODO
T4.RunToSteadyState = true;
T4.TimeToSteadyState = 300;  % TODO -- NEW

% virtual population generation
VPGen1 = session.CreateVPopGen('VPopGen_baseline'); % TODO
VPGen1.VPopResultsFolderName        = 'VirtualPatientsResults'; % TODO Rename property?
VPGen1.VPopName                     = 'VirtualCohort_Generation_Results'; % TODO rename property "CohortName"
VPGen1.VpopGenDataName              = 'vpopgen_data_mean_std'; % TODO rename to TargetStatisticsName
VPGen1.GroupName                    = 'Group';
VPGen1.MinNumVirtualPatients        = 50;
VPGen1.RedistributeWeights          = true;
VPGen1.SetItems({[NoDose_ss_RuleOff, 1]});
VPGen1.SetSpeciesDataMapping({...
    'LDLch', 'LDLch', ...
    'total_pcsk9', 'total_pcsk9', ...
    }); % TODO see above

% run
VPGen1.run()

%% 2.5. Simulation for model validation

% create tasks 
T5_1 = session.CreateTask('validation_40mg');
T5_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
T5_1.ActivateVariants({'TMDD_calibration'}); % TODO
T5_1.AddDoses({'40mg_weeklydose_4x delay_Model_Validation'}); % TODO
T5_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
T5_1.RulesToDeactivate({'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}); %TODO  -- NEW
T5_1.OutputTimes = [0:1:250];  % TODO
T5_1.RunToSteadyState = true;
T5_1.TimeToSteadyState = 300;  % TODO -- NEW


%replicate and edit dose for the other five  tasks
T5_2          = T5_1.Replicate(); % TODO
T5_2.Name     = 'validation_40mg_statin';
T5_2.AddDoses({'40mg_weeklydose_4x delay_Model_Validation', 'statin_5wk_afterPCSK9'}); 

T5_3          = T5_1.Replicate(); % TODO
T5_3.Name     = 'validation_150mg';
T5_3.AddDoses({'150mg_weeklydose_2x delay_Model_Validation'}); 

T5_4          = T5_1.Replicate(); % TODO
T5_4.Name     = 'validation_150mg_statin';
T5_4.AddDoses({'150mg_weeklydose_2x delay_Model_Validation', 'statin_2wk_afterPCSK9'}); 

%I am supposed to rename the vpop generated from the previous step VirtualPopulation_Results 

% create simulation 
Sim2 = session.CreateSimulation('Validation_Sim'); % TODO
Sim2.SetItems({...
    {'validation_40mg', [], []} ...
    {'validation_40mg_statin', [], []} ...
    {'validation_150mg', [], []} ...
    {'validation_150mg_statin', [], []} ...
    }); % TODO
%run simulation
Sim2.run()



%% 2.6. Simulation for model prediction

% create tasks 
T6_1 = session.CreateTask('prediction_400mg_Q4W');
T6_1.SetProject('antiPCSK9_gadkar_v3.sbproj'); % TODO
T6_1.ActivateVariants({'TMDD_calibration'}); % TODO
T6_1.AddDoses({'400mgQ4W anti-PCSK9'}); % TODO
T6_1.IncludeSpecies({'total_antipcsk9', 'total_pcsk9', 'LDLch',}); % TODO
T6_1.RulesToDeactivate({'pcsk9SynthesisRate = circ_pcsk9*pcsk9ClearanceRate'}); %TODO  -- NEW
T6_1.OutputTimes = [0:1:100];  % TODO
T6_1.RunToSteadyState = true;
T6_1.TimeToSteadyState = 300;  % TODO -- NEW

%replicate and edit dose for the other five  tasks
T6_2          = T6_1.Replicate(); % TODO
T6_2.Name     = 'prediction_200mg_Q8W';
T6_2.AddDoses({'200mgQ8W anti-PCSK9'}); 

T6_3          = T6_1.Replicate(); % TODO
T6_3.Name     = 'prediction_400mg_Q8W';
T6_3.AddDoses({'400mgQ8W anti-PCSK9'}); 

T6_4          = T6_1.Replicate(); % TODO
T6_4.Name     = 'prediction_800mg_Q8W';
T6_4.AddDoses({'800mgQ8W anti-PCSK9'}); 

% create simulation 
Sim3 = session.CreateSimulation('Prediction_Sim'); % TODO
Sim3.SetItems({...
    {'prediction_400mg_Q4W', [], []} ...
    {'prediction_200mg_Q8W', [], []} ...
    {'prediction_400mg_Q8W', [], []} ...
    {'prediction_800mg_Q8W', [], []} ...
    }); % TODO
%run simulation
Sim3.run()
