function vp = convertVP(worksheet)
    % CONVERTVP(worksheet) converts QSPToolbox VP definitions to xlsx files
    % appropriate for loading into gQSPSim.
    
    vp = table;
    
    for j = 1:numel(worksheet.vpDef)
        variants = worksheet.vpDef{j}.variants;
        vpName   = worksheet.vpDef{j}.ID;
        
        tab = table;
        
        for i = 1:numel(variants)
            t = worksheet.model.getvariant(variants{i});
            
            names = string(arrayfun(@(x)x{1}{2}, t.Content, 'UniformOutput', false));
            values = arrayfun(@(x)x{1}{4}, t.Content, 'UniformOutput', false);
            values = [values{:}];
            
            % TODO: Need to check if columns already exist.
            tab = horzcat(tab, array2table(values, 'VariableNames', names'));            
        end        
        tab.Properties.RowNames = vpName;
        vp = vertcat(vp, tab);
    end
    vp = tab;
end
