function createTargetStatistics_withDistributions(appObj, SelNodes)
% createTargetStatistics_withDistributions
%
% Syntax:
%       createTargetStatistics_withDistributions(appObj, SelNodes)
%
% Description:
%           Generate a new Target Statistics file from a Optimization Data file
%
% Inputs:
%       QSPViewer.App object
%       SelNodes
%
% Author:

hWbar = uix.utility.CustomWaitbar(0, 'Creating Target Statistics', 'Please wait', false);



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

% m = splitapply( @nanmean, cell2mat(Data(:,strcmp(Header,'Value'))), G);
% s = splitapply( @nanstd, cell2mat(Data(:,strcmp(Header,'Value'))), G);
Gunq = unique(G);
out_data = [];

Nbins = 10;

for g = 1:height(groups)
    
    data = Data(G==g,strcmp(Header,'Value'));
    [N,edges] = histcounts(cell2mat(data), Nbins);
    
    thisGroup = table2cell(groups(g,:));
    
    out_data = [out_data;  
        [ thisGroup, 'DIST_BINS', num2cell(edges)] ;
        [ thisGroup, 'DIST_DENSITY', num2cell(N), {[]} ]];
        
    uix.utility.CustomWaitbar(g/height(groups), hWbar, 'Please wait');    
end

% out_data = cell2table(out_data, 'VariableNames', {'Group', 'Time', 'Species', 'Type', 'Value1', 'Value2'});

out_dir = fullfile(obj.Session.RootDirectory, fileparts(obj.RelativeFilePath));
out_relativePath = fileparts(obj.RelativeFilePath);

out_file = fullfile(out_dir, [obj.Name, '_TargetStatistics_dist.xlsx']);

out_data = [ [ {'Group', 'Time', 'Species', 'Type', 'Value1', 'Value2'}, repmat({[]}, 1, Nbins-1)] ; out_data];
xlwrite(out_file, out_data)
% writetable(out_data,out_file)

% writetable(groups, out_file)

% construct new object
o = QSP.VirtualPopulationGenerationData();
ItemName = sprintf('%s Target Statistics', obj.Name);
o.Name = ItemName;
o.FilePath = fullfile(out_relativePath, [obj.Name, '_TargetStatistics_dist.xlsx']);

% obj.Session.Settings.VirtualPopulationGenerationData(end+1) = o;

appObj.addItemToSession(obj.Session, 'VirtualPopulationGenerationData', o, ItemName);

delete(hWbar)