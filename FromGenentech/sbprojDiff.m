% script to diff two sbproj files
% Justin Feigelman
% feigelmj@gene.com
% m2 assumed to be newer than m1

function commitMsg = sbprojDiff(m1,m2,varargin)

commitMsg = '';

if isstruct(m1) && isstruct(m2)
    % dealing with multiple models
    
    models1 = struct2cell( structfun(@(x) x.Name, m1, 'UniformOutput', false) );
    models2 = struct2cell( structfun(@(x) x.Name, m2, 'UniformOutput', false) );    
    f1 = fields(m1);
    f2 = fields(m2);
    
    commonModels = intersect(models1,models2);
    for k=1:length(commonModels)
        diff = sbprojDiff_( m1.(f1{strcmp(models1,commonModels{k})}),  m2.(f2{strcmp(models2,commonModels{k})}), varargin);
        if ~isempty(diff)
            commitMsg = sprintf('%s\n%s %s %s', commitMsg, repmat('-', 1, 20), commonModels{k}, repmat('-', 1, 20));   
            commitMsg = sprintf('%s\n%s', commitMsg, diff );
        end
    end
elseif ~isstruct(m1) && ~isstruct(m2)
    commitMsg = sbprojDiff_(m1,m2,varargin);
else
    error('Both arguments must either be Simbiology models or struct arrays of Simbiology models')
end
        
    

function commitMsg = sbprojDiff_(m1,m2,varargin)

% generate a diff for variants, species, init conditions, reaction rates, 
% m1: first model
% m2: second model
% additional arguments: more models to compare against
if length(varargin) == 2
    name1 = varargin{1};
    name2 = varargin{2};
else
    name1 = m1.Name;
    name2 = m2.Name; 
    if strcmp(name1,name2)
        name1 = [name1, '_old'];
        name2 = [name2, '_new'];
    end
end

name1 = matlab.lang.makeValidName(name1);
name2 = matlab.lang.makeValidName(name2);

% file handle for diff log
fOut = 1; % stdout

commitMsg = '';
%% variants
var1 = getvariant(m1);
var2 = getvariant(m2);

fprintf(fOut, '%s VARIANTS %s\n\n', repmat('%', 40, 1), repmat('%', 40, 1))
commitMsg = [commitMsg, diffVariants(var1,var2,name1,name2,fOut)];


%% species
spec1 = m1.Species;
spec2 = m2.Species;

fprintf(fOut, '\n');
fprintf(fOut, '%s SPECIES %s\n\n', repmat('%', 40, 1), repmat('%', 40, 1))

commitMsg = [commitMsg, diffSpecies(spec1,spec2,name1,name2,fOut)];

%% parameters
par1 = m1.Parameters;
par2 = m2.Parameters;

fprintf(fOut, '\n');
fprintf(fOut, '%s PARAMETERS %s\n\n', repmat('%', 40, 1), repmat('%', 40, 1))

commitMsg = [commitMsg, diffParams(par1,par2,name1,name2,fOut)];

%% reactions
reac1 = m1.Reactions;
reac2 = m2.Reactions;

fprintf(fOut, '\n');
fprintf(fOut, '%s REACTIONS %s\n\n', repmat('%', 40, 1), repmat('%', 40, 1))

commitMsg = [commitMsg, diffRxns(reac1,reac2,name1,name2,fOut)];

% rules
rules1 = m1.Rules;
rules2 = m2.Rules;

fprintf(fOut, '\n');
fprintf(fOut, '%s RULES %s\n\n', repmat('%', 40, 1), repmat('%', 40, 1))

commitMsg = [commitMsg, diffRules(rules1,rules2,name1,name2,fOut)];

% dose
dose1 = getdose(m1);
dose2 = getdose(m2);
fprintf(fOut, '\n');
fprintf(fOut, '%s DOSES %s\n\n', repmat('%', 40, 1), repmat('%', 40, 1))

commitMsg = [commitMsg, diffDose(dose1,dose2,name1,name2,fOut)];

function snippet = diffVariants(var1,var2,name1,name2,fOut)
% compare variants
snippet = [];

