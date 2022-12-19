classdef NewItemEventData < event.EventData
    properties
        Session (1,1) QSP.Session
        type string
    end

    methods
        function sd = NewItemEventData(session, type)
            sd.Session = session;
            sd.type = type;
        end
    end
end