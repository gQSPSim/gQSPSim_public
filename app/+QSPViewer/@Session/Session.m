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
            
            % Refresh data
            refreshData(vObj.Data.Settings);
            
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
            removeUDF(obj);
            
            % assign value & refresh
            onFileSelection(vObj,h,evt);
           
            % add new path
            addUDF(obj);

           
        end
        
    end
        
    
end %classdef