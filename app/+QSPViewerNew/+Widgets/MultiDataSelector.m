classdef MultiDataSelector < QSPViewerNew.Widgets.Abstract.ModalWindow
    
    properties (Access = private)
        PanelGrid       matlab.ui.container.GridLayout
        
        DoubleSelectBoxes QSPViewerNew.Widgets.DoubleSelectBox
        
%         TableGrids      matlab.ui.container.GridLayout
%         ButtonGrids     matlab.ui.container.GridLayout
%         Labels          matlab.ui.control.Label
%         OptionsTables   
%         SelectionTables 
%         SelectButtons   matlab.ui.control.Button
%         UnselectButtons matlab.ui.control.Button
        
        CloseButtonGrid matlab.ui.container.GridLayout
        CloseButton     matlab.ui.control.Button
    end
    
    properties
        DialogTitle = "Select data";
        CloseButtonWidth = 100;
        ButtonSize = 30;
        LabelTexts
        Options
        Selections
        CloseCallback
    end
        
    methods
        
        function app = MultiDataSelector(title, labels, options, selections, closeCallback)
            % Build multi-data selector app
            %  title ........... figure title
            %  labels .......... string vector of section labels
            %  options ......... cell array of contents of options table;
            %                    number of cells must match number of labels
            %  selections ...... cell array of contents of selections table;
            %                    number of cells must match number of labels
            %  closeCallback ... callback function 'cbFcn(selections)' is
            %                    called with input argument being the cell
            %                    array of current selections (first cell ==
            %                    first table, second cell == second table, ...).
            app.DialogTitle = title;
            app.LabelTexts = labels;
            app.Options = options;
            app.Selections = selections;
            app.CloseCallback = closeCallback;
        end
        
        function build(app)
            
            pos = app.UIFigure.Position;
            app.UIFigure.Position = [pos(1:2), 500, 700];
            app.UIFigure.Name = app.DialogTitle;
            
            numSections = numel(app.LabelTexts);
            
            app.PanelGrid               = uigridlayout(app.UIFigure);
            app.PanelGrid.ColumnWidth   = {'1x'};
            app.PanelGrid.RowHeight     = [repmat({'1x'}, 1, numSections), {app.ButtonSize}];
            
            for i = 1:numSections
                app.DoubleSelectBoxes(i) = QSPViewerNew.Widgets.DoubleSelectBox(app.PanelGrid,i,1,char(app.LabelTexts(i)));
                app.DoubleSelectBoxes(i).setLeftListBox(app.Options{i});
                app.DoubleSelectBoxes(i).setRightListBox(app.Selections{i});
            end

            app.CloseButtonGrid               = uigridlayout(app.PanelGrid);
            app.CloseButtonGrid.Layout.Row    = numSections + 1;
            app.CloseButtonGrid.Layout.Column = 1;
            app.CloseButtonGrid.ColumnWidth   = {'1x', app.CloseButtonWidth};
            app.CloseButtonGrid.RowHeight     = {'1x'};
            app.CloseButtonGrid.Padding       = [0,0,0,0];
            app.CloseButtonGrid.RowSpacing    = 0;
            app.CloseButtonGrid.ColumnSpacing = 0;
            
            app.CloseButton                 = uibutton(app.CloseButtonGrid, 'push');
            app.CloseButton.Layout.Row      = 1;
            app.CloseButton.Layout.Column   = 2;
            app.CloseButton.Text            = 'Close';
            app.CloseButton.ButtonPushedFcn = @(evt,src) app.onCloseButtonClicked();

        end
        
        
    end
    
    methods (Access = private)
        function onCloseButtonClicked(app)
            selections = arrayfun(@(selectBox)selectBox.getRightList(), ...
                app.DoubleSelectBoxes, 'UniformOutput', false);
            app.CloseCallback(selections);
            app.onExit();
        end
    end
end