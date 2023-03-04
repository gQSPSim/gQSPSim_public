
function createTargetStatistics(appObj, SelNodes)
% createTargetStatistics
%
% Syntax:
%       createTargetStatistics(appObj, SelNodes)
%
% Description:
%           Generate a new Target Statistics file from a Optimization Data file       
%
% Inputs:
%       QSPViewer.App object
%       SelNodes
%
% Author:


if length(SelNodes) ~= 1
    return
end

obj = SelNodes.Value;

[StatusOK,Message,Header,Data] = importData(obj,fullfile(obj.Session.RootDirectory, obj.RelativeFilePath), 'tall')    ;

if ~StatusOK
    warning('Failed to create target statistics:\n%s', Message)
    return
end

input = cell2table( [Data(:,strcmp(Header,'Group')), Data(:,strcmp(Header,'Time')),  Data(:,strcmp(Header,'Species'))], 'VariableNames', {'Group','Time','Species'} );

[G, groups] = findgroups(input);

m = splitapply( @nanmean, cell2mat(Data(:,strcmp(Header,'Value'))), G);
s = splitapply( @nanstd, cell2mat(Data(:,strcmp(Header,'Value'))), G);

groups.Type = repelem('MEAN_STD',size(groups,1),1);
groups.Value1 = m;
groups.Value2 = s;

out_dir = fullfile(obj.Session.RootDirectory, fileparts(obj.RelativeFilePath));
out_relativePath = fileparts(obj.RelativeFilePath);

out_file = fullfile(out_dir, [obj.Name, '_TargetStatistics.xlsx']);
writetable(groups, out_file)

% construct new object
o = QSP.VirtualPopulationGenerationData();
ItemName = sprintf('%s Target Statistics', obj.Name);
o.Name = ItemName;
o.FilePath = fullfile(out_relativePath, [obj.Name, '_TargetStatistics.xlsx']);

% obj.Session.Settings.VirtualPopulationGenerationData(end+1) = o;

appObj.addItemToSession(obj.Session, 'VirtualPopulationGenerationData', o, ItemName);
