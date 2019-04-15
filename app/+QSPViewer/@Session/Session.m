classdef Session < uix.abstract.ViewPane
    % Session - View Pane for the object
    % ---------------------------------------------------------------------
    % Display a viewer/editor for the object
    %

    
    %   Copyright 2014-2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 259 $
    %   $Date: 2016-08-24 16:03:36 -0400 (Wed, 24 Aug 2016) $
    % ---------------------------------------------------------------------
  
    
    %% Properties    
    properties (SetAccess=private)
        timerObj
    end
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = Session(varargin)
            
            % Call superclass constructor
            obj = obj@uix.abstract.ViewPane(varargin{:});
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the view
            obj.refresh();
            
            % Create timer
            obj.timerObj = timer(...
                'ExecutionMode','fixedRate',...
                'BusyMode','drop',... 
                'Name','QSPtimer',...
                'Period',1*60,... % minutes
                'StartDelay',1,...
                'TimerFcn',@(h,e)onTimerCallback(obj,h,e));            
        end
        
        % Destructor
        function delete(obj)
            stop(obj.timerObj)
            delete(obj.timerObj)
        end
        
    end %methods
    
    
    %% Callbacks
    methods
        
        function onFileSelection(vObj,h,evt) %#ok<*INUSD>
            
            StatusOk = true;
            
            % Which field was modified?
            Field = h.Tag;
            
            % Update the value, and trap errors
            try
                vObj.Data.(Field) = evt.NewValue;
            catch err
                StatusOk = false;
                hDlg = errordlg(err.message,Field,'modal');
                uiwait(hDlg);
            end
            
            % Refresh data (no need to refresh data for auto-save path
            % change)
            if ~strcmpi(Field,'RelativeAutoSavePath')               
                refreshData(vObj.Data.Settings);
            end
            
            % Update the view
            refresh(vObj);
            
            % Call the callback
            if StatusOk
                evt.InteractionType = Field;
                vObj.callCallback(evt);
            end
            
        end %function
        
        function onUDFSelection(vObj,h,evt)
            
            % remove old path
            removeUDF(vObj.Data);
            
            % assign value & refresh
            onFileSelection(vObj,h,evt);
           
            % add new path
            addUDF(vObj.Data);
            
        end %function
        
        function onAutoSaveChecked(vObj,h,~)
        
            vObj.Data.UseAutoSave = logical(h.Value);
            
            % Use checkbox to turn on/off timer
            if vObj.Data.UseAutoSave
                start(vObj.timerObj);
            else
                stop(vObj.timerObj);
            end
             
            % Update the view
            refresh(vObj);
            
            % Call the callback
            evt.InteractionType = 'UseAutoSave';
            vObj.callCallback(evt);
            
        end %function
        
        function onAutoSaveFrequencyEdited(vObj,h,~) %#ok<*INUSD>
            
            StatusOk = true;
            
            % Update the value, and trap errors
            Field = 'AutoSaveFrequency';
            try
                vObj.Data.AutoSaveFrequency = str2double(get(h,'String'));
                stop(vObj.timerObj)
                vObj.timerObj.Period = vObj.Data.AutoSaveFrequency * 60; % minutes
                vObj.timerObj.StartDelay = 0; % Reduce start delay
                if vObj.Data.UseAutoSave
                    start(vObj.timerObj)
                end
            catch err
                StatusOk = false;
                hDlg = errordlg(err.message,Field,'modal');
                uiwait(hDlg);
            end
            
            % Update the view
            refresh(vObj);
            
            % Call the callback
            if StatusOk
                evt.InteractionType = 'AutoSaveFrequency';
                vObj.callCallback(evt);
            end
            
        end %function
        
        function onAutoSaveBeforeRunChecked(vObj,h,~)
            
            vObj.Data.AutoSaveBeforeRun = logical(h.Value);
            
            % Update the view
            refresh(vObj);
            
            % Call the callback
            evt.InteractionType = 'AutoSaveBeforeRun';
            vObj.callCallback(evt);
            
        end %function
        
        function onTimerCallback(vObj,h,evt)
            
            autoSaveFile(vObj.Data,'TimerObj',vObj.timerObj);
            
        end %function
        
    end %methods
        
    
end %classdef