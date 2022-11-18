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
    
    
    %% Properties
    properties
        AutoSaveFrequency = 1 % minutes
        AutoSaveBeforeRun = true
        AutoSaveSingleFile = false
        UseParallel = false
        ParallelCluster
        UseAutoSaveTimer = false

        RootDirectory = pwd
        ShowProgressBars = true % set false for CLI, testing
        
        AutoSaveGit = false
        GitRepo = '.git'                
        
        UseSQL = false
        experimentsDB = 'experiments.db3'        
        
        UseLogging = true
        LogFile = 'logfile.txt'
        
        LoggerSeverityDialog mlog.Level = mlog.Level.MESSAGE;
        LoggerSeverityFile mlog.Level = mlog.Level.INFO;
    end
    
	properties (Access=protected)
        % These properties need to  be (at least) protected in order for
        % copy to work.
        RelativeResultsPathParts = {''}
        RelativeUserDefinedFunctionsPathParts = {''}
        RelativeObjectiveFunctionsPathParts = {''}
        RelativePluginsPathParts = {''}
        RelativeAutoSavePathParts = {''}
        RelativeLoggerFilePathParts = {''}
    end
    
    properties (Dependent)
        % Dependent properties on *PathParts counter parts to ensure
        % portability between different OS.
        RelativeResultsPath
        RelativeUserDefinedFunctionsPath
        RelativeObjectiveFunctionsPath
        RelativePluginsPath
        RelativeAutoSavePath
        RelativeLoggerFilePath
        LoggerName
    end
    
    properties (Dependent=true, SetAccess=immutable)
        ResultsDirectory
        ObjectiveFunctionsDirectory
        UserDefinedFunctionsDirectory
        PluginsDirectory
        AutoSaveDirectory
        LoggerFile
        GitFiles
    end
    
    properties (Transient)        
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
        GlobalSensitivityAnalysis = QSP.GlobalSensitivityAnalysis.empty(1,0)
        Deleted = QSP.abstract.BaseProps.empty(1,0)
    end
    
    properties (SetAccess='private')
        SessionName = ''
        
        ColorMap1 = QSP.Session.DefaultColorMap
        ColorMap2 = QSP.Session.DefaultColorMap
        
        toRemove = false;
        
        SessionNameListener
    end
    
    properties (Constant=true)
        DefaultColorMap = repmat(lines(10),5,1)
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
            
            % Instantiate logger object
%             obj.LoggerObj = QSPViewerNew.Widgets.Logger(strcat(string(datetime('now', 'format', 'MMMddyyyyhhmm')), "_session"));
%             obj.updateLogger();
            
            % Provide Session handle to Settings
            obj.Settings.Session = obj;
            
            info = ver;
            if ismember('Parallel Computing Toolbox', {info.Name})
                clusters = parallel.clusterProfiles;
                obj.ParallelCluster = clusters{1};
            else
                obj.ParallelCluster = {''};
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
                   warning(err.identifier, 'Failed to close the log file.\n%s', err.message);
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
            
            if isa(s, 'QSP.Session')
                obj = s;
            else
                obj = QSP.Session;
                props = fields(s);
                invalidProps = {};
                for i = 1:numel(props)
                    try
                        obj.(props{i}) = s.(props{i});
                    catch
                        invalidProps = [invalidProps, props{i}];
                    end
                end
                if ~isempty(invalidProps)
                    warning('Unable to set properties %s.', strjoin(invalidProps, ','));
                end
            end
            
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
                % Pass in no UI here regardless of CLI or UI access. Part
                % of cleanup separating the model and the view.
                [StatusOK,Message] = refreshData(obj.Settings, false);
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
                'Plugins Directory',obj.PluginsDirectory;
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
                'Enable Checkpoints',mat2str(~obj.AutoSaveSingleFile);
                'AutoSave Frequency (min)',num2str(obj.AutoSaveFrequency);
                'AutoSave Before Run',mat2str(obj.AutoSaveBeforeRun);  
                'Logger File', obj.LoggerFile;
                'Logger Level (Dialog)', sprintf('%-7s', obj.LoggerSeverityDialog);
                'Logger Level (File)', sprintf('%-7s', obj.LoggerSeverityFile);
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
        
        function updateTimerObj(obj)
            if obj.UseAutoSaveTimer 
                if ~isempty(obj.timerObj) && isvalid(obj.timerObj)
                    if ~strcmpi(obj.timerObj.Running,'on')
                        start(obj.timerObj);
                    end
                else
                    obj.initializeTimer();
                end
            else
                if ~isempty(obj.timerObj) && isvalid(obj.timerObj)
                    if strcmpi(obj.timerObj.Running,'on')
                        stop(obj.timerObj);
                    end
                end
            end
        end
        
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
                
                newObj.RelativeResultsPathParts = obj.RelativeResultsPathParts;
                newObj.RelativeUserDefinedFunctionsPathParts = obj.RelativeUserDefinedFunctionsPathParts;
                newObj.RelativeObjectiveFunctionsPathParts = obj.RelativeObjectiveFunctionsPathParts;
                newObj.RelativePluginsPathParts = obj.RelativePluginsPathParts;
                newObj.RelativeAutoSavePathParts = obj.RelativeAutoSavePathParts;
                newObj.RelativeLoggerFilePathParts = obj.RelativeLoggerFilePathParts;
                
                newObj.AutoSaveSingleFile = obj.AutoSaveSingleFile;
                newObj.AutoSaveFrequency = obj.AutoSaveFrequency;
                newObj.AutoSaveBeforeRun = obj.AutoSaveBeforeRun;
                newObj.UseParallel = obj.UseParallel;
                newObj.ParallelCluster = obj.ParallelCluster;
                
                newObj.UseAutoSaveTimer = obj.UseAutoSaveTimer;
                
                newObj.LoggerSeverityDialog = obj.LoggerSeverityDialog;
                newObj.LoggerSeverityFile = obj.LoggerSeverityFile;
                
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
                
                newObj.GlobalSensitivityAnalysis = obj.GlobalSensitivityAnalysis;
                
                newObj.Deleted = obj.Deleted;
                
                for idx = 1:numel(obj.Settings.Task)
