classdef Session < QSPViewerNew.Application.ViewPane 
    %  Session - A Class for the session settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.Session
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  1/9/20
    % ---------------------------------------------------------------------
    properties
        
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function obj = Session(varargin)  
            %Call superclass constructor
            RunVis = false;
            obj = obj@QSPViewerNew.Application.ViewPane(RunVis,varargin{:});
            
            %create the objects on our end
            obj.create();
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interaction methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = protected) 
      
        function create(obj)
            create@QSPViewerNew.Application.ViewPane(obj)
        end
        
        function refresh(obj)
            
        end
        
        function update(obj)
            
        end
        
    end
    
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
    end
    
end

