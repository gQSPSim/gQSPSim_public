function objVals = defaultObj(species,data,simTime,dataTime,allData,ID,Grp,currID,currGrp)

objVals = abs(species(:)-data(:))/(max(allData)-min(allData));

end

