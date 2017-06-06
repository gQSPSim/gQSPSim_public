function removeInvalidVisualization(vObj)

% Remove invalid indices
if ~isempty(vObj.PlotSpeciesInvalidRowIndices)
    vObj.Data.PlotSpeciesTable(vObj.PlotSpeciesInvalidRowIndices,:) = [];
    vObj.PlotSpeciesInvalidRowIndices = [];
end

if ~isempty(vObj.PlotItemInvalidRowIndices)
    vObj.Data.PlotItemTable(vObj.PlotItemInvalidRowIndices,:) = [];
    vObj.PlotItemInvalidRowIndices = [];
end

if ~isempty(vObj.PlotDataInvalidRowIndices)
    vObj.Data.PlotDataTable(vObj.PlotDataInvalidRowIndices,:) = [];
    vObj.PlotDataInvalidRowIndices = [];
end

if ~isempty(vObj.PlotGroupInvalidRowIndices)
    vObj.Data.PlotGroupTable(vObj.PlotGroupInvalidRowIndices,:) = [];
    vObj.PlotGroupInvalidRowIndices = [];
end

% Update
updateVisualizationView(vObj);