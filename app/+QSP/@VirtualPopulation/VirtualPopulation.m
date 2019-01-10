classdef VirtualPopulation < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % VirtualPopulation - Defines a VirtualPopulation object
    % ---------------------------------------------------------------------
    % Abstract: This object defines VirtualPopulation
    %
    % Syntax:
    %           obj = QSP.VirtualPopulation
    %           obj = QSP.VirtualPopulation('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.VirtualPopulation Properties:
    %
    %
    % QSP.VirtualPopulation Methods:
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
    
    
    %% Protected Properties
    properties (Transient=true, GetAccess=public, SetAccess=protected)
        NumVirtualPatients = 0
        NumParameters = 0
        PrevalenceWeightsStr = 'no'
    end
    
    properties
        validationDateNum = 0;
        LastStatus = false;

        ShowTraces = false;
        ShowSEBar = true;    
    end
    
    %% Constructor
    methods
        function obj = VirtualPopulation(varargin)
            % VirtualPopulation - Constructor for QSP.VirtualPopulation
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.VirtualPopulation object.
            %
            % Syntax:
            %           obj = QSP.VirtualPopulation('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.VirtualPopulation object
            %
            % Example:
            %    aObj = QSP.VirtualPopulation();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = VirtualPopulation(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;
                'File name',obj.RelativeFilePath;                
                'No of virtual patients',obj.NumVirtualPatients;
                'No of parameters/species',obj.NumParameters;
                'Prevalence Weights',obj.PrevalenceWeightsStr;
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Virtual Population: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if isdir(obj.FilePath) || ~exist(obj.FilePath,'file')
                StatusOK = false;
                Message = sprintf('%s\n* Virtual Population file "%s" is invalid or does not exist',Message,obj.FilePath);
            else
                
                FileInfo = dir(obj.FilePath);
                if FileInfo.datenum > obj.validationDateNum
                    % has been modified since the last validation                    
                    % Import data
                    tic
                    fprintf('Importing data...')
                    [ThisStatusOk,ThisMessage] = importData(obj,obj.FilePath);
                    toc
                    if ~ThisStatusOk
                        Message = sprintf('%s\n* Error loading data "%s". %s\n',Message,obj.FilePath,ThisMessage);
                    end

                    obj.validationDateNum = now;
                    obj.LastStatus = ThisStatusOk;
                else
                    ThisStatusOk = obj.LastStatus;
                end
            end
            
            % NumVirtualPatients
            if obj.NumVirtualPatients == 0
                StatusOK = false;
                Message = sprintf('%s\n* Number of VirtualPatients in %s must not be 0',Message,obj.Name);
            end
            
            % NumParameters
            if obj.NumParameters == 0
                StatusOK = false;
                Message = sprintf('%s\n* Number of Parameters in %s must not be 0',Message,obj.Name);
            end
          
            % VPop name forbidden characters
            if any(regexp(obj.Name,'[:*?/]'))
                Message = sprintf('%s\n* Invalid virtual population name.', Message);
                StatusOK=false;
            end            
            
        end
        
        function clearData(obj)            
        end
        
    end
    
    %% Protected Methods
    methods (Access=protected)
        function copyProperty(obj,Property,Value)
            if isprop(obj,Property)
                obj.(Property) = Value;
            end
        end %function
    end
    
    %% Methods
    methods
        function [StatusOk,Message,Header,Data,PrevalenceWeights] = importData(obj,DataFilePath)            
            % Defaults
            StatusOk = true;
            Message = '';
            
            % Load from file
            try
%                 [~,~,Raw] = xlsread(DataFilePath);
                Raw = readtable(DataFilePath);
                Raw = [Raw.Properties.VariableNames;table2cell(Raw)];
            catch ME
                Raw = {};
                StatusOk = false;
                Message = sprintf('Unable to read from Excel file:\n\n%s',ME.message);
            end
            
            % Compute number of VirtualPopulation
            if size(Raw,1) > 1
                
                Header = Raw(1,:);
                Data = Raw(2:end,:);
                
                MatchPW = find(strcmpi(Header,'PWeight'));
                if ~isempty(MatchPW)
                    MatchPW = MatchPW(1);
                    PWWeights = cell2mat(Raw(2:end,MatchPW));
                    if abs(sum(PWWeights) - 1) < 1e-12
                        PrevalenceWeights = PWWeights;
                        obj.PrevalenceWeightsStr = 'yes';
                    else
                        warning(sprintf('Prevalence weights do not sum to 1. Ignorning prevalence weights for file %s',obj.Name)); %#ok<SPWRN>
                        PrevalenceWeights = zeros(0,1);
                        obj.PrevalenceWeightsStr = 'no';
                    end
                else
                    PrevalenceWeights = zeros(0,1);
                    obj.PrevalenceWeightsStr = 'no';
                end                
                obj.NumVirtualPatients = size(Raw,1)-1; % 1 header line
                obj.NumParameters = size(Raw,2)-numel(MatchPW);                
            else
                Header = {};
                Data = {};
                PrevalenceWeights = zeros(0,1);
                obj.PrevalenceWeightsStr = 'no';
                obj.NumVirtualPatients = 0;
                obj.NumParameters = 0;                
            end
            
            obj.FilePath = DataFilePath;           
            
        end %function
        
    end
    
end %classdef