% check for unique variants
varNames1 = get(var1, 'Name');
varNames2 = get(var2, 'Name');

unq1 = setdiff(varNames1, varNames2);
if ~isempty(unq1)
    fprintf(fOut, 'The following variants appear in %s but not %s:\n', name1, name2);    
    fprintf(fOut, '%s\n', unq1{:});
    snippet = [snippet, sprintf('Remove variants: %s\n', strjoin(unq1(:), ', '))];
end

unq2 = setdiff(varNames2, varNames1);
if ~isempty(unq2)
    fprintf(fOut, 'The following variants appear in %s but not %s:\n', name2, name1);
    fprintf(fOut, '%s\n', unq2{:});
    snippet = [snippet, sprintf('Add variants: %s\n', strjoin(unq2(:), ', '))];
end

[common, i1, i2] = intersect(varNames1,varNames2);
% check for different activation states
if isempty(common)
    return
end
act1 = get(var1,'Active');
act2 = get(var2,'Active');

cont1 = get(var1, 'Content');
cont2 = get(var2, 'Content');

diffAct = [];
for k=1:numel(common)
    if act1{i1(k)} ~= act2{i2(k)}
        fprintf(fOut, 'Activation state of variant %s differs between models\n', varNames1{i1(k)});
        diffAct = [diffAct, k];
    end    
end

if ~isempty(diffAct)
    snippet = [snippet, sprintf('Change activation state for states: %s', join(varNames1{i1(diffAct)}, ','))];
end

varElemsDiffTable = table(); %[], 'VariableNames', {'Variant', 'Type', 'Name', 'Value', name1});

% check nature of the variants
for k=1:numel(common)
    thisContent1 = cont1{i1(k)};
    thisContent2 = cont2{i2(k)};
  
    % sanitize if necessary
    name1 = matlab.lang.makeValidName(name1);
    name2 = matlab.lang.makeValidName(name2);

    % create tables for each variant contents
    if ~isempty(thisContent1) 
        contentTable1 = cell2table(vertcat(thisContent1{:}));
        contentTable1.Properties.VariableNames = {'Type', 'Name', 'Value', name1};
    else
        contentTable1 = table([],[],[],[], 'VariableNames', {'Type', 'Name', 'Value', name1});
    end
    
    if ~isempty(thisContent2)
        contentTable2 = cell2table(vertcat(thisContent2{:}));
        contentTable2.Properties.VariableNames = {'Type', 'Name', 'Value', name2};
    else
        contentTable2 = table([],[],[],[], 'VariableNames', {'Type', 'Name', 'Value', name2});
    end
    
    [~,ixCommonVarElems1,ixCommonVarElems2] = intersect(contentTable1(:,1:3), contentTable2(:,1:3));
    
    [unq1, ixUnq1] = setdiff(contentTable1(:,1:3), contentTable2(:,1:3));
    [unq2, ixUnq2] = setdiff(contentTable2(:,1:3), contentTable1(:,1:3));
    

    % construct difference table
    tmpTable = [unq1(:,1:2), contentTable1(ixUnq1, 4), array2table(nan(length(ixUnq1), 1), 'VariableNames', {name2})];
    tmpTable = vertcat(tmpTable, ...
        [unq2(:,1:2), array2table(nan(length(ixUnq2), 1), 'VariableNames', {name1}), contentTable2(ixUnq2, 4)]);

    ixDiff = table2array(contentTable1(ixCommonVarElems1,4)) ~= table2array(contentTable2(ixCommonVarElems2,4));
    
%     tmpTable.Properties.VariableNames{1} 
    varElemsDiffTable = [varElemsDiffTable; [table(repmat(common(k), nnz(ixDiff), 1)), ...
        contentTable1(ixCommonVarElems1(ixDiff), [1:2,4]), ...
        contentTable2(ixCommonVarElems2(ixDiff),4)]];   


end

if ~isempty(varElemsDiffTable)
    varElemsDiffTable.Properties.VariableNames{1} = 'Variant';
    T = varElemsDiffTable;
    snippet = [snippet, sprintf('Change variant details for: %s\n', T.Variant)]
    disp(T)
