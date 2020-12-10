classdef GlobalSensitivityAnalysisProgress < QSPViewerNew.Widgets.Abstract.ModalWindow
    
    properties (Access = private)
        PanelGrid   matlab.ui.container.GridLayout
        LabelGrid   matlab.ui.container.GridLayout
        AxesGrid    matlab.ui.container.GridLayout
        Labels      matlab.ui.control.Label
        LabelPanel  matlab.ui.container.Panel
        PlotPanel   matlab.ui.container.Panel
        Button  matlab.ui.control.Button        
        Axes        matlab.ui.control.UIAxes
        
        DialogTitle = ''
        NumLabels   = 7
        Color       = [0,0,0]
        
        Target      = 0
    end
    
    properties
        ButtonPressed = false;
    end
        
    methods
        
        function app = GlobalSensitivityAnalysisProgress(title)
            app.DialogTitle = title;
        end
        
        function build(app)
            
            pos = app.UIFigure.Position;
            app.UIFigure.Position = [pos(1:2), 550, 220];
            app.UIFigure.Name = app.DialogTitle;
            
            app.PanelGrid               = uigridlayout(app.UIFigure);
            app.PanelGrid.ColumnWidth   = {280, '1x'};
            app.PanelGrid.RowHeight     = {'1x'};
            app.PanelGrid.Padding       = [0,0,0,0];
            app.PanelGrid.RowSpacing    = 0;
            app.PanelGrid.ColumnSpacing = 0;

            app.LabelPanel               = uipanel(app.PanelGrid);
            app.LabelPanel.Layout.Column = 1;
            app.LabelPanel.Layout.Row    = 1;

            app.PlotPanel               = uipanel(app.PanelGrid);
            app.PlotPanel.Layout.Column = 2;
            app.PlotPanel.Layout.Row    = 1;
            
            app.LabelGrid               = uigridlayout(app.LabelPanel);
            app.LabelGrid.ColumnWidth   = {'1x',50,'1x'};
            labelHeight = 20;
            app.LabelGrid.RowHeight     = num2cell([10, ... % space to border
                                           repmat(labelHeight, 1, app.NumLabels), ... % labels
                                           labelHeight, ... % space between labels and button
                                           labelHeight, ... % button
                                           10]); % space to border
            app.LabelGrid.RowSpacing    = 0;
            app.LabelGrid.ColumnSpacing = 0;
                             
            for i = 1:app.NumLabels+1
                app.addLabel(i, '');
            end
            
            app.Button                 = uibutton(app.LabelGrid,'push', 'Visible', 'off');
            app.Button.Layout.Row      = app.NumLabels+3;
            app.Button.Layout.Column   = 2;
            app.Button.Text            = 'Stop';
            app.Button.Tooltip         = 'Stop adding samples';
            app.Button.ButtonPushedFcn = @(evt,src) set(app, 'ButtonPressed', true);
            
            app.AxesGrid               = uigridlayout(app.PlotPanel);
            app.AxesGrid.ColumnWidth   = {'1x'};
            app.AxesGrid.RowHeight     = {'1x'};
            app.AxesGrid.RowSpacing    = 0;
            app.AxesGrid.ColumnSpacing = 0;

            app.Axes = uiaxes(app.AxesGrid, 'Visible', 'off');
            app.Axes.YScale = 'log';

        end
        
        function update(app, messages, xData, yData)
            
            app.ButtonPressed = false;
            app.Button.Visible = 'on';
            
            app.Labels(1).FontWeight = 'bold';
            for i = 1:app.NumLabels
                app.Labels(i).Text = messages{i};
            end
            
            if isempty(yData) || all(isnan(yData))
                drawnow
                return;
            else
                xData = xData(~isnan(yData));
                yData = yData(~isnan(yData));
            end
            
            cla(app.Axes);
            xlabel(app.Axes, 'Number of Samples');
            ylabel(app.Axes, 'Max. difference');
            hold(app.Axes, 'on');
            if app.Target > 0
                plot(app.Axes, xData, app.Target*ones(1,numel(xData)), 'r-');
            end
            plot(app.Axes, xData, yData, 'o-', ...
                'Color', app.Color, 'MarkerFaceColor', app.Color);
            xticks(app.Axes, xData);
            xticklabels(app.Axes, arrayfun(@num2str, xData, 'UniformOutput', false));
            hold(app.Axes, 'off');
            grid(app.Axes, 'on');
            app.Axes.Visible = 'on';
            
            drawnow;
            
        end
        
        function reset(app, target, color)
            app.Target         = target;
            app.Axes.Visible   = 'off';
            app.Button.Visible = 'off';
            app.Color          = color;
        end
        
        function customizeButton(app, text, tooltip, callback)
            app.Button.Text    = text;
            app.Button.Tooltip = tooltip;
            app.Button.ButtonPushedFcn = @(evt,src) callback();
            drawnow;
        end
    end
    
    methods (Access = private)
        function addLabel(app, row, text)
            newLabel               = uilabel(app.LabelGrid);
            newLabel.Layout.Column = [1,3];
            newLabel.Layout.Row    = 1+row;
            newLabel.Text          = text;
            app.Labels = [app.Labels, newLabel];
        end
        
    end
end