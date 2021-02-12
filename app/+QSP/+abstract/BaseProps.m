classdef (Abstract) BaseProps < matlab.mixin.SetGet & matlab.mixin.Heterogeneous & uix.mixin.AssignPVPairs & QSP.abstract.BasicBaseProps
    % BaseProps  A base class for the base properties for the backend
    % ---------------------------------------------------------------------
    % This is an abstract base class and cannot be instantiated.
    % It provides the following properties for its descendents:
    %     * Name
    %     * RelativeFilePath
    %     * Description
    %     * LastUpdate
    %
    % uix.abstract.BaseProps inherits properties and methods from
    % matlab.mixin.SetGet & uix.mixin.AssignPVPairs, and adds the following:
    %
    % uix.abstract.BaseProps Properties:
    %
    %     Name - Name of the object
    %
    %     RelativeFilePath - Path to the corresponding file
    %
    %     Description - Description of the usage
    %
    %     LastUpdate - The timestamp of the last property updated
    %
    %
    % Methods you must define in subclasses:
    %
    %   getSummary, validate
    %
    
    %   Copyright 2008-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 331 $
    %   $Date: 2016-10-05 18:01:36 -0400 (Wed, 05 Oct 2016) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties
        Session = QSP.Session.empty(1,0)
%         Name = ''    % Name
        RelativeFilePathParts = {''}
%         Description = '' % Description
        RelativeFilePath = ''
        
        bShowTraces = []
        bShowQuantiles = []
        bShowMean = []
        bShowMedian = []
        bShowSD = []
    end
    
    %% Dependent properties
    properties (Dependent=true, Access=private)
        SessionRoot
    end
    properties (Dependent=true)
        FilePath
        RelativeFilePath_new
%         LastSavedTimeStr        
    end
    
    %% Protected Properties
    properties (SetAccess=protected)
%         LastSavedTime = [] % Time at which the view was last saved        
%         LastValidatedTime = ''
    end
    
    %% Public methods
    methods
        function obj = BaseProps( varargin )
            
            % Assign PV pairs to properties
            obj.assignPVPairs(varargin{:});
            
        end % constructor       
        
        
                
    end % Public methods
    
    
    
    %% Protected methods
    methods (Access=protected)
        
        function copyProperty(obj,Property,Value)
            if isprop(obj,Property)
                obj.(Property) = Value;
            end
        end %function
        
    end
    
    %% Methods
    methods
        
%         function updateLastSavedTime(obj)
%             
%             obj.LastSavedTime = now;
%             
%         end %function
        
        function newObj = copy(obj,varargin)
            
            if nargin > 1 && isequal(class(obj),class(varargin{1})) && isequal(size(obj),size(varargin{1}))
                newObj = varargin{1};
            elseif nargin > 1 && ~isempty(varargin{1})
                % warning('Copy requires that the classes of the source and destination objects match in type and size');
                newObj = [];
            else
                newObj = [];
            end
            
            % Create a new object if one does not exist
            if isempty(newObj)
                % Get the object and structure size
                objSize = size(obj);
                ClassString = class(obj);
                fConstructor = str2func(ClassString);
                % TODO: Validate if this will work for arrays of objects
