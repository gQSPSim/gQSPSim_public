function createTree(obj, Parent, AllData)
% createTree - create a node for the tree
% -------------------------------------------------------------------------
% Creates node(s) for the tree
%

% Copyright 2016 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 217 $  $Date: 2016-07-29 11:37:42 -0400 (Fri, 29 Jul 2016) $
% ---------------------------------------------------------------------

% Nodes that take children have the type of child as a string in the UserData
% property. Nodes that are children and are movable have [] in UserData.

% Get short name to call this function recursively
thisFcn = @(Parent,Data)createTree(obj,Parent,Data);

% Loop on objects
for idx=1:numel(AllData)
    
    % Get current object
    Data = AllData(idx);
    
    % What type of object is this?
    Type = class(Data);
    
    % Switch on object type for the icon
    switch Type
        
        case 'QSP.Session'
            
            % Session node
            hSession = i_addNode(Parent, Data, ...
                'Session', 'folder_24.png',...
                obj.h.TreeMenu.Branch.Session, [], 'Session');
            Data.TreeNode = hSession; %Store node in the object for cross-ref
            
            % Settings node and children
            hSettings = i_addNode(hSession, Data.Settings, ...
                'Settings', 'settings_24.png',...
                [], 'Settings', 'Settings for the session');
            Data.Settings.TreeNode = hSettings; %Store node in the object for cross-ref
            
            hOptimData = i_addNode(hSettings, Data.Settings, ...
                'Data for Optimization', 'optim_24.png',...
                obj.h.TreeMenu.Branch.OptimizationData, 'OptimizationData', 'Optimization Data');
            thisFcn(hOptimData, Data.Settings.OptimizationData);
            
            hParameters = i_addNode(hSettings, Data.Settings, ...
                'Parameters', 'param_edit_24.png',...
                obj.h.TreeMenu.Branch.Parameters, 'Parameters', 'Parameters');
            thisFcn(hParameters, Data.Settings.Parameters);
            
            hTasks = i_addNode(hSettings, Data.Settings, ...
                'Tasks', 'report_24.png',...
                obj.h.TreeMenu.Branch.Task, 'Task', 'Tasks');
            thisFcn(hTasks, Data.Settings.Task);
            
            hVPops = i_addNode(hSettings, Data.Settings, ...
                'Virtual Populations', 'datatable_24.png',...
                obj.h.TreeMenu.Branch.VirtualPopulation, 'VirtualPopulation', 'Virtual Populations');
            thisFcn(hVPops, Data.Settings.VirtualPopulation);
            
            hVPopDatas = i_addNode(hSettings, Data.Settings, ...
                'Acceptance Criteria', 'database_24.png',...
                obj.h.TreeMenu.Branch.VirtualPopulationData, 'VirtualPopulationData', 'Virtual Population Data');
            thisFcn(hVPopDatas, Data.Settings.VirtualPopulationData);
            
            % Other session children
            hSimulations = i_addNode(hSession, Data, ...
                'Simulations', 'simbio_24.png',...
                obj.h.TreeMenu.Branch.Simulation, 'Simulation', 'Simulation');
            thisFcn(hSimulations, Data.Simulation);
            
            hOptims = i_addNode(hSession, Data, ...
                'Optimizations', 'optim_24.png',...
                obj.h.TreeMenu.Branch.Optimization, 'Optimization', 'Optimization');
            thisFcn(hOptims, Data.Optimization);
            
            hVPopGens = i_addNode(hSession, Data, ...
                'Virtual Population Generations', 'datatable_24.png',...
                obj.h.TreeMenu.Branch.VirtualPopulationGeneration, 'VirtualPopulationGeneration', 'Virtual Population Generation');
            thisFcn(hVPopGens, Data.VirtualPopulationGeneration);
            
            hDeleteds = i_addNode(hSession, Data, ...
                'Deleted Items', 'trash_24.png',...
                obj.h.TreeMenu.Branch.Deleted, 'Deleted', 'Deleted Items');
            thisFcn(hDeleteds, Data.Deleted);
            
            % Expand Nodes
            hSession.expand();
            hSettings.expand();
            
        case 'QSP.OptimizationData'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'optim_24.png',...
                obj.h.TreeMenu.Leaf.OptimizationData, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        case 'QSP.Parameters'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'param_edit_24.png',...
                obj.h.TreeMenu.Leaf.Parameters, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        case 'QSP.Task'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'report_24.png',...
                obj.h.TreeMenu.Leaf.Task, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        case 'QSP.VirtualPopulation'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'datatable_24.png',...
                obj.h.TreeMenu.Leaf.VirtualPopulation, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
            
        case 'QSP.VirtualPopulationData'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'database_24.png',...
                obj.h.TreeMenu.Leaf.VirtualPopulationData, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        case 'QSP.Simulation'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'simbio_24.png',...
                obj.h.TreeMenu.Leaf.Simulation, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        case 'QSP.Optimization'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'optim_24.png',...
                obj.h.TreeMenu.Leaf.Optimization, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        case 'QSP.VirtualPopulationGeneration'
            
            hNode = i_addNode(Parent, Data, Data.Name, 'datatable_24.png',...
                obj.h.TreeMenu.Leaf.VirtualPopulationGeneration, [], '');
            Data.TreeNode = hNode; %Store node in the object for cross-ref
            
        otherwise
            
            % Skip this node
            warning('QSPViewer:App:createTree:UnhandledType',...
                'Unhandled object type for tree: %s. Skipping.', Type);
            continue
            
    end %switch
    
    % If the node is deleted, swap out the context menu
    if strcmp(Parent.Name,'Deleted Items')
        hNode.UIContextMenu = obj.h.TreeMenu.Leaf.Deleted;
    end
    
end %for


end %function


%% Internal function i_addNode
function hNode = i_addNode(Parent, Data, Name, Icon, CMenu, PaneType, Tooltip)

% Create the node
hNode = uix.widget.TreeNode(...
    'Parent', Parent,...
    'Name', Name,...
    'Value', Data,...
    'UserData',PaneType,...
    'UIContextMenu', CMenu,...
    'TooltipString', Tooltip);
hNode.setIcon(uix.utility.findIcon(Icon))

end %function