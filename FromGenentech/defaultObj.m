function objVals = defaultObj(species,data,weights,simTime,dataTime,allData,ID,Grp,currID,currGrp)

allData = allData(~isnan(allData));

if length(allData) > 1 && range(allData) > 0
    objVals = weights.*abs(species(:)-data(:))./(range(allData));
else
    objVals = weights.*abs( species(:)-data(:))./mean(data(:));
end
    
end

