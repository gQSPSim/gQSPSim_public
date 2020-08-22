classdef HistPlotLayoutCustom < QSPViewerNew.Widgets.ModalPopup
    % Custom dialog box to use instead of inputdlg used within uidlg;
    %----------------------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 6/9/20
    properties (Access = private)
        PanelQuest      matlab.ui.container.Panel
        PanelQuestGrid  matlab.ui.container.GridLayout
        PanelExit       matlab.ui.container.Panel
        ExitGrid        matlab.ui.container.GridLayout
        ExitButton      matlab.ui.control.Button
        numWidth
        Parent
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = HistPlotLayoutCustom(Parentfigure,totalPlots)  
            obj.create(Parentfigure,totalPlots);
        end
        
        function delete(obj)
            delete(obj.PanelQuest);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function create(obj,Parentfigure,totalPlots) 
            obj.Parent = Parentfigure;
            obj.PanelQuest = uipanel(Parentfigure);
            obj.PanelQuest.Position = [Parentfigure.Position(3)*.05,Parentfigure.Position(4)*.05,Parentfigure.Position(3)*.9,Parentfigure.Position(4)*.9];
            obj.PanelQuest.Scrollable = true;
            drawnow limitrate
            Width = 300;
            Height = 300;
            
            TotalWidth = Parentfigure.Position(3)*.9;
            
            obj.numWidth = floor(TotalWidth/Width);
            
            %Minimum widht is 2 plots
            if obj.numWidth ==1
                obj.numWidth =2;
            end
            numHeight = ceil(totalPlots/obj.numWidth);
            
            %Create Button 
            obj.PanelQuestGrid = uigridlayout(obj.PanelQuest);
            obj.PanelQuestGrid.ColumnWidth = [repmat({Width},1,obj.numWidth),'1x'];
            obj.PanelQuestGrid.RowHeight = [50,repmat({Height},1,numHeight)];
            obj.PanelQuestGrid.Scrollable = 'on';
            
            
            obj.PanelExit = uipanel(obj.PanelQuestGrid);
            obj.PanelExit.Layout.Row = 1;
            obj.PanelExit.Layout.Column = [1,obj.numWidth+1];
            obj.PanelExit.BackgroundColor = [.9,.9,.9];

            obj.ExitGrid = uigridlayout(obj.PanelExit);
            obj.ExitGrid.ColumnWidth = {'1x',50};
            obj.ExitGrid.RowHeight = {'1x'};

            %Yes Button
            obj.ExitButton= uibutton(obj.ExitGrid);
            obj.ExitButton.Layout.Row = 1;
            obj.ExitButton.Layout.Column = 2;
            obj.ExitButton.Text = 'Exit';
            obj.ExitButton.ButtonPushedFcn = @obj.onExitButton;
            
        end
        
        function onExitButton(obj,~,~)
            obj.ButtonPressed = 'Yes';
        end
        
    end

    methods(Access = public)
    
        function wait(obj)
            obj.turnModalOn(obj.Parent);
            obj.ExitButton.Enable = 'on';
            waitfor(obj,'ButtonPressed');
            obj.turnModalOff();
        end
        
        function value = getPlotGrid(obj)
            value = obj.PanelQuestGrid();
        end
        
        function value = getWidth(obj)
            value = obj.numWidth;
        end
    end
end