%                     sObj.Task(idx) = copy(obj.Settings.Task(idx));
                    sObj.Task(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulation)
%                     sObj.VirtualPopulation(idx) = copy(obj.Settings.VirtualPopulation(idx));
                    sObj.VirtualPopulation(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.Parameters)
%                     sObj.Parameters(idx) = copy(obj.Settings.Parameters(idx));
                    sObj.Parameters(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.OptimizationData)
%                     sObj.OptimizationData(idx) = copy(obj.Settings.OptimizationData(idx));
                    sObj.OptimizationData(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulationData)
%                     sObj.VirtualPopulationData(idx) = copy(obj.Settings.VirtualPopulationData(idx));
                    sObj.VirtualPopulationData(idx).Session = newObj;
                end
                for idx = 1:numel(obj.Settings.VirtualPopulationGenerationData)
%                     sObj.VirtualPopulationGenerationData(idx) = copy(obj.Settings.VirtualPopulationGenerationData(idx));
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
                
                for idx = 1:numel(obj.GlobalSensitivityAnalysis)
%                     newObj.CohortGeneration(idx) = copy(obj.CohortGeneration(idx));
                    newObj.GlobalSensitivityAnalysis(idx).Session = newObj;
                    newObj.GlobalSensitivityAnalysis(idx).Settings = sObj;
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
        
        % todopax replace with a set method so that all methods call this
        % function.
        function setSessionName(obj,SessionName)
            updateLoggerName(obj, SessionName)
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
                s.Session = obj; 
                % Remove .qsp.mat from name temporarily
                ThisName = regexprep(obj.SessionName,'\.qsp\.mat','');
                
                if ~obj.AutoSaveSingleFile
                    TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
                    if ~isempty(Tag)
                        FileName = sprintf('%s_%s_%s.qsp.mat',ThisName,TimeStamp,Tag);
                    else
                        FileName = sprintf('%s_%s.qsp.mat',ThisName,TimeStamp);
                    end
                else
                    FileName = sprintf('%s_autosave.qsp.mat', ThisName);
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
        
        function validateRulesAndReactions(obj)
            % loop over tasks
            for index = 1:length(obj.Settings.Task)
                % check if rules/reactions need to be converted to the new format
                if ~isempty(obj.Settings.Task(index).InactiveReactionNames) 
                    for ixReact = 1:length( obj.Settings.Task(index).InactiveReactionNames)
                        match = regexp( obj.Settings.Task(index).InactiveReactionNames(ixReact), '.*: .*');                        
