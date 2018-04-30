function updateEditView(vObj)
% updateEditView - Updates all parts of the viewer display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the viewer display
%
% Syntax:
%           updateEditView(vObj)
%
% Inputs:
%           vObj - The MyPackageViewer.Empty vObject
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2014-2015 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 319 $  $Date: 2016-09-10 21:44:01 -0400 (Sat, 10 Sep 2016) $
% ---------------------------------------------------------------------

%% Update Results directory

updateResultsDir(vObj);


%% Refresh dataset

refreshDataset(vObj);


%% Refresh Items Table

refreshItemsTable(vObj);

%% Refresh SpeciesData Table

refreshSpeciesDataTable(vObj);


%% Update ParametersPopup

refreshParameters(vObj);


%% Update MaxNumSimulations

updateMaxNumSims(vObj);


%% Update MaxNumVirtualPatients

updateMaxNumVirtualPatients(vObj);

%% set initial conditions file
set(vObj.h.ICFileSelector,'Value',vObj.Data.ICFileName);
