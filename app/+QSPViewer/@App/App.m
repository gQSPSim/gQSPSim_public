classdef App < uix.abstract.AppWithSessionFiles & uix.mixin.ViewPaneManager
    % App - Class definition for a MATLAB desktop application
    % ---------------------------------------------------------------------
    % Instantiates the Application figure window
    %
    % Syntax:
    %           app = QSPViewer.App
    %           app = QSPViewer.App('Property','Value',...)
    %
    % This class inherits properties and methods from:
    %
    %       uix.abstract.AppWithSessionFiles
    %       uix.abstract.AppWindow
    %       matlab.mixin.SetGet
    %       uix.mixin.AssignPVPairs
    %
    % Properties of QSPViewer.App:
    %
    %   Session - top-level QSP.Session objects for each session
    %
    %
    % Properties inherited from uix.abstract.AppWithSessionFiles:
    %
    %   AllowMultipleSessions - indicates whether this app is
    %   single-session or multi-session [true|(false)]
    %
    %   FileSpec - file type specification for load save (see doc
    %   uigetfile) [{'*.mat','MATLAB MAT File'}]
    %
    %   IsDirty - logical array inidicating which session files are dirty
    %
    %   SessionPaths - file paths of sessions currently loaded
    %
    %   SelectedSessionIdx - index of currently selected session
    %
    %   SessionNames (read-only) - filename and extension of sessions
    %   currently loaded, based on the SessionPaths property
    %
    %   NumSessions (read-only) - indicates number of sessions currently
    %   loaded, based on the SessionPaths property
    %
    %
    % Properties inherited from uix.abstract.AppWindow:
    %
    %   AppName - The name of the app, which is typically displayed on the
    %   title bar of the window ['AppWindow']
    %
    %   BeingDeleted (read-only) - Is the object in the process of being
    %   deleted [on|(off)]
    %
    %   DeleteFcn - Callback to execute when the object is deleted
    %
    %   Figure - figure window for the app
    %
    %   h - handles structure for subclasses to place widgets, uicontrols,
    %   etc. within the app
    %
    %   IsConstructed - indicate whether construction is complete
    %   [true|(false)]. Set this true at the end of your constructor method.
    %
    %   Listeners - array of listeners for the app
    %
    %   Position - Position (left bottom width height) [100 100 500 500]
    %
    %   Tag - Tag ['']
    %
    %   Title - Title to display on the figure title bar [char]
    %
    %   Type (read-only) - The object type (class) [char]
    %
    %   TypeStr (read-only) - The object type as a valid identifier string,
    %   as used for storing preferences for the app.
    %
    %   Units - Position units
    %   [inches|centimeters|normalized|points|(pixels)|characters]
    %
    %   UIContextMenu - Context menu for the object
    %
    %   Visible - Is the window visible on-screen [on|(off)]
    %
    %
    %
    % Methods of of QSPViewer.App:
    %
    %   create(obj) - called to create the graphics for the app
    %
    %   refresh(obj) - called to refresh the graphics in the app
    %
    %
    % Methods that are implemented here for superclasses:
    %
    %   createNewSession(obj) - creates a new session object when a new
    %   session is triggered
    %
    %   StatusOk = saveSessionToFile(obj, FilePath, idx) - saves the
    %   session index indicated to the specified file path (called once per
    %   session saved)
    %
    %   StatusOk = loadSessionFromFile(obj, FilePath) - loads the session
    %   index indicated from the specified file path (called once per
    %   session loaded)
    %
    %
    % Methods inherited from uix.abstract.AppWithSessionFiles
    %
    %   markDirty(obj), markClean(obj) - mark the current session as clean
    %   or dirty
    %
    %   createUntitledSession(obj) - create a new untitled session
    %
    %   for more, see uix.abstract.AppWithSessionFiles
    %
    %
    % Methods inherited from uix.abstract.AppWindow. Each of these methods
    % may be overloaded by subclasses:
    %
    %   onClose(obj) - called when the figure is being closed
    %
    %   onResized(obj) - called when the figure is resized
    %
    %   onVisibleChanged(obj) - called when the figure visibility is
    %   changed
    %
    %   onContainerBeingDestroyed(obj) - called when the figure is being
    %   destroyed
    %
    %   for more, see uix.abstract.AppWithSessionFiles
    %
    %
    % Methods inherited from uix.abstract.AssignPVPairs:
    %
    %   varargout = assignPVPairs(obj,varargin) - assigns the
    %   property-value pairs to matching properties of the object
    %       matlab.mixin.SetGet
    %       uix.mixin.AssignPVPairs
    %
    %   and adds the following:
    %
    %
    %
    % Examples:
    %  obj = QSPViewer.App()
    
    %   Copyright 2016 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 299 $
    %   $Date: 2016-09-06 17:18:29 -0400 (Tue, 06 Sep 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    
    properties (SetAccess=private)
        Session = QSP.Session.empty(0,1) %Top level session sessions
    end
    
    properties (SetAccess=private, Dependent=true)
        SelectedSession
        SessionNode
    end
    
    properties( Access = private )
        NavigationChangedListener = event.listener.empty(0,1)
        MarkDirtyListener = event.listener.empty(0,1)
    end
        
    %% Methods in separate files with custom permissions
    methods (Access=protected)
        create(obj);
        refresh(obj);
        assignPaneData(obj,Data,varargin);
        
        % Overloaded methods for file session operations
        createNewSession(obj,Session)
        StatusOk = saveSessionToFile(obj,FilePath,idx)
        StatusOk = loadSessionFromFile(obj,FilePath)
        StatusOk = closeSession(obj,idx)
        
        % To add a session to the tree
        addSessionTreeNode(obj, Session)
        
        % To add tree nodes
        createTree(obj, Parent, AllData)
    end
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = App(varargin)
            
            % Set some superclass properties for the app
            obj.AppName = 'QSP App';
            obj.AllowMultipleSessions = true;
            obj.FileSpec = {'*.qsp.mat','MATLAB QSP MAT File'};
            
            % If we want the app to launch with an untitled session, call
            % the superclass AppWithSessionFiles method to create one here:
            %obj.createUntitledSession();
            
            % Create the graphics objects
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Mark construction complete to tell refresh the graphics exist
            obj.IsConstructed = true;
            
            % Refresh the entire view
            obj.refresh();
            
            % Now, make the figure visible
            set(obj.Figure,'Visible','on')
            
        end %function
        
    end %methods
    
    
    
    
    %% Callbacks
    methods (Access=protected)
        
        function onMarkDirty(obj,h,e)
            
            % Mark the current session dirty
            obj.markDirty();
            
        end %function
        
        function onDataChanged(obj,h,e)
            
            % Mark the current session dirty
            try
                obj.markDirty();
            catch error
                warning(error.message)
            end
            % Refresh if name changed
            if isfield(e,'NameChanged') && e.NameChanged
                
                SelNode = obj.h.SessionTree.SelectedNodes;                
                SelNode.Name = e.Name;
                
                % Update the display
                obj.refresh();
            else
                
                switch e.InteractionType
                    
                    case 'Updated QSP.VirtualPopulation'
                        
                        if isfield(e,'Data')
                            % Add the new VirtualPopulation to the session
                            NewVirtualPopulation = e.Data;
                            for idx = 1:numel(NewVirtualPopulation)
                                onAddItem(obj,NewVirtualPopulation(idx))
                            end
                            
                            % Update the display
                            obj.refresh();
                        end
                        
                end %switch e.InteractionType
            end
            
        end %function
        
        function onSelectionChanged(obj,h,e)
            
            % Update pointer
            set(obj.Figure,'pointer','watch');
            drawnow;
            
            % Find the session node that is selected
            Root = h.Root;
            SelNode = e.Nodes;
            ThisSessionNode = SelNode;
            
            if length(SelNode)>1
                % no updates if doing multiselect
                return
            end
            while ~isempty(ThisSessionNode) && ThisSessionNode.Parent~=Root
                ThisSessionNode = ThisSessionNode.Parent;                
            end
            
            % Update the selected session based on tree selection
            if isempty(ThisSessionNode)
                obj.SelectedSessionIdx = [];
            else
                obj.SelectedSessionIdx = find(ThisSessionNode == obj.SessionNode);
            end
            
            % Disable mouse handler before refresh
            if ~isempty(obj.ActivePane) && strcmpi(class(obj.ActivePane),'QSPViewer.Optimization')
                obj.ActivePane.EnableMouseHandler = false;
            end
            
            % Update the display
            obj.refresh();
            
            % Check the type
            % If either Simulation, Optimization, or Virtual Population Generation, re-plot            
            if ~isempty(SelNode) ...
                    && ~isempty(obj.ActivePane) && isprop(obj.ActivePane,'h') && isfield(obj.ActivePane.h,'MainAxes')
                thisObj = SelNode.Value;
                if any(ismember(obj.ActivePane.Selection,[1 3]))
                    % Call updateVisualizationView to disable Visualization button if invalid items                    
                    switch class(thisObj)
                        case {'QSP.Simulation','QSP.Optimization','QSP.VirtualPopulationGeneration'}
                            if obj.ActivePane.Selection == 3
                                plotData(obj.ActivePane);
                            end
                            updateVisualizationView(obj.ActivePane);                                   
                    end                    
                end                
            end
            
            % Enable mouse handler - Only for visualization view
            if ~isempty(obj.ActivePane) && strcmpi(class(obj.ActivePane),'QSPViewer.Optimization')
                if obj.ActivePane.Selection == 3
                    obj.ActivePane.EnableMouseHandler = true;
                else
                    obj.ActivePane.EnableMouseHandler = false;
                end
            end
            
            % Update pointer
            set(obj.Figure,'pointer','arrow');
            drawnow;
            
        end %function
                
        function onNavigationChanged(obj,h,e)
            
            if ~isempty(e) && isprop(e,'Name')
                
                SelNode = obj.h.SessionTree.SelectedNodes;
                if ~isempty(SelNode) ...
                        && ~isempty(obj.ActivePane) && isprop(obj.ActivePane,'h') && isfield(obj.ActivePane.h,'MainAxes')
                    thisObj = SelNode.Value;
                else
                    thisObj = [];
                end
                            
                switch e.Name
                    case 'Summary'
                        % Need to disable Visualization button if invalid
                        % items
                        if any(ismember(class(thisObj),{...
                                'QSP.Simulation',...
                                'QSP.Optimization',...
                                'QSP.VirtualPopulationGeneration',...
                                }))                        
                            updateVisualizationView(obj.ActivePane);
                        end
                        obj.h.SessionTree.Enable = true;
                        obj.h.FileMenu.Menu.Enable = 'on';
                        obj.h.QSPMenu.Menu.Enable = 'on';
                        % Disable mouse handler
                        if ~isempty(obj.ActivePane) && strcmpi(class(obj.ActivePane),'QSPViewer.Optimization') 
                            obj.ActivePane.EnableMouseHandler = false;
                        end
                    case 'Edit'
                        obj.h.SessionTree.Enable = false;
                        obj.h.FileMenu.Menu.Enable = 'off';
                        obj.h.QSPMenu.Menu.Enable = 'off';
                        % Disable mouse handler
                        if ~isempty(obj.ActivePane) && strcmpi(class(obj.ActivePane),'QSPViewer.Optimization') 
                            obj.ActivePane.EnableMouseHandler = false;
                        end
                    case 'Visualize'  
                        % Check the type
                        % If either Simulation, Optimization, or Virtual Population Generation, re-plot                        
                        switch class(thisObj)
                            case {'QSP.Simulation','QSP.Optimization','QSP.VirtualPopulationGeneration'}                              
                                plotData(obj.ActivePane);
                        end
                        obj.h.SessionTree.Enable = true;
                        obj.h.FileMenu.Menu.Enable = 'on';
                        obj.h.QSPMenu.Menu.Enable = 'on';
                        % Enable mouse handler
                        if ~isempty(obj.ActivePane) && strcmpi(class(obj.ActivePane),'QSPViewer.Optimization') 
                            obj.ActivePane.EnableMouseHandler = true;
                        end
                end
            end
            
        end %function
        
        function onAddItem(obj,ItemType)
            
            % This method accepts ItemType as char and also as the item
            % itself
            if ischar(ItemType)
                ThisObj = QSP.(ItemType)();
            elseif isobject(ItemType)
                ThisObj = ItemType;
                ItemType = strrep(class(ThisObj),'QSP.','');
            else
               error('Invalid ItemType'); 
            end
            
            % special case since vpop data has been renamed to acceptance
            % criteria
            if strcmp(ItemType, 'VirtualPopulationData')
                ItemName = 'AcceptanceCriteria';
            else
                ItemName = ItemType;
            end
            
            % Get the session
            ThisSession = obj.SelectedSession;
            
            % Where does the item go?
            if isprop(ThisSession,ItemType)
                ParentObj = ThisSession;
            else
                ParentObj = ThisSession.Settings;
            end
            
            % What tree branch does this go under?
            ChildNodes = ParentObj.TreeNode.Children;
            ChildTypes = {ChildNodes.UserData};
            ParentNode = ChildNodes(strcmp(ChildTypes,ItemType));
            
            % Create the new item
            NewName = ThisObj.Name;
            if isempty(NewName)
                NewName = ['New ' ItemName];
            end
            DisallowedNames = {ParentObj.(ItemType).Name};
            NewName = matlab.lang.makeUniqueStrings(NewName, DisallowedNames);
            ThisObj.Name = NewName;
            if isprop(ThisObj,'Settings')
                ThisObj.Settings = ThisSession.Settings;
            end
            if isprop(ThisObj,'Session')
                ThisObj.Session = ThisSession;
            end
            
            % Place the item and add the tree node
            if isscalar(ParentNode)
                ParentObj.(ItemType)(end+1) = ThisObj;
                obj.createTree(ParentNode, ThisObj);
                ParentNode.expand();
            else
                error('Invalid tree parent');
            end
            
            % Mark the current session dirty
            obj.markDirty();
            
            % Update the display
            obj.refresh();
            
        end %function
        
        
        function onDuplicateItem(obj)
            
            % What node is selected? What is its parent?
            SelNode = obj.h.SessionTree.SelectedNodes;
            ParentNode = SelNode.Parent;
            
            % What type of item?
            ItemType = ParentNode.UserData;
            
            % What are the data object and its parent?
            ThisObj = SelNode.Value;
            ParentObj = ParentNode.Value;
            
            % Copy the object
%             NewObj = ThisObj.copy();
            
            % Parent the object
%             ParentObj.(ItemType)(end+1) = NewObj;
%             
            % Create the duplicate item
            DisallowedNames = {ParentObj.(ItemType).Name};
            NewName = matlab.lang.makeUniqueStrings(ThisObj.Name, DisallowedNames);
            ThisObj = ThisObj.copy();
            ThisObj.Name = NewName;
            ThisObj.clearData();
            
            % Place the item and add the tree node
            if isscalar(ParentNode)
                ParentObj.(ItemType)(end+1) = ThisObj;
                obj.createTree(ParentNode, ThisObj);
                ParentNode.expand();
            else
                error('Invalid tree parent');
            end
            
            % Mark the current session dirty
            obj.markDirty();
                        
            % Update the display
            obj.refresh();
            
        end %function
        
        
        function onRemoveItem(obj)
            
            % Get the session
            ThisSession = obj.SelectedSession;
            
            % What node is selected? What is its parent?
            SelNode = obj.h.SessionTree.SelectedNodes;
            ParentNode = SelNode.Parent;
            
            % What type of item?
            ItemType = ParentNode.UserData;
            
            % What are the data object and its parent?
            ThisObj = SelNode.Value;
            ParentObj = ParentNode.Value;
            
            % Where is the Deleted Items node?
            hSessionNode = ThisSession.TreeNode;
            hChildNodes = hSessionNode.Children;
            ChildTypes = {hChildNodes.UserData};
            hDeletedNode = hChildNodes(strcmp(ChildTypes,'Deleted'));
            
            % Move the object from its parent to deleted
            ThisSession.Deleted(end+1) = ThisObj;
            ParentObj.(ItemType)( ParentObj.(ItemType)==ThisObj ) = [];
            
            % Update the tree
            
            % if deleted objective was the active object, reset the active
            % pane
%             if obj.ActivePane.Data == ThisObj
%                 obj.ActivePane.Data = [];
%             end
            
            obj.ActivePane.Selection = 1; % switch to summary view

            SelNode.Parent = hDeletedNode;
            SelNode.Tree.SelectedNodes = SelNode;
            hDeletedNode.expand();
            
            % Change context menu
            SelNode.UIContextMenu = obj.h.TreeMenu.Leaf.Deleted;
            
            % Mark the current session dirty
            obj.markDirty();
                        
            % Update the display
            obj.refresh();
            
        end %function
        
        
        function onRestoreItem(obj)
            
            % Get the session
            ThisSession = obj.SelectedSession;
            
            % What node is selected? What is its parent?
            SelNode = obj.h.SessionTree.SelectedNodes;
            
            % What is the data object?
            ThisObj = SelNode.Value;
            
            % What type of item?
            ItemType = strrep(class(ThisObj), 'QSP.', '');
            
            % Where does the item go?
            if isprop(ThisSession,ItemType)
                ParentObj = ThisSession;
            else
                ParentObj = ThisSession.Settings;
            end
            
            % What tree branch does this go under?
            hChildNodes = ParentObj.TreeNode.Children;
            ChildTypes = {hChildNodes.UserData};
            hParentNode = hChildNodes(strcmp(ChildTypes,ItemType));
            
            % check for duplicate names
            if any(strcmp( SelNode.Value.Name, {ParentObj.(ItemType).Name} ))
                errordlg('Cannot restore deleted item because its name is identical to an existing item.')
                return
            end
            
            % Move the object from deleted to the new parent 
            ParentObj.(ItemType)(end+1) = ThisObj;
            MatchIdx = false(size(ThisSession.Deleted));
            for idx = 1:numel(ThisSession.Deleted)
                MatchIdx(idx) = ThisSession.Deleted(idx)==ThisObj;
            end
            ThisSession.Deleted( MatchIdx ) = [];
            
             % Update the name to include the timestamp
            TimeStamp = datestr(now,'dd-mmm-yyyy_HH-MM-SS');
            
            % Strip out date
            SplitName = regexp(ThisObj.Name,'\(\d\d-\D\D\D-\d\d\d\d_\d\d-\d\d-\d\d\)','split');
            if ~isempty(SplitName) && iscell(SplitName)
                SplitName = SplitName{1}; % Take first
            end
            ThisObj.Name = strtrim(SplitName);
            
            ThisObj.Name = sprintf('%s (%s)',ThisObj.Name,TimeStamp);
            
            % Update the tree
            SelNode.Parent = hParentNode;
            SelNode.Tree.SelectedNodes = SelNode;
            hParentNode.expand();
            
            % Change context menu
            SelNode.UIContextMenu = obj.h.TreeMenu.Leaf.(ItemType);
            
            % Mark the current session dirty
            obj.markDirty();
                        
            % Update the display
            obj.refresh();
            
        end %function
        
        
        function onEmptyDeletedItems(obj,DeleteAll)
            
            % Get the session
            ThisSession = obj.SelectedSession;
            
            % What node is selected? What is its parent?
            SelNode = obj.h.SessionTree.SelectedNodes;
            
            % What is the data object?
            ThisObj = SelNode.Value;
            
            % Confirm with user
            Prompt = sprintf('Permanently delete "%s"?', SelNode.Name);
            Result = questdlg(Prompt,'Permanently Delete','Delete','Cancel','Cancel');
            if strcmpi(Result,'Delete')
                
                %  Are we deleting all or just one?
                if DeleteAll
                    % Delete all items
                    ThisSession.Deleted(:) = [];
                    delete(SelNode.Children);
                else
                    % Delete the selected item
                    MatchIdx = false(size(ThisSession.Deleted));
                    for idx = 1:numel(ThisSession.Deleted)
                        MatchIdx(idx) = ThisSession.Deleted(idx)==ThisObj;
                    end
                    % Remove from deleted items in the session
                    ThisSession.Deleted( MatchIdx ) = [];
                    % Select parent before deletion, so we don't deselect
                    % the session
                    SelNode.Tree.SelectedNodes = SelNode.Parent;
                    % Now delete tree node
                    delete(SelNode);
                end
                
                % Mark the current session dirty
                obj.markDirty();
                
            end %if strcmpi(Result,'Delete')
            
            % Update the display
            obj.refresh();
            
        end %function

        function onNodeDrop(obj,h,e)

            if length(unique(arrayfun(@(x) class(x.Value), e.Source, 'UniformOutput', false))) > 1
                % different types selected
                return
            end
            val1 = e.Source(1).Value;
            
            if isa(val1,'QSP.Settings') || isa(val1,'QSP.Session') 
                return
            end
            
            SourceNode = e.Source;
            TargetNode = e.Target;
            if ~isa(val1, class(e.Target.Value))
                return
            end
           
            switch e.DropAction
                case 'move'
                    
                     % Get the session
                    ThisSession = obj.SelectedSession;

                    % What node is selected? What is its parent?
                    SelNode = obj.h.SessionTree.SelectedNodes;

                    % What is the data object?
                    ThisObj = SelNode.Value;

                    % What type of item?
                    ItemType = strrep(class(ThisObj), 'QSP.', '');
            
                    % all data objects of this type
                    ch = ThisSession.Settings.(ItemType);

                    % indices of source nodes
                    [~,ix2] = ismember([SourceNode.Value],ch);
                    [ix2,rank]=sort(ix2);
                    SourceNode=SourceNode(rank);
                    

                    % indices of non-source nodes
                    ixDiff = setdiff(1:length(ch),ix2);
                    ch2 = ch(ixDiff); % objects without source nodes
                    
                    % index of target in remaining nodes 
                    ix = find(ch==TargetNode.Value);
                    % rearrange data objects
                    ch2 = [ch2(1:ix-1), [SourceNode.Value], ch2(ix:end)];
                    
                    % update data objects
                    ThisSession.Settings.(ItemType) = ch2;
                    
                    % update tree
                    for k=length(SourceNode):-1:1
                        TargetNode.Tree.removeNode(SourceNode(k));
                    end
                    for k=length(SourceNode):-1:1
                        TargetNode.Tree.insertNode(SourceNode(k),TargetNode.Parent,max(1,ix));                        
                    end
%                     TargetNode.Tree.reload(TargetNode.Parent);
                    
                    % Mark the current session dirty
                    obj.markDirty();

                    % Update the display
                    obj.refresh();
                otherwise
                    % Do nothing
            end


        end
    end %methods
    
    
    
    %% Get/Set methods
    methods
        
        function value = get.SelectedSession(obj)
            % Grab the session object for the selected session
            value = obj.Session(obj.SelectedSessionIdx);
        end
        
        function value = get.SessionNode(obj)
            if isempty(obj.Session)
                value = uix.widget.TreeNode.empty(0,1);
            else
                value = [obj.Session.TreeNode];
            end
        end
        
    end %methods
    
end %classdef