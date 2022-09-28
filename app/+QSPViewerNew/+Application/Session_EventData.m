classdef Session_EventData < event.EventData
    properties
        Session (:,1) QSP.Session        
    end

    methods
        function sd = Session_EventData(session)
            sd.Session = session;
        end
    end
end