function [Header, Data, StatusOK, Message] = xlread(filepath)
StatusOK = true;
Message = '';
Header = {};
Data = {};

try
    if verLessThan('matlab', '9.8')
        data = readtable(filepath);
    else
        data = readtable(filepath, 'PreserveVariableNames', true);
    end
catch error
    Message = error.message;
    return
end

% The behavior of readtable changed relative to headers having valid MATLAB
% variable names in XXX.
if verLessThan('matlab', '9.8')
    Header = data.Properties.VariableNames;
    if ~isempty(data.Properties.VariableDescriptions)
        idxConverted = arrayfun(@(k) ~isempty(data.Properties.VariableDescriptions{k}), 1:size(data,2));
        
        for k = find(idxConverted)
            tmp = regexp(data.Properties.VariableDescriptions{k}, 'Original column heading: ''(.*)''', 'tokens');
            Header{k} = tmp{1}{1};
        end
    end
else
    Header = data.Properties.VariableNames;
end

try
    Data = table2cell(data);
catch error
    warning(error.message)
end


