classdef Optimization < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Optimization - Defines a Optimization object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Optimization
    %
    % Syntax:
    %           obj = QSP.Optimization
    %           obj = QSP.Optimization('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Optimization Properties:
    %
    %
    % QSP.Optimization Methods:
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
        OptimResultsFolderName = 'OptimResults' 
        ExcelResultFileName = {} % At least one file
        VPopName = {} % At least one Vpop
        
        AlgorithmName = ''        
        
        DatasetName = '' % OptimizationData Name
        GroupName = ''
        IDName = ''
        
        RefParamName = '' % Parameters.Name
        
        Item = QSP.TaskGroup.empty(0,1)        
        SpeciesData = QSP.SpeciesData.empty(0,1)
        SpeciesIC = QSP.SpeciesData.empty(0,1) % Initial Conditions        
        
        PlotSpeciesTable = cell(0,4)
        PlotItemTable = cell(0,4)
        
        PlotProfile = QSP.Profile.empty(0,1)
        SelectedProfileRow = []
        
        SelectedPlotLayout = '1x1'        
        

    end
    
    properties (SetAccess = 'private')
        SpeciesLineStyles
    end
    
    %% Constant Properties
    properties (Constant=true)
        OptimAlgorithms = {
            'Local'
            'ScatterSearch'
            'ParticleSwarm'
            }
    end    
    
    properties (Transient=true)
        ItemModels = []; % cached Item Models
        Results = []; % cached results
    end
    
    %% Constructor
    methods
        function obj = Optimization(varargin)
            % Optimization - Constructor for QSP.Optimization
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Optimization object.
            %
            % Syntax:
            %           obj = QSP.Optimization('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Optimization object
            %
            % Example:
            %    aObj = QSP.Optimization();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
        end %function obj = Optimization(varargin)
        
    end %methods
    
    %% Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            if ~isempty(obj.Item)
                OptimizationItems = {};
                % Check what items are stale or invalid
                [StaleFlag,ValidFlag,InvalidMessages] = getStaleItemIndices(obj);

                for index = 1:numel(obj.Item)
                    ThisResultFilePath = '';
                    if length(obj.ExcelResultFileName) >= numel(obj.Item) && ~isempty(obj.ExcelResultFileName{index})
                        ThisResultFilePath = obj.ExcelResultFileName{index};
                    end
                    if isempty(ThisResultFilePath)
                        ThisResultFilePath = 'Results: N/A';
                    end

                    % Default
                    ThisItem = sprintf('%s - %s (%s)',obj.Item(index).TaskName,obj.Item(index).GroupID,ThisResultFilePath);
                    if StaleFlag(index)
                        % Item may be out of date
                        ThisItem = sprintf('***WARNING*** %s\n%s',ThisItem,'***Item may be out of date***');
                    elseif ~ValidFlag(index)
                        % Display invalid                        
                        ThisItem = sprintf('***ERROR*** %s\n***%s***',ThisItem,InvalidMessages{index});
                    else
                        ThisItem = sprintf('%s',ThisItem);
                    end
                    % Append \n
                    if index < numel(obj.Item)
                        ThisItem = sprintf('%s\n',ThisItem);
                    end
                    OptimizationItems = [OptimizationItems; ThisItem]; %#ok<AGROW>
                end
            else
                OptimizationItems = {};
            end

            % Species-Data mapping
            if ~isempty(obj.SpeciesData)
                SpeciesDataItems = cellfun(@(x,y)sprintf('%s - %s',x,y),{obj.SpeciesData.SpeciesName},{obj.SpeciesData.DataName},'UniformOutput',false);
            else
                SpeciesDataItems = {};
            end
            
            % Species-Initial Conditions
            if ~isempty(obj.SpeciesIC)
                SpeciesICItems = cellfun(@(x,y)sprintf('%s = f(%s)',x,y),{obj.SpeciesData.SpeciesName},{obj.SpeciesData.DataName},'UniformOutput',false);
            else
                SpeciesICItems = {};
            end
            
            % Get the parameter used            
            Names = {obj.Settings.Parameters.Name};
            MatchIdx = strcmpi(Names,obj.RefParamName);
            if any(MatchIdx)
                pObj = obj.Settings.Parameters(MatchIdx);
                [~,~,ParametersHeader,ParametersData] = importData(pObj,pObj.FilePath);                
            else
                ParametersHeader = {};
                ParametersData = {};
            end
            
            if ~isempty(ParametersHeader)
                MatchInclude = find(strcmpi(ParametersHeader,'Include'));
                MatchName = find(strcmpi(ParametersHeader,'Name'));
                if numel(MatchInclude) == 1 && numel(MatchName) == 1
                    IsUsed = strcmpi(ParametersData(:,MatchInclude),'yes');
                    UsedParamNames = ParametersData(IsUsed,MatchName);
                else
                    UsedParamNames = {};
                end
            else
                UsedParamNames = {};
            end
            
            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTime;
                'Description',obj.Description;
                'Results Path',obj.OptimResultsFolderName;
                'Optimization algorithm',obj.AlgorithmName;
                'Dataset',obj.DatasetName;
                'Group Name',obj.GroupName;
                'Items',OptimizationItems;
                'Parameter file',obj.RefParamName;
                'Parameters used for optimization',UsedParamNames;
                'Species-data mapping',SpeciesDataItems;
                'Species-initial conditions',SpeciesICItems;
                'Results',obj.ExcelResultFileName;
                };
            
        end %function
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = sprintf('Optimization: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            % Validate
            if ~isempty(obj.Settings)
                
                % Check if AlgorithmName is valid
                if isempty(obj.AlgorithmName)
                    StatusOK = false;
                    ThisMessage = 'No algorithm name specified.';
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                % Check that Dataset (OptimizationData) is valid if it exists
                if ~isempty(obj.Settings.OptimizationData)
                    MatchIdx = find(strcmpi({obj.Settings.OptimizationData.Name},obj.DatasetName));
                    if isempty(MatchIdx) || numel(MatchIdx) > 1
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,'Invalid dataset name specified for Optimization Data.');
                    else
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.OptimizationData(MatchIdx),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                else
                    ThisMessage = 'No OptimizationData specified';
                    StatusOK = false;
                    Message = sprintf('%s\n%s\n',Message,ThisMessage);
                end                    
                
                % Check that RefParamName (Parameters) is valid if it exists
                if ~isempty(obj.Settings.Parameters)
                    MatchIdx = find(strcmpi({obj.Settings.Parameters.Name},obj.RefParamName));
                    if isempty(MatchIdx) || numel(MatchIdx) > 1
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,'Invalid reference parameter name specified for Parameters.');
                    else
