classdef gQSPSimTester < QSPViewer.App
    properties
        originalWarningStates = struct('state', 'off', 'identifier', '');
    end
    
    methods
        function obj = gQSPSimTester(filename)            
            rootDirectory = fileparts(filename);
            % Suppress some warnings.
            obj.originalWarningStates(1) = warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
            obj.originalWarningStates(2) = warning('off', 'MATLAB:ui:javacomponent:FunctionToBeRemoved');
            
            sessionLoadedTF = obj.loadSessionFromFile(filename, false);
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
                % TODO: If we can't supress the saving of the file the keep
                % this tmp directory. This enables us to clean after the
                % test is run.
                obj.Session.Simulation(i).SimResultsFolderName = 'tmp';
                
                [a, e] = obj.Session.Simulation(i).run;
                
                % This assumes an empty "current" directory for output. So
                % any new files found here are those generated by the
                % Simulation and are used for comparison. If there is a
                % failure the actual files that fail are copied into a
                % failed directory in order to facilitate debugging.
                p = string(obj.Session.RootDirectory) + "/tmp";
                d = dir(p + "/*.mat");
                for result_i = 1:numel(d)
                    actualName = [d(result_i).folder, '/', d(result_i).name];
                    
                    actual = load(actualName);
                    
                    % optimize getting this directory listing..
                    expectedResults = dir(obj.Session.RootDirectory + "/" + simResultsFolder);
                    expectedFileNames = string({expectedResults.name});
                    currentFile = string(d(result_i).name);
                    currentFile = currentFile.extractBefore("Date = ");
                    
                    expectedEntryTF = expectedFileNames.contains(currentFile);
                    expectedFile = expectedResults(expectedEntryTF);
                    if numel(expectedFile) > 1
                        warning("Found two possible baselines. Using first one found.");
                    end
                    expected = load(expectedFile(1).folder + "/" + expectedFile(1).name);
                    
                    testCase.verifyEqual(actual, expected, 'RelTol', 1e-3, 'AbsTol', 1e-4);
                    
                    % Cleanup TODO. If the test failed move the generated
                    % data to a failed directory to aid debugging. Else we
                    % delete the generated file.
                    delete(actualName);
                end
            end
        end
        
        function runOptimizations(obj)
            for i = 1:numel(obj.Session.Optimization)
                [a, e] = obj.Session.Optimization(i);
            end
        end
    end
end