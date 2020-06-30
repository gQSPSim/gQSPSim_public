% Script to drive running of gQSPSim tests on gitlab-runner.
% Want to put all testing infrastructure in this one directory
% however we want to run tests from the root gQSPSim directory.
currentPWD = pwd;
cd ..

% Add gQSPSim to the path.
DefinePaths;

% Add test directory to the path. We need various parts of the model
% available on the path.
addpath(genpath('tests'));

disp('NOTE: Only running simulation tests.')

try
    results = runtests('tgQSPSim/tSimulations');
catch e
    warning(e.message)
    exit(1)
end

if any([results.Failed])
    warning('Some errors encountered. See log file for details.');
    cd(currentPWD);
    exit(1)
else
    cd(currentPWD);
    exit
end
