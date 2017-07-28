function [StatusOk,Message] = refreshData(obj)

StatusOk = true;
Message = '';


%% Task

for index = 1:numel(obj.Task)
    ProjectPath = obj.Task(index).FilePath;
    ModelName = obj.Task(index).ModelName;
    MaxWallClockTime = obj.Task(index).MaxWallClockTime;
    [ThisStatusOk,ThisMessage] = importModel(obj.Task(index),ProjectPath,ModelName);
    obj.Task(index).MaxWallClockTime = MaxWallClockTime;
    if ~ThisStatusOk
        StatusOk = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
end


%% Virtual Population

for index = 1:numel(obj.VirtualPopulation)
    FilePath = obj.VirtualPopulation(index).FilePath;
    [ThisStatusOk,ThisMessage] = importData(obj.VirtualPopulation(index),FilePath);
    if ~ThisStatusOk
        StatusOk = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
end


%% Parameters

for index = 1:numel(obj.Parameters)
    FilePath = obj.Parameters(index).FilePath;
    [ThisStatusOk,ThisMessage] = importData(obj.Parameters(index),FilePath);
    if ~ThisStatusOk
        StatusOk = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
end


%% Optimization Data

for index = 1:numel(obj.OptimizationData)
    FilePath = obj.OptimizationData(index).FilePath;
    [ThisStatusOk,ThisMessage] = importData(obj.OptimizationData(index),FilePath);
    if ~ThisStatusOk
        StatusOk = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
end


%% Virtual Population Data

for index = 1:numel(obj.VirtualPopulationData)
    FilePath = obj.VirtualPopulationData(index).FilePath;
    [ThisStatusOk,ThisMessage] = importData(obj.VirtualPopulationData(index),FilePath);
    if ~ThisStatusOk
        StatusOk = false;
        Message = sprintf('%s\n%s\n',Message,ThisMessage);
    end
end