%                 oSizeCell = num2cell(objSize);
%                 % Initialize first
%                 tmpObj = fConstructor();
%                 if numel(obj) > 1
%                     tmpObj(oSizeCell{:}) = fConstructor();
%                 end
                tmpObj = fConstructor();
                tmpObj = repmat(tmpObj,objSize);
                newObj = tmpObj;
            end
        
            % What props can we set?
            %RAJ - this part could be made faster if we persist a list of classes and
            %retain the needed info. It seems slow when called a bunch of times. I
            %suspect these property attributes are dependent so a lot of queries are
            %made. %
            mc = metaclass(obj);
            pList = mc.PropertyList;
            isPublicOrProtectedProp = ...
                (strcmp({pList.SetAccess}, 'public') | strcmp({pList.SetAccess}, 'protected')) ...
                & (strcmp({pList.GetAccess}, 'public') | strcmp({pList.GetAccess}, 'protected'));
            isOkProp = isPublicOrProtectedProp & ...
                ~([pList.Constant] | [pList.Dependent] | [pList.NonCopyable]); % Removed [pList.Transient] for any Models to grab transient properties successfully
            
            % Get the object and structure properties
            okpList = pList(isOkProp);
            nokpList = pList(~isOkProp);
            okSetProps = {okpList.Name};
            noSetProps = {nokpList.Name};
            
            % Loop on properties to set in newObj, noting obj may be
            % arrays
            for pIdx = 1:numel(okSetProps)
                % Get the current property
                thisProp = okSetProps{pIdx};
                
                % Is this one of the existing properties? Is it settable?
                isThisProp = strcmp(okSetProps, thisProp);
                thisIsSettable = any(isThisProp);
                if thisIsSettable
                    % It is a settable prop. Just get the default value
                    if okpList(isThisProp).HasDefault
                        %RAJ - again this okpList is a bit slow. Would be better to
                        %persist the needed info for each utilized class somewhere.
                        defaultValue = okpList(isThisProp).DefaultValue;
                    elseif ~isempty(obj) && isvalid(obj)
                        defaultValue = obj(1).(thisProp);
                    else
                        defaultValue = [];
                    end
                elseif ~any(strcmp(noSetProps, thisProp)) && ~any(isprop(obj,thisProp))
                    % Try adding dynamic properties
                    NeedsAdd = ~isprop(obj,thisProp);
                    for idx=1:numel(obj)
                        if NeedsAdd(idx)
                            newProp = obj(idx).addprop(thisProp);
                            newProp.AbortSet = true;
                        end
                    end
                    thisIsSettable = true;
                    defaultValue = [];
                else
                    % Not settable at all and can't be added. Skip it.
                end
                
                % If it is settable, do it
                if thisIsSettable
                    
                    % Now, the expected return type defines how we resolve it. If the
                    % expected type is an object that derives from serializable, then
                    % we need to recurse into it.
                    if isa(defaultValue, 'QSP.abstract.BaseProps')
                        % It's a nested serializable object, so we can recursively
                        % convert from JSON
                        
                        % We need to loop on each instance of obj here, because
                        % the value of thisProp in each obj instance might be array of
                        % different sizes. Call this method recursively with each
                        % instance of newObj and populate the value from obj.
                        for idx = 1:numel(obj)
                            thisPropObj = obj(idx).(thisProp);
                            
                            % If empty, copy as is    
                            if isempty(thisPropObj)
                                newObj(idx).(thisProp) = copy(thisPropObj,[]);
                            else
                                % Otherwise, loop through
                                % If there are more elements in the newObj
                                % than the copy-from obj (thisPropObj),
                                % delete from newObj
                                if numel(newObj(idx).(thisProp)) > numel(thisPropObj) 
                                    delete(newObj(idx).(thisProp)((numel(thisPropObj)+1):end));
                                    newObj(idx).(thisProp)((numel(thisPropObj)+1):end) = [];
                                end
                                    
                                for propIdx = 1:numel(thisPropObj)
                                    if numel(newObj(idx).(thisProp)) >= propIdx
                                        newObj(idx).(thisProp)(propIdx) = copy(thisPropObj(propIdx),newObj(idx).(thisProp)(propIdx));
                                    else
                                        newObj(idx).(thisProp)(propIdx) = copy(thisPropObj(propIdx),[]);
                                    end
                                end
                            end
                        end
                        
                    elseif istable(defaultValue)
                        % Table types just need to be converted back to a table
                        
                        for idx = 1:numel(obj)
                            pValue = obj(idx).(thisProp);
                            if isempty(pValue)
                                if isempty(defaultValue)
                                    pValue = defaultValue;
                                else
                                    pValue = defaultValue([]);
                                end
                            end
                            pValue = struct2table(pValue);
                            copyProperty(newObj(idx),thisProp,pValue);                            
                        end
                        
                    else
                        % All other types are treated just by value, and receive no
                        % special treatment (struct, cell char, str, double, etc.)
                        
                        % We need to loop on each instance of obj here, because
                        % the value of thisProp in each obj instance might be array of
                        % different sizes.
                        for idx = 1:numel(obj)
                            if isvalid(obj)
                                pValue = obj(idx).(thisProp);
                            else
                                pValue=[];
                            end
                            if isempty(pValue)
                                if isempty(defaultValue)
                                    pValue = defaultValue;
                                else
                                    pValue = defaultValue([]);
                                end
                            elseif ischar(defaultValue) && ~iscell(pValue) % && iscell(pValue)
                                pValue = char(pValue);                            
                            end
                        
                            
                            copyProperty(newObj(idx),thisProp,pValue);                            
                        end
                        
                    end %if
                    
                end %if thisIsSettable
                
            end %for pIdx = 1:numel(sProps)
        end %function
        
        function initOptions(obj)
            initbShowTraces = false(1,12); % default off
            initbShowQuantiles = true(1,12); % default on
            initbShowSD = false(1,12); % default off
            
            if strcmpi(class(obj),'QSP.VirtualPopulationGeneration')
                initbShowMean = true(1,12); % default on
                initbShowMedian = false(1,12); % default off
            else
                initbShowMean = false(1,12); % default off
                initbShowMedian = true(1,12); % default on
            end
            
            % For compatibility
            if isempty(obj.bShowTraces)
                obj.bShowTraces = initbShowTraces;
            end
            if isempty(obj.bShowQuantiles)
                obj.bShowQuantiles = initbShowQuantiles;
            end
            if isempty(obj.bShowMean)
                obj.bShowMean = initbShowMean;
            end
            if isempty(obj.bShowMedian)
                obj.bShowMedian = initbShowMedian;
            end
            if isempty(obj.bShowSD)
                obj.bShowSD = initbShowSD;
            end
        end %function
        
    end % methods
    
    %% Get/Set methods
    methods
        
