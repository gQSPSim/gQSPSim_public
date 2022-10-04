classdef Logger < mlog.Logger 
    
    
    %% Constructor / Destructor
    methods
        
        function obj = Logger(name, filepath)
            
            arguments
                name (1,1) string = "Advanced_Logger_for_MATLAB"
                filepath (1,1) string = fullfile(tempdir, "temp_log.csv")
            end
           
            
            % Call superclass constructor with the same inputs
            obj@mlog.Logger(name, filepath);
            
            % change logfile to csv if it TXT
            [~,~,ext] = fileparts(obj.LogFile);
            if ~strcmp(ext,'.csv')
                obj.LogFile = strrep(obj.LogFile,ext,'.csv');
            end
            
            % Instruct Logger to use the message subclass
            obj.MessageConstructor = @QSPViewerNew.Widgets.MessageLogger;
            
            % increase buffer size
            obj.BufferSize = 1e4;
            
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
        
        function rename(obj, Name)
            obj.Name = Name;
            
            % rename logger file accordingly
            [loggerPath,~,~] = fileparts(obj.LogFile);
            newLoggerFile = fullfile(loggerPath, [Name, '_log.csv']);
            
            moveLogFile(obj, newLoggerFile);
        end
        
        function moveLogFile(obj, newLoc)
            [loggerDir, loggerFile, loggerExt] = fileparts(obj.LogFile);
            
            if (isfolder(newLoc) && ~isequal(loggerDir, newLoc)) || ...
                    ~isfolder(newLoc)
                obj.fcloseLogFile();
                
                if isfolder(newLoc)
                    movefile(obj.LogFile, newLoc);
                    obj.LogFile = fullfile(newLoc, strcat(loggerFile, loggerExt));
                else
                    if isfile(newLoc)
                        % if a file already exists with the same name,
                        % close the file and then perform move operation
                        fIDs = fopen('all'); % get all open file IDs
                        [openfnames,~,~,~] = arrayfun(@(x) fopen(x), fIDs, 'UniformOutput', false);
                        isNewLoc = cellfun(@(x) isequal(x, newLoc), openfnames);
                        if any(isNewLoc)
                            fclose(fIDs(isNewLoc));
                        end
                    end
                    movefile(obj.LogFile, newLoc);
                    obj.LogFile = newLoc;
                end
            end
             
        end
        
        
        
    end %methods
    
    %% Static methods
    
    methods (Static)
        function deleteInvalidSessionLoggers(sessionNames)
            if ~isempty(sessionNames)
                % Get all logger instances
                persistent AllLoggers
                if isempty(AllLoggers)
                    AllLoggers = mlog.Logger.empty(0);
                end
                AllLoggers(~isvalid(AllLoggers)) = [];
                
                % delete the ones that don't match session names
                allNames = string([AllLoggers.Name]);
                isValidSession = ismember(allNames, sessionNames);
                delete(AllLoggers(isValidSession));
            end
        end
    end
    
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
    
    %% Public methods
    methods 
        function fopenLogFile(obj, permission)
            % Open the log file for writing
            
            % Is it already open?
            if ismember(obj.FileID, fopen('all'))
                
                % Do nothing - it's already open
                
            elseif strlength(obj.LogFile)
                
                % Open the file
                [obj.FileID, openMsg] = fopen(obj.LogFile, permission);
                if obj.FileID == -1
                    msg = "Unable to open log file for writing: ''%s''\n%s\n";
                    error(msg, obj.LogFile, openMsg);
                end
                
            end %if strlength(fileName)
            
        end %function
        
        
        function fcloseLogFile(obj)
            % Close the log file for writing
            
            if obj.FileID >= 0
                try
                    fclose(obj.FileID);
                catch
                    warning("mlog:closeInvalidLogFileId",...
                        "Failed to close logfile: %s",...
                        obj.LogFile);
                end
                obj.FileID = -1;
            end %if
            
        end %function
    end
end %classdef


