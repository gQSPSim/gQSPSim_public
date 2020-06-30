% Script to drive running of gQSPSim tests on gitlab-runner.
% Want to put all testing infrastructure in this one directory
% however we want to run tests from the root gQSPSim directory.
cd ..

% Add gQSPSim to the path.
DefinePaths;

% Add test directory to the path. We need various parts of the model
% available on the path.
addpath(genpath('tests'));

disp('NOTE: Only running simulation tests.')

try
    results = runtests('tgQSPSim/tSimulations');
    if any([results.Failed])
        error('Some errors encountered. See log file for details.');
    end
catch e
    error(e.message)
end