end

function snippet = diffSpecies(spec1,spec2,name1,name2,fOut)

specNames1 = get(spec1,'Name');
specNames2 = get(spec2,'Name');

unq1 = setdiff(specNames1,specNames2);
unq2 = setdiff(specNames2,specNames1);
snippet = [];
if ~isempty(unq1)
    fprintf(fOut, 'The following species appear in %s but not %s:\n', name1, name2);   
    fprintf(fOut, '%s\n', unq1{:});
    snippet = [snippet, sprintf('Remove species: %s\n', strjoin(unq1, ', '))];
end

if ~isempty(unq2)
    fprintf(fOut, 'The following species appear in %s but not %s:\n', name2, name1);
    fprintf(fOut, '%s\n', unq2{:});
    snippet = [snippet, sprintf('Add species: %s\n', strjoin(unq2, ', '))];    
end

% initial values

init1 = get(spec1,'InitialAmount');
init2 = get(spec2,'InitialAmount');

[common, i1, i2] = intersect(specNames1,specNames2);
% check for different activation states
if isempty(common)
    return
end

ixDiff = [init1{i1}] ~= [init2{i2}];
if any(ixDiff)
    T = table({specNames1{i1(ixDiff)}}', [init1{i1(ixDiff)}]', [init2{i2(ixDiff)}]', ...
        'VariableNames', {'Species', name1, name2});
    snippet = [snippet, sprintf('Modify initial condition for: %s\n', strjoin(T.Species, ', '))];
    disp(T)
end

function snippet = diffParams(par1,par2,name1,name2,fOut)
parNames1 = get(par1,'Name');
parNames2 = get(par2,'Name');

unq1 = setdiff(parNames1,parNames2);
unq2 = setdiff(parNames2,parNames1);

snippet = [];

if ~isempty(unq1)
    fprintf(fOut, 'The following parameters appear in %s but not %s:\n', name1, name2);   
    fprintf(fOut, '%s\n\n', unq1{:});
    snippet = [snippet, sprintf('Remove parameters: %s\n', strjoin(unq1,', '))];
end

if ~isempty(unq2)
    fprintf(fOut, 'The following parameters appear in %s but not %s:\n', name2, name1);
    fprintf(fOut, '%s\n\n', unq2{:});
    snippet = [snippet, sprintf('Add parameters: %s\n', strjoin(unq2,', '))];    
end

% initial values

init1 = get(par1,'Value');
init2 = get(par2,'Value');

units1 = get(par1,'ValueUnits');
units2 = get(par2,'ValueUnits');

[common, i1, i2] = intersect(parNames1,parNames2);
% check for different activation states
if isempty(common)
    return
end

ixDiff = [init1{i1}] ~= [init2{i2}] | ~arrayfun(@(k) strcmp(units1{i1(k)},units2{i2(k)}), 1:numel(i1));
if any(ixDiff)
    fprintf('The following parameters differ between %s and %s:\n', name1, name2);
    T = table({parNames1{i1(ixDiff)}}', [init1{i1(ixDiff)}]', units1(i1(ixDiff)), [init2{i2(ixDiff)}]', units2(i2(ixDiff)), ...
        'VariableNames', {'Parameters', name1, [name1 '_Units'], name2, [name2 '_Units']});
    snippet = [snippet, sprintf('Modify parameter values or units for: %s\n', strjoin(T.Parameters, ', '))];
    disp(T)
end


function snippet = diffRxns(reac1,reac2,name1,name2,fOut)
reacNames1 = get(reac1,'Name');
reacNames2 = get(reac2,'Name');

unq1 = setdiff(reacNames1,reacNames2);
unq2 = setdiff(reacNames2,reacNames1);
snippet = [];

if ~isempty(unq1)
    fprintf(fOut, 'The following reactions appear in %s but not %s:\n', name1, name2);   
    fprintf(fOut, '%s\n', unq1{:});
    snippet = [snippet, sprintf('Remove reactions: %s\n', strjoin(unq1,', '))];
