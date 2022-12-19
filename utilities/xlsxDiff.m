function msg = xlsxDiff(file1,file2,varargin)
msg = '';


try
    D1 = readtable(file1);
catch err
    warning('Error reading %s', file1);
    return
end

try
    D2 = readtable(file2);
catch err
    warning('Error reading %s', file2);
    return
end


% generic

% new cols
% cols1 = D1(1,:);
% cols2 = D2(1,:);

cols1 = D1.Properties.VariableNames;
cols2 = D2.Properties.VariableNames;

new12 = setdiff(cols1,cols2);
new21 = setdiff(cols2,cols1);

if ~isempty(new12)
    msg = sprintf('%s\nAdded columns %s', strjoin(new12,',') );
end

if ~isempty(new21)
    msg = sprintf('%s\nRemoved columns %s', strjoin(new12,',') );
end

% new rows
if size(D2,1) ~= size(D2,1)
    msg = sprintf('%s\nModified rows: new rows %d previously was %d', size(D1,1), size(D2,1));
end

if nargin>2 && strcmp(varargin{1},'vpop') && size(D1,1) == size(D2,1)
    for k=1:size(D1,2)
        val1 = D1(:,k);
        name1 = D1.Properties.VariableNames(k);
        
        [h,ix] = ismember(name1, D2.Properties.VariableNames);
        if h
            val2=D2(:,ix);
            if ~isequal(val1,val2)
                msg = sprintf('%s\nValues changed for %s', msg, name1{1});
            end
               
        end
    end
end

