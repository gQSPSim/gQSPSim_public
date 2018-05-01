classdef Optimization < uix.abstract.CardViewPane & uix.mixin.AxesMouseHandler
    % Optimization - View Pane for the object
    % ---------------------------------------------------------------------
    % Display a viewer/editor for the object
    %

    
    %   Copyright 2014-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
  
    %% Private properties
    properties (Access=private)
        
        DatasetPopupItems = {'-'}
        DatasetPopupItemsWithInvalid = {'-'}
        
        DatasetGroupPopupItems = {'-'}        
        DatasetGroupPopupItemsWithInvalid = {'-'}
        
        DatasetIDPopupItems = {'-'}        
        DatasetIDPopupItemsWithInvalid = {'-'}
        
        AlgorithmPopupItems = {'-'}
        AlgorithmPopupItemsWithInvalid = {'-'}
        
        ParameterPopupItems = {'-'}
        ParameterPopupItemsWithInvalid = {'-'}
                
        TaskPopupTableItems = {}
        GroupIDPopupTableItems = {}
        SpeciesPopupTableItems = {} % From Tasks
        
        DatasetHeader = {}
        PrunedDatasetHeader = {};
        DatasetData = {};
        
        ParametersHeader = {} % From RefParamName
        ParametersData = {} % From RefParamName
        
        ObjectiveFunctions = {'defaultObj'}
        
        PlotSpeciesAsInvalidTable = cell(0,3)
        PlotItemAsInvalidTable = cell(0,4)
        
        PlotSpeciesInvalidRowIndices = []
        PlotItemInvalidRowIndices = []  
        
    end
    
    properties (Access=public)
        semaphore = [];
    end
        
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = Optimization(varargin)
            
            % Call superclass constructor
            RunVis = true;
            obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the view
            obj.refresh();
            
        end
        
    end %methods
    
    
    %RAJ - for callbacks:
    %notify(obj, 'DataEdited', <eventdata>);
    
    
    %% Methods from CardViewPane
    methods
       function onPlotConfigChange(obj,h,e)
            
            % Update data first
            Value = get(h,'Value');
            obj.Data.SelectedPlotLayout = obj.PlotLayoutOptions{Value};
            
            onPlotConfigChange@uix.abstract.CardViewPane(obj,h,e);
        end
    end
    
    
    %% Methods from AxesMouseHandler
    methods (Access=protected)
        function onMousePress(vObj, e)
            
            hFigure = ancestor(vObj.h.MainLayout,'Figure');
            set(hFigure,'pointer','watch');
            drawnow;
            
            if isa(e.HitObject.Parent,'matlab.graphics.primitive.Group')
                % Find the matching group by species / axes
                matchIdx = find(cellfun(@(x)ismember(e.HitObject.Parent,x),vObj.h.SpeciesGroup));
                [~,~,runIdx] = ind2sub(size(vObj.h.SpeciesGroup),matchIdx);
                % Use the group to get the line index or profile row
                vObj.Data.SelectedProfileRow = runIdx;                
                % Update the view
                updateVisualizationView(vObj);
            end
            
            set(hFigure,'pointer','arrow');
            drawnow;
            
        end %function
    end
    
    
    %% Callbacks
    methods
        
        function onFolderSelection(vObj,h,evt) %#ok<*INUSD>
            
            % Update the value
            vObj.TempData.OptimResultsFolderName = evt.NewValue;
            
            % Update the view
            updateResultsDir(vObj);
            
        end %function
        
        function onDatasetPopup(vObj,h,e)
            
            vObj.TempData.DatasetName = vObj.DatasetPopupItems{get(h,'Value')};
            
            % Update the view
            refreshDataset(vObj);
            refreshItemsTable(vObj);
            refreshSpeciesDataTable(vObj);
            refreshSpeciesICTable(vObj);
                        
        end %function
        
        function onParametersPopup(vObj,h,e)
            
            vObj.TempData.RefParamName = vObj.ParameterPopupItems{get(h,'Value')};
           
            % Try importing to load data for Parameters view
            MatchIdx = strcmp({vObj.TempData.Settings.Parameters.Name},vObj.TempData.RefParamName);
            if any(MatchIdx)
                pObj = vObj.TempData.Settings.Parameters(MatchIdx);
                [StatusOk,Message,vObj.ParametersHeader,vObj.ParametersData] = importData(pObj,pObj.FilePath);
                if ~StatusOk
                    hDlg = errordlg(Message,'Parameter Import Failed','modal');
                    uiwait(hDlg);
                end
            end
             
            % Update the view
            refreshParameters(vObj);
            
        end %function
        
        function onAlgorithmPopup(vObj,h,e)
            
            vObj.TempData.AlgorithmName = vObj.AlgorithmPopupItems{get(h,'Value')};
            
            % Update the view
            updateAlgorithms(vObj);
            
        end %function
        
        function onGroupNamePopup(vObj,h,e)
            
            vObj.TempData.GroupName = vObj.DatasetGroupPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            refreshItemsTable(vObj);
            
        end %function
        
        function onIDNamePopup(vObj,h,e)
            
            vObj.TempData.IDName = vObj.DatasetIDPopupItems{get(h,'Value')};
            
            % Update the view
            updateDataset(vObj);
            
        end %function
        
        function onTableButtonPressed(vObj,h,e,TableTag)
            
            FlagRefreshTables = true;
            
            switch e.Interaction
                
                case 'Add'
                    
                    if strcmpi(TableTag,'OptimItems')
                        if ~isempty(vObj.TaskPopupTableItems) && ~isempty(vObj.GroupIDPopupTableItems)
                            NewTaskGroup = QSP.TaskGroup;
                            NewTaskGroup.TaskName = vObj.TaskPopupTableItems{1};
                            NewTaskGroup.GroupID = vObj.GroupIDPopupTableItems{1};
                            vObj.TempData.Item(end+1) = NewTaskGroup;
                        else
                            hDlg = errordlg('At least one task and the group column must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                            
                    elseif strcmpi(TableTag,'SpeciesData')
                        if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.PrunedDatasetHeader)
                            NewSpeciesData = QSP.SpeciesData;
                            NewSpeciesData.SpeciesName = vObj.SpeciesPopupTableItems{1};
                            NewSpeciesData.DataName = vObj.PrunedDatasetHeader{1};
                            DefaultExpression = 'x';
                            NewSpeciesData.FunctionExpression = DefaultExpression;
                            vObj.TempData.SpeciesData(end+1) = NewSpeciesData;
                        else
                            hDlg = errordlg('At least one task with active species and a non-empty datset must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                    elseif strcmpi(TableTag,'SpeciesIC')
                        if ~isempty(vObj.SpeciesPopupTableItems) && ~isempty(vObj.PrunedDatasetHeader)
                            NewSpeciesIC = QSP.SpeciesData;
                            NewSpeciesIC.SpeciesName = vObj.SpeciesPopupTableItems{1};
                            NewSpeciesIC.DataName = vObj.PrunedDatasetHeader{1};
                            DefaultExpression = 'x';
                            NewSpeciesIC.FunctionExpression = DefaultExpression;
                            vObj.TempData.SpeciesIC(end+1) = NewSpeciesIC;
                        else
                            hDlg = errordlg('At least one task with active species and a non-empty dataset must be defined in order to add an optimization item.','Cannot Add','modal');
                            uiwait(hDlg);
                            FlagRefreshTables = false;
                        end
                    end
                    
                case 'Remove'
                    
                    DeleteIdx = e.Indices;
                    if isempty(e.Indices)
                        return
                    end
                    
                    if DeleteIdx <= numel(vObj.TempData.Item) && strcmpi(TableTag,'OptimItems')
                        vObj.TempData.Item(DeleteIdx) = [];
                    elseif DeleteIdx <= numel(vObj.TempData.SpeciesData) && strcmpi(TableTag,'SpeciesData')
                        vObj.TempData.SpeciesData(DeleteIdx) = [];
                    elseif DeleteIdx <= numel(vObj.TempData.SpeciesIC) && strcmpi(TableTag,'SpeciesIC')
                        vObj.TempData.SpeciesIC(DeleteIdx) = [];
                    else
                        FlagRefreshTables = false;
                    end
            end
                
            % Update the view
            if FlagRefreshTables
                if strcmpi(TableTag,'OptimItems')
                    Title = 'Refreshing view';
                    hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
                    
                    % Tasks => Species
                    uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Tables...');
                    refreshItemsTable(vObj);
                    refreshSpeciesDataTable(vObj);
                    refreshSpeciesICTable(vObj);
                    
                    uix.utility.CustomWaitbar(1,hWbar,'Done');
                    if ~isempty(hWbar) && ishandle(hWbar)
                        delete(hWbar);
                    end
                    
                elseif strcmpi(TableTag,'SpeciesData')
                    refreshSpeciesDataTable(vObj);
                elseif strcmpi(TableTag,'SpeciesIC')
                    refreshSpeciesICTable(vObj);
                end
            end
            
        end %function
        
        function onTableEdit(vObj,h,e,TableTag)
            
            NewData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            % Update entry
            if strcmpi(TableTag,'OptimItems')            
                if ColIdx == 1
                    vObj.TempData.Item(RowIdx).TaskName = NewData{RowIdx,1};            
                elseif ColIdx == 2
                    vObj.TempData.Item(RowIdx).GroupID = NewData{RowIdx,2};
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                if ColIdx == 1
                    vObj.TempData.SpeciesData(RowIdx).DataName = NewData{RowIdx,1};
                elseif ColIdx == 2
                    vObj.TempData.SpeciesData(RowIdx).SpeciesName = NewData{RowIdx,2};                    
                elseif ColIdx == 4
                    vObj.TempData.SpeciesData(RowIdx).FunctionExpression = NewData{RowIdx,4};
                elseif ColIdx == 5
                    vObj.TempData.SpeciesData(RowIdx).ObjectiveName = NewData{RowIdx,5};
                end
                
            elseif strcmpi(TableTag,'SpeciesIC')
                if ColIdx == 1
                    vObj.TempData.SpeciesIC(RowIdx).SpeciesName = NewData{RowIdx,1};
                elseif ColIdx == 2
                    vObj.TempData.SpeciesIC(RowIdx).DataName = NewData{RowIdx,2};
                elseif ColIdx == 3
                    vObj.TempData.SpeciesIC(RowIdx).FunctionExpression = NewData{RowIdx,3};
                end
            end
            
            % Update the view
            if strcmpi(TableTag,'OptimItems')
                Title = 'Refreshing view';
                hWbar = uix.utility.CustomWaitbar(0,Title,'',false);
                
                % Tasks => Species
                uix.utility.CustomWaitbar(0.5,hWbar,'Refresh Tables...');
                refreshItemsTable(vObj);
                refreshSpeciesDataTable(vObj);
                refreshSpeciesICTable(vObj);
                
                uix.utility.CustomWaitbar(1,hWbar,'Done');
                if ~isempty(hWbar) && ishandle(hWbar)
                    delete(hWbar);
                end
                
            elseif strcmpi(TableTag,'SpeciesData')
                refreshSpeciesDataTable(vObj);
            elseif strcmpi(TableTag,'SpeciesIC')
                refreshSpeciesICTable(vObj);
            end
            
        end %function
        
        function onTableSelect(vObj,h,e,TableTag)
            
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            RowIdx = Indices(1,1);
            
            h.SelectedRows = RowIdx;
            
            % Update the view
            if strcmpi(TableTag,'OptimItems')
                updateItemsTable(vObj);                
            elseif strcmpi(TableTag,'SpeciesData')
                updateSpeciesDataTable(vObj);
            elseif strcmpi(TableTag,'SpeciesIC')
                updateSpeciesICTable(vObj);
            end
            
        end %function
        
        function onSpeciesDataTablePlot(vObj,h,e)
                         
            % Update the view
%             vObj.semaphore.wait();
%             vObj.semaphore.lock();
            ME = [];
            try
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotSpeciesTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            % Plot
            plotData(vObj, false); % don't re-run simulations since we are just changing visualization options


                updateVisualizationView(vObj);
            catch ME
            end
%             vObj.semaphore.release();
            if ~isempty(ME)
                rethrow(ME)
            end
            
        end %function
        
        function onItemsTableSelectionPlot(vObj,h,e)
%             pause(0.25)
%             waitfor(vObj, 'Semaphore', 'free');
%             vObj.Semaphore = 'locked';
%             vObj.semaphore.wait();
%             vObj.semaphore.lock();
            
            ME = [];
            try
                Indices = e.Indices;
                if isempty(Indices)
                    return;
                end

                RowIdx = Indices(1,1);

                h.SelectedRows = RowIdx;

                % Update the view
                updateVisualizationView(vObj);
            catch ME
            end
%             vObj.Semaphore = 'free';
%             vObj.semaphore.release();
            if ~isempty(ME)
                rethrow(ME);
            end
            
        end %function  
        
        function onItemsTablePlot(vObj,h,e)
            
            % Temporarily disable column 1 to prevent quick clicking of
            % 'Include'
            OrigColumnEditable = get(h,'ColumnEditable');
            ColumnEditable = OrigColumnEditable;
            ColumnEditable(1) = false;
            set(h,'ColumnEditable',ColumnEditable);  
            
            ThisData = get(h,'Data');
            Indices = e.Indices;
            if isempty(Indices)
                return;
            end
            
            RowIdx = Indices(1,1);
            ColIdx = Indices(1,2);
            
            h.SelectedRows = RowIdx;
            
            vObj.Data.PlotItemTable(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
            
            % Plot
            plotData(vObj);
            
            % Update the view
            updateVisualizationView(vObj);
            
            % Enable column 1
            set(h,'ColumnEditable',OrigColumnEditable);
            
        end %function
        
        function onSelectedLinePlot(vObj,h,e)
            
            disp('onSelectedLinePlot');
            % Update
            updateVisualizationView(vObj);
            
        end %function
        
        function onPlotParameters(vObj,h,e)
            
            % Plot
%             pause(0.35)
%             waitfor(vObj, 'Semaphore', 'free');
%             vObj.Semaphore = 'locked';
%             vObj.semaphore.wait();
%             vObj.semaphore.lock();
            ME = [];
            try
                plotData(vObj);
            
                % Update
                updateVisualizationView(vObj);
            catch ME
                warning(ME)
            end

%             vObj.Semaphore = 'free';
%             vObj.semaphore.release();
            if ~isempty(ME)
                rethrow(ME)
            end            
            
        end %function
        
        function onHistoryTableButtonPlot(vObj,h,e)
            pause(0.25);
%             waitfor(vObj, 'Semaphore', 'free');
%             vObj.Semaphore = 'locked';           
%             vObj.semaphore.wait();
%             vObj.semaphore.lock();


            ME = [];
            try

                Interaction = e.Interaction;
                Indices = e.Indices;

                switch Interaction
                    case 'Add'
                        vObj.Data.PlotProfile(end+1) = QSP.Profile;
                        vObj.Data.SelectedProfileRow = numel(vObj.Data.PlotProfile);
                        %                     vObj.Data.ItemModels

                    case 'Remove'

                        if isempty(Indices) || Indices > length(vObj.Data.PlotProfile)
                            %                             vObj.Semaphore = 'free';
                            %                             vObj.semaphore.release();
                            return
                        end

                        if numel(vObj.Data.PlotProfile) > 1
                            vObj.Data.PlotProfile(Indices) = [];
                        else
                            vObj.Data.PlotProfile = QSP.Profile.empty(0,1);
                        end

                        if size(vObj.h.SpeciesGroup,3) >=Indices
                            delete([vObj.h.SpeciesGroup{:,:,Indices}]); % remove objects
                            vObj.h.SpeciesGroup(:,:,Indices) = []; % remove group
                        end

                        vObj.Data.SelectedProfileRow = [];

                    case 'Duplicate'
                        if isempty(Indices)
                            %                             vObj.Semaphore = 'free';
                            %                             vObj.semaphore.release();

                            return
                        end

                        vObj.Data.PlotProfile(end+1) = QSP.Profile;
                        vObj.Data.PlotProfile(end).Source = vObj.Data.PlotProfile(Indices).Source;
                        vObj.Data.PlotProfile(end).Description = vObj.Data.PlotProfile(Indices).Description;
                        vObj.Data.PlotProfile(end).Show = vObj.Data.PlotProfile(Indices).Show;
                        vObj.Data.PlotProfile(end).Values = sortrows(vObj.Data.PlotProfile(Indices).Values,1);
                        vObj.Data.SelectedProfileRow = numel(vObj.Data.PlotProfile);
                end

                % Update the view
                updateVisualizationView(vObj);
            catch ME
            end
%             vObj.Semaphore = 'free';
%             vObj.semaphore.release();
            if ~isempty(ME)
                rethrow(ME);
            end
            
        end %function
        
        function onHistoryTableSelectionPlot(vObj,h,e)
            
%             hFigure = ancestor(vObj.h.MainLayout,'Figure');
%             set(hFigure,'pointer','watch');
%             drawnow;
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices'))
                if numel(e.Indices) >= 1
                    vObj.Data.SelectedProfileRow = e.Indices(1); % Temporary
                else
%                     vObj.Data.SelectedProfileRow = [];
                end
            end
            
            % Turn off call to updateVisualizationView (this prevents
            % "Show" checkbox from taking into effect since
            % SelectionChanged (which calls updateVisualizationView) is
            % triggered before EditChanged
            % Update the view
            updateVisualizationView(vObj);
%             updateVisualizationPlot(vObj);
            
%             set(hFigure,'pointer','arrow');
%             drawnow;
            
        end %function
        
        function onHistoryTableEditPlot(vObj,h,e)
            ME = []; % exception object
            try
                pause(0.25)
%                 waitfor(vObj, 'Semaphore', 'free'); % wait until previous operations have finished

%                 vObj.Semaphore = 'locked'; % lock while modifying properties
%                 vObj.semaphore.wait();                
%                 vObj.semaphore.lock();

                hFigure = ancestor(vObj.h.MainLayout,'Figure');
                set(hFigure,'pointer','watch');
                drawnow;

                ThisData = get(h,'Data');
                Indices = e.Indices;
                if isempty(Indices)
                    return;
                end
                RowIdx = Indices(1,1);
                ColIdx = Indices(1,2);            

                if ~isempty(RowIdx)
                    ThisProfile = vObj.Data.PlotProfile(RowIdx);
                    switch ColIdx
                        case 2
                            % Show
                            ThisProfile.Show = ThisData{RowIdx,ColIdx};
                        case 3
                            % Source
                            % Re-import the source values for
                            % ThisProfile.Source (before changing)
                            ThisSourceData = {};
                            if ~isempty(ThisProfile.Source) && ~any(strcmpi(ThisProfile.Source,{'','N/A'}))
                                [~,~,ThisSourceData] = importParametersSource(vObj.Data,ThisProfile.Source);
                            end     

                            % Get the name of the new source                        
                            NewSource = ThisData{RowIdx,ColIdx};

                            % First check if values have been changed. If so,
                            % then alert the user
                            if ~isempty(ThisSourceData)
                                Result = 'Yes';
                                [~,ix1] = sort(ThisProfile.Values(:,1));
                                [~,ix2] = sort(ThisSourceData(:,1));

                                if ~isequal(ThisProfile.Values(ix1,2), ThisSourceData(ix2,2)) && ...
                                        ~any(strcmpi(ThisProfile.Source,{'','N/A'})) && ~any(strcmpi(NewSource,{'','N/A'}))

                                    % Has the source changed?
                                    if ~strcmpi(ThisProfile.Source,NewSource)
                                        % Confirm with user
                                        Prompt = 'Changing the source will clear overriden source parameters. Do you want to continue?';                                
                                    else
                                        % Source did not change but reset the parameter values
                                        Prompt = 'This action will clear overriden source parameters. Do you want to continue? Press Cancel to save.';                                         
                                    end
                                    Result = questdlg(Prompt,'Continue?','Yes','Cancel','Cancel');                                
                                end

                            end
                            % Set the source and values
                            if isempty(NewSource) || any(strcmpi(NewSource,{'','N/A'}))
                                ThisProfile.Source = '';
                                ThisProfile.Values = cell(0,2);
                            elseif isempty(ThisSourceData) || strcmpi(Result,'Yes')



                                obj = vObj.Data;
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

                                optParams = paramData(strcmpi(paramData(:,idxInclude),'yes'),:);
                                optParamNames = optParams(:,idxName);
                                optParamValues = optParams(:,idx_p0);    

                                % Get NewSource Data
                                NewSourceData = {};
                                if ~isempty(NewSource) && ~any(strcmpi(NewSource,{'','N/A'}))
                                    [StatusOk,Message,NewSourceData] = importParametersSource(vObj.Data,NewSource);
                                    if ~StatusOk
                                        hDlg = errordlg(Message,'Cannot import','modal');
                                        uiwait(hDlg);
                                    end
                                end

                                ThisProfile.Source = NewSource;
                                [~,index] = sort(upper(NewSourceData(:,1)));
                                ThisProfile.Values = NewSourceData(index,:);

    %                             inSet = ismember(ThisProfile.Values(:,1), optParamNames);
    %                             idxMissing = ~ismember(optParamNames, ThisProfile.Values(:,1));
    %                             ThisProfile.Values = ThisProfile.Values(inSet,:);
                                % add in any missing entries, use default values
    %                             ThisProfile.Values = [ThisProfile.Values; [optParamNames(idxMissing), optParamValues(idxMissing)]];



                            end

                        case 4
                            % Description
                            ThisProfile.Description = ThisData{RowIdx,ColIdx};
                    end


                end

                % Update the view
                updateVisualizationView(vObj);

                set(hFigure,'pointer','arrow');
                drawnow;
            catch ME                
            end
%             vObj.Semaphore = 'free';
%             vObj.semaphore.release();
            if ~isempty(ME)
                rethrow(ME);
            end
        end %function
        
%         function onPlotParametersSourcePopup(vObj,h,e)
%             
%             Options = get(h,'String');
%             NewSource = Options{get(h,'Value')};
%             ThisProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);
%             
%             if isempty(NewSource) || strcmpi(NewSource,'N/A')
%                 ThisProfile.Source = '';
%                 ThisProfile.Values = cell(0,2);
%             else
%                 [StatusOk,Message,PlotParametersData] = importParametersSource(vObj.Data,NewSource);
%                 if ~StatusOk
%                     hDlg = errordlg(Message,'Cannot import','modal');
%                     uiwait(hDlg);
%                 else
%                     % Finally, set the new source                    
%                     ThisProfile.Source = NewSource;
%                     ThisProfile.Values = PlotParametersData;
%                 end
%             end
%             
%             % Update the view
%             updateVisualizationView(vObj);
%             update(vObj);
%         end %function
                
        function onParametersTablePlot(vObj,h,e)
            pause(0.25);
%             vObj.semaphore.wait();
%             vObj.semaphore.lock();
            
            ME = [];
            h_applyButton = findobj(vObj.h.PlotApplyParametersButtonLayout, 'Tag','ApplyParameters');
            set(h_applyButton, 'Enable', 'off')
%             try
                ThisData = get(h,'Data');
                Indices = e.Indices;
                if isempty(Indices)
                    return;
                end

                RowIdx = Indices(1,1);
                ColIdx = Indices(1,2);

                if ~isempty(vObj.Data.SelectedProfileRow) && ~isempty(ThisData{RowIdx,ColIdx})
                    ThisProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);                
                    if ischar(ThisData{RowIdx,ColIdx})
                        ThisProfile.Values(RowIdx,ColIdx) = {str2double(ThisData{RowIdx,ColIdx})};
                    else
                        ThisProfile.Values(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
                    end
                    
%                     assert(isscalar(ThisData(RowIdx,ColIdx)))
%                     profileRow = find(strcmp(ThisData(RowIdx,1),ThisProfile.Values(:,1)));
%                     assert(size(ThisData(RowIdx,ColIdx),2) == 1);
%                     ThisProfile.Values(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
                    
%                     vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow) = ThisProfile;
%                     vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow).Values(RowIdx,ColIdx) = ThisData(RowIdx,ColIdx);
%                     vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow).Values = ThisData(:,1:2);

                else
                    hDlg = errordlg('Invalid value specified for parameter. Values must be numeric','Invalid value','modal');
                    uiwait(hDlg);
                end

                % Update the view
                updateVisualizationView(vObj);
