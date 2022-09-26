classdef NewSessionEventData < event.EventData
    properties
        Session (1,1) QSP.Session
        buildingBlockTypes cell
        functionalityTypes cell
    end

    methods
        function sd = NewSessionEventData(session, buildingBlockTypes, functionalityTypes)
            sd.Session = session;
            sd.buildingBlockTypes = buildingBlockTypes;
            sd.functionalityTypes = functionalityTypes;
        end
    end
end