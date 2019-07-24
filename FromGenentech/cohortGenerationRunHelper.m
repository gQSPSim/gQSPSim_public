function [StatusOK,Message,ResultsFileName,VpopName] = cohortGenerationRunHelper(obj)

% common setup code
% Function that generates a Virtual population by sampling parameter space,
% running simulations, and comparing the outputs to Acceptance Criteria.

StatusOK = true;
Message = '';
ResultsFileName = '';
VpopName = '';

%% update path to include everything in subdirectories of the root folder
myPath = path;
addpath(genpath(obj.Session.RootDirectory));

%% Check number of items
if numel(obj.Item) == 0
    StatusOK = false;
    Message = 'The number of items is 0.';
    path(myPath);
    return
end

%% Load Acceptance Criteria
Names = {obj.Settings.VirtualPopulationData.Name};
MatchIdx = strcmpi(Names,obj.DatasetName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulationData(MatchIdx);
    
    [ThisStatusOk,ThisMessage,accCritHeader,accCritData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    accCritHeader = {};
    accCritData = {};
end

%% Prepare species-data Mappings
Mappings = cell(length(obj.SpeciesData),2);
for ii = 1:length(obj.SpeciesData)
    Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
    Mappings{ii,2} = obj.SpeciesData(ii).DataName;
end


if ~isempty(accCritHeader) && ~isempty(accCritData)
    
    % filter out any acceptance criteria that are not included
    includeIdx = accCritData(:,strcmp('Include',accCritHeader));
    if ~isempty(includeIdx)
        param_candidate = cell2mat(includeIdx);
        accCritData = accCritData(param_candidate==1,:);
    end
    
    spIdx = ismember( accCritData(:,3), Mappings(:,2));
    % [Group, Species, Time, LB, UB]
    Groups = cell2mat(accCritData(spIdx,strcmp('Group',accCritHeader)));
    unqGroups = unique(Groups);
    Time = cell2mat(accCritData(spIdx,strcmp('Time',accCritHeader)));
    Species = accCritData(spIdx,strcmp('Data',accCritHeader));
    LB_accCrit = cell2mat(accCritData(spIdx,strcmp('LB',accCritHeader)));
    UB_accCrit = cell2mat(accCritData(spIdx,strcmp('UB',accCritHeader)));
else
    
    StatusOK = false;
    Message = 'The selected Acceptance Criteria file is empty.';
    path(myPath);
    return
end



%% Load Parameters
Names = {obj.Settings.Parameters.Name};
MatchIdx = strcmpi(Names,obj.RefParamName);
if any(MatchIdx)
    pObj = obj.Settings.Parameters(MatchIdx);
    [ThisStatusOk,ThisMessage,paramHeader,paramData] = importData(pObj,pObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    paramHeader = {};
    paramData = {};
end

if ~isempty(paramHeader) && ~isempty(paramData)
    % [Include, Name, Scale, LB, UB, P0_1, ...]
    % filter missing LB/UB
    ixValid = (~isnan(cell2mat(paramData(:,strcmp('LB',paramHeader)))) & ~isnan(cell2mat(paramData(:,strcmp('UB',paramHeader))))) | ...
        ~isnan(cell2mat(paramData(:,strcmp('P0_1',paramHeader))));
    paramData = paramData(ixValid,:);
    
    paramNames = paramData(:,strcmp('Name',paramHeader));
    Scale = paramData(:,strcmp('Scale',paramHeader));
    
    LB_params = cell2mat(paramData(:,strcmp('LB',paramHeader)));
    UB_params = cell2mat(paramData(:,strcmp('UB',paramHeader)));
    
    if any(strcmpi(paramHeader,'Dist'))
        Dist = paramData(:,strcmpi('Dist',paramHeader));
    else
        Dist = repmat({'uniform'}, size(LB_params));
    end
    
    
    if any(strcmpi('CV',paramHeader))
        CV_params = cell2mat(paramData(:,strcmpi('CV',paramHeader))); %MES add 2/14/2019
    else
        CV_params = zeros(size(LB_params)); 
    end
    
    useParam = paramData(:,strcmpi('Include',paramHeader));
    p0 = cell2mat(paramData(:,strcmpi('P0_1',paramHeader))); % MES edit to search header instead of column number 
    if isempty(useParam)
        useParam = repmat('yes',size(paramNames));
    end
    
    useParam = strcmpi(useParam,'yes');
    perturbParamNames = paramNames(useParam);
    fixedParamNames = paramNames(~useParam);
    logInds = strcmpi(Scale, 'log');
    
    LB = LB_params(useParam);
    UB = UB_params(useParam);
    CV = CV_params(useParam);
    P0_1 = p0(useParam);
    
    if any(isnan(LB) | isnan(UB))
        StatusOK = false;
        Message = 'At least one optimization parameter is missing a lower/upper bound. Check parameter file';
        path(myPath);
        return
    end
    
    logInds = logInds(useParam);
    
    LB(logInds) = log10(LB(logInds));
    UB(logInds) = log10(UB(logInds));
    fixedParams = p0(~useParam);
else
    %     LB_params = [];
    %     UB_params = [];
    StatusOK = false;
    Message = 'The selected Parameter file is empty.';
    path(myPath);
    return
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
        return
    end
else 
    ICTable = [];
end



%% For each task/group, load models and prepare for simulations

nItems = length(obj.Item);

obj.SimResults = {}; %cell(1,nItems);

for ii = 1:nItems
    
    % get the task obj from the settings obj
    tskInd = find(strcmp(obj.Item(ii).TaskName,{obj.Settings.Task.Name}));
    tObj_i = obj.Settings.Task(tskInd);
    
    % Validate
    [ThisStatusOk,ThisMessage] = validate(tObj_i,false);    
    if isempty(tObj_i)
        continue
    elseif ~ThisStatusOk
        warning('Error loading task %s. Skipping [%s]...', taskName,ThisMessage)
        continue
    end
    
    ItemModels.Task(ii) = tObj_i;
end % for

%% Sample parameter sets, simulate, compare to acceptance criteria
Vpop = zeros(obj.MaxNumSimulations,length(LB_params));
isValid = zeros(obj.MaxNumSimulations,1);

% set up the loop for different initial conditions
if isempty(ICTable )
    % no initial conditions specified
    groupVec = unqGroups;
    ixSpecies = [];
else
    % initial conditions exist
    groupVec = ICTable.data(:,groupCol);
    ixSpecies = setdiff(1:numel(ICTable.colheaders), groupCol); % columns of species in IC table
end

%% loop over the candidates until enough are generated

ViolationTable = [];
% param_candidate = LB + (UB-LB).*rand(size(LB)); % initial candidate
tmp = p0;
logInds = strcmp(Scale, 'log');

tmp(logInds) = log10(tmp(logInds));
logInds = logInds(useParam);

%% MES 2/13: indicate the indices that require normal distribution
normInds = strcmp(Dist, 'norm'); 
normInds = normInds(useParam); 
%%

param_candidate_old = tmp(useParam);
tune_param = obj.MCMCTuningParam; % percent of interval

P = param_candidate_old;
if any(P<LB | P>UB)
    warning('Initial parameter P0_1 outside search interval. Resetting to boundary.')
end


% generate args struct from objects
args = {'LB', 'UB', 'P0_1', 'CV', 'fixedParams', 'perturbParamNames', 'fixedParamNames', ...
    'logInds', 'unqGroups', 'Groups', 'groupVec', 'Species', 'ixSpecies', 'Time', 'LB_accCrit', 'UB_accCrit', 'ICTable', 'Mappings', 'normInds'} ;

args = cell2struct( cellfun(@(s) evalin('caller',s), args, 'UniformOutput', false), args, 2);


%% use parallel or serial version
if obj.Session.UseParallel
    [StatusOK,Message,isValid,Vpop,nPat,nSim,bCancelled] = cohortGenerationRunHelper_par(obj, args);
else
    [StatusOK,Message,isValid,Vpop,nPat,nSim,bCancelled] = cohortGenerationRunHelper_ser(obj, args);    
end

%%
bProceed = true;
if nPat == 0
    bProceed = questdlg('No valid virtual patients generated. Save virtual cohort?', 'Save virtual cohort?', 'No');
    if strcmp(bProceed,'Yes')
        StatusOK = true;
        bProceed = true;   %MES 2/22- added this to allow save vpop if statement to work
    else
        StatusOK = false;
        ThisMessage = 'No virtual patients generated.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        bProceed = false;  %MES 2/22- added this to allow save vpop if statement to work
    end
elseif bCancelled
    bProceed = questdlg('Cohort generation cancelled. Save virtual cohort?', 'Save virtual cohort?', 'No');
    StatusOK = true;
    if strcmp(bProceed,'Yes')      
        bProceed = true;
    else
        bProceed = false;
        StatusOK = false;
    end
end

% StatusOK = all([StatusOK{:}]);

if StatusOK && bProceed
    hWbar = uix.utility.CustomWaitbar(0,'Saving virtual cohort','Saving virtual cohort...',true);

    SaveFlag = true;
    % add prevalence weight
%     VpopHeader = [perturbParamNames; 'PWeight']';
    Names0 = [perturbParamNames; fixedParamNames];

    VpopHeader = [Names0; 'PWeight']';

   if strcmp(obj.SaveInvalid, 'Save valid vpatients')
        % filter out invalids
        Vpop = Vpop(isValid==1,:);
        isValid = true(size(Vpop,1),1);
   end    
    
    % replicate the vpops if multiple initial conditions were specified
    if nnz(isValid)>0
        PW = num2cell(isValid/nnz(isValid));
    else
        PW = num2cell(isValid);
    end
    PW = reshape(PW,[],1);
    
    VpopData = [num2cell(Vpop), PW];
    if ~isempty(ICTable)
        [bSpeciesData,idxSpeciesData] = ismember( ICTable.colheaders, obj.PlotSpeciesTable(:,4));
        ICTableHeaders = ICTable.colheaders;
        ICTableHeaders(bSpeciesData) = obj.PlotSpeciesTable( idxSpeciesData(bSpeciesData>0), 3);
        
        Vpop=[ICTableHeaders, VpopHeader];
        for k=1:size(ICTable.data,1) % loop over initial conditions
            Vpop = [Vpop; [num2cell(repmat(ICTable.data(k,:), size(VpopData,1),1)), VpopData] ];
        end
    else
        Vpop = [VpopHeader; VpopData ];
    end
    obj.PrevalenceWeights = cell2mat(Vpop(2:end,end));     % save prevalence weight to object
    
    % save results
    SaveFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName);
    if ~exist(SaveFilePath,'dir')
        [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
        if ~ThisStatusOk
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            SaveFlag = false;
        end
    end
    
%     obj.SimFlag = repmat(isValid, nIC, 1);
      
 
    
    if SaveFlag
        VpopName = ['Results - Cohort Generation = ' obj.Name ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS')];
        ResultsFileName = [VpopName '.xlsx'];
        if ispc
            try
                [ThisStatusOk,ThisMessage] = xlswrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
            catch error
                fName = regexp(error.message, '(C:\\.*\.mat)', 'match');
                if length(fName{1}) > 260
                    ThisMessage = sprintf('%s\n* Windows cannot save filepaths longer than 260 characters. See %s for more details.\n', ...
                       ThisMessage, 'https://www.howtogeek.com/266621/how-to-make-windows-10-accept-file-paths-over-260-characters/' );
                end
            end
        else
            [ThisStatusOk,ThisMessage] = xlwrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
        end
        if ~ThisStatusOk
            StatusOK = false;
            Message = sprintf('%s\n%s\n',Message,ThisMessage.message);
        end
    else
        StatusOK = false;
        ThisMessage = 'Could not save the output of virtual cohort generation.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
        
    delete(hWbar)
end

% restore path
path(myPath);

end


