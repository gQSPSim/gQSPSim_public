function createAcceptanceCriteria(appObj, SelNodes)

if length(SelNodes) ~= 1
    return
end

obj = SelNodes.Value;

[StatusOK,Message,Header,Data] = importData(obj,fullfile(obj.Session.RootDirectory, obj.RelativeFilePath_new), 'tall')    ;

if ~StatusOK
    warning('Failed to create target statistics:\n%s', Message)
    return
end

input = cell2table( [Data(:,strcmp(Header,'Group')), Data(:,strcmp(Header,'Time')),  Data(:,strcmp(Header,'Species'))], 'VariableNames', {'Group','Time','Data'} );

[G, groups] = findgroups(input);

m = splitapply( @nanmean, cell2mat(Data(:,strcmp(Header,'Value'))), G);
UB = splitapply( @nanmax, cell2mat(Data(:,strcmp(Header,'Value'))), G);
LB = splitapply( @nanmin, cell2mat(Data(:,strcmp(Header,'Value'))), G);


% groups.Type = repelem('MEAN_STD',size(groups,1),1);
groups.LB = LB;
groups.UB = UB;

out_dir = fullfile(obj.Session.RootDirectory, fileparts(obj.RelativeFilePath));
out_relativePath = fileparts(obj.RelativeFilePath);

out_file = fullfile(out_dir, [obj.Name, '_AC.xlsx']);
writetable(groups, out_file)

% construct new object
o = QSP.VirtualPopulationData();
ItemName = sprintf('%s Acceptance Criteria', obj.Name);
o.Name = ItemName;
o.FilePath = fullfile(out_relativePath, [obj.Name, '_AC.xlsx']);

% obj.Session.Settings.VirtualPopulationGenerationData(end+1) = o;

appObj.addItemToSession(obj.Session, 'VirtualPopulationData', o, ItemName);
