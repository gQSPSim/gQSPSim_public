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
        
        ResultsFolderPath = {'GSAResults'}
        ResultsFolderName = ''

        Item
        ItemTemplate = struct('TaskName', [], ...
                              'NumberSamples', 0, ...
                              'Include', true, ...
                              'MATFileName', [], ...
                              'Color', [], ...
                              'Description', [], ...
                              'Results', []);
                  
        ParametersName   = [];
        NumberSamples    = 1000;
        RandomSeed       = []
        NumberIterations = 3;
        
        SelectedPlotLayout = '1x1'

        PlotInputs         = cell(0,1) % Inputs
        PlotOutputs        = cell(0,1) % Outputs
        PlotFirstOrderInfo = cell(0,4) % Plot | Line style | Display | Line handles
        PlotTotalOrderInfo = cell(0,4) % Plot | Line style | Display | Line handles
        
        PlotSettings = repmat(struct(),1,12)
        
    end
      
    properties (Dependent)
        ResultsFolderName_new
    end
    
    properties (SetAccess = 'private')
        SpeciesLineStyles
    end
    
%     properties (Dependent=true)
%         TaskVPopItems
%     end
    
    %% Constructor
    methods
        function obj = GlobalSensitivityAnalysis(varargin)
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
            
            obj.Item = obj.ItemTemplate([]);
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});       
            
            % For compatibility
