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
    cohortData = {};
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
Mappings = cell(length(obj.SpeciesData),2);
for ii = 1:length(obj.SpeciesData)
    Mappings{ii,1} = obj.SpeciesData(ii).SpeciesName;
    Mappings{ii,2} = obj.SpeciesData(ii).DataName;
end


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
    cohortData = cohortData(:, ~ixPW);
end

simData = cell(nItems,1);
unqTime = unique(cell2mat(vpopGenData(:,strcmp(vpopGenHeader,'Time'))));
vpatData = cell(1,nItems);

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
        Values = cohortData(~ixGrp, cell2mat(cohortData(:,ixGrp))==str2num(obj.Item(ii).GroupID) ); 
    else
        Values = cohortData;
    end
    Values = cell2mat(Values);
        
%     OutputTimes = union(taskObj.OutputTimes, unique(vpopGenData(:,strcmp(vpopGenHeader,'Time'))));
    for vpatIdx = 1:size(Values,1)
        simData = taskObj.simulate(...
                    'Names', Names, ...
                    'Values', Values(vpatIdx,:), ...
                    'OutputTimes', unqTime);
        vpatData{ii}(:,:,vpatIdx) = simData.Data;
    end
    spNames = simData.DataNames;
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
tic
fprintf('Computing data statistics...')
for spIdx = 1:size(Mappings,1)
    thisSpecies = Mappings(spIdx,2);

    for itemIdx = 1:length(obj.Item)
        thisGrp = str2num(obj.Item(itemIdx).GroupID);
        
        for timeIdx = 1:numel(unqTime)
            thisData = vpopGenData( strcmp(vpopGenData(:,spCol),thisSpecies) & ...
                dataTimes == unqTime(timeIdx) & ...
                 dataGrps == thisGrp, :);
            thisType = thisData(:,typeCol);

            if numel(unique(thisType)) ~= 1
                StatusOK = false;
                Message = sprintf('%s\nInvalid vpop generation data. Only one type can be defined per species/time/group.\n', Message);
                return
            end
            
            % MEAN only
            spData = reshape(vpatData{itemIdx}(timeIdx,strcmp(thisSpecies,spNames),:), 1, []);
            dataMatrix = [dataMatrix; spData];
            Y = [Y; cell2mat(thisData(:,val1Col))];
            
            % if STD
            if strcmp(thisType, 'MEAN_STD')
               dataMatrix = [dataMatrix; (spData -  cell2mat(thisData(:,val1Col))).^2];
                Y = [Y; cell2mat(thisData(:,val2Col)).^2];         
                %TODO: use STD to compute uncertainty in the mean? requires
                %knowledge of sample size to get the std. err.
            end
        end
    end
end
toc

%% run the appropriate algorithm to get the prevalence weights
thisAlg = obj.MethodName;

if strcmp(thisAlg, 'Maximum likelihood')
    PW = computePW_MLE(dataMatrix,Y);    
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
    Vpop = [VpopHeader; cohortData, num2cell(PW)];
    % save results
    SaveFilePath = fullfile(obj.Session.RootDirectory,obj.VPopResultsFolderName);
    if ~exist(SaveFilePath,'dir')
        [ThisStatusOk,ThisMessage] = mkdir(SaveFilePath);
        if ~ThisStatusOk
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
            SaveFlag = false;
        end
    end
        
    if SaveFlag
        VpopName = ['Results - Vpop Generation = ' obj.Name ' - Date = ' datestr(now,'dd-mmm-yyyy_HH-MM-SS')];
        ResultsFileName = [VpopName '.xlsx'];
        if ispc
            [ThisStatusOk,ThisMessage] = xlswrite(fullfile(SaveFilePath,ResultsFileName),Vpop);
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
        
%     delete(hWbar)
end

% restore path
path(myPath);
end