%                         if ~contains( obj.Settings.Task(index).InactiveReactionNames(ixReact), '.*: .*') 
                        if ~isempty(match{1})
                            
                            MatchIdx = strcmp(obj.Settings.Task(index).ModelObj.ReactionNames, obj.Settings.Task(index).InactiveReactionNames(ixReact));
                            if nnz(MatchIdx) > 1
                                warning('Multiple reactions with same equation. Please update tasks before running')
                                continue
                            elseif ~any(MatchIdx)
                                warning('Invalid reactions detected:\n%s', obj.Settings.Task(index).InactiveReactionNames{ixReact})
                                continue
                            end
                            obj.Settings.Task(index).InactiveReactionNames(ixReact) = obj.Settings.Task(index).ReactionNames(MatchIdx);
                        end
                    end
                end       
                
                if ~isempty(obj.Settings.Task(index).InactiveRuleNames) 
                    for ixRule = 1:length( obj.Settings.Task(index).InactiveRuleNames)
                        match = regexp( obj.Settings.Task(index).InactiveRuleNames(ixRule), '.*: .*');
                        if ~isempty( match{1} ) % ~contains( obj.Settings.Task(index).InactiveRuleNames(ixRule), '.*: .*') 

                            MatchIdx = strcmp(obj.Settings.Task(index).ModelObj.RuleNames, obj.Settings.Task(index).InactiveRuleNames(ixRule));
                            if nnz(MatchIdx) > 1
                                warning('Multiple rules with same equation. Please update tasks before running')
                                continue
                            elseif ~any(MatchIdx)
                                warning('Invalid rules detected:\n%s', obj.Settings.Task(index).InactiveRuleNames{ixRule})
                                continue
                            end                            
                            obj.Settings.Task(index).InactiveRuleNames(ixRule) = obj.Settings.Task(index).RuleNames(MatchIdx);
                        end
                    end
                end             
                
            end
        end

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
                    if ismember(thisFile, unique({obj.Settings.VirtualPopulation.RelativeFilePath}) )
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
                   sbprojFiles = [sbprojFiles, strrep( m.RelativeFilePath, [rootDir filesep], '')];
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
                    warning(err.identifier, 'Could not open log file for writing.\n%s', err.message);
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
        
        function updateLogger(obj)
            loggerObj = QSPViewerNew.Widgets.Logger(obj.LoggerName);
            loggerObj.MessageReceivedEventThreshold = obj.LoggerSeverityDialog;
            loggerObj.FileThreshold = obj.LoggerSeverityFile;
        end
        
        function updateLoggerName(obj, newSessionName)
            loggerObj = QSPViewerNew.Widgets.Logger(obj.LoggerName);
            
            % check if logger exists in root directory
            moveLogFile(loggerObj, obj.RootDirectory); % moves log file if not present in root dir
            
            % check if current logger name is same as new session name
            [~,name,~] = fileparts(newSessionName);
            if contains(name, '.qsp')
                newLoggerName = extractBefore(name, ".qsp");
            else
                newLoggerName = name;
            end
            
            if ~isequal(newLoggerName, obj.LoggerName)
                rename(loggerObj, newLoggerName);
            end
        end
        
        function updateLoggerFileDir(obj)
            loggerObj = QSPViewerNew.Widgets.Logger(obj.LoggerName);
            
            % check if logger exists in root directory
            moveLogFile(loggerObj, obj.RootDirectory); % moves log file if not present in root dir
        end
        
    end %methods    
    
    %% Get/Set Methods
    methods
        function set.RootDirectory(obj, value)
            arguments 
                obj   (1,1) QSP.Session
                value (1,:) char
            end
            obj.RootDirectory = value;
