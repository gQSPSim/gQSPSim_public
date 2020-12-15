classdef ModalWindow < matlab.apps.AppBase
    % ModalWindow - this class will create the window for the UI. 
    % ---------------------------------------------------------------------
    % Instantiates the Application figure window
    %
    % Syntax:
    %           app = QSPViewerNew.Widgets.Abstract.ModalWindow
    %
    % This class inherits properties and methods from:
    %
    %       matlab.apps.AppBase 
    %
    %
    %
    %   Copyright 2020 The MathWorks, Inc.
    %    
    
    properties (Access = protected)
        UIFigure matlab.ui.Figure
    end
    
    properties (Access = private)
        DisabledObjects = {}
    end
    
    methods (Abstract)
        % Implement this method to add ui components to the progres UI
        build(app)
    end
    
    methods 
        
        function app = ModalWindow()
            % Create figure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.CloseRequestFcn = @(evt,src)app.onExit();
        end

        function varargout = open(app, parentFigure)
            % Add customized ui components
            app.build();            
            % Set calling app in wait status; the calling app resumes if
            % the progress UI is closed. Call the method onExit() to close
            % the progress UI via a callback.
            app.modalOn(parentFigure);
            app.UIFigure.Visible = 'on';
            drawnow;
            % Return cleanup object which, on destruction, closes the app.
            if nargout > 0
                varargout = {onCleanup(@()delete(app))};
            end
        end 
        
        function delete(app)
            app.modalOff();
            delete(app.UIFigure);
        end
        
        function onExit(app)
            delete(app);
        end
    end
    
    methods (Access = private)
        function modalOn(app, graphicsObject)
            if isprop(graphicsObject,'Children')
                %Recurse on every child
                for index = 1:numel(graphicsObject.Children)
                    app.modalOn(graphicsObject.Children(index));
                end  
            end
            if isprop(graphicsObject, 'Enable') && strcmp(graphicsObject.Enable, 'on')
                % Disable any graphics object that is enabled
                app.DisabledObjects = [app.DisabledObjects, {graphicsObject}];
                graphicsObject.Enable = 'off';
            end            
        end
        function modalOff(app)
            for index = 1:numel(app.DisabledObjects)
                % Disable any graphics object that was enabled
                if isvalid(app.DisabledObjects{index})
                    set(app.DisabledObjects{index}, 'Enable', 'on');
                end
            end
        end
    end
end