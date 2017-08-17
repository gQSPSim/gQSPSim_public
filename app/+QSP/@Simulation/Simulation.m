classdef Simulation < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Simulation - Defines a Simulation object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Simulation
    %
    % Syntax:
    %           obj = QSP.Simulation
    %           obj = QSP.Simulation('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Simulation Properties:
    %
    %
    % QSP.Simulation Methods:
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
        Settings = QSP.Settings.empty(0,1)
        SimResultsFolderName = 'SimResults' 
        
        DatasetName = '' % OptimizationData Name
        GroupName = ''
        
        Item = QSP.TaskVirtualPopulation.empty(0,1)
        
        PlotSpeciesTable = cell(0,2)
        PlotItemTable = cell(0,4)
        PlotDataTable = cell(0,2)
        PlotGroupTable = cell(0,3)
        
        SelectedPlotLayout = '1x1'
    end
    
    properties (SetAccess = 'private')
        SpeciesLineStyles
    end
    
    %% Constructor
    methods
        function obj = Simulation(varargin)
            % Simulation - Constructor for QSP.Simulation
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Simulation object.
            %
            % Syntax:
            %           obj = QSP.Simulation('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Simulation object
            %
            % Example:
            %    aObj = QSP.Simulation();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Simulation(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            if ~isempty(obj.Item)
                MATFileNames = {obj.Item.MATFileName};
                IsEmpty = cellfun(@isempty,MATFileNames);
                MATFileNames(IsEmpty) = {'Results: N/A'};
                SimulationItems = cellfun(@(x,y,z)sprintf('%s - %s (%s)',x,y,z),{obj.Item.TaskName},{obj.Item.VPopName},MATFileNames,'UniformOutput',false);
            else
                SimulationItems = {};
            end
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTime;
                'Description',obj.Description;
                'Results Path',obj.SimResultsFolderName;
                'Dataset',obj.DatasetName;       
                'Group Name',obj.GroupName;
                'Items',SimulationItems;
                };
            
        end %function
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = sprintf('Simulation: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            % Validate task-vpop pair is valid (TODO: AG: check that params in vpop exist in the file)
            if ~isempty(obj.Settings)
                
                % Check that Dataset (OptimizationData) is valid if it exists
                if ~isempty(obj.DatasetName) || ~strcmpi(obj.DatasetName,'Unspecified')
                    MatchIndex = strcmpi({obj.Settings.OptimizationData.Name},obj.DatasetName);
                    % Clear dataset name if it's invalid
                    if FlagRemoveInvalid && ~any(MatchIndex)
                        obj.DatasetName = '';
                    elseif ~FlagRemoveInvalid && any(MatchIndex)
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.OptimizationData(MatchIndex),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                end
                
                % Remove the invalid task/vpop combos if any
                [TaskItemIndex,MatchTaskIndex] = ismember({obj.Item.TaskName},{obj.Settings.Task.Name});
                [VPopItemIndex,MatchVPopIndex] = ismember({obj.Item.VPopName},{obj.Settings.VirtualPopulation.Name});
                RemoveIndices = ~TaskItemIndex | ~VPopItemIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Task-VPop rows %s are invalid.',num2str(find(RemoveIndices)));
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                if FlagRemoveInvalid
                    obj.Item(RemoveIndices) = [];
                end
                
                % Check Tasks                
                MatchTaskIndex(MatchTaskIndex == 0) = [];
                for index = MatchTaskIndex
                    [ThisStatusOK,ThisMessage] = validate(obj.Settings.Task(index),FlagRemoveInvalid);
                    if ~ThisStatusOK
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                end
                
                % Check VPops
                MatchVPopIndex(MatchVPopIndex == 0) = [];
                for index = MatchVPopIndex
                    [ThisStatusOK,ThisMessage] = validate(obj.Settings.VirtualPopulation(index),FlagRemoveInvalid);
                    if ~ThisStatusOK
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                end
            end
            
            % Check that the group column specified contains only integers 
            if ~isempty(obj.DatasetName)
                Names = {obj.Settings.OptimizationData.Name};
                MatchIdx = strcmpi(Names,obj.DatasetName);

                % Continue if dataset exists
                if any(MatchIdx)
                    % Get dataset
                    dObj = obj.Settings.OptimizationData(MatchIdx);      
                    DestDatasetType = 'wide';
                    [StatusOK,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
                    
                    if StatusOK
                        tmp = cell2mat(OptimData(:, strcmp(obj.GroupName, OptimHeader)));
                        if ~all(isnumeric(tmp) & floor(tmp) == tmp)
                            StatusOK = false;
                            Message = sprintf('%s\nSpecified group column contains invalid (non-integer) data.\n', Message);
                        end
                    else
                        Message = sprintf('%s\nCould not load dataset file.\n', Message);
                    end
                end
            end
    
        end %function
    end
    
    %% Methods    
    methods
        
        function [StatusOK,Message,vpopObj] = run(obj)
            
            % Unused for simulation
            vpopObj = QSP.VirtualPopulation.empty(0,1);
            
            % Invoke validate
            [StatusOK, Message] = validate(obj,false);
            
            % Invoke helper
            if StatusOK
                % Run helper
                [StatusOK,Message,ResultFileNames] = simulationRunHelper(obj);
                % Update MATFileName in the simulation items
                for index = 1:numel(obj.Item)
                    obj.Item(index).MATFileName = ResultFileNames{index};
                end
            end 
            
        end %function
        
        function updateSpeciesLineStyles(obj)
            ThisMap = obj.Settings.LineStyleMap;
            if ~isempty(ThisMap) && size(obj.PlotSpeciesTable,1) ~= numel(obj.SpeciesLineStyles)
                obj.SpeciesLineStyles = uix.utility.GetLineStyleMap(ThisMap,size(obj.PlotSpeciesTable,1)); % Number of species
            end
        end %function
        
        function setSpeciesLineStyles(obj,Index,NewLineStyle)
            NewLineStyle = validatestring(NewLineStyle,obj.Settings.LineStyleMap);
            obj.SpeciesLineStyles{Index} = NewLineStyle;
        end %function
        
    end %methods
    
    
    %% Set Methods
    methods
        
        function set.Settings(obj,Value)
            validateattributes(Value,{'QSP.Settings'},{'scalar'});
            obj.Settings = Value;
        end
        
        function set.SimResultsFolderName(obj,Value)
            validateattributes(Value,{'char'},{'row'});
            obj.SimResultsFolderName = Value;
        end
        
        function set.DatasetName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.DatasetName = Value;
        end
        
        function set.GroupName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.GroupName = Value;
        end
        
        function set.Item(obj,Value)
            validateattributes(Value,{'QSP.TaskVirtualPopulation'},{});
            obj.Item = Value;
        end
        
        function set.PlotSpeciesTable(obj,Value)
            validateattributes(Value,{'cell'},{});
            obj.PlotSpeciesTable = Value;
        end
        
        function set.PlotItemTable(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 4]});
            obj.PlotItemTable = Value;
        end
        
        function set.PlotDataTable(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 2]});
            obj.PlotDataTable = Value;
        end
        
        function set.PlotGroupTable(obj,Value)
            validateattributes(Value,{'cell'},{'size',[nan 3]});
            obj.PlotGroupTable = Value;
        end
        
    end %methods
    
end %classdef
