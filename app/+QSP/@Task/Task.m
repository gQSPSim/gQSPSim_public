classdef Task < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Task - Defines a Task object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Task
    %
    % Syntax:
    %           obj = QSP.Task
    %           obj = QSP.Task('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Task Properties:
    %
    %   Study -
    %
    %   VirtualPopulation -
    %
    %   Parameters -
    %
    %   OptimizationData -
    %
    %   VirtualPopulationData -
    %
    % QSP.Task Methods:
    %
    %
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 299 $  $Date: 2016-09-06 17:18:29 -0400 (Tue, 06 Sep 2016) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        ActiveVariantNames = {}
        ActiveDoseNames = {}
        ActiveSpeciesNames = {}
        InactiveReactionNames = {}
        InactiveRuleNames = {}
        OutputTimesStr = ''
        MaxWallClockTime = 60
        RunToSteadyState = true
        TimeToSteadyState = 100
        Resample = true
    end
    
    %% Protected Properties
    properties (GetAccess=public, SetAccess=protected)
        ModelName
        ExportedModelTimeStamp 
        ExportedModel
        Species
        Parameters
    end
    
    %% Protected Transient Properties
    properties (GetAccess=public, SetAccess=protected, Transient = true)
        ModelObj
        VarModelObj
    end
    
    %% Dependent Properties
    properties(SetAccess=protected,Dependent=true)
        ConfigSet
        VariantNames
        DoseNames
        SpeciesNames
        ParameterNames
        ParameterValues
        ReactionNames
        RuleNames
        OutputTimes
        DefaultOutputTimes
        DefaultMaxWallClockTime        
    end
    
    %% Constructor
    methods
        function obj = Task(varargin)
            % Task - Constructor for QSP.Task
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Task object.
            %
            % Syntax:
            %           obj = QSP.Task('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Task object
            %
            % Example:
            %    aObj = QSP.Task();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            obj.ExportedModelTimeStamp = 0;
        end %function obj = Task(varargin)
        
        [t,x,names] = simulate(obj, varargin) % prototype
        

    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            if obj.RunToSteadyState
                RunToSteadyStateStr = 'yes';
                TimeToSteadyStateStr = num2str(obj.TimeToSteadyState);
            else
                RunToSteadyStateStr = 'no';
                TimeToSteadyStateStr = 'N/A';
            end
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTime;
                'Description',obj.Description;
                'Model',obj.RelativeFilePath;                
                'Active Variants',obj.ActiveVariantNames;
                'Active Doses',obj.ActiveDoseNames;
                'Active Species',obj.ActiveSpeciesNames;
                'Inactive Rules',obj.InactiveRuleNames;
                'Inactive Reactions',obj.InactiveReactionNames;
                'Output Times',obj.OutputTimesStr;
                'Run to Steady State',RunToSteadyStateStr;
                'Time to Steady State',TimeToSteadyStateStr;
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            FileInfo = dir(obj.FilePath);
            if ~isempty(FileInfo) && ~isempty(obj.ExportedModelTimeStamp) && (obj.ExportedModelTimeStamp > FileInfo.datenum) % built after the model file was saved
                StatusOK = true;
                Message = '';
                return
            end
            
            
            StatusOK = true;
            Message = sprintf('Task: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            % Import model
            MaxWallClockTime = obj.MaxWallClockTime;
%             thisObj = obj.copy();
            
            [ThisStatusOk,ThisMessage] = importModel(obj,obj.FilePath,obj.ModelName);
            thisObj.MaxWallClockTime = MaxWallClockTime; % override model defaults
            if ~ThisStatusOk
                Message = sprintf('%s\n* Error loading model "%s" in "%s". %s\n',Message,obj.ModelName,obj.FilePath,ThisMessage);
            end            
            
%             obj = thisObj;
            % Active Variants
            [InvalidActiveVariantNames,MatchIndex] = getInvalidActiveVariantNames(obj);
            if FlagRemoveInvalid
                obj.ActiveVariantNames(MatchIndex) = [];
            end
            
            % Active Doses
            [InvalidActiveDoseNames,MatchIndex] = getInvalidActiveDoseNames(obj);
            if FlagRemoveInvalid
                obj.ActiveDoseNames(MatchIndex) = [];
            end
            
            % Active Species
            [InvalidActiveSpeciesNames,MatchIndex] = getInvalidActiveSpeciesNames(obj);
            if FlagRemoveInvalid
                obj.ActiveSpeciesNames(MatchIndex) = [];
            end
            
            % Inactive Rules
            [InvalidInactiveRuleNames,MatchIndex] = getInvalidInactiveRuleNames(obj);
            if FlagRemoveInvalid
                obj.InactiveRuleNames(MatchIndex) = [];
            end
            
            % Inactive Reactions
            [InvalidInactiveReactionNames,MatchIndex] = getInvalidInactiveReactionNames(obj);
            if FlagRemoveInvalid
                obj.InactiveReactionNames(MatchIndex) = [];
            end
            
            % Check if any invalid components exist
            if ~isempty(InvalidActiveVariantNames) || ~isempty(InvalidActiveDoseNames) || ~isempty(InvalidActiveSpeciesNames) || ...
                    ~isempty(InvalidInactiveRuleNames) || ~isempty(InvalidInactiveReactionNames)
                StatusOK = false;
                Message = sprintf('%s\n* Invalid components exist in the task "%s".\n',Message,obj.Name);
            end
            
            % OutputTimes
            try
                if ~isnumeric(obj.OutputTimes) && ~isnumeric(eval(obj.OutputTimes))
                    StatusOK = false;
                    Message = sprintf('%s\n* Invalid OutputTimes. OutputTimes must be valid Matlab numeric vector.\n',Message);                
                elseif isempty(obj.OutputTimes)
                    StatusOK = false;
                    Message = sprintf('%s\n* Invalid OutputTimes. OutputTimes must not be empty.\n',Message);
                end
            
            catch
                StatusOK = false;
                Message = sprintf('%s\n* Invalid OutputTimes. OutputTimes must not be valid Matlab numeric vector.\n',Message);
            end            

            
            % MaxWallClockTime
            if obj.MaxWallClockTime == 0
                StatusOK = false;
                Message = sprintf('%s\n* Invalid MaxWallClockTime. MaxWallClockTime must be > 0.\n',Message);
            end
        end %function
        
        function clearData(obj)
            obj.ModelObj = [];
            obj.VarModelObj = [];
        end
    end
    
    %% Protected Methods
    methods (Access=protected)
        function copyProperty(obj,Property,Value)
            if isprop(obj,Property)
                obj.(Property) = Value;
            end
        end %function
        
        constructModel(obj)
        
        function upToDate = checkModelCurrent(obj)
            FileInfo = dir(obj.FilePath);
            if isempty(obj.ExportedModelTimeStamp) || FileInfo.datenum > obj.ExportedModelTimeStamp || datenum(obj.LastSavedTime) > obj.ExportedModelTimeStamp || ...
                    isempty(obj.VarModelObj)
                upToDate = false;
            else
                upToDate = true;
            end
        end
    end
    
   
    %% Methods
    methods
        function ModelNames = getModelList(obj)
            ModelNames = {};
            if ~isempty(obj.FilePath) && ~isdir(obj.FilePath) && exist(obj.FilePath,'file')
                try
                    AllModels = sbioloadproject(obj.FilePath);
                catch
                    AllModels = [];
                end     
                if ~isempty(AllModels) && isstruct(AllModels)
                    AllModels = cell2mat(struct2cell(AllModels));
                    m1 = sbioselect(AllModels,'type','sbiomodel');
                    if ~isempty(m1)
                        ModelNames = {m1.Name};
                    end
                end
            end
        end %function
        
        function [StatusOk,Message] = importModel(obj,ProjectPath,ModelName)
            
            % Defaults
            StatusOk = true;
            Message = '';
            warning('off', 'SimBiology:sbioloadproject:Version')
            
            % Store path
            obj.FilePath = ProjectPath;
            
            % Load project
            try
                AllModels = sbioloadproject(ProjectPath);
            catch ME
                StatusOk = false;
                Message = ME.message;
                obj.ModelObj = [];
                obj.ModelName = '';
                obj.MaxWallClockTime = [];
                obj.OutputTimesStr = '';
            end
            
            if StatusOk
                AllModels = cell2mat(struct2cell(AllModels));
                if ~isempty(ModelName)
                    m1 = sbioselect(AllModels,'Name',ModelName,'type','sbiomodel');
                else
                    m1 = sbioselect(AllModels,'type','sbiomodel');
                    if ~isempty(m1)
                        m1 = m1(1);
                        ModelName = m1.Name;
                    end
                end
                
                if isempty(m1)
                    StatusOk = false;
                    Message = sprintf('Model "%s" not found in project',ModelName);
                    obj.ModelObj = [];
                    obj.ModelName = '';
                    obj.MaxWallClockTime = [];
                    obj.OutputTimesStr = '';
                else
                    obj.ModelObj = m1;
                    obj.ModelName = ModelName;
                    obj.MaxWallClockTime = m1.ConfigSet.MaximumWallClock;
                    
                    if isempty(obj.OutputTimesStr)
                        % Use StopTime to compute
                        StopTime = obj.ConfigSet.StopTime;
                        % Update OutputTimesStr and actual value
                        obj.OutputTimesStr = sprintf('[0:%2f/100:%2f]',StopTime,StopTime);
                    end
                end %if
                
                % get inactive reactions from the model
                allReactionNames = get(obj.ModelObj.Reactions, 'Reaction');
                obj.InactiveReactionNames = allReactionNames(~cell2mat(get(obj.ModelObj.Reactions,'Active')));
                
                % get inactive rules from model
                allRulesNames = get(obj.ModelObj.Rules, 'Rule');
                obj.InactiveRuleNames = allRulesNames(~cell2mat(get(obj.ModelObj.Rules,'Active')));
                
%                 % get active variant names
%                 allVariantNames = get(obj.ModelObj.Variants, 'Name');
%                 obj.ActiveVariantNames = allVariantNames(cell2mat(get(obj.ModelObj.Variants,'Active')));
                
            end %if
        end %function
        
        function [Value,MatchIndex] = getInvalidActiveVariantNames(obj)
            MatchIndex = ~ismember(obj.ActiveVariantNames,obj.VariantNames);
            Value = obj.ActiveVariantNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidActiveDoseNames(obj)
            MatchIndex = ~ismember(obj.ActiveDoseNames,obj.DoseNames);
            Value = obj.ActiveDoseNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidActiveSpeciesNames(obj)
            MatchIndex = ~ismember(obj.ActiveSpeciesNames,obj.SpeciesNames);
            Value = obj.ActiveSpeciesNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidInactiveRuleNames(obj)
            MatchIndex = ~ismember(obj.InactiveRuleNames,obj.RuleNames);
            Value = obj.InactiveRuleNames(MatchIndex);
        end %function
        
        function [Value,MatchIndex] = getInvalidInactiveReactionNames(obj)
            MatchIndex = ~ismember(obj.InactiveReactionNames,obj.ReactionNames);
            Value = obj.InactiveReactionNames(MatchIndex);
        end %function
    end
    
    %% Get Methods
    methods
        
        function Value = get.ConfigSet(obj)
            if ~isempty(obj.ModelObj)
                Value = getconfigset(obj.ModelObj,'active');
            else
                Value = [];
            end
        end
        
        function Value = get.VariantNames(obj)
            if ~isempty(obj.ModelObj)
                Value = getvariant(obj.ModelObj);
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                end
            else
                Value = cell(0,1);
            end
        end % get.VariantNames
        
        function Value = get.DoseNames(obj)
            if ~isempty(obj.ModelObj)
                Value = getdose(obj.ModelObj);
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.DoseNames
        
        function Value = get.SpeciesNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Species;
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.SpeciesNames
        
        function Value = get.ParameterNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Parameters;
                Value = get(Value,'Name');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.ParameterNames       
        
        function Value = get.ParameterValues(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Parameters;
                Value = get(Value,'Value');
                if isempty(Value)
                    Value = cell(0,1);
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.ParameterNames          
        
        function Value = get.RuleNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Rules;
                Value = get(Value,'Rule');
                if isempty(Value)
                    Value = cell(0,1);                
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.RuleNames
        
        function Value = get.ReactionNames(obj)
            if ~isempty(obj.ModelObj)
                Value = obj.ModelObj.Reactions;
                Value = get(Value,'Reaction');
                if isempty(Value)
                    Value = cell(0,1);                
                elseif ischar(Value)
                    Value = {Value};
                end
            else
                Value = cell(0,1);
            end
        end % get.ReactionNames
        
        function Value = get.OutputTimes(obj)
            if isempty(obj.OutputTimesStr) && ~isempty(obj.ModelObj) && ~isempty(obj.ConfigSet)
                
                % Use StopTime to compute
                StopTime = obj.ConfigSet.StopTime;
                
                % Update OutputTimesStr and actual value
                obj.OutputTimesStr = sprintf('[0:%2f/100:%2f]',StopTime,StopTime);
                Value = 0:StopTime/100:StopTime;
                
            elseif isempty(obj.OutputTimesStr)
                % Use the default output times from the model if possible
                Value = obj.DefaultOutputTimes;
                
            else
                Value = evalin('base',obj.OutputTimesStr);
            end
            
        end % get.OutputTimes
        
        function Value = get.DefaultOutputTimes(obj)
            if ~isempty(obj.ModelObj) && ~isempty(obj.ConfigSet)
                Value = get(obj.ConfigSet.SolverOptions,'OutputTimes');
            else
                Value = [];
            end
        end % get.DefaultOutputTimes
        
        function Value = get.DefaultMaxWallClockTime(obj)
            if ~isempty(obj.ModelObj) && ~isempty(obj.ConfigSet)
                Value = obj.ConfigSet.MaximumWallClock;
            else
                Value = 60;
            end
        end % get.DefaultMaxWallClockTime
        
    end %methods
    
    %% Set Methods
    methods
        
        function set.ActiveVariantNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.ActiveVariantNames = Value;
        end % set.ActiveVariantNames
        
        function set.ActiveDoseNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.ActiveDoseNames = Value;
        end % set.ActiveDoseNames
        
        function set.ActiveSpeciesNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.ActiveSpeciesNames = Value;
        end % set.ActiveSpeciesNames
        
        function set.InactiveRuleNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.InactiveRuleNames = Value;
        end % set.InactiveRuleNames
        
        function set.InactiveReactionNames(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.InactiveReactionNames = Value;
        end % set.InactiveReactionNames
        
        function set.OutputTimesStr(obj,Value)
            validateattributes(Value,{'char'},{});
            validateattributes(str2num(Value),{'numeric'},{});
            obj.OutputTimesStr = Value;
        end % set.OutputTimesStr
        
        function set.MaxWallClockTime(obj,Value)
            if ~isempty(Value)
                validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'});
            end
            obj.MaxWallClockTime = Value;
        end % set.MaxWallClockTime
        
        function set.RunToSteadyState(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.RunToSteadyState = Value;
        end % set.RunToSteadyState
        
        function set.TimeToSteadyState(obj,Value)
            validateattributes(Value,{'numeric'},{'scalar','nonnegative','nonnan'});
            obj.TimeToSteadyState = Value;
        end % set.TimeToSteadyState
        
        function set.Resample(obj,Value)
            validateattributes(Value,{'logical'},{'scalar'});
            obj.Resample = Value;
        end % set.Resample
        
    end %methods
    
end %classdef
