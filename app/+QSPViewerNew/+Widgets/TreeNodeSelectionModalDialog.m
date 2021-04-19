classdef TreeNodeSelectionModalDialog < handle & ...
        uix.mixin.AssignPVPairs
    % Custom treenode selection box to pass trees and select node(s)
    %----------------------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Karthiga Mahalingam
    %   Revision: 1
    %   Date: 4/17/21
    
    properties (Access = public)
        ModalOn         (1,1) logical = true
        MultiSelection  (1,1) logical = false
        DialogName      (1,1) string  = ""
        SelectedNode    (1,:)  matlab.ui.container.TreeNode
        ParentApp
        ParentAppPosition (1,4) double
        MainFigure          matlab.ui.Figure
    end
    
    % Graphics components properties
    properties (Access = private)
        MainGrid            matlab.ui.container.GridLayout
        MainTree            matlab.ui.container.Tree
        OKButton            matlab.ui.control.Button
        CancelButton        matlab.ui.control.Button
        ParentNode   (1,1)  matlab.ui.container.TreeNode
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = TreeNodeSelectionModalDialog (ParentApp, ParentNode, varargin)
            obj.ParentApp = ParentApp;
            
            obj.ParentNode = ParentNode;
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
            obj.create();
        end
        
        function delete(obj)
            obj.ParentApp.SelectedNodePath = obj.getFullNodePath(obj.SelectedNode);
            delete(obj.MainFigure);
%             uiresume(obj.ParentFigure);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function create(obj) 
            % create a figure
            obj.MainFigure = uifigure('Name', obj.DialogName);
            obj.MainFigure.Position(3:4) = [400, 400];
            if ~isempty(obj.ParentAppPosition)
                obj.MainFigure.Position(1) = obj.ParentAppPosition(1)+(obj.ParentAppPosition(3)/2)-(obj.MainFigure.Position(3)/2);
                obj.MainFigure.Position(2) = obj.ParentAppPosition(2)+(obj.ParentAppPosition(4)/2)-(obj.MainFigure.Position(4)/2);
            end
            if obj.ModalOn
                obj.MainFigure.WindowStyle = 'modal';
            else
                obj.MainFigure.WindowStyle = 'normal';
            end
            
            % Create grid layout
            obj.MainGrid = uigridlayout(obj.MainFigure);
            obj.MainGrid.RowHeight = {'1x',22};
            obj.MainGrid.ColumnWidth = {'1x',70,70};
            
            % create main tree
            obj.MainTree = uitree(obj.MainGrid, ...
                'MultiSelect', obj.MultiSelection);
            obj.MainTree.Layout.Row = 1;
            obj.MainTree.Layout.Column = [1, length(obj.MainGrid.ColumnWidth)];
            
            obj.createTreeNode(obj.ParentNode, obj.MainTree)
            
            % Create OK button
            obj.OKButton = uibutton(obj.MainGrid, 'push', ...
                'ButtonPushedFcn', @(h,e) obj.onOKButtonPushed(h,e));
            obj.OKButton.Text = "OK";
            obj.OKButton.Layout.Row = 2;
            obj.OKButton.Layout.Column = 2;
            
            % Create cancel button
            obj.CancelButton = uibutton(obj.MainGrid, 'push', ...
                'ButtonPushedFcn', @(h,e) obj.onCancelButtonPushed(h,e));
            obj.CancelButton.Text = "Cancel";
            obj.CancelButton.Layout.Row = 2;
            obj.CancelButton.Layout.Column = 3;
            
            expand(obj.MainTree);
        end
        
        function createTreeNode(obj, node, parent)
            % Just create a node if it doesn't have children
            if isempty(node.Children)
                t = uitreenode(parent, 'Text', node.Text);
                expand(t);
                return;
            end
            
            % If it has, keep looking at its children
            parentNode = uitreenode(parent, 'Text', node.Text);
            expand(parentNode);
            for i = 1:length(node.Children)
                currentNode = node.Children(i);
                if ~isa(currentNode.NodeData, 'QSP.Folder')
                    continue;
                end
                obj.createTreeNode(currentNode, parentNode);
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Callbacks
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        function onOKButtonPushed(obj,~,~)
            if isempty(obj.MainTree.SelectedNodes)
                uialert(obj.MainFigure, ...
                    "Hit cancel in the main screen if you want to cancel out of the Dialog.", ...
                    "No nodes selected", ...
                    'Icon', 'warning');
            else
                obj.SelectedNode = obj.MainTree.SelectedNodes;
                obj.delete();
            end
        end
        
        function onCancelButtonPushed(obj,~,~)
            obj.delete();
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Private methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        function fullNodePath = getFullNodePath(obj, node)
            fullNodePath = "";
            if isempty(node)
                return;
            elseif isequal(node.Parent, obj.MainTree)
                fullNodePath = string(node.Text);
            else
                fullNodePath = strcat(fullNodePath, node.Text, filesep, obj.getFullNodePath(node.Parent));
            end
        end
    end
end