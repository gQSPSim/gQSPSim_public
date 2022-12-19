classdef NewItemAddedEventData < event.EventData
    properties        
        newItem
        itemType (1,1) string
    end

    methods
        function sd = NewItemAddedEventData(newItem, itemType)
            sd.newItem = newItem;
            sd.itemType = itemType;            
        end
    end
end