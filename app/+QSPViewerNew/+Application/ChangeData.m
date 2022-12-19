classdef ChangeData < event.EventData
    properties
        change        
    end

    methods
        function sd = ChangeData(change)
            sd.change = change;            
        end
    end
end