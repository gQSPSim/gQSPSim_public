classdef VirtualPopulationGenerationDataPane < QSPViewerNew.Application.ViewPane 
    %  VirtualPopulationGenerationDataPane - A Class for the Virtual Population Generation Data Pane view. This is the
    %  'viewer' counterpart to the 'model' class
    %  QSP.VirtualPopulationGenerationData. This is also called Target
    %  Statistics 
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
        VirtPopGenData = QSP.VirtualPopulationGenerationData.empty()
        TemporaryVirtPopGenData = QSP.VirtualPopulationGenerationData.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        VirtPopGenDataListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterVirtPopGenDataGrid      matlab.ui.container.GridLayout
        VirtPopGenDataFileSelector   QSPViewerNew.Widgets.FileSelectorWithNew
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = VirtualPopulationGenerationDataPane(pvargs)
            arguments
                pvargs.Parent (1,1) matlab.ui.container.GridLayout
                pvargs.layoutrow (1,1) double = 1
                pvargs.layoutcolumn (1,1) double = 1
                pvargs.parentApp
                pvargs.HasVisualization (1,1) logical = false
            end
    
            % TODOpax. This does not work. args = namedargs2cell(pvargs);
            obj = obj@QSPViewerNew.Application.ViewPane(Parent=pvargs.Parent, HasVisualization=pvargs.HasVisualization, ParentApp=pvargs.parentApp);
            obj.create();
            obj.createListenersAndCallbacks();        
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function create(obj)
            obj.OuterVirtPopGenDataGrid = uigridlayout(obj.getEditGrid());
            obj.OuterVirtPopGenDataGrid.ColumnWidth = {'1x'};
            obj.OuterVirtPopGenDataGrid.RowHeight = {obj.WidgetHeight};
            obj.OuterVirtPopGenDataGrid.Layout.Row = 3;
            obj.OuterVirtPopGenDataGrid.Layout.Column = 1;
            obj.OuterVirtPopGenDataGrid.Padding = obj.WidgetPadding;
            obj.OuterVirtPopGenDataGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.OuterVirtPopGenDataGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            obj.VirtPopGenDataFileSelector = QSPViewerNew.Widgets.FileSelectorWithNew(obj.OuterVirtPopGenDataGrid,1,1,' File');
        end
        
        function createListenersAndCallbacks(obj)
            obj.VirtPopGenDataListener = addlistener(obj.VirtPopGenDataFileSelector,'StateChanged',@(src,event) obj.onVirtPopGenDataFile(event.Source.RelativePath));
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onVirtPopGenDataFile(obj,NewData)
            obj.TemporaryVirtPopGenData.RelativeFilePath = NewData;
            obj.IsDirty = true;
        end
    end
    
    methods (Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.VirtPopGenData.Settings.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewVirtualPopulationGenerationData(obj,NewVirtPopGenData)
            obj.VirtPopGenData = NewVirtPopGenData;
            obj.TemporaryVirtPopGenData = copy(obj.VirtPopGenData);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryVirtPopGenData.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryVirtPopGenData.Description= value;
            obj.IsDirty = true;
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryVirtPopGenData.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryVirtPopGenData.updateLastSavedTime();
                
                %This creates an entirely new copy of the Data except
                %the name isnt copied
                obj.VirtPopGenData = copy(obj.TemporaryVirtPopGenData,obj.VirtPopGenData);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.VirtPopGenData.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryVirtPopGenData)
            obj.TemporaryVirtPopGenData = copy(obj.VirtPopGenData);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryVirtPopGenData.Description);
            obj.updateNameBox(obj.TemporaryVirtPopGenData.Name);
            obj.updateSummary(obj.TemporaryVirtPopGenData.getSummary());
            
            obj.VirtPopGenDataFileSelector.setFileExtension('.xlsx')
            obj.VirtPopGenDataFileSelector.RootDirectory = obj.TemporaryVirtPopGenData.Session.RootDirectory;
            obj.VirtPopGenDataFileSelector.setFileTemplate(QSPViewerNew.Resources.LoadResourcePath('TargetStatistics_Template.xlsx'));
            obj.VirtPopGenDataFileSelector.RelativePath = obj.TemporaryVirtPopGenData.RelativeFilePath;
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryVirtPopGenData,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.VirtPopGenData.Session.VirtualPopulationGeneration;
            ixDup = find(strcmp( obj.TemporaryVirtPopGenData.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.VirtPopGenData)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
    end
        
end

