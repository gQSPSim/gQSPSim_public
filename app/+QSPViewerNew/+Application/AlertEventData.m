classdef AlertEventData < event.EventData
    properties        
        message
    end

    methods
        function sd = AlertEventData(message)
            sd.message = message;
        end
    end
end