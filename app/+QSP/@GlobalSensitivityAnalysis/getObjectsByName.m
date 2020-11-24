function matchingObjects = getObjectsByName(~, objects, names)
    % Filter objects by name and return matchingObjects whose Name property
    % matches entries in 'names'. The order of returned objects matches the
    % order of 'names'. 
    %  'objects': specified as vector of objects with a Name property
    %  'names'  : specified as character vector or cell array of
    %             character vectors of names
    
    [~, idx] = ismember(names, {objects.Name});
    matchingObjects = objects(idx);
    % TODOGSA, this assumes that object names are unique within
    % Parameters and within Tasks. Is this assumption justified?
    % TODOGSA: this also assumes that names is a subset of all names.

end