%             if size(obj.PlotSpeciesTable,2) == 3
%                 obj.PlotSpeciesTable(:,4) = obj.PlotSpeciesTable(:,3);
%             end
%             if size(obj.PlotItemTable,2) == 4
%                 TaskNames = obj.PlotItemTable(:,3);
%                 VPopNames = obj.PlotItemTable(:,4);
%                 obj.PlotItemTable(:,5) = cellfun(@(x,y)sprintf('%s - %s',x,y),TaskNames,VPopNames,'UniformOutput',false);
%             end
%             if size(obj.PlotDataTable,2) == 3
%                 obj.PlotDataTable(:,4) = obj.PlotDataTable(:,3);
%             end
%             if size(obj.PlotGroupTable,2) == 3
%                 obj.PlotGroupTable(:,4) = obj.PlotGroupTable(:,3);
%             end
            
            % assign plot settings names
            for index = 1:length(obj.PlotSettings)
                obj.PlotSettings(index).Title = sprintf('Plot %d', index);
            end
            
        end %function obj = Simulation(varargin)
        
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
                        ThisResultFilePath = 'Results: N/A';
                    end

                    % Default
                    ThisItem = sprintf('%s with %d samples (%s)',obj.Item(index).TaskName,obj.Item(index).NumberSamples,ThisResultFilePath);
                    if StaleFlag(index)
                        % Item may be out of date
                            ThisItem = sprintf('***WARNING*** %s\n%s',ThisItem, sprintf('***Item may be out of date %s***', StaleReasons{index}));
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
                'Results Path',obj.ResultsFolderName_new;
                'Sensitivity Inputs',obj.ParametersName;
                'Items',GlobalSensitivityAnalysisItems;
                };
            
        end %function
        
        function [StatusOK, Message] = validate(obj,FlagRemoveInvalid)
            
            StatusOK = true;
            Message = sprintf('Global Sensitivity Analysis: %s\n%s\n',obj.Name,repmat('-',1,75));
            
            if  obj.Session.UseParallel && ~isempty(getCurrentTask())
                return
            end
            
            % Validate number of samples
            if obj.NumberSamples == 0
                StatusOK = false;
                ThisMessage = 'Number of added samples is zero.';
                Message = sprintf('%s\n* %s\n',Message,ThisMessage);
            end
            
            % Validate task-parameters pair is valid
            if ~isempty(obj.Settings)
                
                % Remove the invalid tasks if any
                [TaskItemIndex,MatchTaskIndex] = ismember({obj.Item.TaskName},{obj.Settings.Task.Name});
                RemoveIndices = ~TaskItemIndex;
                if any(RemoveIndices)
                    StatusOK = false;
                    ThisMessage = sprintf('Task rows %s are invalid.',num2str(find(RemoveIndices)));
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
                
                % Check Parameters
                if isempty(obj.ParametersName)
                    StatusOK = false;
                    ThisMessage = 'No sensitivity inputs selected.';
                    Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                else
                    [ParametersItemIndex,MatchParametersIndex] = ismember(obj.ParametersName,{obj.Settings.Parameters.Name});
                    MatchParametersIndex(~ParametersItemIndex) = [];                
                    for index = MatchParametersIndex
                        [ThisStatusOK,ThisMessage] = validate(obj.Settings.Parameters(index),FlagRemoveInvalid);
                        if ~ThisStatusOK
                            StatusOK = false;
                            Message = sprintf('%s\n* %s\n',Message,ThisMessage);
                        end
                    end
                end
            end
            
            % Global Sensitivity Analysis name forbidden characters
            if any(regexp(obj.Name,'[:*?/]'))
                Message = sprintf('%s\n* Invalid Global Sensitivity Analysis name.', Message);
                StatusOK = false;
            end
            
            % Check if the same Task / Parameters is assigned more than once
            allItems = cell2table({obj.Item.TaskName}');
            [~,ia] = unique(allItems);
            
            if length(ia) < size(allItems,1) % duplicates
                dups = setdiff(1:size(allItems,1), ia);

                for k=1:length(dups); dups_{k} = num2str(dups(k)); end
                if length(dups)>1
                    Message = sprintf('Items %s are duplicates. Please remove before continuing.', ...
                        strjoin(dups_, ',') );
                else
                    Message = sprintf('Item %s is a duplicate. Please remove before continuing.', ...
                        dups_{1});
                end
                StatusOK = false;
            end
            
    
        end %function
        
        function clearData(obj)
            for index = 1:numel(obj.Item)
                obj.Item(index).MATFileName = [];
                obj.Item(index).NumberSamples = 0;
            end
        end
        
     
          
    end
    
    %  Methods    
    methods
        
        function [StatusOK, Message] = run(obj, figureHandle, ax)
            
            % Invoke validate
            [StatusOK, Message] = validate(obj,false);
            
            % Invoke helper
            if StatusOK
                
                % For autosave with tag
                if obj.Session.AutoSaveBeforeRun
                    autoSaveFile(obj.Session,'Tag','preRunGlobalSensitivityAnalysis');
                end
                
                % Run helper
                [ThisStatusOK,thisMessage,ResultFileNames] = runHelper(obj, figureHandle, ax);
                
                if ~ThisStatusOK 
%                     error('run: %s',Message);
                    StatusOK = false;
                    Message = sprintf('%s\n\n%s', Message, thisMessage);
                    return
                end
                
                % Update MATFileName in the simulation items
                for index = 1:numel(obj.Item)
                    obj.Item(index).MATFileName = ResultFileNames{index};
                end
                
                % add entry to the database
%                 if obj.Session.UseSQL
%                     obj.Session.addExperimentToDB('GSA', obj.Name, now, ResultFileNames);
%                 end
            end 
            
        end %function
        
        function data = GetData(obj)
            Items = obj.Item;
            data = struct();
            for k = 1:length(Items)
                try
                    filePath = fullfile( obj.Session.RootDirectory, obj.ResultsFolderName_new, Items(k).MATFileName);
                    tmp = load(filePath);
                    data(k).Data = tmp.Results;
                    data(k).TaskName = Items(k).TaskName;
                    data(k).ParametersName = Items(k).ParametersName;
                    data(k).NumberSamples = Items(k).NumberSamples;

                catch err
                    warning(err.message)                    
                end

            end
            
        end
        
        function updatePlotInformation(obj)
                      
            if isempty(obj.Item)
                obj.PlotInputs  = cell(0,1); % Inputs
                obj.PlotOutputs = cell(0,1); % Outputs
                obj.PlotFirstOrderInfo = cell(0,3); % Plot | Line style | Display
                obj.PlotTotalOrderInfo = cell(0,3); % Plot | Line style | Display
                return
            end
            
            [statusOk, message, sensitivityInputs] = obj.getParameterInfo();
            
            numItems = numel(obj.Item);
            sensitivityOutputs = cell(numItems,1);
            for i = 1:numItems
                task = obj.getObjectsByName(obj.Settings.Task, obj.Item(i).TaskName);
                sensitivityOutputs{i} = task.ActiveSpeciesNames;
            end
            sensitivityOutputs = unique([sensitivityOutputs{:}], 'stable');
            
            numInputs  = numel(sensitivityInputs);
            numOutputs = numel(sensitivityOutputs);
            
            plotFirstOrderInfo = cell(numInputs*numOutputs,3); % Plot | Line style | Display
            plotTotalOrderInfo = cell(numInputs*numOutputs,3); % Plot | Line style | Display
            
            [tfInputExists, inputIdx] = ismember(sensitivityInputs, obj.PlotInputs);
            [tfOutputExists, outnputIdx] = ismember(sensitivityOutputs, obj.PlotOutputs);
            for i = 1:numInputs
                for j = 1:numOutputs
                    idx = obj.getInputOutputIndex(i,j,numel(sensitivityInputs));
                    if ~tfInputExists(i) || ~tfOutputExists(j)
                        plotFirstOrderInfo(idx,:) = {' ', '-', ''};
                        plotTotalOrderInfo(idx,:) = {' ', '-', ''};
                    else
                        oldIdx = obj.getInputOutputIndex(inputIdx(i),outnputIdx(j),numel(obj.PlotInputs));
                        plotFirstOrderInfo(idx,:) = obj.PlotFirstOrderInfo(oldIdx,:);
                        plotTotalOrderInfo(idx,:) = obj.PlotTotalOrderInfo(oldIdx,:);
                    end
                end
            end
            obj.PlotInputs  = reshape(sensitivityInputs,[],1);
            obj.PlotOutputs = reshape(sensitivityOutputs,[],1);
            obj.PlotFirstOrderInfo = plotFirstOrderInfo;
            obj.PlotTotalOrderInfo = plotTotalOrderInfo;
            
        end
        
        function plotInfo = getPlotInformation(obj)
            plotInfo = struct('InputsOutputs', [], ...
                'FirstOrderInfo', [], ...
                'TotalOrderInfo', []);
            [outIdx, inIdx] = meshgrid(1:numel(obj.PlotOutputs), 1:numel(obj.PlotInputs));
            plotInfo.InputsOutputs = [obj.PlotInputs(inIdx(:)), obj.PlotOutputs(outIdx(:))];
            plotInfo.FirstOrderInfo = obj.PlotFirstOrderInfo;
            plotInfo.TotalOrderInfo = obj.PlotTotalOrderInfo;
        end
        
        function addItem(obj, item)
            obj.Item(end+1) = item;
            obj.updatePlotInformation();
        end
        
        function removeItem(obj, idx)
            obj.Item(idx) = [];
            obj.updatePlotInformation();
        end
        
        function updateItemTable(obj, idx, item)
            tfNeedUpdatePlotInformation = ~strcmp(item.TaskName, obj.Item(idx).TaskName);
            obj.Item(idx) = item;
            if tfNeedUpdatePlotInformation
                obj.updatePlotInformation();
            end
        end
        
        function updateItemPlotInfo(obj, itemIdx, results)            
            obj.Item(itemIdx).Results = [obj.Item(itemIdx).Results, results];
        end    
            
        
        function hLine = plotTimeCourseHelper(obj, plotInfo, time, sobolIndices, itemIdx, displayname, color, ax)
            
            ThisLineStyle = plotInfo{2};
            ThisDisplayName = plotInfo{3};
            if isempty(ThisDisplayName)
                ThisDisplayName = displayname;
            end
            FullDisplayName = sprintf('%s %s',ThisDisplayName,obj.Item(itemIdx).Description);
            hLine = plot(ax, time, sobolIndices, ...
                'LineWidth', 2, 'LineStyle', ThisLineStyle, 'Color', color, ...
                'Visible', 'off', 'Tag', obj.Item(itemIdx).TaskName);

        end
        
        function setParametersName(obj, parametersName)
            if ~strcmp(parametersName, obj.ParametersName)
                obj.ParametersName = parametersName;
                obj.updatePlotInformation();
            end
        end
        
%         function updateSpeciesLineStyles(obj)
%             ThisMap = obj.Settings.LineStyleMap;
%             if ~isempty(ThisMap) && size(obj.PlotSpeciesTable,1) ~= numel(obj.SpeciesLineStyles)
%                 obj.SpeciesLineStyles = uix.utility.GetLineStyleMap(ThisMap,size(obj.PlotSpeciesTable,1)); % Number of species
%             end
%         end %function
%         
%         function setSpeciesLineStyles(obj,Index,NewLineStyle)
%             NewLineStyle = validatestring(NewLineStyle,obj.Settings.LineStyleMap);
%             obj.SpeciesLineStyles{Index} = NewLineStyle;
%         end %function
        
        function [StaleFlag,ValidFlag,InvalidMessages,StaleReason] = getStaleItemIndices(obj)
            
            StaleFlag = false(1,numel(obj.Item));
            ValidFlag = true(1,numel(obj.Item));
            StaleReason = cell(1,numel(obj.Item));
            InvalidMessages = cell(1,numel(obj.Item));
            
            if isempty(obj.ParametersName)
                tfParametersValid = false;
                ThisParameters = [];
                ParametersFileLastSavedTime = '';
            else
                AllParameterNames = {obj.Settings.Parameters.Name};
                [tfParametersValid, ThisParametersIndex] = ismember(obj.ParametersName, AllParameterNames);
                % Parameters object and file
                ThisParameters = obj.Settings.Parameters(ThisParametersIndex);
                FileInfo = dir(ThisParameters.FilePath);
                ParametersFileLastSavedTime = FileInfo.datenum;
            end

            for index = 1:numel(obj.Item)
                ThisTask = getValidSelectedTasks(obj.Settings,obj.Item(index).TaskName);
                
                if ~isempty(ThisTask) && ~isempty(ThisTask.LastSavedTime) && ...
                        tfParametersValid && ~isempty(obj.LastSavedTime)
                    
                    % Compare times
                    
                    % Global Sensitivity Analysis object (this)
                    GSALastSavedTime = obj.LastSavedTime;
                    
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
                    ThisFilePath = fullfile(obj.Session.RootDirectory,obj.ResultsFolderName_new,obj.Item(index).MATFileName);
                    if exist(ThisFilePath,'file') == 2
                        FileInfo = dir(ThisFilePath);
                        ResultLastSavedTime = FileInfo.datenum;
                    elseif ~isempty(obj.Item(index).MATFileName)
                        ResultLastSavedTime = '';
                        % Display invalid
                        ValidFlag(index) = false;
                        InvalidMessages{index} = 'MAT file cannot be found';
                    else
                        ResultLastSavedTime = '';
                    end
                    
                    % Check
                    if ~isempty(ResultLastSavedTime)
                        STALE_REASON = '';
                        if ResultLastSavedTime < TaskLastSavedTime  % task has changed
                            STALE_REASON = '(Task has changed)';
                        elseif ~isempty(ThisParameters) && ResultLastSavedTime < ParametersFileLastSavedTime %parameters have changed
                            STALE_REASON = '(Parameters has changed)';
                        elseif ResultLastSavedTime < GSALastSavedTime % global sensitivity analysis has changed
                            STALE_REASON = '(Global Sensitivity Analysis has changed)';
                        elseif ResultLastSavedTime < TaskProjectLastSavedTime % sbproj has changed
                            STALE_REASON = '(Sbproj has changed)';
                        end
                        
                        if ~isempty(STALE_REASON)
                            % Item may be out of date
                            StaleFlag(index) = true;
                            StaleReason{index} = STALE_REASON;
                        end                    
                    end
                    
                elseif isempty(ThisTask) || isempty(ThisParameters)
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
        
        function set.ResultsFolderName_new(obj,Value)
            validateattributes(Value,{'char'},{'row'});
            obj.ResultsFolderPath = strsplit(Value, filesep);
        end
        
        function Value = get.ResultsFolderName_new(obj)
            Value = strjoin(obj.ResultsFolderPath, filesep);
        end
        
        function set.Item(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.Item = Value;
        end
        
%         function set.PlotSpeciesTable(obj,Value)
%             validateattributes(Value,{'cell'},{});
%             obj.PlotSpeciesTable = Value;
%         end
%         
%         function set.PlotItemTable(obj,Value)
%             validateattributes(Value,{'cell'},{'size',[nan 6]});
%             obj.PlotItemTable = Value;
%         end
%         
%         function set.PlotDataTable(obj,Value)
%             validateattributes(Value,{'cell'},{});
%             obj.PlotDataTable = Value;
%         end
%         
%         function set.PlotGroupTable(obj,Value)
%             validateattributes(Value,{'cell'},{'size',[nan 4]});
%             obj.PlotGroupTable = Value;
%         end
        
        function set.PlotSettings(obj,Value)
            validateattributes(Value,{'struct'},{});
            obj.PlotSettings = Value;
        end
        
%         function set.TaskVPopItems(obj,Value)
%             validateattributes(Value,{'cell'},{'size',[nan,3]});
%             
%             NewTaskVPop = QSP.TaskVirtualPopulation.empty;
%             for idx = 1:size(Value,1)
%                 NewTaskVPop(end+1) = QSP.TaskVirtualPopulation(...
%                     'TaskName',Value{idx,1},...
%                     'VPopName',Value{idx,2},...
%                     'Group',Value{idx,3}); %#ok<AGROW>
%             end
%             obj.Item = NewTaskVPop;
%         end
%         
%         function Value = get.TaskVPopItems(obj)
%             TaskNames = {obj.Item.TaskName};
%             VPopNames = {obj.Item.VPopName};
%             GroupIDs = {obj.Item.Group};
%             
%             Value = [TaskNames(:) VPopNames(:) GroupIDs(:)];
%         end
    end %methods
     
	methods(Access = private)
        function idx = getInputOutputIndex(~, inputIdx, outputIdx, numInputs)
            % Get index into PlotFirstOrderInfo and PlotTotalOrderInfo
            % from indices if sensitivity inputs/outputs as listed in 
            % PlotInput and PlotOutput.
            idx = inputIdx + (outputIdx-1)*numInputs;
        end
    end
%     methods (Static)
%         function value = ExtractSpeciesData(Results, Species)
%                         
%             for k=1:length(Results)
%             
%                 idxCol = find( strcmp(Results(k).Data.SpeciesNames, Species));
%                 NS = length(Results(k).Data.SpeciesNames);
%                 value(:,k) = Results(k).Data.Data(:, idxCol:NS:end);
%                 
%             end                      
%                 
%         end
%     end       
end %classdef
