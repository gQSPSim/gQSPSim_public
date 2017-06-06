classdef Session < matlab.mixin.SetGet & uix.mixin.AssignPVPairs & uix.mixin.HasTreeReference
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
        Settings = QSP.Settings.empty(1,0);
        Simulation = QSP.Simulation.empty(1,0)
        Optimization = QSP.Optimization.empty(1,0)
        VirtualPopulationGeneration = QSP.VirtualPopulationGeneration.empty(1,0)
        Deleted = QSP.abstract.BaseProps.empty(1,0)
        RootDirectory = pwd
        RelativeResultsPath = ''
        ColorMap1
        ColorMap2
    end
    
    properties (Dependent=true, SetAccess='immutable')
        ResultsDirectory
    end
    
    
    %% Constructor
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
        
    end %methods
    
    
    %% Static methods
    methods (Static=true)
        function obj = loadobj(s)
            
            obj = s;
            
            % Invoke refreshData
            refreshData(obj.Settings);
        end %function
        
    end %methods (Static)
    
    %% Methods
    methods
        function Colors = getItemColors(obj,NumItems)
            ThisColorMap = obj.ColorMap1;
            if ~isempty(ThisColorMap) && size(ThisColorMap,2) == 3
                Colors = uix.utility.getColorMap(ThisColorMap,NumItems);
            else
                % Default
                Colors = jet(NumItems);
            end
        end
            
        function Colors = getGroupColors(obj,NumGroups)
            ThisColorMap = obj.ColorMap2;
            if ~isempty(ThisColorMap) && size(ThisColorMap,2) == 3
                Colors = uix.utility.getColorMap(ThisColorMap,NumGroups);
            else
                % Default
                Colors = jet(NumGroups);
            end
        end
    end
    
    %% Get/Set Methods
    methods
      
        function set.RootDirectory(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RootDirectory = Value;
        end %function
        
        function value = get.ResultsDirectory(obj)
            value = fullfile(obj.RootDirectory, obj.RelativeResultsPath);
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
