function vp = convertVP(worksheet)

for j = 1:numel(myWorksheet.vpDef)
    variants = myWorksheet.vpDef{1}.variants;
    vpName = myWorksheet.vpDef{1}.ID;
    
    tab = table;
    
    for i = 1:numel(variants)
        t = myWorksheet.model.getvariant(variants{i});
        
        names = string(arrayfun(@(x)x{1}{2}, t.Content, 'UniformOutput', false));
        values = arrayfun(@(x)x{1}{4}, t.Content, 'UniformOutput', false);
        values = [values{:}];
        
        % TODO: Need to check if columns already exist.
        tab = horzcat(tab, array2table(values, 'VariableNames', names'));
    end
    
end
end
