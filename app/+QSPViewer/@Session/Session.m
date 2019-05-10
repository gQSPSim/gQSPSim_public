classdef Session <  uix.abstract.CardViewPane % uix.abstract.ViewPane
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
  
    properties (SetAccess=private)
        timerObj
    end
    
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);        
    end
    
    
    %% Constructor and Destructor
    methods
        
%         % Constructor
%         function obj = Session(varargin)
% 
%             % Call superclass constructor
%             RunVis = false;
%             obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
% 
%            
%             % Create the graphics objects
%             obj.create();
%             
%             % Populate public properties from P-V input pairs
%             obj.assignPVPairs(varargin{:});
%             
%             % Mark construction complete to tell refresh the graphics exist
%             obj.IsConstructed = true;
%             
%             % Refresh the view
%             obj.refresh();
%             
%         end
        
% Constructor
        function obj = Session(varargin)
            
%             % Call superclass constructor
%             obj = obj@uix.abstract.ViewPane(varargin{:});
            % Call superclass constructor
            RunVis = false;
            obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
            
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
            
%             StatusOk = true;
            
            % Which field was modified?
            Field = h.Tag;
            
            % Update the value, and trap errors
            try
                vObj.TempData.(Field) = evt.NewValue;
            catch err
%                 StatusOk = false;
                hDlg = errordlg(err.message,Field,'modal');
                uiwait(hDlg);
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
        function onUDFSelection(vObj,h,evt)
            
            % remove old path
            removeUDF(vObj.TempData);
            
            % assign value & refresh
            onFileSelection(vObj,h,evt);
           
            % add new path
            addUDF(vObj.TempData);

           
        end
        
        function onParallelCheckbox(vObj,h,evt)
            vObj.TempData.UseParallel = h.Value;
            if ~vObj.TempData.UseParallel
                set(vObj.h.ParallelCluster, 'Enable', 'off')
            else
                set(vObj.h.ParallelCluster, 'Enable', 'on')
                if iscell(vObj.h.ParallelCluster.String)
                    if isempty(vObj.h.ParallelCluster.String)
                        vObj.h.ParallelCluster.String = parallel.clusterProfiles;
                    end
                    vObj.TempData.ParallelCluster = vObj.h.ParallelCluster.String{vObj.h.ParallelCluster.Value};
                else
                    vObj.TempData.ParallelCluster = vObj.h.ParallelCluster.String;
                end
            end
        end
        
        function onAutosaveTimerCheckbox(vObj,h,evt)
            vObj.TempData.UseAutoSaveTimer = logical(h.Value);
            if ~vObj.TempData.UseAutoSaveTimer
                set(vObj.h.AutoSaveFrequencyEdit, 'Enable', 'off')
            else
                set(vObj.h.AutoSaveFrequencyEdit, 'Enable', 'on')               
            end
            
            update(vObj);
            
        end        
        
        function onParallelClusterPopup(vObj,h,evt)
            vObj.TempData.ParallelCluster = h.String{h.Value};
        end
        
        
        function onAutoSaveFrequencyEdited(vObj,h,~) %#ok<*INUSD>
            
            % Update the value, and trap errors
            Field = 'AutoSaveFrequency';
            try
                vObj.TempData.AutoSaveFrequency = str2double(get(h,'String'));
            catch err
                hDlg = errordlg(err.message,Field,'modal');
                uiwait(hDlg);
            end
            
            % Update the view
            update(vObj);
            
        end %function
        
        function onAutoSaveBeforeRunChecked(vObj,h,~)
            
            vObj.TempData.AutoSaveBeforeRun = logical(h.Value);
            
            % Update the view
            update(vObj);
            
        end %function
        
        function onTimerCallback(vObj,h,evt)
            
            % Note, autosave is applied to vObj.Data, not vObj.TempData
            autoSaveFile(vObj.Data,'TimerObj',vObj.timerObj);
            
        end %function        
        
        function onButtonPress(vObj,h,e)
            
            ThisTag = get(h,'Tag');
            
            % remove old path
            removeUDF(vObj.TempData);
            
            % Invoke superclass's onButtonPress
            onButtonPress@uix.abstract.CardViewPane(vObj,h,e);
            
            % add new path
            addUDF(vObj.TempData);
            
            switch ThisTag
                case 'Save'
                    try
                        % Refresh data (no need to refresh data for auto-save path
                        % change)
                        refreshData(vObj.Data.Settings);
                        
                        % Stop to set the period and start delay
                        stop(vObj.timerObj)
                        vObj.timerObj.Period = vObj.Data.AutoSaveFrequency * 60; % minutes
                        vObj.timerObj.StartDelay = 0; % Reduce start delay
                        % Only restart if UseAutoSave is true
                        if vObj.TempData.UseAutoSaveTimer
                            start(vObj.timerObj)
                        end
                    catch err

                        hDlg = errordlg(err.message,Field,'modal');
                        uiwait(hDlg);
                    end
            end

        end %function        
        
    end
        
    
