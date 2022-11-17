
function [StatusOK,Message,ResultsFileName,VpopName] = vpopGenerationRunHelper(obj)
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

%% load selected cohort
Names = {obj.Settings.VirtualPopulation.Name};
MatchIdx = strcmpi(Names, obj.DatasetName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulation(MatchIdx);
    
    [ThisStatusOk,Message,cohortHeader,cohortData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    cohortHeader = {};
    cohortData = [];
end


%% load selected vpop generation data
Names = {obj.Settings.VirtualPopulationGenerationData.Name};
MatchIdx = strcmpi(Names, obj.VpopGenDataName);

if any(MatchIdx)
    vpopObj = obj.Settings.VirtualPopulationGenerationData(MatchIdx);
    
    [StatusOk,Message,vpopGenHeader,vpopGenData] = importData(vpopObj,vpopObj.FilePath);
    if ~ThisStatusOk
        StatusOK = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
else
    vpopGenHeader = {};
    vpopGenData = {};
end

%% Prepare species-data Mappings
% Mappings = cell(length(obj.SpeciesData),2);
% for ii = 1:length(obj.SpeciesData)
%     Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
%     Mappings{ii,2} = obj.SpeciesData(ii).DataName;
% end


%% For each task/group, load models and prepare for simulations

nItems = length(obj.Item);

obj.SimResults = {}; %cell(1,nItems);

% names of model parameters/species values to be set
ixGrp = strcmp(cohortHeader,'Group');
if any(ixGrp)
    Names = cohortHeader(~ixGrp); % first column is the group
else
    Names = cohortHeader;
end

ixPW = strcmp(Names,'PWeight');
if any(ixPW)
    Names = Names(~ixPW);
    cohortData = cohortData(cohortData(:,ixPW)>0, ~ixPW);  % drop zero-weight vpatients
end

simData = cell(nItems,1);
unqTime = unique(cell2mat(vpopGenData(:,strcmp(vpopGenHeader,'Time'))));
vpatData = cell(1,nItems);
Title2 = sprintf('Simulating tasks...');
if obj.Session.ShowProgressBars
    hWbar2 = uix.utility.CustomWaitbar(0,Title2,'',true);
end
Cancelled = false;

for ii = 1:nItems
    
    % get the task obj from the settings obj
    tskInd = find(strcmp(obj.Item(ii).TaskName,{obj.Settings.Task.Name}));
    taskObj = obj.Settings.Task(tskInd);
    
    % Validate
    [ThisStatusOk,ThisMessage] = validate(taskObj,false);    
    if isempty(taskObj)
        continue
    elseif ~ThisStatusOk
        warning('Error loading task %s. Skipping [%s]...', taskName,ThisMessage)
        continue
    end

%     ixGrp =  
    if any(ixGrp)
%         Values = cohortData(~ixGrp, cell2mat(cohortData(:,ixGrp))==str2num(obj.Item(ii).GroupID) ); 
        Values = cohortData(cohortData(:,ixGrp)==str2num(obj.Item(ii).GroupID), ~ixGrp ); % TODO verify that this is correct

    else
        Values = cohortData;
    end
        
%     OutputTimes = union(taskObj.OutputTimes, unique(vpopGenData(:,strcmp(vpopGenHeader,'Time'))));
    if obj.Session.ShowProgressBars    
        set(hWbar2, 'Name', sprintf('Simulating task %d of %d',ii,nItems))
        uix.utility.CustomWaitbar(0,hWbar2,'');
    end
    nPatients = size(Values,1);
    FailedVpatIdx = [];
    ThisTaskMessage = '';
    for vpatIdx = 1:nPatients
        if obj.Session.ShowProgressBars
            StatusOK = uix.utility.CustomWaitbar(vpatIdx/nPatients, hWbar2, sprintf('Simulating vpatient %d/%d', vpatIdx, nPatients));
        end
        
        % update wait bar
        if ~StatusOK
            Cancelled=true;
            break
        end
        
        [simData,ThisStatusOk,ThisTaskMessage] = taskObj.simulate(...
            'Names', Names, ...
            'Values', Values(vpatIdx,:), ...
            'OutputTimes', unqTime);
        if ~ThisStatusOk
            FailedVpatIdx = [FailedVpatIdx vpatIdx]; %#ok<AGROW>
            continue;
        end
                
        thisData = zeros(length(unqTime), length(obj.SpeciesData)); % temporary object for transforming data for relevant species
        
        % get full data names
        if length(taskObj.ModelObj.mObj.Compartments) > 1
            fullnames = cellfun(@(x) sprintf('%s.%s', x.Compartment, x.Name), simData.DataInfo, 'UniformOutput', false);
        else
            fullnames = simData.DataNames;
        end
        
        for idxSpecies = 1:length(obj.SpeciesData)
            thisData(:,idxSpecies) = obj.SpeciesData(idxSpecies).evaluate(...
                simData.Data(:,strcmp(fullnames,obj.SpeciesData(idxSpecies).SpeciesName)));                       
        end 
        vpatData{ii}(:,:,vpatIdx) = thisData;
    end
    
    if ~isempty(FailedVpatIdx)
        ThisMessage = sprintf('Task simulation failed for virtual patients:\n%s\nPossible cause due to %s',strjoin(string(FailedVpatIdx),','),ThisTaskMessage);
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
        return;
    end
    
    
    if Cancelled
        break
    end
end

if obj.Session.ShowProgressBars && ~isempty(hWbar2)
    delete(hWbar2)
end

if Cancelled
    Message = 'Simulation cancelled';
    return
end
%% get the desired statistics/distribution from the vpopGen

% loop over species in the mapping
spCol = find(strcmp(vpopGenHeader,'Species'));
grpCol = find(strcmp(vpopGenHeader,'Group'));
timeCol = find(strcmp(vpopGenHeader,'Time'));
typeCol = find(strcmp(vpopGenHeader,'Type'));
val1Col = find(strcmp(vpopGenHeader,'Value1'));
val2Col = find(strcmp(vpopGenHeader,'Value2'));


allVpopGenData = [];
dataTimes = cell2mat(vpopGenData(:,timeCol));
dataGrps = cell2mat(vpopGenData(:,grpCol));
Y = []; % observed statistics
X = []; % simulated statistics
dataMatrix = [];
sigY = []; % uncertainty in statistics

M = []; % membership matrix for matching distributions
f = [];

tic
fprintf('Computing data statistics...')
if obj.Session.ShowProgressBars
    hWbar2 = uix.utility.CustomWaitbar(0,'Please wait', 'Computing data statistics...', false);
end

for spIdx = 1:length(obj.SpeciesData)
    thisSpecies = obj.SpeciesData(spIdx).SpeciesName;
    thisDataName = obj.SpeciesData(spIdx).DataName;
    
    for itemIdx = 1:length(obj.Item)
        thisGrp = str2num(obj.Item(itemIdx).GroupID);
        
        for timeIdx = 1:numel(unqTime)
            thisData = vpopGenData( strcmp(vpopGenData(:,spCol),thisDataName) & ...
                dataTimes == unqTime(timeIdx) & ...
                 dataGrps == thisGrp, :);
             if isempty(thisData)
                 continue
             end
             
            thisType = thisData(:,typeCol);

                
            if numel(unique(thisType)) ~= 1 && ~all(ismember(upper(thisType), {'DIST_BINS','DIST_DENSITY'})) 
                StatusOK = false;
                Message = sprintf('%s\nInvalid vpop generation data. Only one type can be defined per species/time/group.\n', Message);
                return
            end
            
            spData = reshape(vpatData{itemIdx}(timeIdx,spIdx,:), 1, []);
            
            % MEAN only
            if strcmpi(thisType, 'MEAN')
                dataMatrix = [dataMatrix; spData];
                Y = [Y; mean(cell2mat(thisData(:,val1Col)))];
            end
            
            % MEAN + STD
            if strcmpi(thisType, 'MEAN_STD')
               dataMatrix = [dataMatrix; (spData -  cell2mat(thisData(:,val1Col))).^2];
                Y = [Y; mean(cell2mat(thisData(:,val2Col)).^2)];         
                %TODO: use STD to compute uncertainty in the mean? requires
                %knowledge of sample size to get the std. err.
            end
            
            % constraints on the distribution            
            % bin definition
            if all(ismember({'DIST_BINS', 'DIST_DENSITY'}, upper(thisType)) )
                bins = cell2mat(thisData(strcmpi(thisType, 'DIST_BINS'),5:end));
                density = cell2mat(thisData(strcmpi(thisType, 'DIST_DENSITY'),5:end-1));
                
                % add rows to the membership matrix for each bin of this distribution
                M = [M; spData >= bins(1:end-1)' & spData <= bins(2:end)' ];
                f = [f; density'/sum(density)];
            end
                    
            
        end
    end
end
toc

%% run the appropriate algorithm to get the prevalence weights
thisAlg = obj.MethodName;

if strcmp(thisAlg, 'Maximum likelihood')
%     PW = computePW_MLE(dataMatrix,Y);    
    redistributePW = obj.RedistributeWeights;
    minVpats = min(obj.MinNumVirtualPatients, nPatients);
    
                     if obj.Session.ShowProgressBars
    uix.utility.CustomWaitbar(0, hWbar2, 'Computing prevalence weights...');
                     end
    
    if ~isempty(dataMatrix) 
        PW = computePW_MLE(dataMatrix,Y,diag(0.1 * abs(Y) + 1e-3),minVpats, redistributePW, M, f); 

    elseif ~isempty(M) && ~isempty(f)
        % matching distributions only
        PW = computePW_MLE(M,f, diag(0.05 * abs(f) + 1e-3) );

    end

elseif strcmp(thisAlg, 'Bayesian')
    disp('pass')
end




% Save the Vpop
if StatusOK
%     hWbar = uix.utility.CustomWaitbar(0,'Saving virtual population','Saving virtual population...',true);

    SaveFlag = true;
    % add prevalence weight
    if any(ixGrp)
        VpopHeader = ['Group', Names, 'PWeight'];
    else
        VpopHeader = [Names, 'PWeight'];
    end

    obj.PrevalenceWeights = PW;     % save prevalence weight to object
    Vpop = [VpopHeader; num2cell(cohortData), num2cell(PW)];
    % save results
    SaveFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName_new);
    if ~exist(SaveFilePath,'dir')
        [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
        if ~ThisStatusOk
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            SaveFlag = false;
        end
    end
        
    if SaveFlag
        if obj.Session.ShowProgressBars
            uix.utility.CustomWaitbar(0,hWbar2,'Writing vpop to disk...');    
        end
        
        VpopName = ['Results - Vpop Generation = ' obj.Name ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS')];
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
        ThisMessage = 'Could not save the output of virtual population generation.';
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
        
    if obj.Session.ShowProgressBars && ~isempty(hWbar2)
        delete(hWbar2)
    end
end

% restore path
path(myPath);
end

