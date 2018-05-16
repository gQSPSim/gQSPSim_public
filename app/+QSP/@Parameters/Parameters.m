classdef Parameters < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Parameters - Defines a Parameters object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Parameters
    %
    % Syntax:
    %           obj = QSP.Parameters
    %           obj = QSP.Parameters('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Parameters Properties:
    %
    %
    % QSP.Parameters Methods:
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
        NumParameters = 0
        myData = [];
        myHeader = [];
        myDataTimeStamp = [];
    end
    
    %% Constructor
    methods
        function obj = Parameters(varargin)
            % Parameters - Constructor for QSP.Parameters
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Parameters object.
            %
            % Syntax:
            %           obj = QSP.Parameters('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Parameters object
            %
            % Example:
            %    aObj = QSP.Parameters();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Parameters(varargin)
        
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
                'No of parameters',obj.NumParameters;
                };
        end
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid) %#ok<INUSD>
            
            StatusOK = true;
            Message = sprintf('Parameters: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if isdir(obj.FilePath) || ~exist(obj.FilePath,'file')
                StatusOK = false;
                Message = sprintf('%s\n* Parameters file "%s" is invalid or does not exist',Message,obj.FilePath);
            else
                % Import data
                [ThisStatusOk,ThisMessage] = importData(obj,obj.FilePath);
                if ~ThisStatusOk
                    Message = sprintf('%s\n* Error loading data "%s". %s\n',Message,obj.FilePath,ThisMessage);
                end
            end
            
        end %function
        
        function clearData(obj)
            obj.myData = [];
            obj.myHeader = [];
            obj.myDataTimeStamp = []; 
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
        function [StatusOk,Message,Header,Data] = importData(obj,DataFilePath)            
            % Defaults
            StatusOk = true;
            Message = '';
            
            if ~isempty(obj.myData) && exist(DataFilePath, 'file')
                FileInfo = dir(DataFilePath);
                timeStamp = FileInfo.datenum;
                if obj.myDataTimeStamp == timeStamp %modified since storing
                    Data = obj.myData;
                    Header = obj.myHeader;
                    return
                end
            end
            
            % Load from file
            try            
                Raw = readtable(DataFilePath);
                Raw = [Raw.Properties.VariableNames;table2cell(Raw)];

            catch ME
                Raw = {};
                StatusOk = false;
                Message = sprintf('Unable to read from Excel file:\n\n%s',ME.message);                
            end
            
            % Compute number of parameters
            if size(Raw,1) > 1
                Header = Raw(1,:);
                Data = Raw(2:end,:);
                obj.NumParameters = size(Raw,1) - 1; % 1 header line
            else
                Header = {};
                Data = {};
                obj.NumParameters = 0;
            end
            
            obj.FilePath = DataFilePath;
            obj.myData = Data;
            obj.myHeader = Header;
            FileInfo = dir(DataFilePath);

            if ~isempty(FileInfo)
                obj.myDataTimeStamp = FileInfo.datenum;
            else
                obj.myDataTimeStamp = [];
            end
            
        end %function
        
    end
    
end %classdef
