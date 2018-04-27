function constructModel(obj)
% construct the model and export it for simulation

    % extract model
    model = obj.ModelObj;

    % apply the active variants (if specified)
    if ~isempty(obj.ActiveVariantNames)
        % turn off all variants
        varObj_i = getvariant(model);
        set(varObj_i,'Active',false);

        % combine active variants in order into a new variant, add to the
        % model and activate
        [~,tmp] = ismember(obj.ActiveVariantNames, obj.VariantNames);
%         varObj_i = model.variant(tmp);
        for k=1:length(tmp)
            commit(model.variant(tmp(k)), model)
            
        end
%         model = CombineVariants(model,varObj_i);
    end % if

    % inactivate reactions (if specified)
    % turn on all reactions
    set(model.Reactions,'Active',true);        
    if ~isempty(obj.InactiveReactionNames)
        % turn off inactive reactions
        set(model.Reactions(ismember(obj.ReactionNames, obj.InactiveReactionNames)),'Active',false);
    end % if
    
    % turn on all rules
    set(model.Rules,'Active',true);
    % inactivate rules (if specified)
    if ~isempty(obj.InactiveRuleNames)        

        % turn off inactive rules
        set(model.Rules(ismember(obj.RuleNames,obj.InactiveRuleNames)),'Active',false);
    end % if
    
    % get all parameter names
    params = sbioselect(model, 'Type', 'Parameter');
        
    % get all species names
    species = sbioselect(model, 'Type', 'Species');
    expModel = export(model, [species; params]);   
        
    % set MaxWallClockTime in the exported model
    if ~isempty(obj.MaxWallClockTime)
        expModel.SimulationOptions.MaximumWallClock = obj.MaxWallClockTime;
    else
        expModel.SimulationOptions.MaximumWallClock = obj.DefaultMaxWallClockTime;
    end
    
    % set the output times
    if ~isempty(obj.OutputTimes)
        expModel.SimulationOptions.OutputTimes = obj.OutputTimes;
    else
        expModel.SimulationOptions.OutputTimes = obj.DefaultOutputTimes;
    end % if
       
    try
        accelerate(expModel)
    catch ME
        warn('Model acceleration failed. Check that you have a compiler installed and setup. %s', ME.message);        
    end 
    
    % export the model
    obj.VarModelObj = model;
    obj.ExportedModel = expModel;    
    
    % update time stamp
    obj.ExportedModelTimeStamp = now;
end