%            obj.updateLoggerFileDir();
        end
        
        function set.RelativeResultsPath(obj, value)
            arguments 
                obj   (1,1) QSP.Session
                value (1,:) char
            end
            value = obj.updatePath(value);
            obj.RelativeResultsPathParts = strsplit(value, filesep);
        end
        function value = get.RelativeResultsPath(obj)
            value = fullfile(obj.RelativeResultsPathParts{:});
        end

        function set.RelativeUserDefinedFunctionsPath(obj, value)
            arguments 
                obj   (1,1) QSP.Session
                value (1,:) char
            end
            value = obj.updatePath(value);
            obj.RelativeUserDefinedFunctionsPathParts = strsplit(value, filesep);
        end
        function value = get.RelativeUserDefinedFunctionsPath(obj)
            value = fullfile(obj.RelativeUserDefinedFunctionsPathParts{:});
        end
        
        function set.RelativeObjectiveFunctionsPath(obj, value)
            arguments 
                obj   (1,1) QSP.Session
                value (1,:) char
            end
            value = obj.updatePath(value);
            obj.RelativeObjectiveFunctionsPathParts = strsplit(value, filesep);
        end
        function value = get.RelativeObjectiveFunctionsPath(obj)
            value = fullfile(obj.RelativeObjectiveFunctionsPathParts{:});
        end
        
        function set.RelativePluginsPath(obj, value)
            arguments 
                obj   (1,1) QSP.Session
                value (1,:) char
            end
            value = obj.updatePath(value);
            obj.RelativePluginsPathParts = strsplit(value, filesep);
        end
        function value = get.RelativePluginsPath(obj)
            value = fullfile(obj.RelativePluginsPathParts{:});
        end
        
        function set.RelativeAutoSavePath(obj, value)
            arguments 
                obj   (1,1) QSP.Session
                value (1,:) char
            end
            value = obj.updatePath(value);
            obj.RelativeAutoSavePathParts = strsplit(value, filesep);
        end
        function value = get.RelativeAutoSavePath(obj)
            value = fullfile(obj.RelativeAutoSavePathParts{:});
        end
        
        function value = get.RelativeLoggerFilePath(obj)
            value = fullfile(obj.RelativeLoggerFilePathParts{:});
        end
        
        function value = get.RelativeLoggerFilePathParts(obj)
            loggerObj = QSPViewerNew.Widgets.Logger(obj.LoggerName);
            [~,name,ext] = fileparts(loggerObj.LogFile);
            value = strcat(name,ext);
        end
        
        function value = get.LoggerName(obj)
            [~,name,~] = fileparts(obj.SessionName);
            if contains(name, '.qsp')
                value = extractBefore(name, ".qsp");
            else
                value = name;
            end
        end
         
        % TODOpax why do we need this
        function addUDF(obj)
            if false %TODOpax
            % add the UDF to the path
            p = path;
            if isempty(obj.RelativeUserDefinedFunctionsPath)
                % don't add anything unless UDF is defined
                return
            end
            
            UDF = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath);
            
            if exist(UDF, 'dir')
                if ~isempty(obj.RelativeUserDefinedFunctionsPath) && ~contains(p, UDF)
                    addpath(genpath(UDF))
                end
            end    
            end
        end
        
        function removeUDF(obj)
            % don't do anything if the session was empty (nothing selected)
            if isempty(obj)
                return
            end
                
            % don't do anything if the UDF is empty
            if isempty(obj.RelativeUserDefinedFunctionsPath)
                return
            end
            
            % remove UDF from the path
            
            p = path;
            try
                subdirs = genpath(uix.utility.getAbsoluteFilePath(obj.RelativeUserDefinedFunctionsPath, obj.RootDirectory));
            catch err
                warning(err.identifier, 'Unable to remove UDF from path\n%s', err.message);
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
            value = uix.utility.getAbsoluteFilePath(obj.RelativeResultsPath, obj.RootDirectory);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end
        end
        
        function value = get.ObjectiveFunctionsDirectory(obj)
            value = uix.utility.getAbsoluteFilePath(obj.RelativeObjectiveFunctionsPath, obj.RootDirectory);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.UserDefinedFunctionsDirectory(obj)
            value = uix.utility.getAbsoluteFilePath(obj.RelativeUserDefinedFunctionsPath, obj.RootDirectory);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.PluginsDirectory(obj)
            value = uix.utility.getAbsoluteFilePath(obj.RelativePluginsPath, obj.RootDirectory);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.AutoSaveDirectory(obj)
            value = uix.utility.getAbsoluteFilePath(obj.RelativeAutoSavePath, obj.RootDirectory);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.LoggerFile(obj)
            value = uix.utility.getAbsoluteFilePath(obj.RelativeLoggerFilePath, obj.RootDirectory);
            if ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function set.UseAutoSaveTimer(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.UseAutoSaveTimer = Value;
            obj.updateTimerObj();
        end
        
        function set.AutoSaveSingleFile(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.AutoSaveSingleFile = Value;
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
        
        function set.LoggerSeverityDialog(obj,Value)
            obj.LoggerSeverityDialog = Value;
            obj.updateLogger();
        end
        
        function set.LoggerSeverityFile(obj,Value)
            obj.LoggerSeverityFile = Value;
            obj.updateLogger();
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
                   allFiles = [allFiles, strrep( m.RelativeFilePath, [obj.RootDirectory filesep], '')];
                end
            end
            allFiles = unique(allFiles);
            
            files = allFiles;
            
            %% input files
            
            % virtual populations
            files = [files, unique({obj.Settings.VirtualPopulation.RelativeFilePath})];
            
            % parameters
            files = [files, unique({obj.Settings.Parameters.RelativeFilePath})];
            
            % data
            files = [files, unique({obj.Settings.OptimizationData.RelativeFilePath})];
            
            % acceptance criteria
            files = [files, unique({obj.Settings.VirtualPopulationData.RelativeFilePath})];
            
            % target statistics
            files = [files, unique({obj.Settings.VirtualPopulationGenerationData.RelativeFilePath})];
            
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
        
        function mObj = GetModelItem(obj, Name)
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

    end %methods
    
    %% API methods
    methods 
        function thisObj = GetTask(obj,Name)
            thisObj = obj.Settings.Task(strcmp({obj.Settings.Task.Name},Name));
        end %function
        
        function newObj = CreateDataset(obj,varargin)
            newObj = AddHelper(obj,'QSP.OptimizationData',varargin(:));
        end %function
        
        function thisObj = GetDataset(obj,Name)
            thisObj = obj.Settings.OptimizationData(strcmp({obj.Settings.OptimizationData.Name},Name));
        end %function
        
        function newObj = CreateParameter(obj,varargin)
            newObj = AddHelper(obj,'QSP.Parameters',varargin(:)); 
        end %function
        
        function thisObj = GetParameter(obj,Name)
            thisObj = obj.Settings.Parameters(strcmp({obj.Settings.Parameters.Name},Name));
        end %function
        
        function newObj = CreateOptimization(obj,varargin)
            newObj = AddHelper(obj,'QSP.Optimization',varargin(:));
        end %function
        
        function thisObj = GetOptimization(obj,Name)
            thisObj = obj.Optimization(strcmp({obj.Optimization.Name},Name));
        end %function
        
        function newObj = CreateAcceptanceCriteria(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulationData',varargin(:));
        end %function
        
        function thisObj = GetAcceptanceCriteria(obj,Name)
            thisObj = obj.VirtualPopulationData(strcmp({obj.VirtualPopulationData.Name},Name));
        end %function
        
        function newObj = CreateVirtualSubjects(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulation',varargin(:));
        end %function
        
        function thisObj = GetVirtualSubjects(obj,Name)
            thisObj = obj.Settings.VirtualPopulation(strcmp({obj.Settings.VirtualPopulation.Name},Name));
        end %function
        
        function newObj = CreateVCohortGen(obj,varargin)
            newObj = AddHelper(obj,'QSP.CohortGeneration',varargin(:));
        end %function
        
        function thisObj = GetCohortGeneration(obj,Name)
            thisObj = obj.CohortGeneration(strcmp({obj.CohortGeneration.Name},Name));
        end %function
        
        function newObj = CreateTargetStatistics(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulationGenerationData',varargin(:));        
        end %function
        
        function thisObj = GetTargetStatistics(obj,Name)
            thisObj = obj.Settings.VirtualPopulationGenerationData(strcmp({obj.Settings.VirtualPopulationGenerationData.Name},Name));
        end %function
        
        function newObj = CreateSimulation(obj,varargin)
            newObj = AddHelper(obj,'QSP.Simulation',varargin(:));
        end %function
        
        function thisObj = GetSimulation(obj,Name)
            thisObj = obj.Simulation(strcmp({obj.Simulation.Name},Name));
        end %function
        
        function newObj = CreateVPopGen(obj,varargin)
            newObj = AddHelper(obj,'QSP.VirtualPopulationGeneration',varargin(:));
        end %function
        
        function thisObj = GetVirtualPopulationGeneration(obj,Name)
            thisObj = obj.VirtualPopulationGeneration(strcmp({obj.VirtualPopulationGeneration.Name},Name));
        end %function
          
        function relativePath = getTaskRelativePath(obj, taskName)
            relativePath = '';
            
            idx = strcmp({obj.Settings.Task.Name}, taskName);
            if any(idx)
                relativePath = obj.Settings.Task(idx).ModelObj.RelativeFilePath;
            end
        end
        
    end

end %classdef
