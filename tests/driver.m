% Script to drive running of gQSPSim tests on gitlab-runner.
run('../DefinePaths.m');
results = runtests;

if any([results.Failed])
    error('Some errors encountered. See log file for details.');
end

