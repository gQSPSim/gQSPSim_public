function [Mappings, accCritData, ICTable, groupVec] = setupCohortGen(obj)
    % Prepare species-data Mappings
    Mappings = cell(length(obj.SpeciesData),2);
    for ii = 1:length(obj.SpeciesData)
        Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
        Mappings{ii,2} = obj.SpeciesData(ii).DataName;
    end


    %% Get Acceptance Criteria Info
    Names = {obj.Settings.VirtualPopulationData.Name};
    MatchIdx = strcmpi(Names,obj.DatasetName);

    if any(MatchIdx)
        vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);

        [StatusOK,Message,accCritData] = prepareAcceptanceCriteria(vpopObj, Mappings);
        if ~StatusOK
    %         path(myPath);
            return
        end
    else
        accCritData = struct();
    end
    
    
    %% Deal with initial conditions file if it is specified and exists
    if ~isempty(obj.ICFileName) && ~strcmp(obj.ICFileName,'N/A') && exist(obj.ICFileName, 'file')
     % get names from the IC file
        ICTable = importdata(obj.ICFileName);
      % validate the column names
        [hasGroupCol, groupCol] = ismember('Group', ICTable.colheaders);
        if ~hasGroupCol
            StatusOK = false;
            ThisMessage = 'Initial conditions file does not contain Group column';
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            return
        end

        % check that we are not specifying an initial condition for a species
        % that is also being sampled
        [~,ixConflictingParameters] = ismember( ICTable.colheaders, perturbParamNames);
        if any(ixConflictingParameters)
            StatusOK = false;
            Message = sprintf(['%s\nInitial conditions file contains species that are sampled in the cohort generation.  '...
                'To continue set Include=No for %s or remove them from the parameters file.\n'], ...
                Message, strjoin(perturbParamNames(ixConflictingParameters(ixConflictingParameters>0)), ','));
        end
    else 
        ICTable = [];
    end

    % set up the loop for different initial conditions
    nItems = length(obj.Item);
    
    if isempty(ICTable )
        % no initial conditions specified
        groupVec = 1:length(nItems);
    else
        % initial conditions exist
        groupVec = ICTable.data(:,groupCol);
        ixSpecies = setdiff(1:numel(ICTable.colheaders), groupCol); % columns of species in IC table
    end
end
