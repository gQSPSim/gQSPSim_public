classdef SessionEventData < event.EventData
    properties
        Session (1,1) QSP.Session
        ItemTypes
    end

    methods
        function sd = SessionEventData(session, itemTypes)
            sd.Session = session;
            sd.ItemTypes = itemTypes;
        end
    end
end