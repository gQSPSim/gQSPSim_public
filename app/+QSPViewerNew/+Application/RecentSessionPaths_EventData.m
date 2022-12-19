classdef RecentSessionPaths_EventData < event.EventData
    % Using Items to refer to an array of QSP.* objects. 
    % But in the UI these are stored as NodeData. That is why the name
    % change here.
    properties
        Paths (:,1) string
    end

    methods
        function sd = RecentSessionPaths_EventData(paths)
            sd.Paths = paths;            
        end
    end
end
