classdef ParametersPane < QSPViewerNew.Application.ViewPane 
    %  ParametersPane - A Class for the session settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.Parameters
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  2/14/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        Parameters = QSP.Parameters.empty()
        TemporaryParameters = QSP.Parameters.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        ParameterFileListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterParametersGrid     matlab.ui.container.GridLayout
        ParameterFileSelector   QSPViewerNew.Widgets.FileSelectorWithNew
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = ParametersPane(varargin)
            obj = obj@QSPViewerNew.Application.ViewPane(varargin{:}{:},false);
            obj.create();
            obj.createListenersAndCallbacks();
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function create(obj)
            obj.OuterParametersGrid = uigridlayout(obj.getEditGrid());
            obj.OuterParametersGrid.ColumnWidth = {'1x'};
            obj.OuterParametersGrid.RowHeight = {obj.WidgetHeight};
            obj.OuterParametersGrid.Layout.Row = 3;
            obj.OuterParametersGrid.Layout.Column = 1;
            obj.OuterParametersGrid.Padding = obj.WidgetPadding;
            obj.OuterParametersGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.OuterParametersGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            obj.ParameterFileSelector = QSPViewerNew.Widgets.FileSelectorWithNew(obj.OuterParametersGrid,1,1,' File');
        end
        
        function createListenersAndCallbacks(obj)
            obj.ParameterFileListener = addlistener(obj.ParameterFileSelector,'StateChanged',@(src,event) obj.onParameterFile(event.Source.getRelativePath()));
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onParameterFile(obj,NewData)
            obj.TemporaryParameters.RelativeFilePath = NewData;
            obj.IsDirty = true;
        end
    end
    
    methods (Access = public) 
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewParameters(obj,NewParameters)
            obj.Parameters = NewParameters;
            obj.TemporaryParameters = copy(obj.Parameters);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryParameters.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryParameters.Description= value;
            obj.IsDirty = true;
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false; 
            [StatusOK,Message] = obj.TemporaryParameters.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryParameters.updateLastSavedTime();
                previousName = obj.TemporaryParameters.Name;
                newName = obj.Parameters.Name;
                
                %This creates an entirely new copy of the Parameters except
                %the name isnt copied
                obj.Parameters = copy(obj.TemporaryParameters,obj.Parameters);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.Parameters.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryParameters)
            obj.TemporaryParameters = copy(obj.Parameters);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryParameters.Description);
            obj.updateNameBox(obj.TemporaryParameters.Name);
            obj.updateSummary(obj.TemporaryParameters.getSummary());
            
            obj.ParameterFileSelector.setFileExtension('.xlsx')
            obj.ParameterFileSelector.setRootDirectory(obj.Parameters.Session.RootDirectory);
            obj.ParameterFileSelector.setFileTemplate('+QSPViewerNew/+Resources/Parameters_Template.xlsx');
            obj.ParameterFileSelector.setRelativePath(obj.TemporaryParameters.RelativeFilePath);
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryParameters,FlagRemoveInvalid);
            obj.draw();
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.Parameters.Session.Settings.Parameters;
            ixDup = find(strcmp( obj.TemporaryParameters.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.Parameters)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
    end
    
    methods (Access = private)
        
    end
        
end

