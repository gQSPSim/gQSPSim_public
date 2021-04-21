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
    %   $Author: kmahalin $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties
        
        Parent 
        
        Children 
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
            %    aObj = QSP.Task();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            obj.Name = 'Folder';
        end %function obj = Task(varargin)
    end
    
    %% Methods
    methods
        function ParentObj = getParentItemObj(obj)
            % to get parent QSP item object class 
            % (which is either a building block node 
            % or functionalities node)
            
            currentObj = obj;
            while isa(currentObj.Parent.NodeData, 'QSP.Folder')
                currentObj = currentObj.Parent.NodeData;
            end
            
            ParentObj = currentObj.Parent;
        end
        
        function folderNodes = getAllChildrenFolderNodes(obj, node)
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