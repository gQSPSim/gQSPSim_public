function [statusOk, message, sensitivityInputs, transformations, ...
    distributions, samplingInfo] = getParameterInfo(obj)
    % Get parameter information from a QSP.Parameters object. Only
    % information for parameters whose are specified to include in the
    % analysis are returned.
    %  'statusOk'         : logical scalar indicating if parameter import
    %                       was successful 
    %  'message'          : character vector containing information about
    %                       parameter import failure
    %  'sensitivityInputs': cell array of character vectors specifying 
    %                       names of parameters to include as sensitivity
    %                       inputs in the global sensitivity analysis
    %  'transformations'  : cell array of character vectors specifying 
    %                       transformations; 'linear' and 'log'
    %                       transformations are supported
    %  'distributions'    : cell array of character vectors specifying 
    %                       distributions; 'uniform' and 'normal'
    %                       distributions are supported. 
    %  'samplingInfo'     : numeric matrix with two columns. There is one
    %                       row per sensitivityInput. The values in each
    %                       row are interpreted as follows, dependent on
    %                       {transformation, distribution}:
    %                       - 'linear' & 'uniform' : [lb, ub]
    %                         meaning the values specified in the xlsx sheet
    %                         determine the sampling range
    %                       - 'linear' & 'log'     : [exp(lb), exp(ub)],
    %                         meaning the values specified in the xlsx sheet
    %                         determine the sampling range
    %                       - 'normal' & 'uniform' : [mu, sig] of normal distribution
    %                       - 'normal' & 'log'     : [mu, sig] of (non-log) normal distribution

    % Import included parameter information
    
    parameters = obj.getObjectsByName(obj.Settings.Parameters, obj.ParametersName);
    [statusOk, message, header, data] = parameters.importData(parameters.FilePath);
    tfInclude = strcmpi(data(:, strcmpi(header, 'include')), 'yes');
    data = data(tfInclude, :);
    
    
    sensitivityInputs = data(:, strcmpi(header, 'name'));
    numberSensitivityInputs = numel(sensitivityInputs);
    
    if nargout <= 3
        return
    end
    
    transformations = data(:, strcmpi(header, 'scale'));
    
    distributions = data(:, strcmpi(header, 'dist'));
    tfNormalDistribution = strcmp(distributions, 'normal');
    
    lb = data(:, strcmpi(header, 'lb'));
    ub = data(:, strcmpi(header, 'ub'));
    
    p0_1 = cell2mat(data(:, strcmpi(header, 'p0_1')));
    cv = nan(size(lb));
    if ismember('cv', header)
        cv = cell2mat(data(:, strcmpi(header, 'cv')));
    end
    
    samplingInfo = cell2mat([lb, ub]);
    samplingInfo(tfNormalDistribution, 1) = p0_1(tfNormalDistribution);
    samplingInfo(tfNormalDistribution, 2) = cv(tfNormalDistribution);
    
    statusOk = statusOk && ~any(isnan(samplingInfo), 'all');
    
end