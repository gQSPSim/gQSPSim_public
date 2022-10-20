classdef VirtualPopulationPane < QSPViewerNew.Application.ViewPane 
    %  VirtualPopulationPane - A 'Target Statistics' option for the user to select. This is the
    %  'viewer' counterpart to the 'model' class QSP.VirtualPopulation.
    %  This is also called Virtual Subjects. 
    %
    % 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Status of the UI properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access = private)
        VirtualPopulation = QSP.VirtualPopulation.empty()
        TemporaryVirtualPopulation= QSP.VirtualPopulation.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        VirtualPopulationFileListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterVirtualPopulationGrid     matlab.ui.container.GridLayout
        VirtualPopulationFileSelector   QSPViewerNew.Widgets.FileSelector
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        function obj = VirtualPopulationPane(pvargs)
            arguments
                pvargs.Parent (1,1) matlab.ui.container.GridLayout
                pvargs.layoutrow (1,1) double = 1
                pvargs.layoutcolumn (1,1) double = 1
                pvargs.parentApp
                pvargs.HasVisualization (1,1) logical = false
            end
    
            args = namedargs2cell(pvargs);
            obj = obj@QSPViewerNew.Application.ViewPane(args{:});
            obj.create();
            obj.createListenersAndCallbacks();
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Interacting with UI components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function create(obj)
            obj.OuterVirtualPopulationGrid = uigridlayout(obj.getEditGrid());
            obj.OuterVirtualPopulationGrid.ColumnWidth = {'1x'};
            obj.OuterVirtualPopulationGrid.RowHeight = {obj.WidgetHeight};
            obj.OuterVirtualPopulationGrid.Layout.Row = 3;
            obj.OuterVirtualPopulationGrid.Layout.Column = 1;
            obj.OuterVirtualPopulationGrid.Padding = obj.WidgetPadding;
            obj.OuterVirtualPopulationGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.OuterVirtualPopulationGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            obj.VirtualPopulationFileSelector = QSPViewerNew.Widgets.FileSelector(obj.OuterVirtualPopulationGrid,1,1,' File');
        end
        
        function createListenersAndCallbacks(obj)
            obj.VirtualPopulationFileListener = addlistener(obj.VirtualPopulationFileSelector,'StateChanged',@(src,event) obj.onVirtualPopulationFile(event.Source.RelativePath));
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onVirtualPopulationFile(obj,NewData)
            obj.TemporaryVirtualPopulation.RelativeFilePath = NewData;
            obj.IsDirty = true;
        end
    end
    
    methods (Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.VirtualPopulation.Settings.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewVirtualPopulation(obj,newVirtualPopulation)
            obj.VirtualPopulation = newVirtualPopulation;
            obj.TemporaryVirtualPopulation = copy(obj.VirtualPopulation);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryVirtualPopulation.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryVirtualPopulation.Description= value;
            obj.IsDirty = true;
        end
        
        function [StatusOk] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryVirtualPopulation.validate(FlagRemoveInvalid); 
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);
            
            if StatusOK
                obj.TemporaryVirtualPopulation.updateLastSavedTime();
                
                %This creates an entirely new copy of the Parameters except
                %the name isnt copied
                obj.VirtualPopulation = copy(obj.TemporaryVirtualPopulation,obj.VirtualPopulation);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.VirtualPopulation.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryVirtualPopulation)
            obj.TemporaryVirtualPopulation = copy(obj.VirtualPopulation);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryVirtualPopulation.Description);
            obj.updateNameBox(obj.TemporaryVirtualPopulation.Name);
            obj.updateSummary(obj.TemporaryVirtualPopulation.getSummary());
            
            obj.VirtualPopulationFileSelector.setFileExtension('.xlsx')
            obj.VirtualPopulationFileSelector.RootDirectory = obj.TemporaryVirtualPopulation.Session.RootDirectory;
            obj.VirtualPopulationFileSelector.RelativePath = obj.TemporaryVirtualPopulation.RelativeFilePath;
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryVirtualPopulation,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.VirtualPopulation.Session.Settings.VirtualPopulation;
            ixDup = find(strcmp( obj.TemporaryVirtualPopulation.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.VirtualPopulation)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
        
    end
    
    methods (Access = private)
        
    end
        
end

