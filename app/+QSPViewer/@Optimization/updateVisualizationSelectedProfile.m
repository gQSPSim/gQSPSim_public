function updateVisualizationSelectedProfile(vObj)
% updateVisualizationSelectedProfile - Updates selected profile
% -------------------------------------------------------------------------
% Abstract: This function updates selected profile
%
% Syntax:
%           updateVisualizationSelectedProfile(vObj)
%
% Inputs:
%           vObj - QSPViewer.Optimization vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%



if ~isempty(vObj.Data) && isfield(vObj.h,'SpeciesGroup')
    
    for i=1:size(vObj.h.SpeciesGroup,1)
        for j=1:size(vObj.h.SpeciesGroup,2)
            for k=1:size(vObj.h.SpeciesGroup,3)
                if ~isempty(vObj.h.SpeciesGroup{i,j,k}) && ishandle(vObj.h.SpeciesGroup{i,j,k})
                    Ch = vObj.h.SpeciesGroup{i,j,k}.Children;
                    Ch = flip(Ch);
                    if numel(Ch) > 1
                        % Skip first (dummy line)
                        Ch = Ch(2:end);
                        set(Ch,'LineWidth',vObj.Data.PlotSettings(j).LineWidth);
                        if (k==vObj.Data.SelectedProfileRow)
                            set(Ch,'LineWidth',vObj.Data.PlotSettings(j).LineWidth+2);
                        end
                    end %if
                end %if
            end % for
        end %for
    end %for
    
end %if
