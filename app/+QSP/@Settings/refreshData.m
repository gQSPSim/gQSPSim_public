function [StatusOk,Message] = refreshData(obj, uiTF)
    % TODO: This should be a method of Settings. [REFACTOR]
    arguments
        obj(1,1) QSP.Settings
        uiTF(1,1) logical = false
    end
    
    if uiTF
        waitbar = @(arg1, arg2, arg3, arg4)uix.utility.CustomWaitbar(arg1, arg2, arg3, arg4);
    else
        waitbar = @(arg1, arg2, arg3, arg4)true;
    end
    
    StatusOk = true;
    Message = '';
    
    hWaitBar = waitbar(0, 'Loading session', '', true);    
    
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
        
        waitStatus = waitbar(index/numel(obj.Task), hWaitBar, 'Loading Tasks');
        
        if ~waitStatus % cancelled
            StatusOk = false;
            obj = QSP.Settings.empty;
            delete(hWaitBar)
            error('Settings:CancelledLoad', 'Cancelled load');
        end
    end
    
    if nargout==3
        varargout{1} = false;
    end
    
    
    %% Virtual Population
    
    for index = 1:numel(obj.VirtualPopulation)
        FilePath = obj.VirtualPopulation(index).FilePath;
        [ThisStatusOk,ThisMessage] = importData(obj.VirtualPopulation(index),FilePath);
        if ~ThisStatusOk
            StatusOk = false;
            Message = sprintf('%s\n%s\n',Message,ThisMessage);
        end
        
        waitStatus = waitbar(index/numel(obj.VirtualPopulation), hWaitBar, 'Loading Virtual Populations');
        
        if ~waitStatus % cancelled
            StatusOk = false;
            obj = QSP.Settings.empty;
            delete(hWaitBar)
            error('Settings:CancelledLoad', 'Cancelled load');
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
        
        waitStatus = waitbar(index/numel(obj.Parameters), hWaitBar, 'Loading Parameters');
        
        if ~waitStatus % cancelled
            StatusOk = false;
            obj = QSP.Settings.empty;
            delete(hWaitBar)
            error('Settings:CancelledLoad', 'Cancelled load');
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
        
        waitStatus = waitbar(index/numel(obj.OptimizationData), hWaitBar, 'Loading Optimization Data');
        
        if ~waitStatus % cancelled
            StatusOk = false;
            obj = QSP.Settings.empty;
            delete(hWaitBar)
            error('Settings:CancelledLoad', 'Cancelled load');
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
        
        waitStatus = waitbar(index/numel(obj.VirtualPopulationData), hWaitBar, 'Loading Virtual Population Data');
        
        if ~waitStatus % cancelled
            StatusOk = false;
            obj = QSP.Settings.empty;
            delete(hWaitBar)
            error('Settings:CancelledLoad', 'Cancelled load');
        end
    end
    
    if uiTF
        delete(hWaitBar)
    end
    
end