classdef GlobalSensitivityAnalysis < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Simulation - Defines a GlobalSensitivityAnalysis object
    % ---------------------------------------------------------------------
    % Abstract: This object defines GlobalSensitivityAnalysis
    %
    % Syntax:
    %           obj = QSP.GlobalSensitivityAnalysis
    %           obj = QSP.GlobalSensitivityAnalysis('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.GlobalSensitivityAnalysis Properties:
    %
    %
    % QSP.GlobalSensitivityAnalysis Methods:
    %
    %
    %
    
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks
    %   $Author: faugusti $
    %   $Revision: 1 $  $Date: Wed, 04 Nov 2020 $
    % ---------------------------------------------------------------------
    
    % Properties
    properties
        Settings = QSP.Settings.empty(0,1)
        
        Item
        SummaryType = 'mean'
                  
        RandomSeed        = []
        StoppingTolerance = 0;
        
        SelectedPlotLayout = '1x1'

        PlotInputs  = cell(0,1) % Inputs
        PlotOutputs = cell(0,1) % Outputs

        PlotSobolIndex
        
        PlotSettings = repmat(struct(),1,12)
        
        % Properties that are NOT part of the public API
        ParametersName_I = []        % needs to be public for copy to work
        ResultsFolderParts_I = {''}  % needs to be public for copy to work

    end
      
    properties (Dependent)
        ParametersName
        ResultsFolder
    end
    
    properties (Access = private)
        ItemTemplate = struct('TaskName', [], ...
                              'NumberSamples', 0, ...
                              'IterationInfo', [0, 5], ...
                              'Include', true, ...
                              'MATFileName', [], ...
                              'Color', [], ...
                              'Description', [], ...
                              'Results', [])
        PlotSobolIndexTemplate = struct('Plot', ' ', ...
                                        'Style', {{'-', 'd'}}, ...
                                        'Input', [], ...
                                        'Output', [], ...
                                        'Type', 'first order', ...
                                        'Mode', 'bar plot', ...
                                        'Display', '')
    end

    
    %% Constructor
    methods
        function obj = GlobalSensitivityAnalysis()
            % GlobalSensitivityAnalysis - Constructor for QSP.GlobalSensitivityAnalysis
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.GlobalSensitivityAnalysis object.
            %
            % Syntax:
            %           obj = QSP.GlobalSensitivityAnalysis('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.GlobalSensitivityAnalysis object
            %
            % Example:
            %    aObj = QSP.GlobalSensitivityAnalysis();
            
            obj.Item           = obj.ItemTemplate([]);
            obj.PlotSobolIndex = obj.PlotSobolIndexTemplate([]);
                       
            % assign plot settings names
            for index = 1:length(obj.PlotSettings)
                obj.PlotSettings(index).Title = sprintf('Plot %d', index);
            end
            
        end %function obj = GlobalSensitivityAnalysis(varargin)
        
    end %methods
    
    % Methods defined as abstract
    methods
        
        function Summary = getSummary(obj)
            
            if ~isempty(obj.Item)
                GlobalSensitivityAnalysisItems = {};
                % Check what items are stale or invalid
                [StaleFlag,ValidFlag,InvalidMessages,StaleReasons] = getStaleItemIndices(obj);                
                
                for index = 1:numel(obj.Item)
                    ThisResultFilePath = obj.Item(index).MATFileName; 
                    if isempty(ThisResultFilePath)
                        ThisResultFilePath = 'N/A';
                    end

                    % Item display
                    ThisItem = sprintf('%s with %d samples (%d staged)\nResults: %s', obj.Item(index).TaskName, ...
                        obj.Item(index).NumberSamples, prod(obj.Item(index).IterationInfo), ThisResultFilePath);
                    if StaleFlag(index)
                        % Item may be out of date
                        ThisItem = sprintf('***WARNING***\n%s\n***Item may be out of date %s***', ThisItem, StaleReasons{index});
                    elseif ~ValidFlag(index)
                        % Display invalid
                        ThisItem = sprintf('***ERROR***\n%s\n***%s***', ThisItem, InvalidMessages{index});
                    end
                    % Append \n
                    if index < numel(obj.Item)
                        ThisItem = sprintf('%s\n',ThisItem);
                    end
                    GlobalSensitivityAnalysisItems = [GlobalSensitivityAnalysisItems; ThisItem]; %#ok<AGROW>
                end
            else
                GlobalSensitivityAnalysisItems = {'No global sensitivity analysis configured yet.'};
            end

            % Populate summary
            Summary = {...
                'Name',obj.Name;
                'Last Saved',obj.LastSavedTimeStr;
                'Description',obj.Description;
                'Results Path',obj.ResultsFolder;
                'Sensitivity Inputs',obj.ParametersName;
                'Items',GlobalSensitivityAnalysisItems;
                };
            
        end %function
        
        function [StatusOK, Message] = validate(obj, FlagRemoveInvalid)
            
            StatusOK = true;
            Message = sprintf('Global Sensitivity Analysis: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end
           
            % Validate task-parameters pair is valid
            if ~isempty(obj.Settings)
                
                % Remove the invalid tasks, if there are any
                [TaskItemIndex,MatchTaskIndex] = ismember({obj.Item.TaskName},{obj.Settings.Task.Name});
                RemoveIndices = ~TaskItemIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Task rows %s are invalid.',num2str(find(RemoveIndices)));
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    if FlagRemoveInvalid
                        obj.Item(RemoveIndices) = [];
                        allOutputs = arrayfun(@(item) ...
                            {item.Results(1).SobolIndices(1,:).Observable}, ...
                            obj.Item, 'UniformOutput', false);
                        allOutputs = unique([allOutputs{:}]);
                        for i = numel(obj.PlotSobolIndex):-1:1
                            if ~ismember(obj.PlotSobolIndex(i).Output, allOutputs)
                                obj.PlotSobolIndex(i) = [];
                            end
                        end
                    end
                end
                
                % Check Tasks                
                MatchTaskIndex(MatchTaskIndex == 0) = [];
                for index = MatchTaskIndex
                    [ThisStatusOK,ThisMessage] = validate(obj.Settings.Task(index),FlagRemoveInvalid);
                    if ~ThisStatusOK
                        if FlagRemoveInvalid
                            obj.Item(RemoveIndices) = [];
                            allOutputs = arrayfun(@(item) ...
                                {item.Results(1).SobolIndices(1,:).Observable}, ...
                                obj.Item, 'UniformOutput', false);
                            allOutputs = unique([allOutputs{:}]);
                            for i = numel(obj.PlotSobolIndex):-1:1
                                if ~ismember(obj.PlotSobolIndex(i).Output, allOutputs)
                                    obj.PlotSobolIndex(i) = [];
                                end
                            end
                        end
                        StatusOK = false;
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    end
                end
                
                % Check Parameters
                if isempty(obj.ParametersName)
                    StatusOK = false;
                    ThisMessage = 'No sensitivity inputs selected.';
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                    if FlagRemoveInvalid
                        obj.Item(1:end) = [];
                        obj.PlotSobolIndex(1:end) = [];
                    end
                else
                    [tfParametersExists,MatchParametersIndex] = ismember(obj.ParametersName,{obj.Settings.Parameters.Name});
                    if ~tfParametersExists
                        StatusOK = false;
                        ThisMessage = sprintf('Sensitivity inputs ''%s'' not found.', obj.ParametersName);
                        Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        if FlagRemoveInvalid
                            obj.Item(1:end) = [];
                            obj.PlotSobolIndex(1:end) = [];
                        end
                    else
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.Parameters(MatchParametersIndex),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                            if FlagRemoveInvalid
                                obj.Item(1:end) = [];
                                obj.PlotSobolIndex(1:end) = [];
                            end
                        end
                    end
                end
            end
            
            % Global Sensitivity Analysis name forbidden characters
            if ~isempty(regexp(obj.Name,'[:*?/]', 'once'))
                Message = sprintf('%s\n* Invalid Global Sensitivity Analysis name.', Message);
                StatusOK = false;
            end
            
            % Check if the same Task / Parameters is assigned more than once
            allItems = {obj.Item.TaskName};
            [~,uniqueItemIdx] = unique(allItems);
            if length(uniqueItemIdx) < numel(allItems) % duplicates
                % Remove unique items to get duplicates:
                allItems(uniqueItemIdx) = [];
                dups = unique(allItems);

                if length(dups)>1
                    Message = sprintf('Items %s are duplicates. Please remove before continuing.', ...
                        strjoin(dups, ',') );
                else
                    Message = sprintf('Item %s is a duplicate. Please remove before continuing.', ...
                        dups{1});
                end
                StatusOK = false;
            end
            
            
            
    
        end %function
        
        function clearData(obj)
            assert(false, "Internal error: unknown call reason.");
            for index = 1:numel(obj.Item)
                obj.Item(index).MATFileName = [];
            end
        end

    end
    
    %  Methods    
    methods
        
        function [StatusOK, Message] = run(obj, figureHandle)
            
            % Invoke validate
            [StatusOK, Message] = validate(obj,false);
            
            % Invoke helper
            if StatusOK
                
                % For autosave with tag
                if obj.Session.AutoSaveBeforeRun
                    autoSaveFile(obj.Session,'Tag','preRunGlobalSensitivityAnalysis');
                end
                
                % Run helper
                [ThisStatusOK,thisMessage,ResultFileNames] = runHelper(obj, figureHandle);
                
                if ~ThisStatusOK 
                    StatusOK = false;
                    Message = sprintf('%s\n\n%s', Message, thisMessage);
                    return
                end
                
                % Update MATFileName in the GSA items
                for index = 1:numel(obj.Item)
                    obj.Item(index).MATFileName = ResultFileNames{index};
                end
                
            end 
            
        end %function
        
        function data = GetData(obj)
            Items = obj.Item;
            data = struct();
            for k = 1:length(Items)
                try
                    filePath = fullfile( obj.Session.RootDirectory, obj.ResultsFolder, Items(k).MATFileName);
                    tmp = load(filePath);
                    data(k).Data           = tmp.Results;
                    data(k).TaskName       = Items(k).TaskName;
                    data(k).ParametersName = Items(k).ParametersName;
                catch err
                    warning(err.message)                    
                end

            end
            
        end
        
        function [statusOk, message] = updateInputsOutputs(obj)
                      
            numItems = numel(obj.Item);
            if numItems == 0
                obj.PlotInputs  = cell(0,1); % Sensitivity inputs to plot
                obj.PlotOutputs = cell(0,1); % Sensitivity outputs to plot
                return
            end
            
            [statusOk, message, sensitivityInputs] = obj.getParameterInfo();
            if ~statusOk
                return
            end
            
            sensitivityOutputs = cell(numItems,1);
            for i = 1:numItems
                task = obj.getObjectsByName(obj.Settings.Task, obj.Item(i).TaskName);
                sensitivityOutputs{i} = task.ActiveSpeciesNames;
            end
            sensitivityOutputs = unique([sensitivityOutputs{:}], 'stable');
            
            obj.PlotInputs  = reshape(sensitivityInputs,[],1);
            obj.PlotOutputs = reshape(sensitivityOutputs,[],1);

        end
        
        function [statusOk, message] = add(obj, type)
            statusOk = true;
            message  = '';
            switch type
                case 'item'
                    existingTaskNames = {obj.Item.TaskName};
                    allTasks = {obj.Settings.Task.Name};
                    tfTaskExists = ismember(allTasks, existingTaskNames);
                    if all(tfTaskExists)
                        statusOk = false;
                        message = 'All tasks are already selected. Add more tasks to add them to this global sensitivity analysis.';
                        return;
                    end
                    obj.Item(end+1) = obj.ItemTemplate;
                    itemColors = getItemColors(obj.Session, numel(obj.Item));                    
                    nonExistingTaskNames = allTasks(~tfTaskExists);
                    obj.Item(end).TaskName = nonExistingTaskNames{1};
                    obj.Item(end).Color = itemColors(end,:);
                    suggestedNumberOfSamples = max([1000, 10^numel(obj.PlotInputs)]);
                    obj.Item(end).IterationInfo(1) = ceil(suggestedNumberOfSamples/obj.Item(end).IterationInfo(2));
                    [statusOk, message] = obj.updateInputsOutputs();
                case 'sobolIndex'
                    if isempty(obj.PlotInputs)
                        statusOk = false;
                        message = 'Selection of sensitivity inputs required. Select Parameters as inputs for the global sensitivity analysis.';
                        return;
                    end
                    if isempty(obj.PlotOutputs)
                        statusOk = false;
                        message = 'Selection of sensitivity outputs required. Select at least one Task as outputs for the global sensitivity analysis.';
                        return;
                    end
                    obj.PlotSobolIndex(end+1) = obj.PlotSobolIndexTemplate;
                    obj.PlotSobolIndex(end).Input = obj.PlotInputs{1};
                    obj.PlotSobolIndex(end).Output = obj.PlotOutputs{1};
            end
        end
        
        function [statusOk, message] = remove(obj, type, idx)
            if idx == 0
                statusOk = false;
                message = 'Select a row to mark it for removal.';
                return;
            end
            statusOk = true;
            message  = '';
            switch type
                case 'item'
                    obj.Item(idx) = [];
                    [statusOk, message] = obj.updateInputsOutputs();
                case 'sobolIndex'
                    obj.PlotSobolIndex(idx) = [];
            end            
        end
        
        
        function [statusOk, message] = propagateValue(obj, property, idx)
            if strcmp(property, 'Samples')
                iterationsInfoIdx = 1;
            else
                iterationsInfoIdx = 2;
            end
            statusOk = true;
            message  = '';            
            valueToPropagate = obj.Item(idx).IterationInfo(iterationsInfoIdx);
            for i = 1:numel(obj.Item)
                obj.Item(i).IterationInfo(iterationsInfoIdx) = valueToPropagate;
            end
        end
        
        
        function [statusOk, message] = moveUp(obj, idx)
            if idx == 0
                statusOk = false;
                message = 'Select a row to move it up.';
                return;
            elseif idx == 1
                statusOk = false;
                message = 'The select row is already on the top of the table.';
                return;
            else
                statusOk = true;
                message  = '';                
            end            
            if numel(obj.PlotSobolIndex) > 1
                obj.PlotSobolIndex([idx-1, idx]) = obj.PlotSobolIndex([idx, idx-1]);
            end
        end
        
        function [statusOk, message] = moveDown(obj, idx)
            if idx == 0
                statusOk = false;
                message = 'Select a row to move it down.';
                return;
            else
                statusOk = true;
                message  = '';                
            end            
            if idx == numel(obj.PlotSobolIndex)
                statusOk = false;
                message = 'The select row is already on the bottom of the table.';
                return;
            end
            if numel(obj.PlotSobolIndex) > 1
                obj.PlotSobolIndex([idx, idx+1]) = obj.PlotSobolIndex([idx+1, idx]);
            end
        end
        
        function [statusOk, message] = updateItem(obj, idx, item)
            tfNeedupdateInputsOutputs = ~strcmp(item.TaskName, obj.Item(idx).TaskName);
            obj.Item(idx) = item;
            if tfNeedupdateInputsOutputs
                [statusOk, message] = obj.updateInputsOutputs();
            end
        end
        
        function removeResultsFromItem(obj, idx)
            obj.Item(idx).MATFileName   = '';
            obj.Item(idx).NumberSamples = 0;
            obj.Item(idx).Results       = [];
        end
        
        function addResults(obj, itemIdx, results)            
            obj.Item(itemIdx).Results = [obj.Item(itemIdx).Results, results];
            obj.Item(itemIdx).NumberSamples = results.NumberSamples;
        end    

        function [numSamples, maxDifferences] = getConvergenceStats(obj, itemIdx)
            
            numResults     = numel(obj.Item(itemIdx).Results);
            maxDifferences = nan(numResults, 1);
            
            for i = 2:numResults
                differences = reshape(abs([([obj.Item(itemIdx).Results(i).SobolIndices(:).FirstOrder] - ...
                    [obj.Item(itemIdx).Results(i-1).SobolIndices(:).FirstOrder]); ...
                    ([obj.Item(itemIdx).Results(i).SobolIndices(:).TotalOrder] - ...
                    [obj.Item(itemIdx).Results(i-1).SobolIndices(:).TotalOrder])]), [], 1);
                differences(isnan(differences)) = [];
                maxDifferences(i) = max(differences, [], 'all');
            end
            if numResults > 0
                numSamples = vertcat(obj.Item(itemIdx).Results.NumberSamples);
            else
                numSamples = zeros(0,1);
            end
        end
        
        function [StaleFlag,ValidFlag,InvalidMessages,StaleReason] = getStaleItemIndices(obj)
            
            StaleFlag       = false(1,numel(obj.Item));
            ValidFlag       = true(1,numel(obj.Item));
            StaleReason     = cell(1,numel(obj.Item));
            InvalidMessages = cell(1,numel(obj.Item));
            
            if isempty(obj.ParametersName)
                tfParametersValid = false;
                ThisParameters    = [];
                ParametersFileLastSavedTime = '';
            else
                AllParameterNames = {obj.Settings.Parameters.Name};
                [tfParametersValid, ThisParametersIndex] = ismember(obj.ParametersName, AllParameterNames);
                if tfParametersValid
                    % Parameters object and file
                    ThisParameters = obj.Settings.Parameters(ThisParametersIndex);
                    FileInfo = dir(ThisParameters.FilePath);
                    ParametersFileLastSavedTime = FileInfo.datenum;
                else
                    ThisParameters    = [];
                    ParametersFileLastSavedTime = '';
                end
            end

            for index = 1:numel(obj.Item)
                ThisTask = getValidSelectedTasks(obj.Settings,obj.Item(index).TaskName);
                
                if ~isempty(ThisTask) && ~isempty(ThisTask.LastSavedTime) && ...
                        tfParametersValid && ~isempty(obj.LastSavedTime)
                    
                    % Compare times
                    
                    % Task object (item)
                    TaskLastSavedTime = ThisTask.LastSavedTime;
                    
                    % SimBiology Project file from Task
                    FileInfo = dir(ThisTask.FilePath);  
                    if ~isempty(FileInfo)
                        TaskProjectLastSavedTime = FileInfo.datenum;
                    else
                        TaskProjectLastSavedTime = 0;
                    end
                    
                    % Results file
                    ThisFilePath = fullfile(obj.Session.RootDirectory,obj.ResultsFolder,obj.Item(index).MATFileName);
                    if exist(ThisFilePath,'file') == 2
                        FileInfo = dir(ThisFilePath);
                        ResultLastSavedTime = FileInfo.datenum;
                    elseif ~isempty(obj.Item(index).MATFileName)
                        ResultLastSavedTime = [];
                        % Display invalid
                        ValidFlag(index) = false;
                        InvalidMessages{index} = 'MAT file cannot be found';
                    else
                        ResultLastSavedTime = [];
                    end
                    
                    % Check
                    if ~isempty(ResultLastSavedTime)
                        STALE_REASON = '';
                        if ResultLastSavedTime < TaskLastSavedTime  % task has changed
                            STALE_REASON = '(Task has changed)';
                        elseif ~isempty(ThisParameters) && ResultLastSavedTime < ParametersFileLastSavedTime %parameters have changed
                            STALE_REASON = '(Parameters has changed)';
                        elseif ResultLastSavedTime < TaskProjectLastSavedTime % sbproj has changed
                            STALE_REASON = '(Sbproj has changed)';
                        end
                        
                        if ~isempty(STALE_REASON)
                            % Item may be out of date
                            StaleFlag(index) = true;
                            StaleReason{index} = STALE_REASON;
                        end                    
                    end
                    
                elseif isempty(ThisTask) || ~tfParametersValid
                    % Display invalid
                    ValidFlag(index) = false;      
                    InvalidMessages{index} = 'Invalid Task and/or Parameters';
                end                
            end 
        end %function
        
    end %methods
    
    
    %  Set Methods
    methods
        
        function set.Settings(obj,Value)
            validateattributes(Value,{'QSP.Settings'},{'scalar'});
            obj.Settings = Value;
        end
        
        function set.ResultsFolder(obj,Value)
            validateattributes(Value,{'char'},{});
            obj.ResultsFolderParts_I = strsplit(Value, filesep);
        end
        
        function Value = get.ResultsFolder(obj)
            Value = strjoin(obj.ResultsFolderParts_I, filesep);
        end

        function set.ParametersName(obj,parametersName)
%             validateattributes(parametersName,{'char'},{'row'});
            if ~strcmp(parametersName, obj.ParametersName_I)
                obj.ParametersName_I = parametersName;
                obj.updateInputsOutputs();
            end
        end
        
        function Value = get.ParametersName(obj)
            Value = obj.ParametersName_I;
        end
        
        
        function set.Item(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.Item = Value;
        end
        
        function set.PlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.PlotSettings = Value;
        end
        
        function matchingObjects = getObjectsByName(~, objects, names)
            % Filter objects by name and return matchingObjects whose Name property
            % matches entries in 'names'. The order of returned objects matches the
            % order of 'names'. 
            %  'objects': specified as vector of objects with a Name property
            %  'names'  : specified as character vector or cell array of
            %             character vectors of names

            [tfExists, idx] = ismember(names, {objects.Name});
            if tfExists
                matchingObjects = objects(idx);
            else
                matchingObjects = [];
            end
            % TODOGSA, this assumes that object names are unique within
            % Parameters and within Tasks. Is this assumption justified?
            % TODOGSA: this also assumes that names is a subset of all names.

        end
        
        function [statusOk, message, sensitivityInputs, transformations, ...
            distributions, samplingInfo] = getParameterInfo(obj)
            % Get parameter information from a QSP.Parameters object. Only
            % information for parameters whose are specified to include in the
            % analysis are returned.
            %  'statusOk'         : logical scalar indicating if parameter import
            %                       was successful 
            %  'message'          : character vector containing information about
            %                       parameter import failure
            %  'sensitivityInputs': cell array of character vectors specifying 
            %                       names of parameters to include as sensitivity
            %                       inputs in the global sensitivity analysis
            %  'transformations'  : cell array of character vectors specifying 
            %                       transformations; 'linear' and 'log'
            %                       transformations are supported
            %  'distributions'    : cell array of character vectors specifying 
            %                       distributions; 'uniform' and 'normal'
            %                       distributions are supported. 
            %  'samplingInfo'     : numeric matrix with two columns. There is one
            %                       row per sensitivityInput. The values in each
            %                       row are interpreted as follows, dependent on
            %                       {transformation, distribution}:
            %                       - 'linear' & 'uniform' : [lb, ub]
            %                         meaning the values specified in the xlsx sheet
            %                         determine the sampling range
            %                       - 'linear' & 'log'     : [exp(lb), exp(ub)],
            %                         meaning the values specified in the xlsx sheet
            %                         determine the sampling range
            %                       - 'normal' & 'uniform' : [mu, sig] of normal distribution
            %                       - 'normal' & 'log'     : [mu, sig] of (non-log) normal distribution

            % Import included parameter information

            sensitivityInputs = {};
            transformations = {};
            distributions = {};
            samplingInfo = {};
            if isempty(obj.ParametersName)
                statusOk = false;
                message = 'No sensitivity inputs selected.';
                return;
            end
            parameters = obj.getObjectsByName(obj.Settings.Parameters, obj.ParametersName);
            if isempty(parameters)
                statusOk = false;
                message = sprinitf('Unable to find Parameters ''%s''.', obj.ParametersName);
                return;
            end
            [statusOk, message, header, data] = parameters.importData(parameters.FilePath);
            if ~statusOk
                return;
            end
            
            tfInclude = strcmpi(data(:, strcmpi(header, 'include')), 'yes');
            data = data(tfInclude, :);

            sensitivityInputs = data(:, strcmpi(header, 'name'));

            if nargout <= 3
                return
            end

            transformations = data(:, strcmpi(header, 'scale'));

            distributions = data(:, strcmpi(header, 'dist'));
            tfNormalDistribution = strcmp(distributions, 'normal');

            lb = data(:, strcmpi(header, 'lb'));
            ub = data(:, strcmpi(header, 'ub'));

            p0_1 = cell2mat(data(:, strcmpi(header, 'p0_1')));
            cv = nan(size(lb));
            if ismember('cv', header)
                cv = cell2mat(data(:, strcmpi(header, 'cv')));
            end

            samplingInfo = cell2mat([lb, ub]);
            samplingInfo(tfNormalDistribution, 1) = p0_1(tfNormalDistribution);
            samplingInfo(tfNormalDistribution, 2) = cv(tfNormalDistribution);

            statusOk = statusOk && ~any(isnan(samplingInfo), 'all');

        end                
    end %methods


end %classdef
