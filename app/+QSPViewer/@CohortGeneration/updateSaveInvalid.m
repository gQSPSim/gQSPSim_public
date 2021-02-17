function updateSaveInvalid(vObj)

if ~isempty(vObj.TempData)
    options = {'Save all virtual subjects','Save valid virtual subjects'};
    matchIdx = find(strcmpi(vObj.TempData.SaveInvalid,options));
    set(vObj.h.SaveInvalidPopup,'Value',matchIdx);
else
    set(vObj.h.SaveInvalidPopup,'Value',1);
end