classdef VirtualPopulationDataPane < QSPViewerNew.Application.ViewPane 
    %  VirtualPopulationDataPane - A Class for the Virtual Population Data Pane settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.VirtualPopulationData.
    %  This is also called Acceptance Criteria
    %
    % 
    % ---------------------------------------------------------------------
    %    Copyright 2020 The Mathworks, Inc.
    %
    % Auth/Revision:
    %   Max Tracy
    %
    %  3/2/20
    % ---------------------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        VirtPopData = QSP.VirtualPopulationData.empty()
        TemporaryVirtPopData = QSP.VirtualPopulationData.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        VirtPopDataFileListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterVirtPopDataGrid      matlab.ui.container.GridLayout
        VirtPopDataFileSelector   QSPViewerNew.Widgets.FileSelectorWithNew
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = VirtualPopulationDataPane(varargin)
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
            obj.OuterVirtPopDataGrid = uigridlayout(obj.getEditGrid());
            obj.OuterVirtPopDataGrid.ColumnWidth = {'1x'};
            obj.OuterVirtPopDataGrid.RowHeight = {obj.WidgetHeight};
            obj.OuterVirtPopDataGrid.Layout.Row = 3;
            obj.OuterVirtPopDataGrid.Layout.Column = 1;
            obj.OuterVirtPopDataGrid.Padding = obj.WidgetPadding;
            obj.OuterVirtPopDataGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.OuterVirtPopDataGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            obj.VirtPopDataFileSelector = QSPViewerNew.Widgets.FileSelectorWithNew(obj.OuterVirtPopDataGrid,1,1,' File');
        end
        
        function createListenersAndCallbacks(obj)
            obj.VirtPopDataFileListener = addlistener(obj.VirtPopDataFileSelector,'StateChanged',@(src,event) obj.onVirtPopDataFile(event.Source.RelativePath));
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onVirtPopDataFile(obj,NewData)
            obj.TemporaryVirtPopData.RelativeFilePath = NewData;
            obj.IsDirty = true;
        end
    end
    
    methods (Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.VirtPopData.Settings.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewVirtPopData(obj,NewVirtPopData)
            obj.VirtPopData = NewVirtPopData;
            obj.TemporaryVirtPopData = copy(obj.VirtPopData);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryVirtPopData.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryVirtPopData.Description= value;
            obj.IsDirty = true;
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryVirtPopData.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryVirtPopData.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.VirtPopData = copy(obj.TemporaryVirtPopData,obj.VirtPopData);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.VirtPopData.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryVirtPopData)
            obj.TemporaryVirtPopData = copy(obj.VirtPopData);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryVirtPopData.Description);
            obj.updateNameBox(obj.TemporaryVirtPopData.Name);
            obj.updateSummary(obj.TemporaryVirtPopData.getSummary());
            
            obj.VirtPopDataFileSelector.setFileExtension('.xlsx')
            obj.VirtPopDataFileSelector.RootDirectory = obj.TemporaryVirtPopData.Session.RootDirectory;
            obj.VirtPopDataFileSelector.setFileTemplate(QSPViewerNew.Resources.LoadResourcePath('AcceptanceCriteria_Template.xlsx'));
            obj.VirtPopDataFileSelector.RelativePath = obj.TemporaryVirtPopData.RelativeFilePath;
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryVirtPopData,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.VirtPopData.Session.Settings.VirtualPopulationData;
            ixDup = find(strcmp( obj.TemporaryVirtPopData.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.VirtPopData)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
    end
        
end

