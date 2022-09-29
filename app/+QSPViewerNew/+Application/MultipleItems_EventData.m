classdef MultipleItems_EventData < event.EventData
    % Using Items to refer to an array of QSP.* objects. 
    % But in the UI these are stored as NodeData. That is why the name
    % change here.
    properties
        Session (:,1) QSP.Session        
        Items (:,1)
    end

    methods
        function sd = MultipleItems_EventData(session, nodeData)
            sd.Session = session;
            sd.Items = nodeData;
        end
    end
end