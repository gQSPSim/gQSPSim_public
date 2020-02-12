classdef SessionPane < QSPViewerNew.Application.ViewPane 
    %  SessionPane - A Class for the session settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.Session
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  1/9/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        Session = QSP.Session.empty()
        TemporarySession = QSP.Session.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        GridLayout
        RDFileSelect
        %TODO Add Widgets Specific to Sessions
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = SessionPane(varargin)
            obj = obj@QSPViewerNew.Application.ViewPane(varargin{:}{:},false);
            obj.create();
        end      
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function create(obj)
            %TODO Session Specific widgets
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onFileSelection(obj,h,e)
            disp("TODO:FileSelect")
        end
        
        function onUDFSelection(obj,h,e)
            disp("TODO:UDF Select")
        end
        
        function onParallelCheckbox(obj,h,e)
            disp("TODO:ParrCheck")
        end
        
        function onAutosaveTimerCheckbox(obj,h,e)
            disp("TODO:AutoSave")
        end
        
        function onParallelClusterPopup(obj,h,e)
            disp("TODO:ParrClust")
        end
        
        function onAutoSaveFrequencyEdited(obj,h,e)
            disp("TODO:AutoSaveFreq")
        end
        
        function onAutoSaveBeforeRunChecked(obj,h,e)
            disp("TODO: AutoSaveBeforeRun")
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Private methods to manage the view and data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function [Status,Message] = checkDuplicateNames(obj,StatusOk,Message)
            %TODO Check for duplicate Names()
            Status = true;
        end
        
    end
    
    methods(Access = public) 
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewSession(obj,NewSession)
            obj.Session = NewSession;
            obj.TemporarySession = copy(obj.Session);
            obj.IsDirty = false;
        end
        
    end
       
    methods(Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporarySession.Name = value;
            obj.IsDirty = false;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporarySession.Description= value;
            obj.IsDirty = false;
        end

        function saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporarySession.validate(FlagRemoveInvalid);
            [StatusOK,Message] = checkDuplicateNames(obj,StatusOK,Message);             
            
            if StatusOK
                obj.TemporarySession.updateLastSavedTime();
                previousName = obj.TemporarySession.Name;
                newName = obj.Session.Name;
                
                %This creates an entirely new copy of the Session except
                %the name isnt copied
                delete(obj.Session);
                obj.Session = copy(obj.TemporarySession);
                
                %We now need to notify the applicaiton to update the
                %session pointer to the new object created
                obj.notifyOfChange(obj.Session,previousName,newName);
                
                obj.IsDirty = true;
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save','modal');
            end
        end
        
        function deleteTemporary(obj)
            obj.TemporarySession = obj.Session;
        end
        
        function draw(obj)
            %Draw the superclass Widgets values
            obj.updateDescriptionBox(obj.TemporarySession.Description);
            obj.updateNameBox(obj.TemporarySession.Name);
            obj.updateSummary(obj.TemporarySession.getSummary());
        end
        
        function checkForInvalid(obj)
            %This method should check each box to verify it has valid
            %inputs before the temporarySession can be saved 
            disp("TODO: Checking for invalid")
        end
        
    end
end

