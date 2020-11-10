classdef gQSPSimTester < QSPViewer.App
    properties
        originalWarningStates = struct('state', 'off', 'identifier', '');
    end
    
    methods
        function obj = gQSPSimTester(filename)            
            rootDirectory = fileparts(filename);
            % Suppress these warnings.
            obj.originalWarningStates(1) = warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            obj.originalWarningStates(2) = warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');
            
            sessionLoadedTF = obj.loadSessionFromFile(char(filename), false);
            assert(sessionLoadedTF == true);
            
            obj.Session.RootDirectory = char(rootDirectory);
            obj.Session.UseParallel = false;
            obj.Session.AutoSaveBeforeRun = false;
        end
        
        function delete(obj)
            % Restore warning states.
            for w = 1:numel(obj.originalWarningStates)                
                warning(obj.originalWarningStates(w).state, obj.originalWarningStates(w).identifier);
            end
            % Close all QSPApp instances.
            close all force
        end
        
        function testCase = runSimulations(obj, testCase)            
            for i = 1:numel(obj.Session.Simulation)
                simResultsFolder = string(obj.Session.Simulation(i).SimResultsFolderName);
                % TODO: If we can't supress the saving of the file keep this tmp directory. 
                % This enables us to cleanup after the test is run and keep results for failed 
                % tests.
                obj.Session.Simulation(i).SimResultsFolderName = 'tmp';
                                
                [statusOK, Message, ~, actualResults] = obj.Session.Simulation(i).run;
                
                testCase.onFailure(Message);
                testCase.verifyTrue(statusOK);
                
                for result_i = 1:numel(actualResults)
                    actual = actualResults{result_i};
                    
                    % optimize getting this directory listing. We don't have to do it everytime.
                    baselines = dir(obj.Session.RootDirectory + "/" + simResultsFolder);
                    baselineNames = string({baselines.name});                    
                    
                    actualResultsName = string(actual.FileNames); %Get the name we are looking for from the actual Results.                    
                    currentFile = actualResultsName.extractBefore("Date = ");
                    
                    expectedEntryTF = baselineNames.contains(currentFile);
                    expectedFile = baselines(expectedEntryTF);
                    if numel(expectedFile) > 1
                        warning("Found two possible baselines. Using first one found.");
                    end
                    expected = load(expectedFile(1).folder + "/" + expectedFile(1).name);
                    
                    if isfield(expected.Results, 'FileNames')
                        % Remove the names field for struct comparison purposes
                        expected.Results = rmfield(expected.Results, 'FileNames');                                            
                    end
                    
                    if isfield(actual, 'FileNames')
                        actual = rmfield(actual, 'FileNames');
                    end
                    
                    testCase.verifyEqual(actual, expected.Results, 'RelTol', 1e-3, 'AbsTol', 1e-4);
                    
                    % Cleanup TODO. If the test failed move the generated
                    % data to a failed directory to aid debugging. Else we
                    % delete the generated file.
                    % delete(actualName);
                end                
            end
        end
        
        function testCase = runCohortGeneration(obj, testCase)            
            for i = 1:numel(obj.Session.CohortGeneration)
                simResultsFolder = string(obj.Session.CohortGeneration(i).VPopResultsFolderName);
                % TODO: If we can't supress the saving of the file keep this tmp directory. 
                % This enables us to cleanup after the test is run and keep results for failed 
                % tests.
                obj.Session.CohortGeneration(i).VPopResultsFolderPath = 'tmp';
                                
                [statusOK, Message, vpopObj] = obj.Session.CohortGeneration(i).run;                
                
                testCase.onFailure(Message);
                testCase.verifyTrue(statusOK);                
            end
        end
        
        function testCase = runVirtualPopulationGeneration(obj, testCase)            
            for i = 1:numel(obj.Session.VirtualPopulationGeneration)
                simResultsFolder = string(obj.Session.VirtualPopulationGeneration(i).VPopResultsFolderName);
                % TODO: If we can't supress the saving of the file keep this tmp directory. 
                % This enables us to cleanup after the test is run and keep results for failed 
                % tests.
                %obj.Session.VirtualPopulationGeneration(i).VPopResultsFolderPath = 'tmp';
                                
                [statusOK, Message, vpopObj] = obj.Session.VirtualPopulationGeneration(i).run;                
                
                testCase.onFailure(Message);
                testCase.verifyTrue(statusOK);                
            end
        end

        function runOptimizations(obj, testCase)
            for i = 1:1 %numel(obj.Session.Optimization)
                resultsFolder = string(obj.Session.Optimization(i).OptimResultsFolderName);
                % TODO: If we can't supress the saving of the file keep this tmp directory. 
                % This enables us to cleanup after the test is run and keep results for failed 
                % tests.
                obj.Session.Optimization(i).OptimResultsFolderName = 'tmp';
                rng('default');
                                
                [statusOK, Message, ~, actualResults] = obj.Session.Optimization(i).run;
                
                
                %testCase.onFailure(Message);
                testCase.verifyTrue(statusOK);
                
                for result_i = 1:numel(actualResults)
                    actual = actualResults(result_i);
                    
                    actual.Results = cell2table(actual.Results(2:end,:), 'VariableNames', matlab.lang.makeValidName(actual.Results(1,:)));
                    
                    % optimize getting this directory listing. We don't have to do it everytime.
                    baselines = dir(obj.Session.RootDirectory + "/" + resultsFolder);
                    baselineNames = string({baselines.name});                    
                    
                    actualResultsName = string(actual.FileNames); %Get the name we are looking for from the actual Results.                    
                    currentFile = actualResultsName.extractBefore("Date = ");
                    
                    expectedEntryTF = baselineNames.contains(currentFile);
                    expectedFile = baselines(expectedEntryTF);
                    if numel(expectedFile) > 1
                        warning("Found two possible baselines. Using first one found.");
                    end
                    expected = readtable(expectedFile(1).folder + "/" + expectedFile(1).name);
                    %expected = load(expectedFile(1).folder + "/" + expectedFile(1).name);
                    
                    % Remove the names field for struct comparison purposes
                    actual = rmfield(actual, 'FileNames');
                    
                    expected.Properties.VariableDescriptions = {};
                    
                    testCase.verifyEqual(actual.Results, expected, 'RelTol', 1e-3, 'AbsTol', 1e-4);
                    
                    % Cleanup TODO. If the test failed move the generated
                    % data to a failed directory to aid debugging. Else we
                    % delete the generated file.
                    % delete(actualName);
                end    
            end
        end
    end
end