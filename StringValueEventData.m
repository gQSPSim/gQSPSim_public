classdef StringValueEventData < event.EventData
    properties        
        name
        value (1,1) string
    end

    methods
        function sd = StringValueEventData(name, value)
            sd.name = name;
            sd.value = value;            
        end
    end
end