% =======
% classdef Session < uix.abstract.CardViewPane % uix.abstract.ViewPane
%     % Session - View Pane for the object
%     % ---------------------------------------------------------------------
%     % Display a viewer/editor for the object
%     %
% 
%     
%     %   Copyright 2014-2016 The MathWorks, Inc.
%     %
%     % Auth/Revision:
%     %   MathWorks Consulting
%     %   $Author: rjackey $
%     %   $Revision: 259 $
%     %   $Date: 2016-08-24 16:03:36 -0400 (Wed, 24 Aug 2016) $
%     % ---------------------------------------------------------------------
%   
%     
%     %% Properties    
%     properties (SetAccess=private)
%         timerObj
%     end
%     
%     
%     %% Methods in separate files with custom permissions
%     methods (Access=protected)
%         create(obj);        
%     end
%     
%     
%     %% Constructor and Destructor
%     methods
%         
%         % Constructor
%         function obj = Session(varargin)
%             
% %             % Call superclass constructor
% %             obj = obj@uix.abstract.ViewPane(varargin{:});
%             % Call superclass constructor
%             RunVis = false;
%             obj = obj@uix.abstract.CardViewPane(RunVis,varargin{:});
%             
%             % Create the graphics objects
%             obj.create();
%             
%             % Populate public properties from P-V input pairs
%             obj.assignPVPairs(varargin{:});
%             
%             % Mark construction complete to tell refresh the graphics exist
%             obj.IsConstructed = true;
%             
%             % Refresh the view
%             obj.refresh();
%             
%             % Create timer
%             obj.timerObj = timer(...
%                 'ExecutionMode','fixedRate',...
%                 'BusyMode','drop',... 
%                 'Name','QSPtimer',...
%                 'Period',1*60,... % minutes
%                 'StartDelay',1,...
%                 'TimerFcn',@(h,e)onTimerCallback(obj,h,e));            
%         end
%         
%         % Destructor
%         function delete(obj)
%             stop(obj.timerObj)
%             delete(obj.timerObj)
%         end
%         
%     end %methods
%     
%     
%     %% Callbacks
%     methods
%         
%         function onFileSelection(vObj,h,evt) %#ok<*INUSD>
%             
% %             StatusOk = true;
%             
%             % Which field was modified?
%             Field = h.Tag;
%             
%             % Update the value, and trap errors
%             try
%                 vObj.TempData.(Field) = evt.NewValue;
%             catch err
% %                 StatusOk = false;
%                 hDlg = errordlg(err.message,Field,'modal');
%                 uiwait(hDlg);
%             end
%             
%             % Update the view
%             update(vObj);
%             
%         end %function
%         
%         function onUDFSelection(vObj,h,evt)
%             
%             % assign value & refresh
%             onFileSelection(vObj,h,evt);
%             
%         end %function
%         
%         function onAutoSaveChecked(vObj,h,~)
%         
%             vObj.TempData.UseAutoSave = logical(h.Value);
%              
%             % Update the view
%             update(vObj);
%             
%         end %function
%         
%         function onAutoSaveFrequencyEdited(vObj,h,~) %#ok<*INUSD>
%             
%             % Update the value, and trap errors
%             Field = 'AutoSaveFrequency';
%             try
%                 vObj.TempData.AutoSaveFrequency = str2double(get(h,'String'));
%             catch err
%                 hDlg = errordlg(err.message,Field,'modal');
%                 uiwait(hDlg);
%             end
%             
%             % Update the view
%             update(vObj);
%             
%         end %function
%         
%         function onAutoSaveBeforeRunChecked(vObj,h,~)
%             
%             vObj.TempData.AutoSaveBeforeRun = logical(h.Value);
%             
%             % Update the view
%             update(vObj);
%             
%         end %function
%         
%         function onTimerCallback(vObj,h,evt)
%             
%             % Note, autosave is applied to vObj.Data, not vObj.TempData
%             autoSaveFile(vObj.Data,'TimerObj',vObj.timerObj);
%             
%         end %function
%         
%         function onButtonPress(vObj,h,e)
%             
%             ThisTag = get(h,'Tag');
%             
%             % remove old path
%             removeUDF(vObj.Data);
%             
%             % Invoke superclass's onButtonPress
%             onButtonPress@uix.abstract.CardViewPane(vObj,h,e);
%             
%             % add new path
%             addUDF(vObj.Data);
%             
%             switch ThisTag
%                 case 'Save'
%                     try
%                         % Refresh data (no need to refresh data for auto-save path
%                         % change)
%                         refreshData(vObj.Data.Settings);
%                         
%                         % Stop to set the period and start delay
%                         stop(vObj.timerObj)
%                         vObj.timerObj.Period = vObj.Data.AutoSaveFrequency * 60; % minutes
%                         vObj.timerObj.StartDelay = 0; % Reduce start delay
%                         % Only restart if UseAutoSave is true
%                         if vObj.Data.UseAutoSave
%                             start(vObj.timerObj)
%                         end
%                     catch err
% 
%                         hDlg = errordlg(err.message,Field,'modal');
%                         uiwait(hDlg);
%                     end
%             end
% 
%         end %function
%         
%     end %methods
%         
    
% >>>>>>> master
end %classdef