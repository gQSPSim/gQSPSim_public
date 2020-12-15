classdef OptimizationDataPane < QSPViewerNew.Application.ViewPane 
    %  ParametersPane - A Class for the session settings view pane. This is the
    %  'viewer' counterpart to the 'model' class QSP.OptimizationData. This
    %  is also called Datasets. 
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
        OptimizationData = QSP.OptimizationData.empty()
        TemporaryOptimizationData = QSP.OptimizationData.empty();
        IsDirty;
        LastPath = pwd
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Listeners
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    properties (Access = private)
        OptimFileListener
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Graphical Components
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties(Access=private)
        OuterOptimizationDataGrid      matlab.ui.container.GridLayout
        OptimFileSelector              QSPViewerNew.Widgets.FileSelectorWithNew
        FileTypeDropDown               matlab.ui.control.DropDown
        FileTypeDataGrid               matlab.ui.container.GridLayout
        FileTypeLabel                  matlab.ui.control.Label
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods      
        
        function obj = OptimizationDataPane(varargin)
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
            obj.OuterOptimizationDataGrid = uigridlayout(obj.getEditGrid());
            obj.OuterOptimizationDataGrid.ColumnWidth = {'1x'};
            obj.OuterOptimizationDataGrid.RowHeight = {obj.WidgetHeight,obj.WidgetHeight};
            obj.OuterOptimizationDataGrid.Layout.Row = 3;
            obj.OuterOptimizationDataGrid.Layout.Column = 1;
            obj.OuterOptimizationDataGrid.Padding = obj.WidgetPadding;
            obj.OuterOptimizationDataGrid.RowSpacing = obj.WidgetHeightSpacing;
            obj.OuterOptimizationDataGrid.ColumnSpacing = obj.WidgetWidthSpacing;
            
            obj.OptimFileSelector = QSPViewerNew.Widgets.FileSelectorWithNew(obj.OuterOptimizationDataGrid,1,1,' File');
            
            
            obj.FileTypeDataGrid = uigridlayout(obj.OuterOptimizationDataGrid);
            obj.FileTypeDataGrid.ColumnWidth = {obj.LabelLength,'1x'};
            obj.FileTypeDataGrid.RowHeight = {obj.WidgetHeight};
            obj.FileTypeDataGrid.Layout.Row = 2;
            obj.FileTypeDataGrid.Layout.Column = 1;
            obj.FileTypeDataGrid.Padding = [0,0,0,0];
            obj.FileTypeDataGrid.RowSpacing = 0;
            obj.FileTypeDataGrid.ColumnSpacing = 0;
            
            obj.FileTypeDropDown = uidropdown(obj.FileTypeDataGrid);
            obj.FileTypeDropDown.Layout.Column = 2;
            obj.FileTypeDropDown.Layout.Row = 1;
            obj.FileTypeDropDown.Items = {'wide','tall'};
            
            obj.FileTypeLabel = uilabel(obj.FileTypeDataGrid);
            obj.FileTypeLabel.Layout.Column = 1;
            obj.FileTypeLabel.Layout.Row = 1;
            obj.FileTypeLabel.Text = ' File Type';
            
            
        end
        
        function createListenersAndCallbacks(obj)
            obj.OptimFileListener = addlistener(obj.OptimFileSelector,'StateChanged',@(src,event) obj.onOptimFile(event.Source.RelativePath));
            
            obj.FileTypeDropDown.ValueChangedFcn = @(h,e) obj.onFileType(e.Value);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function onOptimFile(obj,newData)
            obj.TemporaryOptimizationData.RelativeFilePath = newData;
            obj.IsDirty = true;
        end
        
        function onFileType(obj,newData)
            obj.TemporaryOptimizationData.DatasetType = newData;
             if strcmp(obj.FileTypeDropDown.Value,'wide')
                obj.OptimFileSelector.setFileTemplate(QSPViewerNew.Resources.LoadResourcePath('DataSet_Template.xlsx'));
            elseif strcmp(obj.FileTypeDropDown.Value,'tall')
                obj.OptimFileSelector.setFileTemplate(QSPViewerNew.Resources.LoadResourcePath('DataSet_Template_tall.xlsx'));
            end
            obj.IsDirty = true;
        end
    end
    
    methods (Access = public) 
        
        function Value = getRootDirectory(obj)
            Value = obj.OptimizationData.Settings.Session.RootDirectory;
        end
        
        function showThisPane(obj)
            obj.showPane();
        end
        
        function hideThisPane(obj)
            obj.hidePane();
        end
        
        function attachNewOptimizationData(obj,newOptimizationData)
            obj.OptimizationData = newOptimizationData;
            obj.TemporaryOptimizationData = copy(obj.OptimizationData);
            obj.draw();
        end
        
        function value = checkDirty(obj)
            value = obj.IsDirty;
        end
        
    end
       
    methods (Access = public)
        
        function NotifyOfChangeInName(obj,value)
            obj.TemporaryOptimizationData.Name = value;
            obj.IsDirty = true;
        end
        
        function NotifyOfChangeInDescription(obj,value)
            obj.TemporaryOptimizationData.Description= value;
            obj.IsDirty = true;
        end
        
        function [StatusOK] = saveBackEndInformation(obj)
            
            %Validate the temporary data
            FlagRemoveInvalid = false;
            [StatusOK,Message] = obj.TemporaryOptimizationData.validate(FlagRemoveInvalid);
            [StatusOK,Message] = obj.checkForDuplicateNames(StatusOK,Message);       
            
            if StatusOK
                obj.TemporaryOptimizationData.updateLastSavedTime();
                
                %This creates an entirely new copy of the Parameters except
                %the name isnt copied
                obj.OptimizationData = copy(obj.TemporaryOptimizationData,obj.OptimizationData);
                
                %We now need to notify the application
                obj.notifyOfChange(obj.OptimizationData.Session);
                
            else
                uialert(obj.getUIFigure,sprintf('Cannot save changes. Please review invalid entries:\n\n%s',Message),'Cannot Save');
            end
            
        end
        
        function deleteTemporary(obj)
            delete(obj.TemporaryOptimizationData)
            obj.TemporaryOptimizationData = copy(obj.OptimizationData);
        end
        
        function draw(obj)
            obj.updateDescriptionBox(obj.TemporaryOptimizationData.Description);
            obj.updateNameBox(obj.TemporaryOptimizationData.Name);
            obj.updateSummary(obj.TemporaryOptimizationData.getSummary());
            obj.FileTypeDropDown.Value = obj.TemporaryOptimizationData.DatasetType;
            
            obj.OptimFileSelector.setFileExtension('.xlsx')
            obj.OptimFileSelector.RootDirectory = obj.TemporaryOptimizationData.Session.RootDirectory;
            obj.OptimFileSelector.RelativePath = obj.TemporaryOptimizationData.RelativeFilePath;
            
            if strcmp(obj.FileTypeDropDown.Value,'wide')
                obj.OptimFileSelector.setFileTemplate(QSPViewerNew.Resources.LoadResourcePath('DataSet_Template.xlsx'));
            elseif strcmp(obj.FileTypeDropDown.Value,'tall')
                obj.OptimFileSelector.setFileTemplate(QSPViewerNew.Resources.LoadResourcePath('DataSet_Template_tall.xlsx'));
            end
            
            obj.IsDirty = false;
        end
        
        function checkForInvalid(obj)
            FlagRemoveInvalid = true;
            % Remove the invalid entries
            validate(obj.TemporaryOptimizationData,FlagRemoveInvalid);
            obj.draw()
            obj.IsDirty = true;
        end
        
        function [StatusOK,Message] = checkForDuplicateNames(obj,StatusOK,Message)
            refObject = obj.OptimizationData.Session.Settings.OptimizationData;
            ixDup = find(strcmp( obj.TemporaryOptimizationData.Name, {refObject.Name}));
            if ~isempty(ixDup) && (refObject(ixDup) ~= obj.OptimizationData)
                Message = sprintf('%s\nDuplicate names are not allowed.\n', Message);
                StatusOK = false;
            end
        end
    end
    
    methods (Access = private)
        
    end
        
end

