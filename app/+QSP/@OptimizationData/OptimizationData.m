classdef OptimizationData < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % OptimizationData - Defines a OptimizationData object
    % ---------------------------------------------------------------------
    % Abstract: This object defines OptimizationData
    %
    % Syntax:
    %           obj = QSP.OptimizationData
    %           obj = QSP.OptimizationData('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.OptimizationData Properties:
    %
    %
    % QSP.OptimizationData Methods:
    %
    %
    %
    
    % Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 322 $  $Date: 2016-09-11 23:01:33 -0400 (Sun, 11 Sep 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Public Properties
    properties
        DatasetType = 'wide'
    end
    
    %% Constructor
    methods
        function obj = OptimizationData(varargin)
            % OptimizationData - Constructor for QSP.OptimizationData
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.OptimizationData object.
            %
            % Syntax:
            %           obj = QSP.OptimizationData('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.OptimizationData object
            %
            % Example:
            %    aObj = QSP.OptimizationData();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = OptimizationData(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTime;
                'Description',obj.Description;
                'File name',obj.RelativeFilePath;                
                'Dataset Type',obj.DatasetType;
                };
        end
        
        function [StatusOK, Message,OptimHeader] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Optimization Data: %s\n%s\n',obj.Name,repmat('-',1,75));
            OptimHeader = {};
            
            if isdir(obj.FilePath) || ~exist(obj.FilePath,'file')
                StatusOK = false;
                Message = sprintf('%s\n* Optimization data file "%s" is invalid or does not exist',Message,obj.FilePath);
            else
                DestFormat = 'wide';
                % Import data
                [ThisStatusOk,ThisMessage,OptimHeader] = importData(obj,obj.FilePath,DestFormat);
                if ~ThisStatusOk
                    Message = sprintf('%s\n* Error loading data "%s". %s\n',Message,obj.FilePath,ThisMessage);
                end
            end
            
        end
    end
    
    %% Methods
    methods
        function [StatusOk,Message,Header,Data] = importData(obj,DataFilePath,varargin)            
            
            % Get destination format
            if nargin > 2 && islogical(varargin{1})
                DestDatasetType = varargin{1};
            else
                % Default
                DestDatasetType = 'wide';
            end
                
            % Defaults
            StatusOk = true;
            Message = '';
            
            try
                Table = readtable(DataFilePath);                
            catch ME
                Table = table;
                StatusOk = false;
                Message = sprintf('Unable to read from Excel file:\n\n%s',ME.message);
            end
            
            if ~isempty(Table)
                Header = Table.Properties.VariableNames;
                Data = table2cell(Table);
                
                % Convert between formats if needed
                if strcmpi(obj.DatasetType,'wide') && strcmpi(DestDatasetType,'tall')
                    % Wide -> Tall
                    
                    warning('Wide to tall conversion not implemented.')
                    
                elseif strcmpi(obj.DatasetType,'tall') && strcmpi(DestDatasetType,'wide')
                    % Tall -> Wide
                    
                    MatchSpecies = find(strcmpi(Header,'Species'));
                    MatchValue = find(strcmpi(Header,'Value'));
                    if numel(MatchSpecies) == 1 && numel(MatchValue) == 1
                        Table = unstack(Table,{'Value'},'Species');
                        
                        % Overwrite Header and Data
                        Header = Table.Properties.VariableNames;
                        Data = table2cell(Table);
                    else    
                        StatusOk = false;
                        Message = 'Header must contain ''Species'' and ''Value'' columns. Cannot convert from tall to wide format.';
                    end
                    
                end
            else
                Header = {};
                Data = {};
            end
            obj.FilePath = DataFilePath;
            
        end %function
        
    end
        
    %% Get/Set Methods
    methods
        
        function set.DatasetType(obj,Value)
            Value = validatestring(Value,{'wide','tall'});
            obj.DatasetType = Value;
        end
        
    end %methods
    
end %classdef
