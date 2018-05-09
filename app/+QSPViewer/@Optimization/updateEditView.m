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
%   $Revision: 318 $  $Date: 2016-09-09 17:22:35 -0400 (Fri, 09 Sep 2016) $
% ---------------------------------------------------------------------


%% Refresh Dataset

refreshDataset(vObj);


%% Update ItemsTable

refreshItemsTable(vObj);


%% Update SpeciesDataTable

refreshSpeciesDataTable(vObj);


%% Update SpeciesICTable

refreshSpeciesICTable(vObj);


%% Update Parameters

refreshParameters(vObj);


%% Update Results directory

updateResultsDir(vObj);


%% Update AlgorithmsPopup

updateAlgorithms(vObj);


