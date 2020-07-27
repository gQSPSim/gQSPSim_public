classdef ModalPopup < handle
    % ModalPopup - Use this class so that a popup window can modal a figure
    %----------------------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 6/9/20
    properties (Access = private)
        Handles
        InteractionTF
        ModalOn = false;
        
    end
    properties (Access = public)
        ButtonPressed = '';
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function obj = ModalPopup()
            
        end
        
        
    end
    
    methods(Access = protected)
        
        function turnModalOn(obj,~)
            obj.ModalOn = true;
        end
        
        function turnModalOff(obj)
            obj.ModalOn = false;
        end
        
    end
    
    methods(Access = private)
        function [Handles,count] = fillHandles(obj,Handles,count,graphicsObject)

            if isprop(graphicsObject,'Children')
                %Recurse on every child
                for index = 1:length(graphicsObject.Children)
                    [Handles,count] = obj.fillHandles(Handles,count,graphicsObject.Children(index));
                end  
            end
            
            if isprop(graphicsObject,'Enable')
                %Fill in Handles with all graphics children
                Handles{count} = graphicsObject;
                count = count +1;
            end
        end
        
        function counter = numChildren(obj,graphicsObject)
            %determine the total children that 'Enable' is a property
            counter = 0;
            
            %Only use recursion if the object has children. Otherwise return 0
            if isprop(graphicsObject,'Children')
                %For each child, recurse
                for index = 1:length(graphicsObject.Children)
                    counter = counter + obj.numChildren(graphicsObject.Children(index));
                end
            end
            
            %Only record the number of children that can be enabled
            if isprop(graphicsObject,'Enable')
                counter = counter +1;
            end
        end
        
    end
    
end