%             catch ME
%             end
            
%             vObj.semaphore.release();
           set(h_applyButton, 'Enable', 'on')
            
        end %function   
        
        function onSaveParametersAsVPopButton(vObj,h,e)
            
            Options.Resize = 'on';
            Options.WindowStyle = 'modal';
            DefaultAnswer = {datestr(now,'dd-mmm-yyyy_HH-MM-SS')};
            Answer = inputdlg('Save Virtual Population as?','Save VPop',[1 50],DefaultAnswer,Options);
            
            if ~isempty(Answer)
                AllVPops = vObj.Data.Settings.VirtualPopulation;
                AllVPopNames = get(AllVPops,'Name');
                AllVPopFilePaths = get(AllVPops,'FilePath');
                
                % Append the source with the postfix appender
                ThisProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);
                ThisVPopName = matlab.lang.makeValidName(strtrim(Answer{1}));
                ThisVPopName = sprintf('%s - %s',ThisProfile.Source,ThisVPopName);
                
                ThisFilePath = fullfile(vObj.Data.Session.RootDirectory, vObj.Data.OptimResultsFolderName,[ThisVPopName '.xlsx']);
                
                if isempty(ThisVPopName) || any(strcmpi(ThisVPopName,AllVPopNames)) || ...
                        any(strcmpi(ThisFilePath,AllVPopFilePaths))
                    Message = 'Please provide a valid, unique virtual population name.';
                    Title = 'Invalid name';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                else
                    
                    % Create a new virtual population
                    vpopObj = QSP.VirtualPopulation;
                    vpopObj.Session = vObj.Data.Session;
                    vpopObj.Name = ThisVPopName;                    
                    vpopObj.FilePath = ThisFilePath;                 
                    
                    ThisProfile = vObj.Data.PlotProfile(vObj.Data.SelectedProfileRow);
                    Values = ThisProfile.Values'; % Take first 2 rows and transpose
                    
                    xlwrite(vpopObj.FilePath,Values); 

                    % Update last saved time
                    updateLastSavedTime(vpopObj);
                    % Validate
                    validate(vpopObj,false);
                    
                    % Call the callback
                    evt.InteractionType = sprintf('Updated %s',class(vpopObj));
                    evt.Data = vpopObj;
                    vObj.callCallback(evt);           
                    
                    % Update the view
                    updateVisualizationView(vObj);
                end
            end
            
        end %function
        
        function onPlotItemsTableContextMenu(vObj,h,e)
            
            SelectedRow = get(vObj.h.PlotItemsTable,'SelectedRows');
            if ~isempty(SelectedRow)
                ThisColor = vObj.Data.PlotItemTable{SelectedRow,2};
                
                NewColor = uisetcolor(ThisColor);
                
                if ~isequal(NewColor,0)
                    vObj.Data.PlotItemTable{SelectedRow,2} = NewColor;
                    
                    % Plot
                    plotData(vObj, false);
                    
                    % Update the view
                    updateVisualizationView(vObj);
                    
                end
            else
                hDlg = errordlg('Please select a row first to set new color.','No row selected','modal');
                uiwait(hDlg);
            end
        end %function
        
        function onNavigation(vObj,View)
            
            onNavigation@uix.abstract.CardViewPane(vObj,View);
            
        end %function
        
    end
        
    
end %classdef