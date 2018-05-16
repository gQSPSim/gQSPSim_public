function updateVisualizationPlot(vObj)
% updateVisualizationPlot - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateVisualizationPlot(vObj)
%
% Inputs:
%           vObj - The MyPackageViewer.Empty vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2014-2015 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 331 $  $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
% ---------------------------------------------------------------------

if ~isempty(vObj.Data) && isfield(vObj.h,'SpeciesGroup')
    Show = [vObj.Data.PlotProfile.Show];
    
    for i=1:size(vObj.h.SpeciesGroup,1)
        for j=1:size(vObj.h.SpeciesGroup,2)
            for k=1:size(vObj.h.SpeciesGroup,3)
                if ~isempty(vObj.h.SpeciesGroup{i,j,k}) && ishandle(vObj.h.SpeciesGroup{i,j,k})
                    Ch = vObj.h.SpeciesGroup{i,j,k}.Children;
                    Ch = flip(Ch);
                    if numel(Ch) > 1
                        % Skip first (dummy line)
                        Ch = Ch(2:end);
                        set(Ch,'LineWidth',0.5);
                        if (k==vObj.Data.SelectedProfileRow)
                            set(Ch,'LineWidth',2);
                        end
                        % Show
                        if ~isempty(Show) && numel(Show) >= k && Show(k)
                            set(Ch,'Visible','on');
                        else
                            set(Ch,'Visible','off');
                        end
                    end %if
                end %if
            end % for
        end %for
    end %for
    
end %if
