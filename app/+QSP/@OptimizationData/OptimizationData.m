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
    
    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 322 $  $Date: 2016-09-11 23:01:33 -0400 (Sun, 11 Sep 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Public Properties
    properties
        DatasetType = 'wide'
%         Headers = {};
%         Data = [];
    end
    
    properties (Access=private)
        Data
        Header        
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
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;
                'File Name',obj.RelativeFilePath_new;                
                'Dataset Type',obj.DatasetType;
                };
        end
        
        function [StatusOK, Message,OptimHeader] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Optimization Data: %s\n%s\n',obj.Name,repmat('-',1,75));
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end
            
            OptimHeader = {};
            
            if isdir(obj.FilePath) || ~exist(obj.FilePath,'file')
                StatusOK = false;
                Message = sprintf('%s\n* Optimization data file "%s" is invalid or does not exist',Message,obj.FilePath);
            else
                DestFormat = 'wide';
                % Import data
                [ThisStatusOk,ThisMessage,OptimHeader,OptimData] = importData(obj,obj.FilePath,DestFormat);
                if ~ThisStatusOk
                    Message = sprintf('%s\n* Error loading data "%s". %s\n',Message,obj.FilePath,ThisMessage);
                    StatusOK = false;
                end
                
                ixIgnore = strcmpi(OptimHeader, 'Species') | strcmpi(OptimHeader,'Exclude');
                try
                    data = cell2mat(OptimData(:,~ixIgnore));
                catch
                    Message = sprintf('%s\n* Optimization data contains invalid non-numeric data\n', Message);
                    StatusOK = false;
                end
                
                if ~all(ismember( {'GROUP','ID','TIME'}, upper(OptimHeader)))
                    Message = sprintf('%s\n* Optimization data must contain columns for Group, ID, and Time\n', Message);
                    StatusOK = false;
                end
                
%                 if ~all(isnumeric(OptimData(:,~ixSpecies)))
%                     Message = sprintf('%s\n* Optimization data contains invalid non-numeric data\n', Message);
%                     StatusOK = false;
%                 end
                
            end
            
        end
        
        function clearData(obj)
            obj.Data = {};
            obj.Header = {};
        end
    end
    
    %% Methods
    methods
        function [StatusOk,Message,Header,Data] = importData(obj,DataFilePath,varargin)            
            
            FileInfo = dir(DataFilePath);
            if ischar(obj.LastSavedTime)
                lastSavedTime = datenum(obj.LastSavedTime);
            else
                lastSavedTime = obj.LastSavedTime;
            end
            
            if ~isempty(lastSavedTime) && ~isempty(FileInfo) && ...
                    lastSavedTime > FileInfo.datenum && ...
                    ~isempty(obj.Data) && ~isempty(obj.Header)
                Header = obj.Header;
                Data = obj.Data;
                Message = '';
                StatusOk = true;
                return
            end
                
            
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
                opts = detectImportOptions(DataFilePath);
                opts.VariableTypes = repmat({'double'},1,numel(opts.VariableTypes)); % Force all columns to be numeric
                Table = readtable(DataFilePath,opts);                
            catch ME
                Table = table;
                StatusOk = false;
                Message = sprintf('Unable to read from Excel file:\n\n%s',ME.message);
            end
            
            if ~isempty(Table)
                Header = Table.Properties.VariableNames;
                
                excludeCol = strcmpi(Header,'Exclude');
                if any(excludeCol)
                    Table = Table(~strcmpi('Yes',Table{:,excludeCol}),~excludeCol);
                    Header = Header(~excludeCol);
                end
                
                weightsCol = strcmpi(Header,'Weight');
                if any(weightsCol)
                    Weights = Table(:,weightsCol);
                else
                    Weights = {};
                end                    
                
                Data = table2cell(Table);
                

                    
                % Convert between formats if needed
                if strcmpi(obj.DatasetType,'wide') && strcmpi(DestDatasetType,'tall')
                    % Wide -> Tall
                    
                    SpeciesCols = find(~ismember( upper(Header), {'GROUP','ID','TIME'}) );
                    Table = stack(Table, SpeciesCols, 'NewDataVariableName', 'Value', ...
                        'IndexVariableName', 'Species');                    
                    Header = Table.Properties.VariableNames;
                    Data = table2cell(Table);   
                    
                elseif strcmpi(obj.DatasetType,'tall') && strcmpi(DestDatasetType,'wide')
                    % Tall -> Wide
                    
                    allColNames = {'Group','ID','Time','Species','Value','Weight','Exclude'};
                    metadataCols = ~contains( Header, allColNames,'IgnoreCase', true);
                    
                    
                    MatchSpecies = find(strcmpi(Header,'Species'));
                    MatchValue = find(strcmpi(Header,'Value'));
                    if numel(MatchSpecies) == 1 && numel(MatchValue) == 1
                        Table = unstack(Table(:,~metadataCols),'Value','Species', 'AggregationFunction', @mean);
                        
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
            if StatusOk
                obj.LastSavedTime = now;
                obj.Data = Data;
                obj.Header = Header;
            end
        end %function
        
    end
        
    %% Get/Set Methods
    methods
        
        function set.DatasetType(obj,Value)
            Value = validatestring(Value,{'wide','tall'});
            obj.DatasetType = Value;
        end
        
%         function Headers = get.Headers(obj)
%             % check if the optimization data have changed since the last
%             % time
%             FileInfo = dir(obj.FilePath);
%             if isempty(obj.Headers) || datenum(obj.LastSavedTime) < datenum(FileInfo.date)
%                 % out of date -- reimport
%                 [~,~,obj.Headers,obj.Data] = importData(obj,obj.FilePath);
%             end
%             Headers = obj.Headers;
%             obj.LastSavedTime = now;
%         end
%         
%         function Data = get.Data(obj)
%             % check if the optimization data have changed since the last
%             % time
%             FileInfo = dir(obj.FilePath);
%             if isempty(obj.Data) || datenum(obj.LastSavedTime) < datenum(FileInfo.date)
%                 % out of date -- reimport
%                 [~,~,obj.Headers,obj.Data] = importData(obj,obj.FilePath);
%             end
%             Data = obj.Data;
%             obj.LastSavedTime = now;
%         end
%             
    end %methods
    
end %classdef
