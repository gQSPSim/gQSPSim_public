classdef Session < QSP.abstract.BasicBaseProps & uix.mixin.HasTreeReference
    % Session - Defines an session object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Session
    %
    % Syntax:
    %           obj = QSP.Session
    %           obj = QSP.Session('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Session Properties:
    %
    %   Settings - 
    %
    %   Simulation - 
    %
    %   Optimization - 
    %
    %   VirtualPopulationGeneration - 
    %
    %   RootDirectory -
    %
    %   ResultsDirectory -
    %
    %   RelativeResultsPath -
    %
    %   RelativeFunctionsPath -
    %
    % QSP.Session Methods:
    %
    %    
    %
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        RootDirectory = pwd
        AutoSaveFrequency = 1 % minutes
        AutoSaveBeforeRun = true
        UseParallel = false
        ParallelCluster
        UseAutoSaveTimer = false
        
        AutoSaveGit = false
        GitRepo = '.git'                
        
        UseSQL = false
        experimentsDB = 'experiments.db3'        
        
        UseLogging = true
        LogFile = 'logfile.txt'

        RelativeResultsPathParts = {}
        RelativeUserDefinedFunctionsPathParts = {}
        RelativeObjectiveFunctionsPathParts = {}
        RelativeAutoSavePathParts = {}
        
        % for backwards compatibility
        RelativeResultsPath = ''        
        RelativeUserDefinedFunctionsPath = ''
        RelativeObjectiveFunctionsPath = ''        
        RelativeAutoSavePath = ''  
        
    end
    
    properties (Transient=true)        
        timerObj
        dbid = []
        LogHandle = []
        
    end
    
    properties % (NonCopyable=true) % Note: These properties need to be public for tree
        Settings = QSP.Settings.empty(1,0);
        Simulation = QSP.Simulation.empty(1,0)
        Optimization = QSP.Optimization.empty(1,0)
        VirtualPopulationGeneration = QSP.VirtualPopulationGeneration.empty(1,0)
        CohortGeneration = QSP.CohortGeneration.empty(1,0)
        Deleted = QSP.abstract.BaseProps.empty(1,0)
    end
    
    properties (SetAccess='private')
        SessionName = ''
        
        ColorMap1 = QSP.Session.DefaultColorMap
        ColorMap2 = QSP.Session.DefaultColorMap
        
        toRemove = false;
    end
    
    properties (Constant=true)
        DefaultColorMap = repmat(lines(10),5,1)
    end
    
    properties (Dependent)
        RelativeResultsPath_new = ''        
        RelativeUserDefinedFunctionsPath_new = ''
        RelativeObjectiveFunctionsPath_new = ''        
        RelativeAutoSavePath_new = ''                
    end
        
    properties (Dependent=true, SetAccess='immutable')
        ResultsDirectory
        ObjectiveFunctionsDirectory
        UserDefinedFunctionsDirectory
        AutoSaveDirectory
        GitFiles
    end
    
    %% Constructor and Destructor
    methods
        function obj = Session(varargin)
            % Session - Constructor for QSP.Session
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Session object.
            %
            % Syntax:
            %           obj = QSP.Session('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Session object
            %
            % Example:
            %    aObj = QSP.Session();
            
            % Instantiate settings
            obj.Settings = QSP.Settings;
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Provide Session handle to Settings
            obj.Settings.Session = obj;
            
            info = ver;
            if ismember('Parallel Computing Toolbox', {info.Name})
                clusters = parallel.clusterProfiles;
                obj.ParallelCluster = clusters{1};
            else
                obj.ParallelCluster = {''};
            end
            
            % check if the new path fields need to be set from old
            % properties
            if ~isempty(obj.RelativeResultsPath)
                obj.RelativeResultsPath_new = obj.RelativeResultsPath;
                obj.RelativeResultsPath = [];                
            end
            
            if ~isempty(obj.RelativeUserDefinedFunctionsPath)
                obj.RelativeUserDefinedFunctionsPath_new = obj.RelativeUserDefinedFunctionsPath;
                obj.RelativeUserDefinedFunctionsPath = [];
            end
            
            if ~isempty(obj.RelativeObjectiveFunctionsPath)
                obj.RelativeObjectiveFunctionsPath_new = obj.RelativeObjectiveFunctionsPath;
                obj.RelativeObjectiveFunctionsPath = [];
            end
            
            if ~isempty(obj.RelativeAutoSavePath)
                obj.RelativeAutoSavePath_new = obj.RelativeAutoSavePath;
                obj.RelativeAutoSavePath = [];
            end
            
%             % Initialize timer - If you call initialize here, it will
%             enter a recursive loop. Do not call here. Instead, invoke
%             initializeTimer on the App side when new sessions are created
%             and call deleteTimer on the App side when sessions are closed
%             initializeTimer(obj);            
            
        end %function obj = Session(varargin)
        
        % Destructor
        function delete(obj)
            if ~isempty(obj.LogHandle) && obj.LogHandle > 0
                try
                    status = fclose(obj.LogHandle);
                catch err
                   warning('Failed to close the log file.\n%s', err.message)
                end

            end
        end
%         function delete(obj)
%             removeUDF(obj)             
%         end
        
    end %methods
    
    
    %% Static methods
    methods (Static=true)
        function obj = loadobj(s)
            
            obj = s;
            
            % check if the root directory does not exist
            % for example if running on a worker on a remote cluster
            % if that is the case then change the root directory
%             if ~exist(obj.RootDirectory,'dir')
%                 try
%                     newRoot = getAttachedFilesFolder(obj.RootDirectory);
%                     obj.OriginalRootDirectory = obj.RootDirectory;
%                 catch 
%                     newRoot = '';
%                 end
%                 
%                 if ~isempty(newRoot) 
%                     % working on remote machine                     
%                     obj.RootDirectory = newRoot;
%                     warning('Changed root directory to worker temp dir %s', newRoot)                 
%                     files = dir(newRoot);                   
%                     fprintf('Directory contents: %s\n', strjoin({files.name},'\n'));               
%                 end
%             end
            
            info = ver;
            if ~any(contains({info.Name},'Parallel Computing Toolbox'))
                obj.UseParallel = false; % disable parallel
            end
            % Invoke refreshData
            try 
                [StatusOK,Message] = refreshData(obj.Settings);
            catch err
                if strcmp(err.identifier, 'Settings:CancelledLoad')
                     % cancelled
                     obj.toRemove = true;
                else
                    rethrow(err)
                end
            end
            
            % run units script
            units

        end %function
        
    end %methods (Static)
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;       
                'Root Directory',obj.RootDirectory;
                'Objective Functions Directory',obj.ObjectiveFunctionsDirectory;
                'User Functions Directory',obj.UserDefinedFunctionsDirectory;
                'Enable Logging', mat2str(obj.UseLogging);
                'Log file', obj.LogFile;
                'Use Git Versioning', mat2str(obj.AutoSaveGit);
                'Git Repository Directory', obj.GitRepo;
                'Use SQLite DB', mat2str(obj.UseSQL);
                'SQLite DB file', obj.experimentsDB;
                'Use parallel toolbox', mat2str(logical(obj.UseParallel));
                'Parallel cluster', obj.ParallelCluster;
                'Use AutoSave',mat2str(obj.UseAutoSaveTimer);
                'AutoSave Directory',obj.AutoSaveDirectory;
                'AutoSave Frequency (min)',num2str(obj.AutoSaveFrequency);
                'AutoSave Before Run',mat2str(obj.AutoSaveBeforeRun);                
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Session: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if ~isfolder(obj.RootDirectory)
                StatusOK = false;
                Message = sprintf('%s\n* Invalid Root Directory specified "%"',Message,obj.RootDirectory);
            end
        end
        
        function clearData(obj) %#ok<MANU>
        end
    end
    
    
    %% Callback (non-standard)
    methods

        function onTimerCallback(obj,~,~)
            
            % Note, autosave is applied to vObj.Data, not vObj.TempData
            autoSaveFile(obj);
            
        end %function        
        
    end %methods
    
    %% Methods
    methods
        
        
        function initializeTimer(obj)
            
            % Delete timer
            deleteTimer(obj);
                
            % Create timer
            obj.timerObj = timer(...
                'ExecutionMode','fixedRate',...
                'BusyMode','drop',...
                'Tag','QSPtimer',...
                'Period',obj.AutoSaveFrequency*60,... % minutes
                'StartDelay',1,...
                'TimerFcn',@(h,e)onTimerCallback(obj,h,e));
            
            % Only start if UseAutoSave is true
            if obj.UseAutoSaveTimer
                start(obj.timerObj);
            end
            
        end %function
        
        function deleteTimer(obj)
            if ~isempty(obj.timerObj) && isvalid(obj.timerObj)
                if strcmpi(obj.timerObj.Running,'on')
                    stop(obj.timerObj);
                end
                delete(obj.timerObj);
                obj.timerObj = [];
            end
        end %function
        
        function newObj = copy(obj,varargin)
            % Note: copy actually is used in place of BaseProps copy
            
            if ~isempty(obj)
                
                % Copy basic properties
                newObj = QSP.Session;
                newObj.Name = obj.Name; % Do not copy name, as this changes the tree node
                newObj.SessionName = obj.SessionName; 
                newObj.Description = obj.Description;                
              
                newObj.RootDirectory = obj.RootDirectory;
                
                if ~isempty(obj.RelativeResultsPath)
                    if ispc
                        newPath = strrep(obj.RelativeResultsPath, '/', '\');
                    else
                        newPath = strrep(obj.RelativeResultsPath, '\', '/');
                    end
                    newObj.RelativeResultsPath_new = newPath;
                    
                else
                    newObj.RelativeResultsPath_new = obj.RelativeResultsPath_new;
                end
                
               if ~isempty(obj.RelativeUserDefinedFunctionsPath)
                    if ispc
                        newPath = strrep(obj.RelativeUserDefinedFunctionsPath, '/', '\');
                    else
                        newPath = strrep(obj.RelativeUserDefinedFunctionsPath, '\', '/');
                    end
                    newObj.RelativeUserDefinedFunctionsPath_new = newPath;
                else
                    newObj.RelativeUserDefinedFunctionsPath_new = obj.RelativeUserDefinedFunctionsPath_new;
                end
                
               if ~isempty(obj.RelativeObjectiveFunctionsPath)
                    if ispc
                        newPath = strrep(obj.RelativeObjectiveFunctionsPath, '/', '\');
                    else
                        newPath = strrep(obj.RelativeObjectiveFunctionsPath, '\', '/');
                    end
                    newObj.RelativeObjectiveFunctionsPath_new = newPath;
                else
                    newObj.RelativeObjectiveFunctionsPath_new = obj.RelativeObjectiveFunctionsPath_new;
               end

                if ~isempty(obj.RelativeAutoSavePath)
                    if ispc
                        newPath = strrep(obj.RelativeAutoSavePath, '/', '\');
                    else
                        newPath = strrep(obj.RelativeAutoSavePath, '\', '/');
                    end
                    newObj.RelativeAutoSavePath_new = newPath;
                else
                    newObj.RelativeAutoSavePath_new = obj.RelativeAutoSavePath_new;
                end                                               
                
                newObj.AutoSaveFrequency = obj.AutoSaveFrequency;
                newObj.AutoSaveBeforeRun = obj.AutoSaveBeforeRun;
                newObj.UseParallel = obj.UseParallel;
                newObj.ParallelCluster = obj.ParallelCluster;
                
                newObj.UseAutoSaveTimer = obj.UseAutoSaveTimer;
                
                newObj.UseLogging = obj.UseLogging;
                newObj.AutoSaveGit = obj.AutoSaveGit;
                newObj.GitRepo = obj.GitRepo;
                newObj.UseSQL = obj.UseSQL;
                
                newObj.LastSavedTime = obj.LastSavedTime;
                newObj.LastValidatedTime = obj.LastValidatedTime;
                
                newObj.TreeNode = obj.TreeNode;
                
                % Carry-over Settings object; just assign Session
                sObj = obj.Settings;                
                sObj.Session = newObj;
                
                newObj.Settings = sObj;
                SettingsItems = {'Task','VirtualPopulation','Parameters','OptimizationData','VirtualPopulationData','VirtualPopulationGenerationData','Model'};
                for idxType = 1:length(SettingsItems)
                    thisSetting = newObj.Settings.(SettingsItems{idxType});
                    for idxItem = 1:length(thisSetting)
                        if ~isempty(thisSetting(idxItem).RelativeFilePath)
                            if ispc
                                newPath = strrep(thisSetting(idxItem).RelativeFilePath, '/', '\');
                            else
                                newPath = strrep(thisSetting(idxItem).RelativeFilePath, '\', '/');
                            end

                            thisSetting(idxItem).RelativeFilePath_new = newPath;
                        end
                    end
                end
                                
                newObj.Simulation = obj.Simulation;
                for idxSimulation = 1:length(newObj.Simulation)
                    if ~isempty(newObj.Simulation(idxSimulation).SimResultsFolderName)
                            if ispc
                                newPath = strrep(newObj.Simulation(idxSimulation).SimResultsFolderName, '/', '\');
                            else
                                newPath = strrep(newObj.Simulation(idxSimulation).SimResultsFolderName, '\', '/');
                            end                        
                        newObj.Simulation(idxSimulation).SimResultsFolderName_new = newPath;
                    end
                end
                
                newObj.Optimization = obj.Optimization;
                for idxOptimization = 1:length(newObj.Optimization)
                    if ~isempty(newObj.Optimization(idxOptimization).OptimResultsFolderName)
                        if ispc
                            newPath = strrep(newObj.Optimization(idxOptimization).OptimResultsFolderName, '/', '\');
                        else
                            newPath = strrep(newObj.Optimization(idxOptimization).OptimResultsFolderName, '\', '/');
                        end     
                        newObj.Optimization(idxOptimization).OptimResultsFolderName_new = newPath;
                    end
                end
                
                newObj.VirtualPopulationGeneration = obj.VirtualPopulationGeneration;
                for idxVpop = 1:length(newObj.VirtualPopulationGeneration)
                    if ~isempty(newObj.VirtualPopulationGeneration(idxVpop).VPopResultsFolderName)
                        if ispc
                            newPath = strrep(newObj.VirtualPopulationGeneration(idxVpop).VPopResultsFolderName, '/', '\');
                        else
                            newPath = strrep(newObj.VirtualPopulationGeneration(idxVpop).VPopResultsFolderName, '\', '/');
                        end   
                        newObj.VirtualPopulationGeneration(idxVpop).VPopResultsFolderName_new = newPath;
                    end
                end
                
                newObj.CohortGeneration = obj.CohortGeneration;
                for idxCohort = 1:length(newObj.CohortGeneration)
                    if ~isempty(newObj.CohortGeneration(idxCohort).VPopResultsFolderName)
                        if ispc
                            newPath = strrep(newObj.CohortGeneration(idxCohort).VPopResultsFolderName, '/', '\');
                        else
                            newPath = strrep(newObj.CohortGeneration(idxCohort).VPopResultsFolderName, '\', '/');
                        end
                        newObj.CohortGeneration(idxCohort).VPopResultsFolderName_new = newPath;
                    end
                end
                
                newObj.Deleted = obj.Deleted;
                
                for idx = 1:numel(obj.Settings.Task)
%                     sObj.Task(idx) = copy(obj.Settings.Task(idx));
                    if ~isempty(sObj.Task(idx).RelativeFilePath)
                        if ispc
                            newPath = strrep(sObj.Task(idx).RelativeFilePath, '/', '\');
                        else
                            newPath = strrep(sObj.Task(idx).RelativeFilePath, '\', '/');
                        end
                        sObj.Task(idx).RelativeFilePath_new = newPath;
                        sObj.Task(idx).RelativeFilePath = [];
                    end
                    sObj.Task(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulation)
%                     sObj.VirtualPopulation(idx) = copy(obj.Settings.VirtualPopulation(idx));
                    if ~isempty(sObj.VirtualPopulation(idx).RelativeFilePath)
                        if ispc
                            newPath = strrep(sObj.VirtualPopulation(idx).RelativeFilePath, '/', '\');
                        else
                            newPath = strrep(sObj.VirtualPopulation(idx).RelativeFilePath, '\', '/');
                        end
                        sObj.VirtualPopulation(idx).RelativeFilePath_new = newPath;
                        sObj.VirtualPopulation(idx).RelativeFilePath = [];
                    end
                    sObj.VirtualPopulation(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.Parameters)
%                     sObj.Parameters(idx) = copy(obj.Settings.Parameters(idx));
                    if ~isempty(sObj.Parameters(idx).RelativeFilePath)
                        if ispc
                            newPath = strrep(sObj.Parameters(idx).RelativeFilePath, '/', '\');
                        else
                            newPath = strrep(sObj.Parameters(idx).RelativeFilePath, '\', '/');
                        end
                        sObj.Parameters(idx).RelativeFilePath_new = newPath;
                        sObj.Parameters(idx).RelativeFilePath = [];
                    end
                    sObj.Parameters(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.OptimizationData)
%                     sObj.OptimizationData(idx) = copy(obj.Settings.OptimizationData(idx));
                    if ~isempty(sObj.OptimizationData(idx).RelativeFilePath)
                        if ispc
                            newPath = strrep(sObj.OptimizationData(idx).RelativeFilePath, '/', '\');
                        else
                            newPath = strrep(sObj.OptimizationData(idx).RelativeFilePath, '\', '/');
                        end
                        sObj.OptimizationData(idx).RelativeFilePath_new = newPath;
                        sObj.OptimizationData(idx).RelativeFilePath = [];
                    end
                    sObj.OptimizationData(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulationData)
%                     sObj.VirtualPopulationData(idx) = copy(obj.Settings.VirtualPopulationData(idx));
                    if ~isempty(sObj.VirtualPopulationData(idx).RelativeFilePath)
                        if ispc
                            newPath = strrep(sObj.VirtualPopulationData(idx).RelativeFilePath, '/', '\');
                        else
                            newPath = strrep(sObj.VirtualPopulationData(idx).RelativeFilePath, '\', '/');
                        end
                        sObj.VirtualPopulationData(idx).RelativeFilePath_new = newPath;
                        sObj.VirtualPopulationData(idx).RelativeFilePath = [];
                    end
                    sObj.VirtualPopulationData(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulationGenerationData)
%                     sObj.VirtualPopulationGenerationData(idx) = copy(obj.Settings.VirtualPopulationGenerationData(idx));
                    if ~isempty(sObj.VirtualPopulationGenerationData(idx).RelativeFilePath)
                        if ispc
                            newPath = strrep(sObj.VirtualPopulationGenerationData(idx).RelativeFilePath, '/', '\');
                        else
                            newPath = strrep(sObj.VirtualPopulationGenerationData(idx).RelativeFilePath, '\', '/');
                        end
                        sObj.VirtualPopulationGenerationData(idx).RelativeFilePath_new = newPath;
                        sObj.VirtualPopulationGenerationData(idx).RelativeFilePath = [];
                    end
                    sObj.VirtualPopulationGenerationData(idx).Session = newObj;
                end
          
                % Get all BaseProps and if isprop(...,'QSP.Session)...
                for idx = 1:numel(obj.Simulation)
%                     newObj.Simulation(idx) = copy(obj.Simulation(idx));
                    newObj.Simulation(idx).Session = newObj;
                    newObj.Simulation(idx).Settings = sObj;
                end
                for idx = 1:numel(obj.Optimization)
%                     newObj.Optimization(idx) = copy(obj.Optimization(idx));
                    newObj.Optimization(idx).Session = newObj;
                    newObj.Optimization(idx).Settings = sObj;
                end
                for idx = 1:numel(obj.VirtualPopulationGeneration)
%                     newObj.VirtualPopulationGeneration(idx) = copy(obj.VirtualPopulationGeneration(idx));
                    newObj.VirtualPopulationGeneration(idx).Session = newObj;
                    newObj.VirtualPopulationGeneration(idx).Settings = sObj;
                end
                for idx = 1:numel(obj.CohortGeneration)
%                     newObj.CohortGeneration(idx) = copy(obj.CohortGeneration(idx));
                    newObj.CohortGeneration(idx).Session = newObj;
                    newObj.CohortGeneration(idx).Settings = sObj;
                end
             
                % TODO:
                for index = 1:numel(obj.Deleted)
%                     newObj.Deleted(index) = copy(obj.Deleted(index));
                    if isprop(newObj.Deleted(index),'Settings')
                        newObj.Deleted(index).Settings = sObj;
                    end
                    if isprop(newObj.Deleted(index),'Session')
                        newObj.Deleted(index).Session = newObj;
                    end
                end 
            end %if
            
        end %function
        
        function setSessionName(obj,SessionName)
            obj.SessionName = SessionName;
        end %function
        
        function Colors = getItemColors(obj,NumItems)
            ThisColorMap = obj.ColorMap1;
            if isempty(ThisColorMap) || size(ThisColorMap,2) ~= 3
                ThisColorMap = obj.DefaultColorMap;
            end
            if NumItems ~= 0
                Colors = uix.utility.getColorMap(ThisColorMap,NumItems);
            else
                Colors = [];
            end
        end %function
            
        function Colors = getGroupColors(obj,NumGroups)
            ThisColorMap = obj.ColorMap2;
            if isempty(ThisColorMap) || size(ThisColorMap,2) ~= 3
                ThisColorMap = obj.DefaultColorMap;
            end
            if NumGroups ~= 0
                Colors = uix.utility.getColorMap(ThisColorMap,NumGroups);
            else
                Colors = [];
            end
        end %function
        
        function autoSaveFile(obj,varargin)
            
            p = inputParser;
            p.KeepUnmatched = false;
            
            % Define defaults and requirements for each parameter
            p.addParameter('Tag',''); %#ok<*NVREPL>
            
            p.parse(varargin{:});
            
            Tag = p.Results.Tag;
            
            try
                % Save when fired
                s.Session = obj; %#ok<STRNU>
                % Remove .qsp.mat from name temporarily
                ThisName = regexprep(obj.SessionName,'\.qsp\.mat','');
                TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
                if ~isempty(Tag)
                    FileName = sprintf('%s_%s_%s.qsp.mat',ThisName,TimeStamp,Tag);
                else
                    FileName = sprintf('%s_%s.qsp.mat',ThisName,TimeStamp);
                end
                if ~exist(obj.AutoSaveDirectory, 'dir')
                    mkdir(obj.AutoSaveDirectory)
                    warning('Creating autosave directory %s', obj.AutoSaveDirectory)
                end
                FilePath = fullfile(obj.AutoSaveDirectory,FileName);
                save(FilePath,'-struct','s')
            catch err %#ok<NASGU>
                warning('The file could not be auto-saved');  
                if strcmpi(obj.timerObj.Running,'off')
                    start(obj.timerObj);
                end
            end
        end %function
        
        function addExperimentToDB(obj, type, Name, time, ResultFileNames)
            rootDir = regexprep(obj.RootDirectory, '\\$', '');
            
            commit = git(sprintf('-C "%s" --git-dir="%s" rev-parse HEAD', rootDir, fullfile(rootDir,obj.GitRepo)));
            cmd = sprintf('INSERT INTO Experiments VALUES ("%s", "%s", "%s", %f)', ...
                type, Name, commit, time);
            if isempty(obj.dbid)
%                 system(sprintf('touch "%s"', fullfile(rootDir, obj.experimentsDB)) );
                dbPath = fullfile(rootDir, obj.experimentsDB);
                fclose(fopen(dbPath,'w'));
                
                obj.dbid = mksqlite(0, 'open', dbPath, 'rw');
%                 obj.dbid = mksqlite('open', 'experiments.db3', 'rw');
                
                mksqlite(obj.dbid, 'create table if not exists EXPERIMENTS (Type TEXT, Item TEXT, GitCommit TEXT, Time INTEGER);')
                mksqlite(obj.dbid, 'create table if not exists RUNS (Experiment INTEGER, Files TEXT);')                
            end
            
            mksqlite( obj.dbid, cmd );
                       
            % add files
            id=mksqlite(obj.dbid, sprintf('select rowid from Experiments where Type="%s" and Item="%s" and GitCommit="%s" and Time=%f', ...
                type, Name, commit, time));
            if iscell(ResultFileNames)
                values=cellfun(@(s) sprintf('(%d, "%s")', id.rowid, s), ResultFileNames, 'UniformOutput', false);
                cmd = sprintf('INSERT INTO RUNS VALUES %s', strjoin(values, ','));
                
            else
                values = sprintf('(%d, "%s")', id.rowid, ResultFileNames);
                cmd = sprintf('INSERT INTO RUNS VALUES %s', values);
            end
            
            mksqlite(obj.dbid, cmd);
            
            
        end
        
        function gitCommit(obj)
            
            gitFiles = obj.GitFiles;
            tic
            
            rootDir = regexprep(obj.RootDirectory, '\\$', '');
            
            if ~exist(fullfile(rootDir, obj.GitRepo), 'dir')
                obj.Log('creating git repository')
                [repoPath,repo,~] = fileparts(obj.GitRepo);
                result = git(sprintf('init "%s"', fullfile(rootDir, fullfile(repoPath,repo))));
%                 if ~isempty(result)
%                     warning(result)
%                 end                
            end
                
            % get all the changes for each of the model files
            fileChanges = git(sprintf('-C "%s" --git-dir="%s" diff --name-only', ...
                rootDir, obj.GitRepo));
            fileChanges = strsplit(fileChanges,'\n');
            % add files
            for k=1:length(gitFiles)
                result = git(sprintf('-C "%s" --git-dir="%s" add "%s" ', rootDir, ...
                     obj.GitRepo, gitFiles{k}));
                if ~isempty(result)
                    warning(result)
                end                
            end
            
            diffMsg = '';

            
            % do some diffing on the excel files
            for k=1:length(fileChanges)
                thisFile = fileChanges{k};
                [~,~,ext] = fileparts(thisFile);
                if strcmp(ext,'.xlsx')
                    tmpFile = [tempname '.xlsx'];
                    tmpXlsx = git(sprintf('-C "%s" --git-dir="%s" show HEAD:"%s" > "%s" ', rootDir, ...
                        obj.GitRepo, thisFile, tmpFile));
                    
                    % check if this is a vpop
                    if ismember(thisFile, unique({obj.Settings.VirtualPopulation.RelativeFilePath_new}) )
                        type = 'vpop';
                    else
                        type = '';
                    end

                    
                    if isempty(type)
                        xlsMsg = xlsxDiff(fullfile(rootDir, thisFile), tmpFile);
                    else
                        xlsMsg = xlsxDiff(fullfile(rootDir, thisFile), tmpFile, type);
                    end
                    
                    diffMsg = sprintf('%s\n%s\n%s\n', diffMsg, thisFile, xlsMsg);
                        
                end
            end
            
            
            
            % update files that were already added for now. would be better
            % if this were only the files that are currently in the session
            result = git(sprintf('-C "%s" --git-dir="%s" add -u ', rootDir, ...
                obj.GitRepo));
            if ~isempty(result)
                warning(result)
            end                    

            % construct commit message
%             gitMessage = git(sprintf('-C "%s" diff', obj.Session.RootDirectory));

            
            % get model files
            objs = obj.Settings.Task;
            sbprojFiles = {};
            for ixObj = 1:length(objs)
                m = objs(ixObj).ModelObj;
                if ~isempty(m)
                   sbprojFiles = [sbprojFiles, strrep( m.RelativeFilePath_new, [rootDir filesep], '')];
                end
            end
            sbprojFiles = unique(sbprojFiles);
            sbprojFiles = intersect(sbprojFiles, fileChanges);
            
            for ixProj = 1:length(sbprojFiles)
                % pull out cached version for comparison
                tmpFile = [tempname '.sbproj'];
                
                git(sprintf('-C "%s" --git-dir="%s" show HEAD:"%s" > "%s"', ...
                    rootDir, obj.GitRepo, sbprojFiles{ixProj}, tmpFile ));
                m1 = sbioloadproject( tmpFile);
                m2 = sbioloadproject( fullfile(rootDir, sbprojFiles{ixProj}));
                evalc('thisMsg = sbprojDiff(m1.m1, m2.m1)'); % TODO handle case with multiple models
                diffMsg = [diffMsg, thisMsg]; 
            end
            
            gitMessage = [fileChanges, diffMsg];
            
            gitMessage = sprintf('Snapshot at %s\r\n\r\n%s', datestr(now), strjoin(gitMessage,'\r\n'));
          
            result = git(sprintf('-C "%s" --git-dir="%s" commit -m "%s"', rootDir, obj.GitRepo, ...
                gitMessage ));

            fprintf('[%s] Committed snapshot to git (%0.2f s)\n', datestr(now), toc);

            % TODO version control qsp session as well

%                     if ~isempty(result)
%                         warning(result)
%                     end               
            
            
        end
      
        function Log(obj,msg)
            if ~obj.UseLogging
                return
            end

            if isempty(obj.LogHandle)  
                try
                    obj.LogHandle = fopen(fullfile(obj.RootDirectory, obj.LogFile), 'a');
                catch err
                    warning('Could not open log file for writing.\n%s', err.message)
                    obj.LogHandle = -1;
                    return
                end       
            elseif obj.LogHandle == -1
                return
            end            

            try
                fprintf(obj.LogHandle, sprintf('[%s] %s\n', datestr(now), msg))  ;                      
            catch
                warning('Could not write to log file.' )
                obj.LogHandle = -1;
            end

        end
    
    end %methods    
    
    %% Get/Set Methods
    methods
      
        function set.RootDirectory(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RootDirectory = fullfile(Value);
        end %function
        
        function set.RelativeResultsPath_new(obj,Value)
            validateattributes(Value,{'char'},{});
%             obj.RelativeResultsPath = fullfile(Value);
            obj.RelativeResultsPathParts = strsplit(fullfile(Value), filesep);
        end %function\
        
        function Value=get.RelativeResultsPath_new(obj)
            Value = strjoin(obj.RelativeResultsPathParts, filesep);
        end
        
        function set.RelativeObjectiveFunctionsPath_new(obj,Value)
            validateattributes(Value,{'char'},{});
%             obj.RelativeObjectiveFunctionsPath = fullfile(Value);
            obj.RelativeObjectiveFunctionsPathParts = strsplit(fullfile(Value),filesep);
        end %function
        
        function Value = get.RelativeObjectiveFunctionsPath_new(obj)
            if ~isempty(obj.RelativeObjectiveFunctionsPathParts)
                Value = strjoin(obj.RelativeObjectiveFunctionsPathParts, filesep);
            else
                Value = '';
            end
        end
        
                
        function set.RelativeUserDefinedFunctionsPath_new(obj,Value)
            validateattributes(Value,{'char'},{});
%             obj.RelativeUserDefinedFunctionsPath = fullfile(Value);
            obj.RelativeUserDefinedFunctionsPathParts = strsplit(fullfile(Value), filesep);
        end %function
        
        function Value = get.RelativeUserDefinedFunctionsPath_new(obj)
            if ~isempty(obj.RelativeUserDefinedFunctionsPathParts)
                Value = strjoin(obj.RelativeUserDefinedFunctionsPathParts, filesep);
            else
                Value = '';
            end
                
        end
            
                
        function set.RelativeAutoSavePath_new(obj,Value)
            validateattributes(Value,{'char'},{});
%             obj.RelativeAutoSavePath = fullfile(Value);                
            obj.RelativeAutoSavePathParts = strsplit(fullfile(Value), filesep);           
        end %function
        
        function Value = get.RelativeAutoSavePath_new(obj)
            Value = strjoin(obj.RelativeAutoSavePathParts,filesep);
        end
        
        function addUDF(obj)
            % add the UDF to the path
            p = path;
            if isempty(obj.RelativeUserDefinedFunctionsPath_new)
                % don't add anything unless UDF is defined
                return
            end
            
            UDF = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath_new);
            
            if exist(UDF, 'dir')
                if ~isempty(obj.RelativeUserDefinedFunctionsPath_new) && ...
                	isempty(strfind(p, UDF))
                    addpath(genpath(UDF))
                end
            end    
        end
        
        function removeUDF(obj)
            % don't do anything if the session was empty (nothing selected)
            if isempty(obj)
                return
            end
                
            % don't do anything if the UDF is empty
            if isempty(obj.RelativeUserDefinedFunctionsPath_new)
                return
            end
            
            % remove UDF from the path
            
            p = path;
            try
                subdirs = genpath(fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath_new));
            catch err
                warning('Unable to remove UDF from path\n%s', err.message)
                return
            end
            if isempty(subdirs)
                return
            end
            
            if ispc
                subdirs = strsplit(subdirs,';');
                pp = strsplit(p,';');
            else
                subdirs = strsplit(subdirs,':');
                pp = strsplit(p,':');                
            end
            
            pp = setdiff(pp, subdirs);
            
            if ispc
                ppp = strjoin(pp,';');
            else
                ppp = strjoin(pp,':');
            end
            
            path(ppp)
        end
        
        function value = get.ResultsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeResultsPath_new);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end
        end
        
        function value = get.ObjectiveFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeObjectiveFunctionsPath_new);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.UserDefinedFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath_new);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.AutoSaveDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeAutoSavePath_new);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function set.UseAutoSaveTimer(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.UseAutoSaveTimer = Value;
        end
        
        function set.AutoSaveFrequency(obj,Value)
            validateattributes(Value,{'numeric'},{'positive'});
            obj.AutoSaveFrequency = Value;
        end
        
        function set.AutoSaveBeforeRun(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.AutoSaveBeforeRun = Value;
        end
        
        function set.ColorMap1(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.ColorMap1 = Value;
        end
        
        function set.ColorMap2(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.ColorMap2 = Value;
        end
        
        function files = get.GitFiles(obj)
            allFiles = {};

            % session
            allFiles = [allFiles, obj.SessionName];
            
            % model files
            files = {};
            objs = obj.Settings.Task;
            for ixObj = 1:length(objs)
                m = objs(ixObj).ModelObj;
                if ~isempty(m)
                   allFiles = [allFiles, strrep( m.RelativeFilePath_new, [obj.RootDirectory filesep], '')];
                end
            end
            allFiles = unique(allFiles);
            
            files = allFiles;
            
            %% input files
            
            % virtual populations
            files = [files, unique({obj.Settings.VirtualPopulation.RelativeFilePath_new})];
            
            % parameters
            files = [files, unique({obj.Settings.Parameters.RelativeFilePath_new})];
            
            % data
            files = [files, unique({obj.Settings.OptimizationData.RelativeFilePath_new})];
            
            % acceptance criteria
            files = [files, unique({obj.Settings.VirtualPopulationData.RelativeFilePath_new})];
            
            % target statistics
            files = [files, unique({obj.Settings.VirtualPopulationGenerationData.RelativeFilePath_new})];
            
            % Session
            
            % remove . for empty items
            files = setdiff(files, {'.','./','.\'});
            
        end
        
    end %methods
    
    %% Utility Methods
    methods
        function sObj = getSimulationItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Simulation.Name});
            sObj = [];
            if any(MatchIdx)
                sObj = obj.Simulation(MatchIdx);
            else
                warning('Simulation %s not found in session', Name)
	    end
	end
    end

    
    %% API methods - Helper
    methods (Access=private)
        function newObj = AddHelper(obj,FuncType,varargin)
            ThisFcn = str2func(FuncType);
            newObj = ThisFcn();
            updateLastSavedTime(newObj);
            
            Type = regexprep(FuncType,'QSP\.','');
            
            if isprop(obj.Settings,Type)
                AllNames = {obj.Settings.(Type).Name}; 
            else
                AllNames = {obj.(Type).Name};
            end
            
            if isprop(newObj,'Session')
                newObj.Session = obj;
            end
            
            if isprop(newObj,'Settings')
                newObj.Settings = obj.Settings;
            end
            
            if nargin > 2
                NewName = varargin{1};
                if iscell(NewName)
                    NewName = NewName{1};
                end
            else
                switch Type
                    case 'VirtualPopulationGenerationData'
                        NewName = 'New Target Statistics';
                    case 'VirtualPopulationData'
                        NewName = 'New Acceptance Criteria';
                    otherwise
                        NewName = sprintf('New %s',Type);
                end
            end
            
            newObj.Name =  matlab.lang.makeUniqueStrings(NewName,AllNames);
            
            if isprop(obj.Settings,Type)
                obj.Settings.(Type)(end+1) = newObj;
            else
                obj.(Type)(end+1) = newObj;
            end
        end %function
    end %methods (private)
    
    
    %% API methods
    methods 
        function newObj = CreateTask(obj,varargin)
            newObj = AddHelper(obj,'QSP.Task',varargin(:));
        end %function
        
        function sObj = getVPopItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.VirtualPopulation.Name});
            sObj = [];
            if any(MatchIdx)
                sObj = obj.Settings.VirtualPopulation(MatchIdx);
            else
                warning('Virtual subjects %s not found in session', Name)
            end
        end        
        
        function sObj = getTaskItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.Task.Name});
            sObj = [];
            if any(MatchIdx)
                sObj = obj.Settings.Task(MatchIdx);
            else
                warning('Task %s not found in session', Name)
            end            
        end
        
        function mObj = getModelItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.Model.ModelName});
            mObj = [];
            if any(MatchIdx)
                mObj = obj.Settings.Model(MatchIdx);
            else
                warning('Model %s not found in session', Name)
            end            
        end        
        
            
        function sObj = getACItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.VirtualPopulationData.Name});
            sObj = [];
            if any(MatchIdx)
                sObj = obj.Settings.VirtualPopulationData(MatchIdx);
            else
                warning('Acceptance Criteria %s not found in session', Name)
            end
        end           
        
        function sObj = getDataItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.OptimizationData.Name});
            sObj = [];
            if any(MatchIdx)
                sObj = obj.Settings.OptimizationData(MatchIdx);
            else
                warning('Optimization Data %s not found in session', Name)
            end            
        end
        
        function sObj = getParametersItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.Parameters.Name});
            sObj = [];
            if any(MatchIdx)
                sObj = obj.Settings.Parameters(MatchIdx);
            else
                warning('Parameter %s not found in session', Name)
            end            
        end
  
        function relativePath = getTaskRelativePath(obj, taskName)
            relativePath = '';
            
            idx = strcmp({obj.Settings.Task.Name}, taskName);
            if any(idx)
                relativePath = obj.Settings.Task(idx).ModelObj.RelativeFilePath_new;
            end
        end         
	
	function newObj = CreateDataset(obj,varargin)
            newObj = AddHelper(obj,'QSP.OptimizationData',varargin(:));
        end %function
        
        function newObj = CreateParameter(obj,varargin)
            newObj = AddHelper(obj,'QSP.Parameters',varargin(:)); 
        end %function
        
        function newObj = CreateOptimization(obj,varargin)
            newObj = AddHelper(obj,'QSP.Optimization',varargin(:));
        end %function
        
        function newObj = CreateAcceptanceCriteria(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulationData',varargin(:));
        end %function
        
        function newObj = CreateVCohortGen(obj,varargin)
            newObj = AddHelper(obj,'QSP.CohortGeneration',varargin(:));
        end %function
        
        function newObj = CreateTargetStatistics(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulationGenerationData',varargin(:));        
        end %function
        
        function newObj = CreateSimulation(obj,varargin)
            newObj = AddHelper(obj,'QSP.Simulation',varargin(:));
        end %function
        
        function newObj = CreateVPopGen(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulationGeneration',varargin(:));
        end %function
    end
    
end %classdef
