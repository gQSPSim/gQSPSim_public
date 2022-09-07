classdef Folder < QSP.abstract.BaseProps & uix.mixin.HasTreeReference
    % Folder - Defines a Folder object
    % ---------------------------------------------------------------------
    % Abstract: This object defines Folder
    %
    % Syntax:
    %           obj = QSP.Folder
    %           obj = QSP.Folder('Property','Value',...)
    %
    %   All properties may be assigned at object construction using
    %   property-value pairs.
    %
    % QSP.Folder Properties:
    %
    % Copyright 2021 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   Author: Karthiga Mahalingam 
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        Parent 
        
        Children 
        
        OldParent % previous parent. used to move back folder to previous parent when deleted
    end
    
    %% Constructor methods
    methods
        function obj = Folder(varargin)
            % Folder - Constructor for QSP.Folder
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new QSP.Folder object.
            %
            % Syntax:
            %           obj = QSP.Folder('Parameter1',Value1,...)
            %
            % Inputs:
            %           Parameter-value pairs
            %
            % Outputs:
            %           obj - QSP.Folder object
            %
            % Example:
            %    aObj = QSP.Folder();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            obj.Name = 'Folder';
        end %function obj = Folder(varargin)
    end
    
    %% Methods
    methods
        function ParentNode = getParentItemNode(obj, treeRoot)
            % to get parent QSP item object class 
            % (which is either a building block node 
            % or functionalities node)
            
            currentObj = obj;
            while isa(currentObj.Parent, 'QSP.Folder')
                currentObj = currentObj.Parent;
            end
            
            % find session node
            sessionNodeIdx = arrayfun(@(x) isequal(x.NodeData.SessionName, obj.Session.SessionName), treeRoot.Children);
            sessionNode = treeRoot.Children(sessionNodeIdx);
            sessNodeChildren = sessionNode.Children;
            
            % is it a building block or functionality?
            if ismember(currentObj.Parent, {'Tasks', 'Parameters', 'Datasets', ...
                    'Acceptance Criteria', 'Target Statistics', 'Virtual Subject(s)'})
                parentParentNode = sessNodeChildren(arrayfun(@(x) strcmp(x.Text, 'Building blocks'), sessNodeChildren));
                ParentNodeIdx = arrayfun(@(x) strcmp(x.Text, currentObj.Parent), parentParentNode.Children);
                ParentNode = parentParentNode.Children(ParentNodeIdx);
            elseif ismember(currentObj.Parent, {'Simulations', 'Optimizations', 'Virtual Cohort Generations', ...
                    'Virtual Population Generations', 'Global Sensitivity Analyses'})
                parentParentNode = sessNodeChildren(arrayfun(@(x) strcmp(x.Text, 'Functionalities'), sessNodeChildren));
                ParentNodeIdx = arrayfun(@(x) strcmp(x.Text, currentObj.Parent), parentParentNode.Children);
                ParentNode = parentParentNode.Children(ParentNodeIdx);
            else
                ParentNode = sessNodeChildren(arrayfun(@(x) strcmp(x.Text, 'Deleted Items'), sessNodeChildren));
            end
            
        end
        
        function folderNodes = getAllChildrenFolderNodes(obj, node)
            % get all folder children nodes below "node"
            folderNodes = [];
            for i = 1:length(node.Children)
                currentNode = node.Children(i);
                if isa(currentNode.NodeData, 'QSP.Folder')
                    folderNodes = [folderNodes; currentNode; getAllChildrenFolderNodes(obj, currentNode)];
                end
            end
        end
        
    end
    
    %% Methods (defined as abstract)
    methods
        function Summary = getSummary(obj)
            % Populate summary
            Summary = {...
                'Name',obj.Name;};
        end
        
        function clearData(~)
        end
        
        function validate(~)
        end
    end
    
end