%         function set.Name(obj,value)
%             validateattributes(value,{'char'},{})
%             obj.Name = value;
%         end
        
        function set.RelativeFilePath_new(obj,value)
            validateattributes(value,{'char'},{})
            obj.RelativeFilePathParts = strsplit(value,filesep);
        end
        
        function Value = get.RelativeFilePath_new(obj)
            Value = strjoin(obj.RelativeFilePathParts,filesep);
        end
        
%         function set.Description(obj,value)
%             validateattributes(value,{'char'},{})
%             obj.Description = value;
%         end
        
%         function set.LastSavedTime(obj,value)    
%             if ischar(value)
%                 if isempty(value)
%                     value = [];
%                 else
%                     value = datenum(value);
%                 end
%             end
%             obj.LastSavedTime = value;
%         end
%         
%         function value = get.LastSavedTimeStr(obj)
%             value = datestr(obj.LastSavedTime);
%         end
        
        function value = get.SessionRoot(obj)
            if isscalar(obj.Session)
                value = obj.Session.RootDirectory;
                if obj.Session.UseParallel && ~isempty(getCurrentWorker)
                    newRoot = getAttachedFilesFolder(value);
                    if ~isempty(newRoot)
                        obj.Session.RootDirectory = newRoot; % update session root
                        value = newRoot;
                    end
                end                
            else
                value = '';
            end
        end
        
        function value = get.FilePath(obj)
            value = fullfile(obj.SessionRoot, obj.RelativeFilePath_new);       
            if isempty(value)
                return
            end
            
        end
        
        function set.FilePath(obj,value)
            validateattributes(value,{'char'},{})
            obj.RelativeFilePath_new = uix.utility.getRelativeFilePath(value, obj.SessionRoot, false);
        end
        
    end %methods
    
    
    %% API methods
    methods
        
        function Remove(obj)
            
            FuncType = class(obj);
            Type = regexprep(FuncType,'QSP\.','');
            
            % Get its parent container
            if isprop(obj,'Settings') && isprop(obj.Settings,Type)
                containerObj = obj.Settings;
            elseif isprop(obj,'Session') && isprop(obj.Session,Type)
                containerObj = obj.Session;
            elseif isprop(obj,'Session') && isprop(obj.Session.Settings,Type)
                containerObj = obj.Session.Settings;                
            else
                containerObj = [];
            end
            
            % Delete
            delete(obj)
            
            % Remove from its parent container
            if ~isempty(containerObj)
                containerObj.(Type)(~isvalid(containerObj.(Type))) = [];
            end
            
        end %function
        
        function newObj = Replicate(obj)
            
            FuncType = class(obj);
            ThisFcn = str2func(FuncType);
            newObj = ThisFcn();
            
            % Copy
            newObj = copy(obj,newObj);
            updateLastSavedTime(newObj);
            
            Type = regexprep(FuncType,'QSP\.','');
            
            if isprop(obj,'Settings') && isprop(obj.Settings,Type)
                AllNames = {obj.Settings.(Type).Name}; 
            elseif isprop(obj,'Session') && isprop(obj.Session,Type)
                AllNames = {obj.Session.(Type).Name};
            elseif isprop(obj,'Session') && isprop(obj.Session.Settings,Type)
                AllNames = {obj.Session.Settings.(Type).Name};
            else
                AllNames = {};
            end
            
            if isprop(obj,'Session')
                newObj.Session = obj.Session;
            end
            
            if isprop(obj,'Settings')
                newObj.Settings = obj.Settings;
            end
            
            switch Type
                case 'VirtualPopulationGenerationData'
                    NewName = 'New Target Statistics';
                case 'VirtualPopulationData'
                    NewName = 'New Acceptance Criteria';
                otherwise
                    NewName = sprintf('New %s',Type);
            end
            
            newObj.Name =  matlab.lang.makeUniqueStrings(NewName,AllNames);
            
            if isprop(obj,'Settings') && isprop(obj.Settings,Type)
                obj.Settings.(Type)(end+1) = newObj;
            elseif isprop(obj,'Session') && isprop(obj.Session,Type)
                obj.Session.(Type)(end+1) = newObj;
            elseif isprop(obj,'Session') && isprop(obj.Session.Settings,Type)
                obj.Session.Settings.(Type)(end+1) = newObj;
            else
                warning('Could not add replicated object to Session or Settings');
            end
            
        end %function
    end %methods (API)
    
end % classdef