end

if ~isempty(unq2)
    fprintf(fOut, 'The following reactions appear in %s but not %s:\n', name2, name1);
    fprintf(fOut, '%s\n', unq2{:});
    snippet = [snippet, sprintf('Add reactions: %s\n', strjoin(unq2,', '))];        
end

% initial values

eqn1 = get(reac1,'ReactionRate');
eqn2 = get(reac2,'ReactionRate');

[common, i1, i2] = intersect(reacNames1,reacNames2);
% check for different activation states
if isempty(common)
    return
end

% ixDiff = [eqn1{i1}] ~= [init2{i2}];
eqnArray1 = {eqn1{i1}};
eqnArray2 = {eqn2{i2}};

ixDiff = arrayfun(@(k) ~strcmp(eqnArray1{k}, eqnArray2{k}), 1:length(common));
if any(ixDiff)
    T = table({reacNames1{i1(ixDiff)}}', {eqn1{i1(ixDiff)}}', {eqn2{i2(ixDiff)}}', ...
        'VariableNames', {'Reaction', name1, name2});    
    snippet = [snippet, sprintf('Change reaction rate for: %s\n', strjoin(T.Reaction, ', '))];
    disp(T)        
end

% check for active/inactive across models
reactActArray1 = cell2mat(get(reac1, 'Active'));
reactActArray1 = reactActArray1(i1);
reactActArray2 = cell2mat(get(reac2, 'Active'));
reactActArray2 = reactActArray2(i2);
ixDiff = arrayfun(@(k) ~isequal(reactActArray1(k), reactActArray2(k)), 1:length(common));
if any(ixDiff)
    fprintf(fOut, 'The activation state of the following reactions differ between model versions:\n');
    T = table(common(ixDiff), reactActArray1(ixDiff), reactActArray2(ixDiff), ...
        'VariableNames', {'Activation', name1, name2});
    snippet = [snippet, sprintf('Change reaction activation state for: %s\n', strjoin(T.Activation, ', '))];
    disp(T)            
end

function snippet = diffRules(rules1,rules2,name1,name2,fOut)

rulesNames1 = get(rules1,'Name');
rulesNames2 = get(rules2,'Name');

unq1 = setdiff(rulesNames1,rulesNames2);
unq2 = setdiff(rulesNames2,rulesNames1);

snippet = [];

if ~isempty(unq1)
    fprintf(fOut, 'The following rules appear in %s but not %s:\n', name1, name2);   
    fprintf(fOut, '%s\n', unq1{:});
    snippet = [snippet, sprintf('Remove rules: %s\n', strjoin(unq1,', '))];            
end

if ~isempty(unq2)
    fprintf(fOut, 'The following rules appear in %s but not %s:\n', name2, name1);
    fprintf(fOut, '%s\n', unq2{:});
    snippet = [snippet, sprintf('Add rules: %s\n', strjoin(unq2,', '))];            
end

[common, i1, i2] = intersect(rulesNames1,rulesNames2);
% check for different activation states
if isempty(common)
    return
end

% ixDiff = [eqn1{i1}] ~= [init2{i2}];
ruleArray1 = get(rules1, 'Rule');
ruleArray1 = ruleArray1(i1);
ruleArray2 = get(rules2, 'Rule');
ruleArray2 = ruleArray2(i2);
ixDiff = arrayfun(@(k) ~strcmp(ruleArray1{k}, ruleArray2{k}), 1:length(common));
if any(ixDiff)
    fprintf(fOut, 'The following rules differ between model versions:\n');
    T = table(common(ixDiff), {ruleArray1{ixDiff}}', {ruleArray2{ixDiff}}', ...
        'VariableNames', {'Rule', name1, name2});
    snippet = [snippet, sprintf('Change rules for: %s\n', strjoin(T.Rule, ', '))];
    disp(T)                
end