%                         [ThisStatusOK,ThisMessage] = validate(obj.Settings.OptimizationData(MatchIdx),FlagRemoveInvalid);
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.Parameters(MatchIdx),FlagRemoveInvalid);
                        
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                else
                    ThisMessage = 'No Parameters specified';
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                
                % Import OptimData
                if ~isempty(obj.Settings.OptimizationData)
                    Names = {obj.Settings.OptimizationData.Name};
                    MatchIdx = strcmpi(Names,obj.DatasetName);
                    
                    if any(MatchIdx)
                        dObj = obj.Settings.OptimizationData(MatchIdx);
                        
                        DestDatasetType = 'wide';
                        [~,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
                    else
                        OptimHeader = {};
                    end
                else
                    OptimHeader = {};
                end
                
                % Get the group column
                % GroupID
                if ~isempty(OptimHeader) && ~isempty(OptimData)
                    MatchIdx = strcmp(OptimHeader,obj.GroupName);
                    GroupIDs = OptimData(:,MatchIdx);
                    if iscell(GroupIDs)
                        GroupIDs = cell2mat(GroupIDs);
                    end
                    GroupIDs = unique(GroupIDs);
                    GroupIDs = cellfun(@(x)num2str(x),num2cell(GroupIDs),'UniformOutput',false);
                else
                    GroupIDs = [];
                end                
                
                % ID Column - Validate?
                
                
                %%% Remove the invalid task/group combos if any
                [TaskItemIndex,MatchTaskIndex] = ismember({obj.Item.TaskName},{obj.Settings.Task.Name});
                if ~isempty(GroupIDs)
                    GroupItemIndex = ismember({obj.Item.GroupID},GroupIDs(:)');
                else
                    GroupItemIndex = false(size({obj.Item.GroupID}));
                end
                RemoveIndices = ~TaskItemIndex | ~GroupItemIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Task-Group rows %s are invalid.',num2str(find(RemoveIndices)));
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
                
                % Check GroupID
                if any(GroupItemIndex == 0)
                    BadGroupIDs = {obj.Item(GroupItemIndex == 0).GroupID};
                    ThisMessage = sprintf('Invalid group indices: %s',uix.utility.cellstr2dlmstr(BadGroupIDs,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                % Get the species list
                ItemTaskNames = {obj.Item.TaskName};
                SpeciesList = getSpeciesFromValidSelectedTasks(obj.Settings,ItemTaskNames);
                
                %%% Remove the invalid species-data mapping                
                % Check Species
                SpeciesMappingIndex = ismember({obj.SpeciesData.SpeciesName},SpeciesList(:)');
                
                % Check Data
                DataMappingIndex = ismember({obj.SpeciesData.DataName},OptimHeader(:)');
                 
                % Check Objective Fcn
                if exist(obj.Session.FunctionsDirectory,'dir')
                    FileList = dir(obj.Session.FunctionsDirectory);
                    IsDir = [FileList.isdir];
                    ObjectiveFcns = {FileList(~IsDir).name};
                    ObjectiveFcns = vertcat({'defaultObj'},ObjectiveFcns(:));
                else
                    ObjectiveFcns = {'defaultObj'};
                end
                ObjectiveFcnMappingIndex = ismember({obj.SpeciesData.ObjectiveName},ObjectiveFcns(:)');
                
                % Check Species (Mapping)
                if any(SpeciesMappingIndex == 0)
                    BadValues = {obj.SpeciesData(SpeciesMappingIndex==0).SpeciesName};
                    ThisMessage = sprintf('Invalid species: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                                
                 % Check Data (Mapping)
                if any(DataMappingIndex == 0)
                    BadValues = {obj.SpeciesData(DataMappingIndex==0).DataName};
                    ThisMessage = sprintf('Invalid data: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                else
                    % Check that the function is only a function of x
                    tmp = cellfun(@symvar, {obj.SpeciesData.FunctionExpression}, 'UniformOutput', false);
                    ThisStatusOK = all(cellfun(@(x) length(x) == 1 && strcmp(x,'x'), tmp));
                    if ~ThisStatusOK
                        StatusOK = false;
                        ThisMessage = 'Data mappings must be a function of x only';
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end

                end
                
                % Check ObjectiveFcn
                if any(ObjectiveFcnMappingIndex == 0)
                    BadValues = {obj.SpeciesData(ObjectiveFcnMappingIndex==0).ObjectiveName};
                    ThisMessage = sprintf('Invalid objective fcn: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                % Then, remove invalid
                RemoveIndices = ~SpeciesMappingIndex | ~DataMappingIndex | ~ObjectiveFcnMappingIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Species-Data mappings %s are invalid.',num2str(find(RemoveIndices)));
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                if FlagRemoveInvalid                    
                    obj.SpeciesData(RemoveIndices) = [];
                end

                %%% Remove the invalid species-data initial conditions
                % Check Species
                SpeciesMappingIndex = ismember({obj.SpeciesIC.SpeciesName},SpeciesList(:)');
                
                % Check Data
                DataMappingIndex = ismember({obj.SpeciesIC.DataName},OptimHeader(:)');
                 
                % Check Species (IC)
                if any(SpeciesMappingIndex == 0)
                    BadValues = {obj.SpeciesIC(SpeciesMappingIndex==0).SpeciesName};
                    ThisMessage = sprintf('Invalid species: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                                
                 % Check Data (IC)
                if any(DataMappingIndex == 0)
                    BadValues = {obj.SpeciesIC(DataMappingIndex==0).DataName};
                    ThisMessage = sprintf('Invalid species: %s',uix.utility.cellstr2dlmstr(BadValues,','));
                    StatusOK = false;
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                % Check for multiple initial conditions for same species
                if length({obj.SpeciesIC.SpeciesName}) > length(unique({obj.SpeciesIC.SpeciesName}))
                    StatusOK = false;
                    ThisMessage = 'Only one initial condition allowed per species';
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                
                % Then, remove invalid
                RemoveIndices = ~SpeciesMappingIndex | ~DataMappingIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Species-Data IC rows %s are invalid.',num2str(find(RemoveIndices)));
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                end
                if FlagRemoveInvalid
                    obj.SpeciesIC(RemoveIndices) = [];
                end
                
                % Optimization name forbidden characters
                if any(regexp(obj.Name,'[:*?/]'))
                    Message = sprintf('%s\n* Invalid optimization name.', Message);
                    StatusOK=false;
                end
                
            end
            
        end %function
        
        function clearData(obj)
            obj.ItemModels = [];
            obj.Results = [];
            obj.PlotProfile = QSP.Profile.empty(0,1);
            obj.SelectedProfileRow = [];
            obj.LastSavedTime = '';
        end
    end
    
    
    %% Methods    
    methods
        
        function [StatusOk,Message,PlotParametersData] = importParametersSource(obj,NewSource)
            
            StatusOk = true;
            Message = '';
            PlotParametersData = cell(0,2);
            
            % Check if parameter
            % Parameter File
            Names = {obj.Settings.Parameters.Name};
            MatchIdx = strcmpi(Names,NewSource);
            if any(MatchIdx)
                thisObj = obj.Settings.Parameters(MatchIdx);
                DataFilePath = thisObj.FilePath;
            else
                thisObj = [];
                DataFilePath = '';
            end
            
            % Check if virtual population, if thisObj is empty
            if isempty(thisObj)            
                % Virtual Population
                Names = {obj.Settings.VirtualPopulation.Name};
                [~,ThisName] = fileparts(NewSource);
                MatchIdx = strcmpi(Names,ThisName);
                if any(MatchIdx)
                    thisObj = obj.Settings.VirtualPopulation(MatchIdx);
                    DataFilePath = thisObj.FilePath;
                else
                    thisObj = [];
                    DataFilePath = '';
                end
            end
                        
            % Import
            if ~isempty(thisObj) && ~isempty(DataFilePath)
                [StatusOk,Message,Header,Data] = importData(thisObj,DataFilePath);
                
                if StatusOk
                    
                    if strcmpi(class(thisObj),'QSP.Parameters')
                        % Parameter File
                        IsName = strcmpi(Header,'Name');
                        IsP0_1 = strcmpi(Header,'P0_1');
                        IsInclude = strcmpi(Header,'Include');
                        if any(IsName) && any(IsP0_1)
%                             IsUsed = strcmpi(Data(:,IsInclude),'yes');
%                             PlotParametersData = cell(nnz(IsUsed),2);
%                             PlotParametersData(:,1) = Data(IsUsed,IsName);
%                             PlotParametersData(:,2) = Data(IsUsed,IsP0_1);  
                             PlotParametersData = cell(size(Data,1),2);
                            PlotParametersData(:,1) = Data(:,IsName);
                            PlotParametersData(:,2) = Data(:,IsP0_1);  
                            PlotParametersData(cell2mat(cellfun(@isnan, PlotParametersData(:,2), 'UniformOutput', false)), 2) = {''};
                        end
                    elseif strcmpi(class(thisObj),'QSP.VirtualPopulation')
                        % Virtual Population Data
                        PlotParametersData = cell(numel(Header),2);
                        PlotParametersData(:,1) = Header(:);
                        if ~isempty(Data)
                            PlotParametersData(:,2) = Data(1,:);                            
                        end
                    else
                        PlotParametersData = cell(0,2);
                    end
                    
%                     PlotParametersData(:,2) = cell2mat(cellfun(@str2num, PlotParametersData(:,2), 'UniformOutput', false));
                    if iscell(PlotParametersData(:,2))
                        isStr = cellfun(@ischar, PlotParametersData(:,2));
                        PlotParametersData(isStr,2) = cellfun(@str2num, PlotParametersData(isStr,2), 'UniformOutput', false);
                    end                                       
                    
                    % reorder alphabetically
                    [~,index] = sort(upper(PlotParametersData(:,1)));
                    PlotParametersData = PlotParametersData(index,:);
                    
                    %obj.PlotParametersSource = NewSource;
                else
                    Message = sprintf('Could not import from file. %s',Message);
                end
            else
                StatusOk = false;
                Message = sprintf('Could not import from file. Validate source''s filepath.');
            end
        end %function 
        
        function [StatusOK,Message,vpopObj] = run(obj)
            
            % Invoke validate
            [StatusOK, Message] = validate(obj,false);
            
            % Invoke helper
            if StatusOK
                % If no initial conditions are specified, only one VPop is
                % created. If IC are provided, the # of VPops is equivalent
                % to the number of groups + 1
                
                % Run helper
                [StatusOK,Message,ResultsFileNames,VPopNames] = optimizationRunHelper(obj);
                % Update MATFileName in the simulation items
                obj.ExcelResultFileName = ResultsFileNames;
                obj.VPopName = VPopNames;
                
                if StatusOK
                    vpopObj = QSP.VirtualPopulation.empty(0,1);
                    for idx = 1:numel(VPopNames)
                        % Create a new virtual population
                        thisVpopObj = QSP.VirtualPopulation;
                        thisVpopObj.Session = obj.Session;
                        thisVpopObj.Name = VPopNames{idx};
                        thisVpopObj.FilePath = fullfile(obj.Session.RootDirectory,obj.OptimResultsFolderName,obj.ExcelResultFileName{idx});
                        % Update last saved time
                        updateLastSavedTime(thisVpopObj);
                        % Validate
                        validate(thisVpopObj,false);                        
                        
                        % Append
                        vpopObj = [vpopObj thisVpopObj]; %#ok<AGROW>
                    end
                    
                    % update runs to have only the parameters that are
                    % present in the parameter object in order to stay up to date with
                    % changes to the parameter file
                    
                    Names = {obj.Settings.Parameters.Name};
                    MatchIdx = strcmpi(Names,obj.RefParamName);
                    if any(MatchIdx)
                        pObj = obj.Settings.Parameters(MatchIdx);
                        [ThisStatusOk,ThisMessage,paramHeader,paramData] = importData(pObj,pObj.FilePath);
                        if ~ThisStatusOk
                            StatusOK = false;
                            Message = sprintf('%s\n%s\n',Message,ThisMessage);
                            path(myPath);
                            return
                        end
                    else
                        warning('Could not find match for specified parameter file')
                        paramData = {};
                    end
                    
                    % parameters that are being optimized
                    idxInclude = strcmp(paramHeader,'Include');
                    idxName = strcmp(paramHeader,'Name');
                    idx_p0 = strcmpi(paramHeader,'P0_1');
                    
%                     optParams = paramData(strcmpi(paramData(:,idxInclude),'yes'),:);
                      optParams = paramData;
                  
                    optParamNames = optParams(:,idxName);
                    optParamValues = optParams(:,idx_p0);
                    isStr = cellfun(@ischar, optParamValues);
                    optParamValues(isStr) = cellfun(@str2num, optParamValues(isStr), 'UniformOutput', false);
                    for idx = 1:numel(obj.PlotProfile)
                        inSet = ismember(obj.PlotProfile(idx).Values(:,1), optParamNames);
                        % keep only those that are in the current parameter
                        % file
                        idxMissing = ~ismember(optParamNames, obj.PlotProfile(idx).Values(:,1));

                        obj.PlotProfile(idx).Values = obj.PlotProfile(idx).Values(inSet,:);
                        % add in any missing entries, use default values
                        obj.PlotProfile(idx).Values = [obj.PlotProfile(idx).Values; [optParamNames(idxMissing), optParamValues(idxMissing)]];
%                         obj.PlotProfile(idx).Values(:,2) = cellfun(@str2num, obj.PlotProfile(idx).Values(:,2));
                    end
                    
                else
                    vpopObj = QSP.VirtualPopulation.empty(0,1);
                end
            else
                vpopObj = QSP.VirtualPopulation.empty(0,1);
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
        
        function [StaleFlag,ValidFlag,InvalidMessages] = getStaleItemIndices(obj)
            
            StaleFlag = false(1,numel(obj.Item));
            ValidFlag = true(1,numel(obj.Item));
            InvalidMessages = cell(1,numel(obj.Item));
            
            % Check if OptimizationData is valid
            ThisList = {obj.Settings.OptimizationData.Name};
            MatchIdx = strcmpi(ThisList,obj.DatasetName);
            if any(MatchIdx)
                dObj = obj.Settings.OptimizationData(MatchIdx);
                ThisStatusOk = validate(dObj);
                ForceMarkAsInvalid = ~ThisStatusOk;
                
                if ThisStatusOk
                    
                    DestDatasetType = 'wide';
                    [~,~,OptimHeader,OptimData] = importData(dObj,dObj.FilePath,DestDatasetType);
                    
                    MatchIdx = strcmp(OptimHeader,obj.GroupName);
                    GroupIDs = OptimData(:,MatchIdx);
                    
                    if iscell(GroupIDs)
                        GroupIDs = cell2mat(GroupIDs);
                    end
                    GroupIDs = unique(GroupIDs);
                else
                    GroupIDs = [];
                end
            else
                ForceMarkAsInvalid = false;
            end
            
            % ONLY if OptimizationData is valid, check Parameters
            ThisList = {obj.Settings.Parameters.Name};
            MatchIdx = strcmpi(ThisList,obj.RefParamName);
            if any(MatchIdx)
                pObj = obj.Settings.Parameters(MatchIdx);
            else
                pObj = QSP.Parameters.empty(0,1);
            end
                
            if ForceMarkAsInvalid                
                if ~isempty(pObj)
                    ThisStatusOk = validate(pObj);
                    ForceMarkAsInvalid = ~ThisStatusOk;
                else
                    ForceMarkAsInvalid = false;
                end
            end
            
            for index = 1:numel(obj.Item)
                % Validate Task-Group and ExcelFilePath
                ThisTask = getValidSelectedTasks(obj.Settings,obj.Item(index).TaskName);
                % Validate groupID
                ThisID = obj.Item(index).GroupID;
                if ischar(ThisID)
                    ThisID = str2double(ThisID);
                end
                MatchGroup = ismember(ThisID,GroupIDs);                
               
                if ~ForceMarkAsInvalid && ...
                        ~isempty(ThisTask) && ...
                        ~isempty(ThisTask.LastSavedTime) && ...
                        any(MatchGroup) && ...
                        ~isempty(obj.LastSavedTime)
                    
                    % Compare times
                    
                    % Optimization object (this)
                    OptimLastSavedTime = datenum(obj.LastSavedTime);
                    
                    % Task object (item)
                    TaskLastSavedTime = datenum(ThisTask.LastSavedTime);
                    
                    % SimBiology Project file from Task
                    FileInfo = dir(ThisTask.FilePath);
                    TaskProjectLastSavedTime = FileInfo.datenum;
                    
                    % OptimizationData object and file
                    OptimizationDataLastSavedTime = datenum(dObj.LastSavedTime);
                    FileInfo = dir(dObj.FilePath);
                    OptimizationDataFileLastSavedTime = FileInfo.datenum;
                    
                    % Parameter object and file
                    ParametersLastSavedTime = datenum(pObj.LastSavedTime);
                    FileInfo = dir(pObj.FilePath);
                    ParametersFileLastSavedTime = FileInfo.datenum;                    
                    
                    % Results file
                    if length(obj.ExcelResultFileName) < numel(obj.Item) ... % missing some items
                            || isempty(obj.ExcelResultFileName{index}) % no excel file available for this index
                        ResultLastSavedTime = '';        
                    else
                        ThisFilePath = fullfile(obj.Session.RootDirectory,obj.OptimResultsFolderName,obj.ExcelResultFileName{index});
                        if exist(ThisFilePath,'file') == 2
                            FileInfo = dir(ThisFilePath);                        
                            ResultLastSavedTime = FileInfo.datenum;                        
                        elseif ~isempty(obj.ExcelResultFileName{index})
                            ResultLastSavedTime = '';
                            % Display invalid
                            ValidFlag(index) = false;
                            InvalidMessages{index} = 'Excel file cannot be found';
                        else
                            ResultLastSavedTime = '';                        
                        end
                    end
                    
                    % Check
                    if OptimLastSavedTime < TaskLastSavedTime || ...
                            OptimLastSavedTime < TaskProjectLastSavedTime || ...   
                            OptimLastSavedTime < OptimizationDataLastSavedTime || ...
                            OptimLastSavedTime < OptimizationDataFileLastSavedTime || ...
                            OptimLastSavedTime < ParametersLastSavedTime || ...
                            OptimLastSavedTime < ParametersFileLastSavedTime || ...
                            (~isempty(ResultLastSavedTime) && OptimLastSavedTime > ResultLastSavedTime)
                        % Item may be out of date
                        StaleFlag(index) = true;
                    end
                    
                elseif ForceMarkAsInvalid
                    % Display invalid
                    ValidFlag(index) = false;                    
                    InvalidMessages{index} = 'Invalid reference parameter set';
                elseif isempty(ThisTask) || ~any(MatchGroup)
                    % Display invalid
                    ValidFlag(index) = false;                    
                    InvalidMessages{index} = 'Invalid Task and/or Group ID';
                end       
            end 
        end %function
        
    end %methods
    
    
    %% Set Methods
    methods
        
        function set.Settings(obj,Value)
            validateattributes(Value,{'QSP.Settings'},{'scalar'});
            obj.Settings = Value;
        end
        
        function set.OptimResultsFolderName(obj,Value)
            validateattributes(Value,{'char'},{'row'});
            obj.OptimResultsFolderName = Value;
        end
        
        function set.DatasetName(obj,Value)
            validateattributes(Value,{'char'},{});
            if ~isequal(Value,obj.DatasetName)
                % Set
                obj.DatasetName = Value;
                % Clear
                obj.Item = QSP.TaskGroup.empty(0,1); %#ok<MCSUP>
                obj.SpeciesData = QSP.SpeciesData.empty(0,1); %#ok<MCSUP>
                obj.SpeciesIC = QSP.SpeciesData.empty(0,1); %#ok<MCSUP>
            end
        end
        
        function set.RefParamName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.RefParamName = Value;
        end
        
        function set.Item(obj,Value)
            validateattributes(Value,{'QSP.TaskGroup'},{});
            obj.Item = Value;
        end
    
        function set.SpeciesData(obj,Value)
            validateattributes(Value,{'QSP.SpeciesData'},{});
            obj.SpeciesData = Value;
        end
        
        function set.AlgorithmName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.AlgorithmName = Value;
        end
        
        function set.GroupName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.GroupName = Value;
        end
        
        function set.IDName(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.IDName = Value;
        end
        
        function set.SpeciesIC(obj,Value)
            validateattributes(Value,{'QSP.SpeciesData'},{});
            obj.SpeciesIC = Value;
        end
        
        function set.PlotProfile(obj,Value)
            validateattributes(Value,{'QSP.Profile'},{});
            obj.PlotProfile = Value;
        end
        
        function set.SelectedProfileRow(obj,Value)
            validateattributes(Value,{'numeric'},{});
            obj.SelectedProfileRow = Value;
        end
        
    end %methods
    
end %classdef
