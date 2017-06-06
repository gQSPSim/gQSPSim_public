function [CurrTable,InvalidTable,InvalidRowIndices] = updateVisualizationTable(CurrPlotTable,NewPlotTable,KeyIndex)

for index = 1:size(NewPlotTable,1)
    MatchRow = true(size(CurrPlotTable,1),1);
    for kIndex = KeyIndex
        % Find this row in the previous table
        MatchRow = MatchRow & strcmp(NewPlotTable{index,kIndex},CurrPlotTable(:,kIndex));
    end
    MatchRow = find(MatchRow);
    
    if ~isempty(MatchRow)
        % TODO:
        % Take the first match
        MatchRow = MatchRow(1);
        % Update the NewPlotTable
        NewPlotTable(index,:) = CurrPlotTable(MatchRow,:);
    end
end

% Before assigning, get the non-members and highlight
MissingIndices = false(size(CurrPlotTable,1),1);
for kIndex = KeyIndex
    MissingIndices = MissingIndices | ~ismember(CurrPlotTable(:,kIndex),NewPlotTable(:,kIndex));
end
InvalidRows = CurrPlotTable(MissingIndices,:);

% Update Data
CurrTable = vertcat(NewPlotTable,InvalidRows);

% Highlight
for index = 1:size(InvalidRows,1)
    for kIndex = KeyIndex
        InvalidRows{index,kIndex} = QSP.makeInvalid(InvalidRows{index,kIndex});
    end
end
InvalidTable = vertcat(NewPlotTable,InvalidRows);
if isempty(InvalidRows)
    InvalidRowIndices = [];
else
    InvalidRowIndices = (size(NewPlotTable,1)+1):size(InvalidTable,1);
end


