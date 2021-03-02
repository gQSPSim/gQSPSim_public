classdef MessageLogger < mlog.Message
    
    %   Copyright 2021 The MathWorks Inc.
    
    %#ok<*PROP>
    
    
    %% Properties
    properties
        Name (1,1) string
        Type (1,1) string
    end
    
    
    %% Public Methods
    methods
        
        function t = toTable(obj)
            % Convert array of messages to a table
            
            % Call superclass method
            t = obj.toTable@mlog.Message();
            
            % Find any invalid handles
            idxValid = isvalid(obj);
            
            % Create variables
            Name(idxValid,1) = vertcat( obj(idxValid).Name );
            Type(idxValid,1) = vertcat( obj(idxValid).Type );
            
            % Insert Variables
            t = addvars(t, Name, Type, 'after', "Level");
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = {?mlog.Message, ?mlog.Logger})
        
        function str = createDisplayMessage(obj)
            % Customize the message display format
            
            str = sprintf("%-7s %s, %s, %s", obj.Level, obj.Name,...
                obj.Type, obj.Text);
            
        end %function
        
    end %methods
    
    %% Get/Set methods
    methods
        
        function set.Type(obj, value)
            validatestring(value, QSPViewerNew.Application.ApplicationUI.ItemTypes(:,2));
            obj.Type = value;
        end
    end
    
end %classdef