% check for active/inactive across models
ruleActArray1 = asCell(get(rules1, 'Active'));
ruleActArray1 = ruleActArray1(i1);
ruleActArray2 = asCell(get(rules2, 'Active'));
ruleActArray2 = ruleActArray2(i2);
ixDiff = arrayfun(@(k) ~isequal(ruleActArray1(k), ruleActArray2(k)), 1:length(common));
if any(ixDiff)
    fprintf(fOut, 'The activation state of the following rules differ between model versions:\n');
    T = table(common(ixDiff), ruleActArray1(ixDiff)', ruleActArray2(ixDiff)', ...
        'VariableNames', {'Activation', name1, name2});
    snippet = [snippet, sprintf('Change rule activation state for: %s\n', strjoin(T.Activation, ', '))];
    disp(T)            
end


function snippet = diffDose(dose1,dose2,name1,name2,fOut)

doseNames1 = get(dose1,'Name');
doseNames2 = get(dose2,'Name');

unq1 = setdiff(doseNames1,doseNames2);
unq2 = setdiff(doseNames2,doseNames1);
snippet = [];

if ~isempty(unq1)
    fprintf(fOut, 'The following doses appear in %s but not %s:\n', name1, name2);   
    fprintf(fOut, '%s\n', unq1{:});
    snippet = [snippet, sprintf('Remove doses: %s\n', strjoin(unq1,', '))];            
end

if ~isempty(unq2)
    fprintf(fOut, 'The following doses appear in %s but not %s:\n', name2, name1);
    fprintf(fOut, '%s\n', unq2{:});
    snippet = [snippet, sprintf('Add doses: %s\n', strjoin(unq2,', '))];           
end

[common, i1, i2] = intersect(doseNames1,doseNames2);
excludeFields = {'Parent', 'Annotation'};

doseElemsDiffTable = table(); 

for k=1:numel(common)
    fields1 = fields(dose1(i1(k)));
    fields2 = fields(dose2(i2(k)));
    fields1 = setdiff(fields1, excludeFields);
    fields2 = setdiff(fields2, excludeFields);

    unq1 = setdiff(fields1,fields2);
    unq2 = setdiff(fields2,fields1);
    tmpTable = table();
    if ~isempty(unq1)
        data1 = cellfun( @(s) dose1(i1(k)).(s), unq1, 'UniformOutput', false);
        tmpTable = vertcat(tmpTable, cell2table([repmat(common(k), size(data1)), unq1, data1, repmat('-', size(data1))]));
    end
    if ~isempty(unq2)
        data2 = cellfun( @(s) dose2(i2(k)).(s), unq2, 'UniformOutput', false);
        tmpTable = vertcat(tmpTable, cell2table([repmat(common(k), size(data1)), unq2, repmat('-', size(data2)), data2 ]));
    end
    
    [commonFields, ix1, ix2] = intersect(fields1,fields2);
    
    ixDiff = cellfun(@(f) ~isequal(dose1(i1(k)).(f), dose2(i2(k)).(f)), commonFields);
    if any(ixDiff)
        data1 = cellfun( @(s) dose1(i1(k)).(s), commonFields(ixDiff), 'UniformOutput', false);
        data2 = cellfun( @(s) dose2(i2(k)).(s), commonFields(ixDiff), 'UniformOutput', false);
        tmpTable = vertcat(tmpTable, cell2table([repmat(common(k), nnz(ixDiff), 1), commonFields(ixDiff), data1, data2]));
    end
    
    if ~isempty(tmpTable)
        if ~iscell(tmpTable.Var3)
            tmpTable.Var3 = num2cell(tmpTable.Var3);
        end
        if ~iscell(tmpTable.Var4)
            tmpTable.Var4 = num2cell(tmpTable.Var4);
        end
    end
    
%     try
        doseElemsDiffTable = vertcat(doseElemsDiffTable, tmpTable);
%     catch
%         disp(doseElemsDiffTable)
%         disp(tmpTable)
%     end
end
if ~isempty(doseElemsDiffTable)
    doseElemsDiffTable.Properties.VariableNames = {'Name', 'Field', name1, name2};
    T = doseElemsDiffTable;
    snippet = [snippet, sprintf('Change doses: %s\n', strjoin(T.Name, ', '))];
    disp(T)            
end
