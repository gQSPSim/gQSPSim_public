classdef Session < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
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
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        RootDirectory = pwd
        RelativeResultsPath = ''        
        RelativeUserDefinedFunctionsPath = ''
        RelativeObjectiveFunctionsPath = ''        
        RelativeAutoSavePath = ''
        AutoSaveFrequency = 1 % minutes
        AutoSaveBeforeRun = true
        
        Deleted = QSP.abstract.BaseProps.empty(1,0)
    end
    
    properties (Transient=true)
        UseAutoSave = false % Make transient so user always needs to toggle this true through Session node
    end
    
    properties (SetAccess='private')
        SessionName = ''
        AutoSaveID = 1
        
        Settings = QSP.Settings.empty(1,0);
        Simulation = QSP.Simulation.empty(1,0)
        Optimization = QSP.Optimization.empty(1,0)
        VirtualPopulationGeneration = QSP.VirtualPopulationGeneration.empty(1,0)
        CohortGeneration = QSP.CohortGeneration.empty(1,0)
        
        ColorMap1 = QSP.Session.DefaultColorMap
        ColorMap2 = QSP.Session.DefaultColorMap
        
        toRemove = false;
    end
    
    properties (Constant=true)
        DefaultColorMap = repmat(lines(10),5,1)
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
            
        end %function obj = Session(varargin)
        
        % Destructor
        function delete(obj)
           removeUDF(obj)            
        end
        
    end %methods
    
    
    %% Static methods
    methods (Static=true)
        function obj = loadobj(s)
            
            obj = s;
            
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
                'Use AutoSave',mat2str(obj.UseAutoSave);
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
    
    %% Methods
    methods
        
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
            p.addParameter('TimerObj',[]);
            
            p.parse(varargin{:});
            
            Tag = p.Results.Tag;
            timerObj = p.Results.TimerObj;

            if obj.UseAutoSave
                try
                    % Save when fired
                    s.Session = obj; %#ok<STRNU>
                    % Remove .qsp.mat from name temporarily
                    ThisName = regexprep(obj.SessionName,'\.qsp\.mat','');
                    TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
                    if ~isempty(Tag)
%                         FileName = sprintf('%05d_%s.mat',obj.AutoSaveID,Tag);
                        FileName = sprintf('%s_%s_%s.qsp.mat',ThisName,TimeStamp,Tag);
                    else
%                         FileName = sprintf('%05d.mat',obj.AutoSaveID);
                        FileName = sprintf('%s_%s.qsp.mat',ThisName,TimeStamp);
                    end
                    FilePath = fullfile(obj.AutoSaveDirectory,FileName);
                    obj.AutoSaveID = obj.AutoSaveID + 1;
                    save(FilePath,'-struct','s')
                catch err %#ok<NASGU>
                    warning('The file could not be auto-saved');  
                    if ~isempty(timerObj)
                        start(timerObj);
                    end
                end
            end
        end %function
        
    end %methods    
    
    %% Get/Set Methods
    methods
      
        function set.RootDirectory(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RootDirectory = fullfile(Value);
        end %function
        
        function set.RelativeResultsPath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeResultsPath = fullfile(Value);
        end %function
        
        function set.RelativeObjectiveFunctionsPath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeObjectiveFunctionsPath = fullfile(Value);
        end %function
        
        function set.RelativeUserDefinedFunctionsPath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeUserDefinedFunctionsPath = fullfile(Value);                
        end %function
        
        function set.RelativeAutoSavePath(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RelativeAutoSavePath = fullfile(Value);                
        end %function
        
        function addUDF(obj)
            % add the UDF to the path
            p = path;
            if exist(obj.UserDefinedFunctionsDirectory, 'dir')
                if ~isempty(obj.RelativeUserDefinedFunctionsPath) && ...
                        isempty(strfind(p,obj.RelativeUserDefinedFunctionsPath))
                    addpath(genpath(obj.UserDefinedFunctionsDirectory))
                end
            end    
        end
        
        function removeUDF(obj)
            % don't do anything if the session was empty (nothing selected)
            if isempty(obj)
                return
            end
                
            % remove UDF from the path
            if ~isempty(obj.RelativeUserDefinedFunctionsPath)
                rmpath(genpath(obj.UserDefinedFunctionsDirectory));
            end
        end
        
        function value = get.ResultsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeResultsPath);
        end
        
        function value = get.ObjectiveFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeObjectiveFunctionsPath);
        end
        
        function value = get.UserDefinedFunctionsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeUserDefinedFunctionsPath);
        end
        
        function value = get.AutoSaveDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeAutoSavePath);
        end
        
        function set.UseAutoSave(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.UseAutoSave = Value;
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
    
end %classdef
