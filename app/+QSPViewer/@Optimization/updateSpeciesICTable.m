function updateSpeciesICTable(vObj)

set(vObj.h.SpeciesICTable,...
    'ColumnName',{'Species','Data','f(x)'},...
    'ColumnEditable',[true true true],...
    'ColumnFormat',{vObj.SpeciesPopupTableItems(:),vObj.PrunedDatasetHeader(:),'char'});