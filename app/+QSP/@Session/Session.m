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
        ShowProgressBars = true % set false for CLI, testing
        
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
            if obj.UseParallel && ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end
        end
        
        function value = get.ObjectiveFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeObjectiveFunctionsPath_new);
            if obj.UseParallel && ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.UserDefinedFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath_new);
            if obj.UseParallel && ~isempty(getCurrentWorker)
                value = getAttachedFilesFolder(value);
            end            
        end
        
        function value = get.AutoSaveDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeAutoSavePath_new);
            if obj.UseParallel && ~isempty(getCurrentWorker)
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
        
       
        
    end %methods
       
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
        
        function thisObj = GetModelItem(obj, Name)
            MatchIdx = strcmp(Name, {obj.Settings.Model.ModelName});
            thisObj = [];
            if any(MatchIdx)
                thisObj = obj.Settings.Model(MatchIdx);
            else
                warning('Model %s not found in session', Name)
            end
        end
        
    end

end %classdef
