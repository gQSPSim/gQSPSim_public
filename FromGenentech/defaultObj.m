function objVals = defaultObj(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)

allData = allData(~isnan(allData));

if length(allData) > 1 && range(allData) > 0
    objVals = abs(species(:)-data(:))/(range(allData));
else
    objVals = abs( species(:)-data(:))/mean(data(:));
end
    
end

