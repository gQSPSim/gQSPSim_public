classdef Logger < mlog.Logger
    
    %   Copyright 2021 The MathWorks Inc.
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Logger(name, filepath)
            
            arguments
                name (1,1) string = "Advanced_Logger_for_MATLAB"
                filepath (1,1) string = fullfile(tempdir, "templogFile.csv")
            end
            
            % Construct the logger
            
            % Call superclass constructor with the same inputs
            obj@mlog.Logger(name, filepath);
            
            % Instruct Logger to use the message subclass
            obj.MessageConstructor = @QSPViewerNew.Widgets.MessageLogger;
            
            % increase buffer size
            obj.BufferSize = 1e4;
            
            % assign logfile
            obj.LogFile = filepath;
            
        end %function
        
    end %methods
    
    
    
    %% Public Methods
    methods
        
        function varargout = write(obj, Name, Type, varargin)
            % write a message to the log
            %
            % Syntax:
            %       logObj.write(name, type, level,...)
            
            % Check arguments
            arguments
                obj  (1,1)
                Name (1,1) string
                Type (1,1) string
            end
            arguments (Repeating)
                varargin
            end
            
            % Construct the message
            msg = constructMessage(obj, varargin{:});
            
            % Was a message created? Note that it might be empty if the
            % level did not meet any log level thresholds.
            if ~isempty(msg)
                
                % Add custom properties
                msg.Name = Name;
                msg.Type = Type;
                
                % Add the message to the log
                obj.addMessage(msg);
                
            end %if ~isempty(msg)
            
            % Send msg output if requested
            if nargout
                varargout{1} = msg;
            end
            
        end %function
        
    end %methods
    
    %% Protected methods
    methods (Access = protected)
        function writeToLogFile(obj, msgObj)
            % Writes a log message
            
            arguments
                obj
                msgObj (1,1) mlog.Message
            end
            
            try
                T = readtable(obj.LogFile);
                
                towriteT = table(msgObj.Level, msgObj.Name, msgObj.Type, msgObj.Text, ...
                    'VariableNames', {'Level', 'Name', 'Type', 'Text'});
                
                if isempty(T)
                    writetable(towriteT, obj.LogFile);
                else
                    writetable(towriteT, obj.LogFile, 'WriteMode','Append',...
                        'WriteVariableNames',false);
                end
                
            catch err
                warning(err.identifier, '%s', err.message);
            end %try
            
        end %function
        
    end
    
end %classdef


