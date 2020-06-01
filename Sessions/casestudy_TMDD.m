
% create new session
session = QSP.Session();

% configure session
session.Name = 'CaseStudy1_TMDD';
session.RootDirectory = 'C:\Users\agajjala\sandbox\P7470_Genentech_QSP_Github_API\Sessions\CaseStudy_TMDD_AG\CaseStudy_TMDD_blank';
session.AutoSaveBeforeRun = true; 

% create task
T1 = session.CreateTask('A_3.0 mpk');

% configure
T1.SetProject('casestudy1_TMDD_template.sbproj'); % TODO
T1.SetModel('A_3.0 mpk'); % TODO
T1.ActivateVariants({'Ref values - treatment A - KD  = 0.4'}); % TODO AG: Was: {'Ref values ? treatment A ? KD = 0.4'}
T1.AddDoses({'3.0 mg/kg'}); % TODO AG: Was 3.0 mg/kg
T1.IncludeSpecies({'UnboundAbConc (mcg/ml)', 'FreeTarget (ng/ml)', 'TotalTarget (ng/ml)', 's_target_init'}); % TODO
T1.OutputTimes = 0:0.1:21;  % TODO
T1.RunToSteadyState = true;

% add/configure task 2
T2          = T1.Replicate(); % TODO
T2.Name     = 'A_0.3 mpk';
T2.AddDoses({'0.3 mg/kg'}); 

% add dataset

Dataset1 = session.CreateDataset('Data_mean'); % TODO
Dataset1.RelativeFilePath   = 'Data_mean.xlsx'; 
Dataset1.DatasetType        = 'wide';

% add parameter

Parameter1 = session.CreateParameter('Param_8'); % TODO
Parameter1.RelativeFilePath = 'Param_8.xlsx';

% add optimization
Optim1 = session.CreateOptimization('Optimization');
Optim1.AlgorithmName    = 'ScatterSearch';
Optim1.RefParamName     = 'Param_8';
Optim1.DatasetName      = 'Data_mean';
Optim1.GroupName        = 'Group';
Optim1.IDName           = 'ID';
Optim1.OptimizationItems = {...
    'A_3.0 mpk','1';...
    'A_0.3 mpk','2'...
    }; % TODO requires constructing a TaskGroup object (AG: Unnested, change SetOptim to Optim
Optim1.SpeciesDataMapping = {...
    'pk_free_ugm', 'UnboundAbConc (mcg/ml)'; ...
    'target_free_ngml', 'FreeTarget (ng/ml)'; ...
    'target_tot_ngml', 'TotalTarget (ng/ml)'...
    }; % TODO requires constructing SpeciesData object

% run optimization
Optim1.run()

% % change algorithm
% Optim1.AlgorithmName = 'ParticleSwarm'; % AG: Don't have this algorithm
% % run again
% Optim1.run()

% acceptance criteria
AC1 = session.CreateAcceptanceCriteria('AC_fixed_target'); % TODO
AC1.RelativeFilePath = 'AC_vpop_fixed_target.xlsx';

% cohort generation
VCGen1 = session.CreateVCohortGen('Cohort_fixed_target_1000'); % TODO
VCGen1.VPopResultsFolderName        = 'CohortGenerationResults'; % TODO maybe rename property for simplicity?
VCGen1.RefParamName                 = 'Param_8'; % TODO probably rename property
VCGen1.DatasetName                  = 'AC_fixed_target'; % TODO probably rename property
VCGen1.GroupName                    = 'Group';
VCGen1.MaxNumSimulations            = 5000;
VCGen1.MaxNumVirtualPatients        = 500; 
VCGen1.SaveInvalid                   = 'all'; % 'Save all virtual subjects'; % TODO probably simplify options to 'valid' and 'all'?
VCGen1.Method                        = 'Distribution';
VCGen1.TaskGroupItems = {...
    'A_3.0 mpk','1';...
    'A_0.3 mpk','2' ...
    }; % TODO
VCGen1.SpeciesDataMapping = {...
    'pk_free_ugm', 'UnboundAbConc (mcg/ml)'; ...
    'target_free_ngml', 'FreeTarget (ng/ml)'; ...
    'target_tot_ngml', 'TotalTarget (ng/ml)'...
    };% TODO see above
[StatusOK,Message,vpopObj] = VCGen1.run()
session.Settings.VirtualPopulation(end+1) = vpopObj; % Ask: Append method? (append for createVPopGen, otherwise there is an error that no cohort is specified)

% target statistics

TS1 = session.CreateTargetStatistics('Data_with_mean'); % TODO
TS1.RelativeFilePath = 'Data_mean_vpop_gen.xlsx';

% virtual population generation
VPGen1 = session.CreateVPopGen('VP_mean_data'); % TODO
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
    'pk_free_ugm', 'UnboundAbConc (mcg/ml)'; ...
    'target_free_ngml', 'FreeTarget (ng/ml)'; ...
    'target_tot_ngml', 'TotalTarget (ng/ml)' ...
    }; % TODO see above

% run
VPGen1.DatasetName = session.Settings.VirtualPopulation(1).Name; % AG: Added this but is it correct? Without this, it errors on Invalid dataset name specified for cohort

[StatusOK,Message,vpopObj2] = VPGen1.run()
session.Settings.VirtualPopulation(end+1) = vpopObj2;

% get name of the results produced from running the Vpop generation
vpopName = VPGen1.VPopName;


% task 3
T3                  = T1.Replicate();
T3.Name             = 'A_0.3 mpk_S';
T3.ActiveDoseNames  = {'0.3 mg/kg'};
T3.OutputTimes      = 0:0.1:49; % TODO

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
T6.ActiveDoseNames  = {'10 mg/kg_3'};
T6.OutputTimes      = 0:0.1:49;

% create simulation
Sim1 = session.CreateSimulation('Sim_Cohort_fixed_target_1000 VP'); % TODO
Sim1.DatasetName    = 'Data_mean';
Sim1.GroupName      = 'Group';


Sim1.TaskVPopItems = {...
    'A_0.3 mpk_S', vpopName, ''; ...
    'A_3 mpk_S', vpopName, ''; ...
    'A_1 mpk_M', vpopName, ''; ...
    'A_10 mpk_M', vpopName, '' ...
    }; % TODO

%run
Sim1.run()

% supplementary figures
Parameter2 = session.CreateParameter('Param_7');
Parameter2.RelativeFilePath = 'Param_7.xlsx';
	
% acceptance criteria
AC2 = session.CreateAcceptanceCriteria('AC_var_target');
AC2.RelativeFilePath = 'AC_vpop_var_target.xlsx';

VCGen2              = VCGen1.Replicate();
VCGen2.Name         = 'Cohort_variable_target_1000';
VCGen2.RefParamName = 'Param_7';
VCGen2.DatasetName  = 'AC_var_target';
VCGen2.TaskGroupItems = {
    'A_3.0 mpk','4'; ...
    'A_0.3 mpk','5'...
    };
VCGen2.ICFileName = 'Data_vpop_init_val.xlsx';
[StatusOK,Message,vpopObj3] = VCGen2.run()
session.Settings.VirtualPopulation(end+1) = vpopObj3;

vpopName2 = VCGen2.VPopName;

% sim 2

Sim2 = Sim1.Replicate();
Sim2.Name           = 'Sim_model_default';
Sim2.DatasetName    = 'Data_mean';
Sim2.GroupName      = 'Group';
Sim2.TaskVPopItems = {...
    'A_3.0 mpk', 'ModelDefault', ''; ... % AG: Model Default to ModelDefault: enum?
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









