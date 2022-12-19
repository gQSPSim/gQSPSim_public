classdef InputDlgCustom < QSPViewerNew.Widgets.ModalPopup
    % Custom dialog box to use instead of inputdlg used within uidlg;
    properties (Access = private)
        PanelQuest      matlab.ui.container.Panel
        PanelQuestGrid  matlab.ui.container.GridLayout
        YesButton       matlab.ui.control.Button
        CancelButton    matlab.ui.control.Button
        EditField       matlab.ui.control.EditField
        QuestionLabel   matlab.ui.control.Label
        Parent

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = InputDlgCustom(Parentfigure,Question,DefaultValue)  
            obj.create(Parentfigure,Question,DefaultValue);
        end
        
        function delete(obj)
            delete(obj.PanelQuest);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function create(obj,Parentfigure,Question,DefaultValue)  
            obj.Parent = Parentfigure;
            obj.PanelQuest = uipanel(Parentfigure);
            Width = 450;
            Height = 150;
            Xstart = (Parentfigure.Position(3)-Width)/2;
            Ystart = (Parentfigure.Position(4)-Height)/2;
            obj.PanelQuest.Position = [Xstart,Ystart,Width,Height];
            
            %Create Button 
            obj.PanelQuestGrid = uigridlayout(obj.PanelQuest);
            obj.PanelQuestGrid.ColumnWidth = {'1x',200,80,80,'1x'};
            obj.PanelQuestGrid.RowHeight = {'1x',30,30,'1x'};

            %Yes Button
            obj.YesButton= uibutton(obj.PanelQuestGrid);
            obj.YesButton.Layout.Row =3;
            obj.YesButton.Layout.Column = 3;
            obj.YesButton.Text = 'Yes';
            obj.YesButton.ButtonPushedFcn = @obj.onYesButton;


            %Yes Button
            obj.CancelButton= uibutton(obj.PanelQuestGrid);
            obj.CancelButton.Layout.Row = 3;
            obj.CancelButton.Layout.Column = 4;
            obj.CancelButton.Text = 'Cancel';
            obj.CancelButton.ButtonPushedFcn = @obj.onCancelButton;

            %Editfield
            obj.EditField= uieditfield(obj.PanelQuestGrid,'text');
            obj.EditField.Layout.Row = 3;
            obj.EditField.Layout.Column = 2;
            obj.EditField.Value = DefaultValue;

            %Question
            obj.QuestionLabel= uilabel(obj.PanelQuestGrid);
            obj.QuestionLabel.Layout.Row = 2;
            obj.QuestionLabel.Layout.Column = [2,4];
            obj.QuestionLabel.Text = Question;
        end
        
        function onYesButton(obj,~,~)
            obj.ButtonPressed = 'Yes';
            
        end
        
        function onCancelButton(obj,~,~)
            obj.ButtonPressed = 'Cancel';
        end
        
       
    end

    methods(Access = public)
    
        function wait(obj)
            obj.turnModalOn(obj.Parent);
            obj.YesButton.Enable = 'on';
            obj.CancelButton.Enable = 'on';
            obj.EditField.Enable = 'on';
            waitfor(obj,'ButtonPressed');
            obj.turnModalOff();
        end
        
        function outputValue = getValue(obj)
            if strcmpi(obj.ButtonPressed,'Yes')
                outputValue = obj.EditField.Value;
            else
                outputValue = [];
            end
        end
        
    end
    
end

